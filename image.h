#include <pd_api.h>

void floyd_steinberg_dither(unsigned char *input, int w, int h);
LCDBitmap* pack_bitmap(PlaydateAPI* pd, const unsigned char *input, int w, int h);