MAC_OS =          0x02000000
SYS_EXIT =        MAC_OS | 1
SYS_FORK =        MAC_OS | 2
SYS_READ =        MAC_OS | 3
SYS_WRITE =       MAC_OS | 4
SYS_OPEN =        MAC_OS | 5
SYS_CLOSE =       MAC_OS | 6

STD_INPUT =       0x0000
STD_OUTPUT =      0x0001
STD_ERR =         0x0002

O_RDONLY =        0x0000
O_WRONLY =        0x0001
O_RDWR =          0x0002

O_CREAT =         0x00000200      /* create if nonexistant */
O_TRUNC =         0x00000400      /* truncate to zero length */
O_EXCL =          0x00000800      /* error if already exists */


heap_size = 16 * 1024 * 1024

.text
.align 3
.globl _main

_main:
   subq $40, %rsp                      // space for global variables
   movq %rsp, %r14                     // save global var pointer
   movq %rdi, 32(%r14)                 // argc
   movq %rsi, 24(%r14)                 // argv
   xorq %rax, %rax
   movq $heap_size, %rdi               // allocate heap
   call _malloc
   cmpq $0, %rax                       // check for null
   jz main_fail
   movq %rax, %r15                     // top of heap pointer
   movq %rax, 8(%r14)                  // save base heap pointer

   // main code here
   call f$_tiger_entry

   movq 8(%r14),  %rdi                 // free the heap
   call _free
   jmp main_done

main_fail:
   movq $STD_ERR, %rdi
   leaq heap_err_msg(%rip), %rsi
   movq $25, %rdx
   movq $SYS_WRITE, %rax
   syscall

main_done:
   addq $40, %rsp
   xorq %rax, %rax
   ret


.align 3
.globl f$_open_input
f$_open_input:
   movq 16(%rsp), %rdi
   addq $8, %rdi
   leaq read_mode(%rip), %rsi
   call _fopen
   ret


.align 3
.globl f$_close_file
f$_close_file:
   movq 16(%rsp), %rdi
   call _fclose
   ret


.align 3
.globl f$_getchar_file
f$_getchar_file:
   movq 16(%rsp), %rdi                 // FILE *
   call _fgetc
   movsx %eax, %rax                    // sign-extend int (EOF = -1)
   ret


.align 3
.globl f$_getchar
f$_getchar:
	movq ___stdinp@GOTPCREL(%rip), %rax
	movq (%rax), %rdi
   call _fgetc
   movsx %eax, %rax
   ret


.align 3
.globl f$_putchar_file
f$_putchar_file:
   movq 16(%rsp), %rdi
   movq 24(%rsp), %rsi
   call _fputc
   ret


.align 3
.globl f$_putchar
f$_putchar:
   movq 16(%rsp), %rdi
	movq ___stdoutp@GOTPCREL(%rip), %rax
	movq (%rax), %rsi
	call _fputc
	ret


.align 3
.globl f$_str
f$_str:
   pushq %rbx
   pushq %rcx
   leaq 8(%r15), %rdi                   // output string
   leaq str_fmt(%rip), %rsi             // format string
   movq 32(%rsp), %rdx                  // number
   xorq %rax, %rax                      // no float args
   call _sprintf
   movq %rax, (%r15)
   movq %rax, %rbx
   movq %r15, %rax
   addq $15, %rbx
   addq %rbx, %r15
   andq $0xfffffffffffffff8, %r15      // align 8 bytes
   popq %rcx
   popq %rbx
   ret


.align 3
.globl f$_length
f$_length:
   pushq %rsi
   movq 24(%rsp), %rsi
   movq (%rsi), %rax
   popq %rsi
   ret


.align 3
.globl f$_ord
f$_ord:
   ret                                 // cast char to int, does nothing


.align 3
.globl f$_chr
f$_chr:                                // cast int to char, does nothing
   ret


.align 3
copy:
   xorq %rbx, %rbx
copy_loop:
   cmpq %rbx, %rcx
   jle copy_done
   movb (%rsi, %rbx, 1), %al
   movb %al, (%rdi, %rbx, 1)
   incq %rbx
   jmp copy_loop
copy_done:
   movb $0, (%rdi, %rbx, 1)
   ret


.align 3
.globl f$_string_concat
f$_string_concat:
   movq 16(%rsp), %rsi                 // string 1
   movq (%rsi), %rcx
   movq %rcx, %rdx
   addq $8, %rsi
   leaq 8(%r15), %rdi
   call copy
   movq 24(%rsp), %rsi                 // string 2
   addq %rcx, %rdi
   movq (%rsi), %rcx
   addq %rcx, %rdx
   addq $8, %rsi
   call copy
   movq %rdx, (%r15)
   movq %r15, %rax
   addq $15, %rdx
   addq %rdx, %r15
   andq $0xfffffffffffffff8, %r15      // align 8 bytes
   ret


.align 3
.globl f$_substring
f$_substring:
   movq 16(%rsp), %rsi                 // source string
   movq 24(%rsp), %rbx                 // start position
   addq $8, %rbx
   addq %rbx, %rsi
   movq 32(%rsp), %rcx                 // length
   movq %rcx, (%r15)
   leaq 8(%r15), %rdi
   call copy
   movq %r15, %rax
   addq $15, %rcx
   addq %rcx, %r15
   andq $0xfffffffffffffff8, %r15      // align 8 bytes
   ret


.align 3
.globl f$_string_compare
f$_string_compare:
   movq 16(%rsp), %rsi                 // string1
   movq 24(%rsp), %rdi                 // string2
   movq $-1, %rdx
   xorq %rbx, %rbx
   xorq %rax, %rax
   movq (%rsi), %rcx
   cmpq (%rdi), %rcx
   jl compare_loop
   je compare_same_size
   movq (%rdi), %rcx                   // string2 is shorter
   movq $1, %rdx
   jmp compare_loop
compare_same_size:
   xorq %rdx, %rdx
compare_loop:
   cmpq %rbx, %rcx
   jle loop_done
   movb 8(%rsi, %rbx, 1), %al
   subb 8(%rdi, %rbx, 1), %al
   movsx %al, %rax
   jne compare_done
   incq %rbx
   jmp compare_loop
loop_done:
   movq %rdx, %rax
compare_done:
   ret


.align 3
.globl f$_toh
f$_toh:
   movq %r15, %rax
   ret


.align 3
.globl f$_command_argcount
f$_command_argcount:
   movq 32(%r14), %rax
   ret


.align 3
.globl f$_command_getarg
f$_command_getarg:
   movq 16(%rsp), %rbx                 // argv number
   movq 24(%r14), %rsi                 // get pointer to argv
   movq (%rsi, %rbx, 8), %rsi          // get offset
   leaq 8(%r15), %rdi                  // copy string here
   xorq %rbx, %rbx
getarg_loop:
   cmpb $0, (%rsi, %rbx, 1)            // end of string?
   je getarg_done
   movb (%rsi, %rbx, 1), %al           // copy char
   movb %al, (%rdi, %rbx, 1)
   incq %rbx                           // next char
   jmp getarg_loop
getarg_done:
   movq %rbx, (%r15)                   // string length
   movq %r15, %rax
   addq $15, %rbx                      // add space for length plus alignment
   addq %rbx, %r15                     // update heap pointer
   andq $0xfffffffffffffff8, %r15      // align 8 bytes
   ret


.data

.align 3
newline:
   .quad 1
   .asciz "\n"

.align 3
read_mode:
   .asciz "r"

.align 3
write_mode:
   .asciz "w"

.align 3
append_mode:
   .asciz "a"

.align 3
heap_err_msg:
   .asciz "Could not allocate heap.\n"

.align 3
str_fmt:
   .asciz "%ld"

.align 3
input_count:
   .quad 0
input_pos:
   .quad 0

.align 3
input_buffer:
   .skip 4096, 0

.align 3
output_buffer:
   .skip 4096, 0

