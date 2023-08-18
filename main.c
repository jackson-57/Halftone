#include <pd_api.h>
#include <opusfile.h>
#include "index.h"
#include "playback.h"
#include "audio.h"

PlaydateAPI* pd;
OpusFileCallbacks op_callbacks = {NULL};

int eventHandler(PlaydateAPI* playdate, PDSystemEvent event, uint32_t arg)
{
    switch (event)
    {
        case kEventInitLua:
            pd = playdate;

            struct LUA_C_FUNCTION {
                lua_CFunction function;
                char* name;
            };
            struct LUA_C_FUNCTION LUA_C_FUNCTIONS[] = {
                {set_playback, "set_playback"},
                {get_playback_status, "get_playback_status"},
                {toggle_playback, "toggle_playback"},
                {seek_playback, "seek_playback"},
                {parse_metadata, "parse_metadata"},
                {process_art, "process_art"},
                {audio_init, "audio_init"},
                {audio_update, "audio_update"}
            };
            const char* err;
            for (int i = 0; i < 8; ++i)
            {
                if ( !pd->lua->addFunction(LUA_C_FUNCTIONS[i].function, LUA_C_FUNCTIONS[i].name, &err) )
                    pd->system->logToConsole("%s:%i: addFunction failed, %s", __FILE__, __LINE__, err);
            }

            // setup opusfile callbacks
            op_callbacks.read = (op_read_func) pd->file->read;
            op_callbacks.seek = (op_seek_func) pd->file->seek;
            op_callbacks.tell = (op_tell_func) pd->file->tell;
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