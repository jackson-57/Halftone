#include "pd_api.h"
#include "opusfile.h"
#include "speex/speex_resampler.h"
#include "image.h"
#include <stb_image.h>
#include <stb_image_resize.h>

// TODO: malloc vs pd->system->realloc?

int const COVER_SIZE = 240;
char DEBUG_PATH[] = "C418 - Excursions/11 - C418 - Nest.opus";

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

void index_file(char* path);

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

static int play_music_demo(lua_State* L)
{
    // I don't know
    pd->lua->pushNil();

    // Create folder
    pd->file->mkdir("");

    // Test index
    index_file(DEBUG_PATH);

    // Open file
    SDFile *file = pd->file->open(DEBUG_PATH, kFileReadData);
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
    SpeexResamplerState* spx = speex_resampler_init(2, 48000, 44100, 5, &speex_err);
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

    return 1;
}

void index_file(char* path)
{
    // Open file
    SDFile *file = pd->file->open(path, kFileReadData);
    if (file == NULL)
    {
        pd->system->error("Could not open file (%s)", path);
        return;
    }
    int err;
    OggOpusFile* of = op_open_callbacks(file, &cb, NULL, 0, &err);
    if (err != 0)
    {
        pd->system->error("Opus error while opening to index: %i (%s)", err, path);
        pd->file->close(file);
        return;
    }

    const OpusTags* opusTags = op_tags(of, -1);
    if (opusTags == NULL)
    {
        // TODO: Special case for indexing
        op_free(of);
        return;
    }

    // TODO: Index tags. Free op_tags?

    // TODO: Check if album art is needed
    const char *pictureBlock = opus_tags_query(opusTags, "METADATA_BLOCK_PICTURE", 0);
    if (pictureBlock == NULL)
    {
        op_free(of);
        return;
    }
    OpusPictureTag pictureTag;
    err = opus_picture_tag_parse(&pictureTag, pictureBlock);
    if (err != 0)
    {
        pd->system->error("Error parsing image data: %i (%s)", err, path);
        op_free(of);
        return;
    }

    if (pictureTag.format != OP_PIC_FORMAT_JPEG && pictureTag.format != OP_PIC_FORMAT_PNG && pictureTag.format != OP_PIC_FORMAT_GIF)
    {
        pd->system->logToConsole("Unknown image type (%s)", path);
        opus_picture_tag_clear(&pictureTag);
        op_free(of);
        return;
    }

    int x, y, channels;
    unsigned char *originalImage = stbi_load_from_memory(pictureTag.data, (int)pictureTag.data_length, &x, &y, &channels, 1);
    opus_picture_tag_clear(&pictureTag);
    if (originalImage == NULL)
    {
        pd->system->error("Error reading image data: %s (%s)", stbi_failure_reason(), path);
        op_free(of);
        return;
    }

    unsigned char* newImage = pd->system->realloc(NULL, sizeof(unsigned char) * COVER_SIZE * COVER_SIZE);
    if (newImage == NULL)
    {
        pd->system->error("Error allocating image memory");
        stbi_image_free(originalImage);
        op_free(of);
        return;
    }

    err = stbir_resize_uint8(originalImage, x, y, 0, newImage, COVER_SIZE, COVER_SIZE, 0, 1);
    stbi_image_free(originalImage);
    if (err == 0)
    {
        pd->system->error("Error resizing image");
        pd->system->realloc(newImage, 0);
        op_free(of);
        return;
    }

    floyd_steinberg_dither(newImage, COVER_SIZE, COVER_SIZE);
    LCDBitmap *bitmap = pack_bitmap(pd, newImage, COVER_SIZE, COVER_SIZE);
    pd->system->realloc(newImage, 0);

    pd->graphics->drawBitmap(bitmap, 160, 0, kBitmapUnflipped);
    pd->graphics->freeBitmap(bitmap);

    op_free(of);
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