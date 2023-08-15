#include <pd_api.h>
#include <opusfile.h>
#include "index.h"
#include "playback.h"
#include "audio.h"

// TODO: malloc vs pd->system->realloc?
// TODO: consistent formatting/naming

PlaydateAPI* pd;
OpusFileCallbacks cb = {NULL};

__attribute__((unused)) int eventHandler(PlaydateAPI* playdate, PDSystemEvent event, uint32_t arg)
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
                {set_playback,        "set_playback"},
                {get_playback_status, "get_playback_status"},
                {toggle_playback, "toggle_playback"},
                {seek_playback, "seek_playback"},
                {parse_metadata, "parse_metadata"},
                {process_art, "process_art"},
                {audio_init,          "audio_init"}
            };
            const char* err;
            for (int i = 0; i < 7; ++i)
            {
                if ( !pd->lua->addFunction(LUA_C_FUNCTIONS[i].function, LUA_C_FUNCTIONS[i].name, &err) )
                    pd->system->logToConsole("%s:%i: addFunction failed, %s", __FILE__, __LINE__, err);
            }

            // setup opusfile callbacks
            cb.read = (op_read_func) pd->file->read;
            cb.seek = (op_seek_func) pd->file->seek;
            cb.tell = (op_tell_func) pd->file->tell;
            cb.close = pd->file->close;
            break;
        case kEventTerminate:
            pd->system->logToConsole("Terminating");
            playback_terminate();
            audio_terminate();
            break;
        default:
            break;
    }


    return 0;
}