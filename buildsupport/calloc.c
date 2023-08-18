#include <pd_api.h>

#if TARGET_PLAYDATE
void* _calloc_r(struct _reent* _REENT, size_t nb_of_items, size_t item_size)
#else
void* calloc(size_t nb_of_items, size_t item_size)
#endif
{
    if (item_size && (nb_of_items > (SIZE_MAX / item_size))) {
        return NULL;
    }

    size_t size = nb_of_items * item_size;
    void* memory = malloc(size);
    if(memory != NULL) {
        memset(memory, 0, size);
    }

    return memory;
}
