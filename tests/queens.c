# include <stdio.h>

const int n = 8;

int row[n];
int col[n];
int diag1[n + n - 1];
int diag2[n + n - 1];


void init(void) {
   int i;
   for (i = 0; i < n; i++) {
      row[i] = 0;
      col[i] = 0;
   }
   for (i = 0; i < n + n - 1; i++) {
      diag1[i] = 0;
      diag2[i] = 0;
   }
}


void printboard(void) {
    int i, j;
    for (i = 0; i < n; i++) {
       for (j = 0; j < n; j++)
         if (col[i] == j)
            fputs(" O", stdout);
         else
            fputs(" .", stdout);
       fputs("\n", stdout);
    }
    fputs("\n", stdout);
}


void try(int c) {
   int r;
   if (c == n)
      printboard();
   else
      for (r = 0; r < n; r++) {
         if (row[r] == 0 && diag1[r + c] == 0 && diag2[r + 7 - c] == 0) {
            row[r] = 1;
            diag1[r + c] = 1;
            diag2[r + 7 - c] = 1;
            col[c] = r;
            try(c + 1);
            row[r] = 0;
            diag1[r + c] = 0;
            diag2[r + 7 - c] = 0;
         }
      }
}

int main(void) {

   init();
   try(0);

}
