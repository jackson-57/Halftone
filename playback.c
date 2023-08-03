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

    // Close old file if open
    if (playbackState.of != NULL)
    {
        OggOpusFile *old_file = playbackState.of;
        playbackState.of = NULL;
        op_free(old_file);
    }

    // Open file
    SDFile *file = pd->file->open(path, kFileReadData);
    if (file == NULL)
    {
        pd->system->error("Could not open file.");
        return 0;
    }
    int err;
    playbackState.of = op_open_callbacks(file, &cb, NULL, 0, &err);
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
    if (playbackState.of == NULL)
    {
        return 0;
    }

    // elapsed time
    pd->lua->pushInt((int)(op_pcm_tell(playbackState.of) / OPUSFILE_RATE));
    return 1;
}
