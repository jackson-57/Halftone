#include "playback.h"
#include "audio_internal.h"
#include "shared_pd.h"
#include "shared_opusfile.h"
#include "shared_audio.h"

// Globals
PlaybackState playbackState = {NULL};
SoundSource *soundSource = NULL;

int set_playback(lua_State* L)
{
    const char *path = pd->lua->getArgString(1);

    // Do not continue if new file is already loaded
    if (playbackState.new_of != NULL)
    {
        pd->system->error("New Opus file is already loaded.");
        return 0;
    }

    // Open file
    SDFile *file = pd->file->open(path, kFileReadData);
    if (file == NULL)
    {
        pd->system->error("Could not open file.");
        return 0;
    }
    int err;
    playbackState.new_of = op_open_callbacks(file, &cb, NULL, 0, &err);
    if (err != 0)
    {
        pd->system->error("Opus error while opening: %i", err);
        return 0;
    }

    // Setup audio source if not open
    if (soundSource == NULL)
    {
        soundSource = pd->sound->addSource(AudioHandler, &playbackState, 1);
    }

    return 0;
}

int get_playback_status(lua_State *L)
{
    if (playbackState.current_of == NULL)
    {
        return 0;
    }

    // elapsed time
    pd->lua->pushInt((int)(op_pcm_tell(playbackState.current_of) / OPUSFILE_RATE));
    return 1;
}

int toggle_playback(lua_State *L)
{
    if (playbackState.current_of == NULL)
    {
        return 0;
    }

    int currently_playing = soundSource != NULL;

    // Toggle playback if desired state isn't given
    int playing = !currently_playing;
    if (!pd->lua->argIsNil(1))
    {
        playing = pd->lua->getArgBool(1);
    }

    if (playing && !currently_playing)
    {
        soundSource = pd->sound->addSource(AudioHandler, &playbackState, 1);
    }
    else if (!playing && currently_playing)
    {
        pd->sound->removeSource(soundSource);
        soundSource = NULL;
    }

    pd->lua->pushBool(playing);
    return 1;
}

int seek_playback(lua_State *L)
{
    if (playbackState.current_of == NULL)
    {
        return 0;
    }

    int seconds = pd->lua->getArgInt(1);
    int err = op_pcm_seek(playbackState.current_of, seconds * OPUSFILE_RATE);
    if (err != 0)
    {
        pd->system->error("Opus error while seeking: %i", err);
    }

    return 0;
}