#include "index.h"
#include "shared_opusfile.h"
#include "shared_pd.h"
#include "audio.h"
#include "image.h"
#include <opusfile.h>
#include <stb_image.h>
#include <stb_image_resize.h>

int const COVER_SIZE = 240;

int index_file(lua_State* L)
{
    const char* path = pd->lua->getArgString(1);
    int stack_count = 0;

    // Open file
    SDFile *file = pd->file->open(path, kFileReadData);
    if (file == NULL)
    {
        pd->system->error("Could not open file (%s)", path);
        return stack_count;
    }
    int err;
    OggOpusFile* of = op_open_callbacks(file, &cb, NULL, 0, &err);
    if (err != 0)
    {
        pd->system->error("Opus error while opening to index: %i (%s)", err, path);
        pd->file->close(file);
        return stack_count;
    }

    // Index
    ogg_int64_t samples = op_pcm_total(of, -1);
    if (samples > 0)
    {
        // duration
        pd->lua->pushInt((int)(samples / OPUSFILE_RATE));
    }
    else
    {
        // treat non-seekable files as zero seconds long
        pd->lua->pushInt(0);
    }
    stack_count++;

    const OpusTags* opusTags = op_tags(of, -1);
    if (opusTags == NULL)
    {
        op_free(of);
        return stack_count;
    }

    // More indexing
    const char* OPUS_TAGS_LIST[] = {"TITLE", "ALBUM", "ARTIST", "ALBUMARTIST", "DATE", "TRACKNUMBER"};
    for (int i = 0; i < 6; ++i)
    {
        const char *tagValue = opus_tags_query(opusTags, OPUS_TAGS_LIST[i], 0);
        if (tagValue == NULL)
        {
            pd->lua->pushNil();
        }
        else
        {
            pd->lua->pushString(tagValue);
        }
        stack_count++;
    }

    op_free(of);
    return stack_count;
}

int index_image(lua_State *L)
{
    const char* path = pd->lua->getArgString(1);

    // Open file
    SDFile *file = pd->file->open(path, kFileReadData);
    if (file == NULL)
    {
        pd->system->error("Could not open file (%s)", path);
        return 0;
    }
    int err;
    OggOpusFile* of = op_open_callbacks(file, &cb, NULL, 0, &err);
    if (err != 0)
    {
        pd->system->error("Opus error while opening to index image: %i (%s)", err, path);
        pd->file->close(file);
        return 0;
    }

    const OpusTags* opusTags = op_tags(of, -1);
    if (opusTags == NULL)
    {
        op_free(of);
        return 0;
    }

    // TODO: Check if album art is needed
    const char *pictureBlock = opus_tags_query(opusTags, "METADATA_BLOCK_PICTURE", 0);
    if (pictureBlock == NULL)
    {
        op_free(of);
        return 0;
    }
    OpusPictureTag pictureTag;
    err = opus_picture_tag_parse(&pictureTag, pictureBlock);
    if (err != 0)
    {
        pd->system->error("Error parsing image data: %i (%s)", err, path);
        op_free(of);
        return 0;
    }

    if (pictureTag.format != OP_PIC_FORMAT_JPEG && pictureTag.format != OP_PIC_FORMAT_PNG && pictureTag.format != OP_PIC_FORMAT_GIF)
    {
        pd->system->logToConsole("Unknown image type (%s)", path);
        opus_picture_tag_clear(&pictureTag);
        op_free(of);
        return 0;
    }

    int x, y, channels;
    unsigned char *originalImage = stbi_load_from_memory(pictureTag.data, (int)pictureTag.data_length, &x, &y, &channels, 1);
    opus_picture_tag_clear(&pictureTag);
    if (originalImage == NULL)
    {
        pd->system->error("Error reading image data: %s (%s)", stbi_failure_reason(), path);
        op_free(of);
        return 0;
    }

    unsigned char* newImage = pd->system->realloc(NULL, sizeof(unsigned char) * COVER_SIZE * COVER_SIZE);
    if (newImage == NULL)
    {
        pd->system->error("Error allocating image memory");
        stbi_image_free(originalImage);
        op_free(of);
        return 0;
    }

    err = stbir_resize_uint8(originalImage, x, y, 0, newImage, COVER_SIZE, COVER_SIZE, 0, 1);
    stbi_image_free(originalImage);
    if (err == 0)
    {
        pd->system->error("Error resizing image");
        pd->system->realloc(newImage, 0);
        op_free(of);
        return 0;
    }

    floyd_steinberg_dither(newImage, COVER_SIZE, COVER_SIZE);
    LCDBitmap *bitmap = pack_bitmap(pd, newImage, COVER_SIZE, COVER_SIZE);
    pd->system->realloc(newImage, 0);

    pd->graphics->drawBitmap(bitmap, 160, 0, kBitmapUnflipped);
    pd->graphics->freeBitmap(bitmap);

    op_free(of);
    return 0;
}