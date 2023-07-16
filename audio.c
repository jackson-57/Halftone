#include "audio.h"
#include "shared_pd.h"
#include "shared_opusfile.h"
#include <speex/speex_resampler.h>

#define OPUS_BUFFER_SIZE 11520
#define SPEEX_BUFFER_SIZE 1024

// Buffer struct
typedef struct {
    int16_t *buf;
    int size;
    int count;
    int pos;
} Buffer;

// Context state for audio callback
typedef struct {
    PlaydateAPI *pd;
    SoundSource *source;
    OggOpusFile *of;
    SpeexResamplerState *spx;
    Buffer *op_buf;
    Buffer *spx_buf;
} AudioState;

typedef int (*refill_buffer)(Buffer*, AudioState*, int);

int get_buffered_samples(Buffer *buffer, int len, AudioState *state, refill_buffer refill)
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

            int result = refill(buffer, state, offset);

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

int refill_opus_buffer(Buffer *buffer, AudioState *state, int offset)
{
    return op_read_stereo(state->of, buffer->buf + offset, buffer->size - offset);
}

int refill_speex_buffer(Buffer *buffer, AudioState *state, int offset)
{
    int available = buffer->size - offset;

    // get opus samples
    int in_res = get_buffered_samples(state->op_buf, available, state, refill_opus_buffer);
    int16_t *input = state->op_buf->buf + state->op_buf->pos - in_res;

    uint32_t in_len = in_res / 2;
    uint32_t result = available / 2;
    speex_resampler_process_interleaved_int(state->spx, input, &in_len, buffer->buf + offset, &result);
    return (int)result;
}

// Audio callback routine
int AudioHandler(void *context, int16_t *left, int16_t *right, int len) {

    // Resolve state fields as needed
    AudioState *state = (AudioState *) context;
    // Do not use the audio callback for system tasks:
    //   spend as little time here as possible

    int target = len * 2;

    // get samples
    int samples = get_buffered_samples(state->spx_buf, target, state, refill_speex_buffer);
    int16_t *buffer = state->spx_buf->buf + state->spx_buf->pos - samples;

//    // if no samples read or an error, stop after processing
//    if (result <= 0) {
//        if (result < 0)
//        {
//            pd->system->error("Opus error while decoding: %i", result);
//        }
//
//        op_free(state->of);
//        state->pd->sound->removeSource(state->source);
//        state->pd->system->realloc(state, 0);
//        break;
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

int play_music_demo(lua_State* L)
{
    const char *path = pd->lua->getArgString(1);

    // Create folder
    pd->file->mkdir("");

    // Open file
    SDFile *file = pd->file->open(path, kFileReadData);
    if (file == NULL)
    {
        pd->system->error("Could not open file.");
        return 0;
    }
    int err;
    OggOpusFile* of = op_open_callbacks(file, &cb, NULL, 0, &err);
    if (err != 0)
    {
        pd->system->error("Opus error while opening: %i", err);
        return 0;
    }

    // setup resampler
    int speex_err;
    SpeexResamplerState* spx = speex_resampler_init(2, OPUSFILE_RATE, PLAYDATE_RATE, 5, &speex_err);
    if (speex_err != 0)
    {
        pd->system->error("Speex error while initializing: %i", speex_err);
        return 0;
    }

    // create opus buffer
    Buffer *op_buf = pd->system->realloc(NULL, sizeof(Buffer));
//    int16_t buf[OPUS_BUFFER_SIZE];
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

    // Create a new audio source with a state context
    AudioState *state = pd->system->realloc(NULL, sizeof(AudioState));
    state->pd     = pd;
    state->source = pd->sound->addSource(&AudioHandler, state, 1);
    state->of     = of;
    state->spx    = spx;
    state->op_buf = op_buf;
    state->spx_buf = spx_buf;

    return 0;
}