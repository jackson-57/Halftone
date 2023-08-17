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
    }

    // Open file
    SDFile *file = pd->file->open(path, kFileReadData);
    if (file == NULL)
    {
        pd->system->error("Could not open file.");
        return 0;
    }
    int err;
    playback_state.opus_file = op_open_callbacks(file, &op_callbacks, NULL, 0, &err);
    if (err != 0)
    {
        pd->system->error("Opus error while opening: %i", err);
        return 0;
    }

    // Setup audio source if not open
    if (playback_state.sound_source == NULL)
    {
        playback_state.sound_source = pd->sound->addSource(audio_render, NULL, 1);
    }

    return 0;
}

int get_playback_status(lua_State *L)
{
    if (playback_state.opus_file == NULL)
    {
        return 0;
    }

    // elapsed time
    pd->lua->pushInt((int)(op_pcm_tell(playback_state.opus_file) / OPUSFILE_RATE));
    return 1;
}

int toggle_playback(lua_State *L)
{
    if (playback_state.opus_file == NULL)
    {
        return 0;
    }

    int currently_playing = playback_state.sound_source != NULL;

    // Toggle playback if desired state isn't given
    int playing = !currently_playing;
    if (!pd->lua->argIsNil(1))
    {
        playing = pd->lua->getArgBool(1);
    }

    if (playing && !currently_playing)
    {
        playback_state.sound_source = pd->sound->addSource(audio_render, NULL, 1);
    }
    else if (!playing && currently_playing)
    {
        pd->sound->removeSource(playback_state.sound_source);
        playback_state.sound_source = NULL;
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