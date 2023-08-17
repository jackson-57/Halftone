#include <opusfile.h>

int audio_render(void *context, int16_t *left, int16_t *right, int len);

typedef struct {
    int playing;
    OggOpusFile *opus_file;
    SoundSource *sound_source;
} PlaybackState;
