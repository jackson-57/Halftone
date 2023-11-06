#include "audio.h"
#include "audio_internal.h"
#include "shared_pd.h"
#include "shared_opusfile.h"
#include "shared_audio.h"
#include <speex_resampler.h>

#define OPUS_BUFFER_SIZE 11520
#define SPEEX_BLOCK_COUNT 32
//#define SPEEX_QUALITY 5
#define SPEEX_QUALITY 0

// Simple buffer struct
typedef struct {
    // Interleaved samples
    int16_t buf[OPUS_BUFFER_SIZE];
    // Number of samples in buffer
    int count;
    // Start of samples
    int pos;
} SimpleBuffer;

// Buffer "block" struct
typedef struct
{
    // Interleaved samples
    int16_t buf[AUDIO_FRAMES_PER_CYCLE];
    // Number of samples in block
    int count;
} BufferBlock;

// Circular buffer struct
// https://en.wikipedia.org/wiki/Circular_buffer
typedef struct
{
    // Buffer blocks
    BufferBlock blocks[SPEEX_BLOCK_COUNT];
    // Index of block to read
    int read_index;
    // Index of block to write
    int write_index;
    // Number of full blocks
    _Atomic int block_count;
} CircularBuffer;

// Globals
SpeexResamplerState *speex_state = NULL;
CircularBuffer *speex_buffer = NULL;
SimpleBuffer *opus_buffer = NULL;
PlaybackState playback_state = {0, NULL, NULL, NULL};

int audio_update(lua_State* L)
{
    if (!playback_state.playing)
    {
        return 0;
    }

    if (speex_buffer == NULL || opus_buffer == NULL)
    {
        pd->system->error("Error: Playback enabled before initialization");
        return 0;
    }

    // Check for buffer fullness
    if (speex_buffer->block_count == SPEEX_BLOCK_COUNT)
    {
        return 0;
    }

    // Refill empty blocks
    // Ignores potential changes to block count while running
    for (int c = speex_buffer->block_count; c < SPEEX_BLOCK_COUNT; ++c)
    {
        int waiting_for_next = 0;
        int total = 0;
        BufferBlock *block = &speex_buffer->blocks[speex_buffer->write_index];
        do
        {
            // Refill Opus buffer if empty
            if (opus_buffer->count == 0)
            {
                if (playback_state.opus_file == NULL)
                {
                    pd->system->logToConsole("Warning: attempted to refill Opus buffer without open file");
                    playback_state.playing = 0;
                    return 0;
                }

                int samples = op_read_stereo(playback_state.opus_file, opus_buffer->buf, OPUS_BUFFER_SIZE);

                if (samples > 0)
                {
                    opus_buffer->pos = 0;
                    opus_buffer->count = samples * 2;
                    waiting_for_next = 0;
                }
                else if (samples == 0)
                {
                    if (waiting_for_next)
                    {
                        // Prevent infinite loop
                        pd->system->error("Error: Lua didn't stop playback but no samples were read");
                        return 0;
                    }

                    const char* outerr;
                    int err = pd->lua->callFunction("Playback.play_next", 0, &outerr);
                    if (err != 1)
                    {
                        pd->system->error("Lua error while calling for next track: %s", outerr);
                        return 0;
                    }
                    else if (!playback_state.playing)
                    {
                        // Playback has ended, break
                        break;
                    }

                    waiting_for_next = 1;
                    continue;
                }
                else
                {
                    pd->system->error("Opus error while decoding: %c", samples);
                    op_free(playback_state.opus_file);
                    playback_state.opus_file = NULL;
                    pd->system->realloc(playback_state.mem_file, 0);
                    playback_state.mem_file = NULL;
                    pd->sound->removeSource(playback_state.sound_source);
                    return 0;
                }
            }

            // Refill Speex block
            int16_t *in = opus_buffer->buf + opus_buffer->pos;
            uint32_t in_len = opus_buffer->count / 2;
            int16_t *out = block->buf + total;
            uint32_t out_len = (AUDIO_FRAMES_PER_CYCLE - total) / 2;
            speex_resampler_process_interleaved_int(speex_state, in, &in_len, out, &out_len);

            if (in_len > 0)
            {
                opus_buffer->count -= (int)in_len * 2;
                opus_buffer->pos += (int)in_len * 2;
            }

            if (out_len > 0)
            {

                total += (int)out_len * 2;
            }
        }
        while (total < AUDIO_FRAMES_PER_CYCLE);

        // Update block status
        block->count = total;
        speex_buffer->write_index = (speex_buffer->write_index + 1) % SPEEX_BLOCK_COUNT;
        speex_buffer->block_count++;
    }

    if (playback_state.sound_source == NULL)
    {
        playback_state.sound_source = pd->sound->addSource(audio_render, NULL, 1);
    }

    return 0;
}

// Playdate audio rendering callback. Happens on a separate thread.
int audio_render(void *context, int16_t *left, int16_t *right, int len) {
    if (len != (AUDIO_FRAMES_PER_CYCLE / 2))
    {
        pd->system->error("Error: amount of samples requested is unexpected");
        pd->sound->removeSource(playback_state.sound_source);
        playback_state.sound_source = NULL;
        return 0;
    }

    if (speex_buffer == NULL || opus_buffer == NULL)
    {
        pd->system->error("Error: Audio render called before initialization");
        pd->sound->removeSource(playback_state.sound_source);
        playback_state.sound_source = NULL;
        return 0;
    }

    // Check for buffer emptiness
    if (speex_buffer->block_count == 0)
    {
        // Stop if not playing
        if (!playback_state.playing)
        {
            pd->sound->removeSource(playback_state.sound_source);
            playback_state.sound_source = NULL;
        }

        return 0;
    }

    BufferBlock *block = &speex_buffer->blocks[speex_buffer->read_index];

    // https://stackoverflow.com/q/14567786
    // Deinterleave stream and put into buffers
    int16_t *buffer = block->buf;
    int half_samples = block->count / 2;
    for (int i = 0, j = 0; i < half_samples; i++, j += 2)
    {
        left[i] = buffer[j];
        right[i] = buffer[j+1];
    }

    // Update buffer status
    block->count = 0;
    speex_buffer->read_index = (speex_buffer->read_index + 1) % SPEEX_BLOCK_COUNT;
    speex_buffer->block_count--;

    return 1;
}

int audio_init(lua_State* L)
{
    if (speex_state != NULL)
    {
        pd->system->error("Audio init called with existing state. Something has gone disastrously wrong.");
        return 0;
    }

    // Setup resampler
    int speex_err;
    speex_state = speex_resampler_init(2, OPUSFILE_RATE, PLAYDATE_RATE, SPEEX_QUALITY, &speex_err);
    if (speex_err != 0)
    {
        pd->system->error("Speex error while initializing: %i", speex_err);
        return -1;
    }

    // Setup Speex buffer
    speex_buffer = pd->system->realloc(NULL, sizeof(CircularBuffer));
    speex_buffer->read_index = 0;
    speex_buffer->write_index = 0;
    speex_buffer->block_count = 0;
    for (int b = 0; b < SPEEX_BLOCK_COUNT; ++b)
    {
        speex_buffer->blocks[b].count = 0;
    }

    // Setup Opus buffer
    opus_buffer = pd->system->realloc(NULL, sizeof(SimpleBuffer));
    opus_buffer->count = 0;
    opus_buffer->pos = 0;

    return 0;
}

void audio_terminate(void)
{
    if (speex_state != NULL)
    {
        speex_resampler_destroy(speex_state);
        speex_state = NULL;
    }

    if (speex_buffer != NULL)
    {
        pd->system->realloc(speex_buffer, 0);
        speex_buffer = NULL;
    }

    if (opus_buffer != NULL)
    {
        pd->system->realloc(opus_buffer, 0);
        opus_buffer = NULL;
    }

    playback_state.playing = 0;
    
    if (playback_state.opus_file != NULL)
    {
        op_free(playback_state.opus_file);
        playback_state.opus_file = NULL;
    }

    if (playback_state.mem_file != NULL)
    {
        pd->system->realloc(playback_state.mem_file, 0);
        playback_state.mem_file = NULL;
    }

    if (playback_state.sound_source != NULL)
    {
        pd->sound->removeSource(playback_state.sound_source);
        playback_state.sound_source = NULL;
    }
}