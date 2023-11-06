#include "playback.h"
#include "audio_internal.h"
#include "shared_pd.h"
#include "shared_opusfile.h"
#include "shared_audio.h"

// Globals
extern PlaybackState playback_state;

int set_playback(lua_State* L)
{
    const char *path = pd->lua->getArgString(1);

    // Close old file if open
    if (playback_state.opus_file != NULL)
    {
        op_free(playback_state.opus_file);
        playback_state.opus_file = NULL;
    }

    // Free old memory buffer if loaded
    if (playback_state.mem_file != NULL)
    {
        pd->system->realloc(playback_state.mem_file, 0);
        playback_state.mem_file = NULL;
    }

    // Get file size and other info
    FileStat file_stat;
    if (pd->file->stat(path, &file_stat))
    {
        pd->system->error("%s", pd->file->geterr());
        return 0;
    }

    // Open file
    SDFile *file = pd->file->open(path, kFileRead|kFileReadData);
    if (file == NULL)
    {
        pd->system->error("%s", pd->file->geterr());
        return 0;
    }

    // Allocate buffer for file
    playback_state.mem_file = pd->system->realloc(NULL, file_stat.size);
    if (playback_state.mem_file == NULL)
    {
        pd->system->error("File buffer allocation failed");
        pd->file->close(file);
        return 0;
    }

    // Read file into buffer
    int bytes_read = pd->file->read(file, playback_state.mem_file, file_stat.size);
    if (bytes_read != file_stat.size)
    {
        pd->system->error("File read expected %i bytes, got %i instead", file_stat.size, bytes_read);
        pd->file->close(file);
        pd->system->realloc(playback_state.mem_file, 0);
        playback_state.mem_file = NULL;
        return 0;
    }

    // Close file
    pd->file->close(file);

    // Open Opusfile stream
    int err;
    playback_state.opus_file = op_open_memory(playback_state.mem_file, bytes_read, &err);
    if (err)
    {
        pd->system->error("Opusfile error upon opening memory: %i", err);
        pd->system->realloc(playback_state.mem_file, 0);
        playback_state.mem_file = NULL;
        return 0;
    }

    // Enable playback
    playback_state.playing = 1;

    return 0;
}

int get_playback_status(lua_State *L)
{
    if (playback_state.opus_file == NULL)
    {
        return 0;
    }

    // Elapsed time
    pd->lua->pushInt((int)(op_pcm_tell(playback_state.opus_file) / OPUSFILE_RATE));
    return 1;
}

int toggle_playback(lua_State *L)
{
    if (playback_state.opus_file == NULL)
    {
        return 0;
    }

    int currently_playing = playback_state.playing;

    // Toggle playback if desired state isn't given
    int playing = !currently_playing;
    if (!pd->lua->argIsNil(1))
    {
        playing = pd->lua->getArgBool(1);
    }

    if (playing && !currently_playing)
    {
        playback_state.playing = 1;
    }
    else if (!playing && currently_playing)
    {
        playback_state.playing = 0;
    }

    pd->lua->pushBool(playing);
    return 1;
}

int seek_playback(lua_State *L)
{
    if (playback_state.opus_file == NULL)
    {
        return 0;
    }

    int seconds = pd->lua->getArgInt(1);
    int err = op_pcm_seek(playback_state.opus_file, seconds * OPUSFILE_RATE);
    if (err != 0)
    {
        pd->system->error("Opus error while seeking: %i", err);
    }

    return 0;
}