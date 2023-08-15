#include <opusfile.h>

int AudioHandler(void *context, int16_t *left, int16_t *right, int len);

typedef struct {
    OggOpusFile *current_of;
    OggOpusFile *new_of;
} PlaybackState;
