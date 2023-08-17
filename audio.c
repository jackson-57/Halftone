#include "audio.h"
#include "audio_internal.h"
#include "shared_pd.h"
#include "shared_opusfile.h"
#include "shared_audio.h"
#include <speex/speex_resampler.h>
#include <speex/speex_buffer.h>
#include <assert.h>

#define OPUS_BUFFER_SIZE 11520
#define SPEEX_BUFFER_SIZE 1024
#define SPEEX_QUALITY 5

// Buffer struct
typedef struct {
    // Interleaved samples
    int16_t *buf;
    // Total sample capacity
    int size;
    // Number opus_file samples
    int count;
    // Start opus_file samples
    int pos;
} Buffer;

// Globals
SpeexResamplerState *speex_state = NULL;
SpeexBuffer *speex_ring_buffer = NULL;
int16_t *speex_linear_buffer = NULL;
int16_t *audio_render_buffer = NULL;
Buffer opus_buffer = {NULL, OPUS_BUFFER_SIZE, 0, 0};
PlaybackState playback_state = {NULL};

int audio_update(lua_State* L)
{
    if (playback_state.sound_source == NULL)
    {
        return 0;
    }

    // refill opus buffer if empty
    if (opus_buffer.count == 0)
    {
        if (playback_state.opus_file == NULL)
        {
            return 0;
        }

        int samples = op_read_stereo(playback_state.opus_file, opus_buffer.buf, opus_buffer.size);

        if (samples > 0)
        {
            opus_buffer.pos = 0;
            opus_buffer.count = samples * 2;
        }
        else if (samples == 0)
        {
            const char* outerr;
            int err = pd->lua->callFunction("play_next", 0, &outerr);
            if (err != 1)
            {
                pd->system->error("Lua error while calling for next track: %s", outerr);
            }
        }
        else
        {
            pd->system->error("Opus error while decoding: %i", samples);
            op_free(playback_state.opus_file);
            playback_state.opus_file = NULL;
            pd->sound->removeSource(playback_state.sound_source);
        }

        // skip cycle
        return 0;
    }

    // refill speex output buffer if less than half full
    int speex_samples_available = speex_buffer_get_available(speex_ring_buffer) / (int)sizeof(int16_t);
    if (speex_samples_available < SPEEX_BUFFER_SIZE / 2)
    {
        int16_t *in = opus_buffer.buf + opus_buffer.pos;
        uint32_t in_len = opus_buffer.count / 2;
        uint32_t out_len = SPEEX_BUFFER_SIZE - speex_samples_available / 2;
        speex_resampler_process_interleaved_int(speex_state, in, &in_len, speex_linear_buffer, &out_len);

        if (in_len > 0)
        {
            opus_buffer.count -= (int)in_len * 2;
            opus_buffer.pos -= (int)in_len * 2;
        }

        if (out_len > 0)
        {
            speex_buffer_write(speex_ring_buffer, speex_linear_buffer, (int)out_len * 2 * (int)sizeof(int16_t));
        }
    }

    return 0;
}

// Playdate audio rendering callback. Happens on a separate thread.
int audio_render(void *context, int16_t *left, int16_t *right, int len) {
    // https://stackoverflow.com/q/14567786
    // Deinterleave stream and put into buffers

    assert(len == (AUDIO_FRAMES_PER_CYCLE / 2));

    int target_data = (len * 2) * (int)sizeof(int16_t);
    int speex_data_read = speex_buffer_read(speex_ring_buffer, audio_render_buffer, target_data);
    int half_samples = (speex_data_read / (int)sizeof(int16_t)) / 2;
    for (int i = 0, j = 0; i < half_samples; i++, j += 2)
    {
        left[i] = audio_render_buffer[j];
        right[i] = audio_render_buffer[j+1];
    }

    // Audio data is meaningful, so return 1
    return 1;
}

int audio_init(lua_State* L)
{
    if (speex_state != NULL)
    {
        pd->system->error("Audio init called with existing state. Something has gone disastrously wrong.");
        return 0;
    }

    // setup resampler
    int speex_err;
    speex_state = speex_resampler_init(2, OPUSFILE_RATE, PLAYDATE_RATE, SPEEX_QUALITY, &speex_err);
    if (speex_err != 0)
    {
        pd->system->error("Speex error while initializing: %i", speex_err);
        return -1;
    }

    // setup buffers
    speex_ring_buffer = speex_buffer_init(SPEEX_BUFFER_SIZE * sizeof(int16_t));
    speex_linear_buffer = pd->system->realloc(NULL, SPEEX_BUFFER_SIZE * sizeof(int16_t));
    audio_render_buffer = pd->system->realloc(NULL, AUDIO_FRAMES_PER_CYCLE * sizeof(int16_t));
    opus_buffer.buf = pd->system->realloc(NULL, OPUS_BUFFER_SIZE * sizeof(int16_t));

    return 0;
}

void audio_terminate(void)
{
    if (speex_state != NULL)
    {
        speex_resampler_destroy(speex_state);
        speex_state = NULL;
    }

    if (speex_ring_buffer != NULL)
    {
        speex_buffer_destroy(speex_ring_buffer);
        speex_ring_buffer = NULL;
    }

    if (speex_linear_buffer != NULL)
    {
        pd->system->realloc(speex_linear_buffer, 0);
        speex_linear_buffer = NULL;
    }

    if (audio_render_buffer != NULL)
    {
        pd->system->realloc(audio_render_buffer, 0);
        audio_render_buffer = NULL;
    }

    if (opus_buffer.buf != NULL)
    {
        pd->system->realloc(opus_buffer.buf, 0);
        opus_buffer.buf = NULL;
    }

    opus_buffer.count = 0;
    opus_buffer.pos = 0;

    if (playback_state.opus_file != NULL)
    {
        op_free(playback_state.opus_file);
        playback_state.opus_file = NULL;
    }

    if (playback_state.sound_source != NULL)
    {
        pd->sound->removeSource(playback_state.sound_source);
        playback_state.sound_source = NULL;
    }
}