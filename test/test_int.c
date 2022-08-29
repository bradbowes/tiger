#include <stdio.h>
#include <stdlib.h>

extern long entry (void *heap);

int main(void) {
   void *heap = malloc(65536);
   long result = entry(heap);
   printf("%ld\n", result);
   free(heap);
}

