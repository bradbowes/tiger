#include <stdio.h>
#include <stdlib.h>

extern int entry (void *heap, void *istack, void *pstack);

int main(void) {
   void *heap = malloc(16*1024*1024); 
   void *istack = malloc(4096 * 8);
   void *pstack = malloc(4096 * 8);
   printf("%d\n", entry(heap, istack, pstack));
   free(heap);
   free(istack);
   free(pstack);
   return 0;
}

