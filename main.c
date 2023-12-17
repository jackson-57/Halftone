#include <pd_api.h>
#include <opusfile.h>
#include "index.h"
#include "playback.h"
#include "audio.h"

PlaydateAPI* pd;
OpusFileCallbacks op_callbacks = {NULL};

int seek_64(void *_stream, opus_int64 _offset, int _whence)
{
    return pd->file->seek(_stream, (int)_offset, _whence);
};

opus_int64 tell_64(void *_stream)
{
    return pd->file->tell(_stream);
};

int eventHandler(PlaydateAPI* playdate, PDSystemEvent event, uint32_t arg)
{
    switch (event)
    {
        case kEventInitLua:
            pd = playdate;

            lua_reg engine_reg[] = {
                {"set_playback", set_playback},
                {"get_playback_status", get_playback_status},
                {"toggle_playback", toggle_playback},
                {"seek_playback", seek_playback},
                {"parse_metadata", parse_metadata},
                {"process_art", process_art},
                {"audio_init", audio_init},
                {"audio_update", audio_update},
                {NULL, NULL}
            };
            const char* err;
            if (!pd->lua->registerClass("Engine", engine_reg, NULL, 1, &err))
            {
                pd->system->error("registerClass failed: %s", err);
            }

            // setup opusfile callbacks
            op_callbacks.read = (op_read_func) pd->file->read;
            op_callbacks.seek = seek_64;
            op_callbacks.tell = tell_64;
            op_callbacks.close = pd->file->close;
            break;
        case kEventTerminate:
            pd->system->logToConsole("Terminating");
            audio_terminate();
            break;
        default:
            break;
    }

    return 0;
}