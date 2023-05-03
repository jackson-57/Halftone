#include "pd_api.h"
#include "opusfile.h"
#include "speex/speex_resampler.h"

#define OPUS_BUFFER_SIZE 11520
#define SPEEX_BUFFER_SIZE 1024

static PlaydateAPI* pd = NULL;

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

OpusFileCallbacks cb;

int get_op_samples(Buffer *buffer, int len, OggOpusFile *of)
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
            int result = op_read_stereo(of, buffer->buf + offset, buffer->size - offset);
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

int get_spx_samples(Buffer *buffer, int len, SpeexResamplerState *spx, Buffer *op_buf, OggOpusFile *of)
{
    // todo: check if length fits in buffer
    // refill if samples in buffer is less than requested amount
    if (len > buffer->count)
    {
        // move remaining data to beginning
        // destination, source
        memcpy(buffer->buf, buffer->buf + buffer->pos, buffer->size);
        buffer->pos = 0;

        // get samples
        // todo: error/zero handling
        do {
//            int result = op_read_stereo(of, buffer->buf + offset, buffer->size - offset);
            int offset = buffer->pos + buffer->count;
            int available = buffer->size - offset;

            // get opus samples
            int in_res = get_op_samples(op_buf, available, of);
            int16_t *input = op_buf->buf + op_buf->pos - in_res;

            uint32_t in_len = in_res / 2;
            uint32_t result = available / 2;
            speex_resampler_process_interleaved_int(spx, input, &in_len, buffer->buf + offset, &result);


            if (result > 0)
            {
                buffer->count += (int)result * 2;
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

// Audio callback routine
int AudioHandler(void *context, int16_t *left, int16_t *right, int len) {

    // Resolve state fields as needed
    AudioState *state = (AudioState *) context;
    // Do not use the audio callback for system tasks:
    //   spend as little time here as possible

    int target = len * 2;

    // get samples
    int samples = get_spx_samples(state->spx_buf, target, state->spx, state->op_buf, state->of);
    int16_t *buffer = state->spx_buf->buf + state->spx_buf->pos - samples;

//    // if no samples read or an error, stop after processing
//    if (result <= 0) {
//        if (result < 0)
//        {
//            pd->system->logToConsole("Opus error while decoding: %i", result);
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

static int play_music_demo(lua_State* L)
{
    // I don't know
    pd->lua->pushNil();

    // Create folder
    pd->file->mkdir("");

    // Open file
    SDFile *file = pd->file->open("wsf.opus", kFileReadData);
    if (file == NULL)
    {
        pd->system->logToConsole("Could not open file.");
        return 0;
    }
    int *err = NULL;
    OggOpusFile* of = op_open_callbacks(file, &cb, NULL, 0, err);
    if (err != 0)
    {
        pd->system->logToConsole("Opus error while opening: %i", err);
        return 0;
    }

    // setup resampler
    int speex_err;
    SpeexResamplerState* spx = speex_resampler_init(2, 48000, 44100, 5, &speex_err);
    if (speex_err != 0)
    {
        pd->system->logToConsole("Speex error while initializing: %i", speex_err);
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

    return 1;
}

static int hello_world(lua_State* L)
{
    pd->system->logToConsole("hello!");
    pd->lua->pushNil();
    return 1;
}

int eventHandler(PlaydateAPI* playdate, PDSystemEvent event, uint32_t arg)
{
    if ( event == kEventInitLua )
    {
        pd = playdate;

        const char* err;

        if ( !pd->lua->addFunction(hello_world, "hello_world", &err) )
            pd->system->logToConsole("%s:%i: addFunction failed, %s", __FILE__, __LINE__, err);

        if ( !pd->lua->addFunction(play_music_demo, "play_music_demo", &err) )
            pd->system->logToConsole("%s:%i: addFunction failed, %s", __FILE__, __LINE__, err);

        // setup opusfile callbacks
        cb.read = (op_read_func) pd->file->read;
        cb.seek = (op_seek_func) pd->file->seek;
        cb.tell = (op_tell_func) pd->file->tell;
        cb.close = pd->file->close;
    }

    return 0;
}