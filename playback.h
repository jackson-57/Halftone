#include <pd_api.h>

int set_playback(lua_State* L);
int get_playback_status(lua_State *L);
int toggle_playback(lua_State *L);
int seek_playback(lua_State *L);
void playback_terminate(void);
