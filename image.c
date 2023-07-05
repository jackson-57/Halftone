#include "image.h"

// TODO: Attempt to flatten loops. Try to understand the bitshift logic in pack_bitmap.

unsigned char clamp(int value);

// https://chat.openai.com/share/ec572308-f597-416f-9f38-43fd4aefd909
// https://en.wikipedia.org/wiki/Floyd%E2%80%93Steinberg_dithering
void floyd_steinberg_dither(unsigned char *input, int w, int h)
{
    for (int y = 0; y < h; y++)
    {
        for (int x = 0; x < w; x++)
        {
            // Get the current pixel value
            unsigned char oldPixel = input[y * w + x];

            // Quantize the pixel value
            unsigned char newPixel = (oldPixel < 128) ? 0 : 255;

            // Set the new pixel value
            input[y * w + x] = newPixel;

            // Calculate the quantization error
            int error = oldPixel - newPixel;

            // Distribute the error to neighboring pixels
            if (x + 1 < w)
            {
                input[y * w + (x + 1)] = clamp(input[y * w + (x + 1)] + (error * 7) / 16);
            }
            if (x - 1 >= 0 && y + 1 < h)
            {
                input[(y + 1) * w + (x - 1)] = clamp(input[(y + 1) * w + (x - 1)] + (error * 3) / 16);
            }
            if (y + 1 < h)
            {
                input[(y + 1) * w + x] = clamp(input[(y + 1) * w + x] + (error * 5) / 16);
            }
            if (x + 1 < w && y + 1 < h)
            {
                input[(y + 1) * w + (x + 1)] = clamp(input[(y + 1) * w + (x + 1)] + error / 16);
            }
        }
    }
}

// Stores 8-bit image data in a Playdate bitmap. Can act as a threshold filter.
LCDBitmap* pack_bitmap(PlaydateAPI* pd, const unsigned char *input, int w, int h)
{
    LCDBitmap *bitmap = pd->graphics->newBitmap(w, h, kColorWhite);
    int rowbytes;
    uint8_t *output;
    pd->graphics->getBitmapData(bitmap, NULL, NULL, &rowbytes, NULL, &output);

    for (int y = 0; y < h; ++y)
    {
        for (int x = 0; x < w; ++x)
        {
            // Set pixel black if value is half or less
            if (input[y * w + x] < 128) {
                output[y * rowbytes + (x / 8)] &= ~(1 << (7 - (x % 8)));
            }
        }
    }

    return bitmap;
}

// Limit values within valid ranges for pixels
unsigned char clamp(int value)
{
    if (value < 0)
    {
        return 0;
    }
    else if (value > 255)
    {
        return 255;
    }
    else
    {
        return (unsigned char)value;
    }
}