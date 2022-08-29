#include <stdio.h>
#include <stdlib.h>

extern int* entry (void *heap);

int main(void) {
   void *heap = malloc(65536);
   int * result = entry(heap);
   printf("%d  %s\n", *result, ((char *)result) + 4);
   free(heap);
}

