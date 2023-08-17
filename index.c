#include "index.h"
#include "shared_opusfile.h"
#include "shared_pd.h"
#include "shared_audio.h"
#include "image.h"
#include <opusfile.h>
#include <stb_image.h>
#include <stb_image_resize.h>

int parse_metadata(lua_State* L)
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
    OggOpusFile* opus_file = op_open_callbacks(file, &op_callbacks, NULL, 0, &err);
    if (err != 0)
    {
        pd->system->error("Opus error while opening to index: %i (%s)", err, path);
        pd->file->close(file);
        return 0;
    }

    // Index
    int stack_count = 0;
    ogg_int64_t samples = op_pcm_total(opus_file, -1);
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

    const OpusTags* opus_tags = op_tags(opus_file, -1);
    if (opus_tags == NULL)
    {
        op_free(opus_file);
        return stack_count;
    }

    // More indexing
    const char* OPUS_TAGS_LIST[] = {"TITLE", "ALBUM", "ARTIST", "ALBUMARTIST", "DATE", "TRACKNUMBER"};
    for (int i = 0; i < 6; ++i)
    {
        const char *tag_value = opus_tags_query(opus_tags, OPUS_TAGS_LIST[i], 0);
        if (tag_value == NULL)
        {
            pd->lua->pushNil();
        }
        else
        {
            pd->lua->pushString(tag_value);
        }
        stack_count++;
    }

    op_free(opus_file);
    return stack_count;
}

int process_art(lua_State *L)
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
    OggOpusFile* opus_file = op_open_callbacks(file, &op_callbacks, NULL, 0, &err);
    if (err != 0)
    {
        pd->system->error("Opus error while opening to index image: %i (%s)", err, path);
        pd->file->close(file);
        return 0;
    }

    const OpusTags* opus_tags = op_tags(opus_file, -1);
    if (opus_tags == NULL)
    {
        op_free(opus_file);
        return 0;
    }

    const char *picture_block = opus_tags_query(opus_tags, "METADATA_BLOCK_PICTURE", 0);
    if (picture_block == NULL)
    {
        op_free(opus_file);
        return 0;
    }
    OpusPictureTag picture_tag;
    err = opus_picture_tag_parse(&picture_tag, picture_block);
    if (err != 0)
    {
        pd->system->error("Error parsing image data: %i (%s)", err, path);
        op_free(opus_file);
        return 0;
    }

    if (picture_tag.format != OP_PIC_FORMAT_JPEG && picture_tag.format != OP_PIC_FORMAT_PNG && picture_tag.format != OP_PIC_FORMAT_GIF)
    {
        pd->system->logToConsole("Unknown image type (%s)", path);
        opus_picture_tag_clear(&picture_tag);
        op_free(opus_file);
        return 0;
    }

    int x, y, channels;
    unsigned char *original_image = stbi_load_from_memory(picture_tag.data, (int)picture_tag.data_length, &x, &y, &channels, 1);
    opus_picture_tag_clear(&picture_tag);
    op_free(opus_file);
    if (original_image == NULL)
    {
        pd->system->error("Error reading image data: %s (%s)", stbi_failure_reason(), path);
        return 0;
    }

    int stack_count = 0;
    const int art_sizes_count = pd->lua->getArgCount() - 1;
    for (int i = 0; i < art_sizes_count; ++i)
    {
        // arguments start at 1, and we've already gotten first argument
        int cover_size = pd->lua->getArgInt(i + 2);

        unsigned char* new_image = pd->system->realloc(NULL, sizeof(unsigned char) * cover_size * cover_size);
        if (new_image == NULL)
        {
            pd->system->error("Error allocating image memory");
            stbi_image_free(original_image);
            return stack_count;
        }
        
        err = stbir_resize_uint8(original_image, x, y, 0, new_image, cover_size, cover_size, 0, 1);
        if (err == 0)
        {
            pd->system->error("Error resizing image");
            stbi_image_free(original_image);
            pd->system->realloc(new_image, 0);
            return stack_count;
        }

        floyd_steinberg_dither(new_image, cover_size, cover_size);
        LCDBitmap *bitmap = pack_bitmap(pd, new_image, cover_size, cover_size);
        pd->system->realloc(new_image, 0);

        pd->lua->pushBitmap(bitmap);
        stack_count++;
    }

    stbi_image_free(original_image);
    return stack_count;
}