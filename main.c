#include "pd_api.h"
#include "opusfile.h"
#include "speex/speex_resampler.h"

static PlaydateAPI* pd = NULL;

// // bigassbuffer: lib/opusfile/examples/seeking_example.c:314
// #define BIG_ASS_BUFFER_SIZE 11520

// Context state for audio callback
typedef struct {
    PlaydateAPI *pd;
    SoundSource *source;
    OggOpusFile *of;
    SpeexResamplerState *spx;
//    int16_t big_ass_buffer[BIG_ASS_BUFFER_SIZE];
//    int samples_count;
} AudioState;

OpusFileCallbacks cb;
SpeexResamplerState* spx;


// Audio callback routine
int AudioHandler(void *context, int16_t *left, int16_t *right, int len) {

    // Resolve state fields as needed
    AudioState *state = (AudioState *) context;
    // Do not use the audio callback for system tasks:
    //   spend as little time here as possible

    int target = len * 2;
    int16_t buffer[target];
    int result;
    int remaining = target;
    int total_read = 0;
    do
    {
        // read opus samples. returns the number of samples read, or an error if negative
        result = op_read_stereo(state->of, buffer + total_read, remaining);

        // update total samples read if not an error, and remaining samples
        if (result > 0)
            total_read += result * 2;
        remaining = target - total_read;

        // if no samples read or an error, stop after processing
        if (result <= 0) {
            if (result < 0)
            {
                pd->system->logToConsole("Opus error while decoding: %i", result);
            }

            op_free(state->of);
            state->pd->sound->removeSource(state->source);
            state->pd->system->realloc(state, 0);
            break;
        }
    }
    while (remaining > 0);

    // Resample
    int half_read = total_read / 2;
    int16_t resample_buffer[len * 2];
    uint32_t in_len = half_read;
    uint32_t out_len = len;
    speex_resampler_process_interleaved_int(state->spx, buffer, &in_len, resample_buffer, &out_len);

//    // Stop if resampling was unsuccessful
//    if (out_len != half_read) {
//        pd->system->logToConsole("Speex error: expected %i samples but only returned %i samples", total_read, out_len);
//
//        op_free(state->of);
//        state->pd->sound->removeSource(state->source);
//        state->pd->system->realloc(state, 0);
//        return 0;
//    }

    // https://stackoverflow.com/q/14567786
    // Deinterleave stream and put into buffers
    int i, j;
    for (i = 0, j = 0; i < out_len; i++, j += 2)
    {
        left[i] = resample_buffer[j];
        right[i] = resample_buffer[j+1];
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

    // Create a new audio source with a state context
    AudioState *state = pd->system->realloc(NULL, sizeof (AudioState));
    state->pd     = pd;
    state->source = pd->sound->addSource(&AudioHandler, state, 1);
    state->of     = of;
    state->spx    = spx;
//    state->samples_count = 0;

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

        // setup resampler
        int speex_err;
        spx = speex_resampler_init(2, 48000, 41000, 5, &speex_err);
        if (speex_err != 0)
        {
            pd->system->logToConsole("Speex error while initializing: %i", speex_err);
        }
    }

    return 0;
}