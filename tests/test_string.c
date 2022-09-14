#include <stdio.h>
#include <stdlib.h>

extern long* tiger_entry (void *heap);

int main(void) {
   void *heap = malloc(65536);
   long * result = tiger_entry(heap);
   printf("%ld  %s\n", *result, ((char *)result) + 8);
   free(heap);
}

