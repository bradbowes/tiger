heap_size = 16 * 1024 * 1024
SEEK_SET	= 0
SEEK_CUR = 1
SEEK_END = 2


.text
.p2align 3
.globl _main
_main:
   pushq %rbp
   movq %rsp, %rbp
   andq $0xfffffffffffffff0, %rsp
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
   leaq heap_err_msg(%rip), %rdi       // print error message
   movq ___stderrp@GOTPCREL(%rip), %rax
   movq (%rax), %rsi
   call _fputs

main_done:
   // addq $40, %rsp
   movq %rbp, %rsp
   xorq %rax, %rax
   popq %rbp
   ret


.p2align 3
.globl f$_open_input
f$_open_input:
   movq 16(%rsp), %rdi
   addq $8, %rdi
   leaq read_mode(%rip), %rsi
   call _fopen
   ret


.p2align 3
.globl f$_open_output
f$_open_output:
   movq 16(%rsp), %rdi
   addq $8, %rdi
   leaq write_mode(%rip), %rsi
   call _fopen
   ret


.p2align 3
.globl f$_close_file
f$_close_file:
   movq 16(%rsp), %rdi
   call _fclose
   ret


.p2align 3
.globl f$_get_stdin_ptr
f$_get_stdin_ptr:
	movq ___stdinp@GOTPCREL(%rip), %rax
	movq (%rax), %rax
   ret


.p2align 3
.globl f$_get_stdout_ptr
f$_get_stdout_ptr:
	movq ___stdoutp@GOTPCREL(%rip), %rax
	movq (%rax), %rax
   ret


.p2align 3
.globl f$_get_stderr_ptr
f$_get_stderr_ptr:
	movq ___stderrp@GOTPCREL(%rip), %rax
	movq (%rax), %rax
   ret


.p2align 3
.globl f$_file_getchar
f$_file_getchar:
   movq 16(%rsp), %rdi                 // FILE *
   call _fgetc
   movsx %eax, %rax                    // sign-extend int (EOF = -1)
   ret


.p2align 3
.globl f$_file_putchar
f$_file_putchar:
   movq 16(%rsp), %rdi
   movq 24(%rsp), %rsi
   call _fputc
   ret


.p2align 3
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
   andq $0xfffffffffffffff8, %r15      // p2align 8 bytes
   popq %rcx
   popq %rbx
   ret


.p2align 3
.globl f$_string_buffer
f$_string_buffer:
   movq 16(%rsp), %rbx
   movq %rbx, (%r15)
   addq $15, %rbx
   shrq $3, %rbx
   xorq %rax, %rax
buffer_loop:
   cmpq $0, %rbx
   je buffer_done
   movq %rax, 8(%r15, %rbx, 8)
   decq %rbx
   jmp buffer_loop
buffer_done:
   movq %r15, %rax
   addq (%r15), %r15
   addq $15, %r15
   andq $0xfffffffffffffff8, %r15      // p2align 8 bytes
   ret


.p2align 3
.globl f$_length
f$_length:
   movq 16(%rsp), %rax
   movq (%rax), %rax
   ret


.p2align 3
.globl f$_ord
f$_ord:
   ret                                 // cast char to int, does nothing


.p2align 3
.globl f$_chr
f$_chr:                                // cast int to char, does nothing
   ret


.p2align 3
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


.p2align 3
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
   andq $0xfffffffffffffff8, %r15      // p2align 8 bytes
   ret


.p2align 3
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
   andq $0xfffffffffffffff8, %r15      // p2align 8 bytes
   ret


.p2align 3
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


.p2align 3
.globl f$_toh
f$_toh:
   movq %r15, %rax
   ret


.p2align 3
.globl f$_command_argcount
f$_command_argcount:
   movq 32(%r14), %rax
   ret


.p2align 3
.globl f$_command_arg
f$_command_arg:
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
   addq $15, %rbx                      // add space for length plus p2alignment
   addq %rbx, %r15                     // update heap pointer
   andq $0xfffffffffffffff8, %r15      // p2align 8 bytes
   ret


.data

.p2align 3
newline:
   .quad 1
   .asciz "\n"

.p2align 3
read_mode:
   .asciz "r"

.p2align 3
write_mode:
   .asciz "w"

.p2align 3
append_mode:
   .asciz "a"

.p2align 3
heap_err_msg:
   .asciz "Could not allocate heap.\n"

.p2align 3
str_fmt:
   .asciz "%ld"

