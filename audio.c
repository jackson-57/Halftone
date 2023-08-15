#include "audio.h"
#include "audio_internal.h"
#include "shared_pd.h"
#include "shared_opusfile.h"
#include "shared_audio.h"
#include <speex/speex_resampler.h>

#define OPUS_BUFFER_SIZE 11520
#define SPEEX_BUFFER_SIZE 1024
#define SPEEX_QUALITY 5

// Buffer struct
typedef struct {
    int16_t *buf;
    int size;
    int count;
    int pos;
} Buffer;

// Audio engine state
typedef struct {
    SpeexResamplerState *spx_state;
    Buffer *op_buf;
    Buffer *spx_buf;
} AudioState;

typedef int (*refill_buffer)(Buffer*, PlaybackState*, int);

// Globals
AudioState *audioState = NULL;

int get_buffered_samples(Buffer *buffer, PlaybackState *playbackState, int len, refill_buffer refill)
{
    // todo: check if length fits in buffer
    // todo: memcpy or memmove?
    // refill if samples in buffer is less than requested amount
    if (len > buffer->count)
    {
        // move remaining data to beginning
        // destination, source
        memcpy(buffer->buf, buffer->buf + buffer->pos, buffer->size);
        buffer->pos = 0;

        // get samples
        // todo: error/zero handling, properly shut down
        do {
            int offset = buffer->pos + buffer->count;

            int result = refill(buffer, playbackState, offset);

            if (result > 0)
            {
                buffer->count += result * 2;
            }
            else
            {
                break;
            }
        }
        while (len > buffer->count);
    }

    // return
    if (buffer->count > len)
    {
        buffer->count -= len;
        buffer->pos += len;
        return len;
    }
    else
    {
        int temp = buffer->count;
        buffer->count = 0;
        buffer->pos += temp;
        return temp;
    }
}

int refill_opus(Buffer *buffer, PlaybackState *playbackState, int offset)
{
    if (playbackState->current_of == NULL)
    {
        return -1;
    }
    return op_read_stereo(playbackState->current_of, buffer->buf + offset, buffer->size - offset);
}

int refill_speex(Buffer *buffer, PlaybackState *playbackState, int offset)
{
    int available = buffer->size - offset;

    // get opus samples
    int in_res = get_buffered_samples(audioState->op_buf, playbackState, available, refill_opus);

    // call for next track if no samples returned
    if (in_res == 0)
    {
        const char* outerr;
        int err = pd->lua->callFunction("play_next", 0, &outerr);
        if (err != 1)
        {
            pd->system->error("Lua error while calling for next track: %s", outerr);
        }

        return 0;
    }

    int16_t *input = audioState->op_buf->buf + audioState->op_buf->pos - in_res;

    uint32_t in_len = in_res / 2;
    uint32_t result = available / 2;
    speex_resampler_process_interleaved_int(audioState->spx_state, input, &in_len, buffer->buf + offset, &result);
    return (int)result;
}

// Audio callback routine
int AudioHandler(void *context, int16_t *left, int16_t *right, int len) {
    // Resolve playbackState fields as needed
    PlaybackState *playbackState = (PlaybackState*) context;

    // Do not use the audio callback for system tasks:
    //   spend as little time here as possible
    // TODO: Move decoding out of callback

    if (playbackState->new_of)
    {
        OggOpusFile *old_of = playbackState->current_of;
        playbackState->current_of = playbackState->new_of;
        playbackState->new_of = NULL;
        op_free(old_of);
    }

    int target = len * 2;

    // get samples
    int samples = get_buffered_samples(audioState->spx_buf, playbackState, target, refill_speex);
    int16_t *buffer = audioState->spx_buf->buf + audioState->spx_buf->pos - samples;

//    // if no samples read or an error, stop after processing
//    if (samples <= 0) {
////        if (result < 0)
////        {
////            pd->system->error("Opus error while decoding: %i", result);
////        }
//
//        op_free(playbackState->of);
//        pd->sound->removeSource(playbackState->source);
//        return 0;
//    }

    // https://stackoverflow.com/q/14567786
    // Deinterleave stream and put into buffers
    int i, j;
    int half_samples = samples / 2;
    for (i = 0, j = 0; i < half_samples; i++, j += 2)
    {
        left[i] = buffer[j];
        right[i] = buffer[j+1];
    }

    // Audio data is meaningful, so return 1
    return 1;
}

int audio_init(lua_State* L)
{
    if (audioState != NULL)
    {
        pd->system->error("Audio init called with existing state. Something has gone disastrously wrong.");
        return 0;
    }

    // setup resampler
    int speex_err;
    SpeexResamplerState* spx = speex_resampler_init(2, OPUSFILE_RATE, PLAYDATE_RATE, SPEEX_QUALITY, &speex_err);
    if (speex_err != 0)
    {
        pd->system->error("Speex error while initializing: %i", speex_err);
        return -1;
    }

    // create opus buffer
    Buffer *op_buf = pd->system->realloc(NULL, sizeof(Buffer));
    op_buf->buf = pd->system->realloc(NULL, OPUS_BUFFER_SIZE * sizeof(Buffer));
    op_buf->size = OPUS_BUFFER_SIZE;
    op_buf->count = 0;
    op_buf->pos = 0;

    // create speex buffer
    Buffer *spx_buf = pd->system->realloc(NULL, sizeof(Buffer));
    spx_buf->buf = pd->system->realloc(NULL, SPEEX_BUFFER_SIZE * sizeof(Buffer));
    spx_buf->size = SPEEX_BUFFER_SIZE;
    spx_buf->count = 0;
    spx_buf->pos = 0;

    // create audio state
    audioState = pd->system->realloc(NULL, sizeof(AudioState));
    audioState->spx_state = spx;
    audioState->op_buf = op_buf;
    audioState->spx_buf = spx_buf;

    return 0;
}

void audio_terminate(void)
{
    // In theory, variables belonging to dynamically allocated structs don't need to be set to null, once freed
    if (audioState != NULL)
    {
        if (audioState->spx_state != NULL)
        {
            speex_resampler_destroy(audioState->spx_state);
        }

        if (audioState->op_buf != NULL)
        {
            pd->system->realloc(audioState->op_buf, 0);
        }

        if (audioState->spx_buf != NULL)
        {
            pd->system->realloc(audioState->spx_buf, 0);
        }

        pd->system->realloc(audioState, 0);
        audioState = NULL;
    }
}