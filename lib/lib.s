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
   movq heap_err_msg@GOTPCREL(%rip), %rsi
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
   movq 16(%rsp), %rdi                 // path
   addq $8, %rdi
   movq $O_RDONLY, %rsi
   movq $SYS_OPEN, %rax
   syscall
   ret


.align 3
.globl f$_close
f$_close:
   movq 16(%rsp), %rdi
   movq $SYS_CLOSE, %rax
   syscall
   ret


.align 3
.globl f$_read
f$_read:
   movq $STD_INPUT, %rdi
   leaq 8(%r15), %rsi                  // read buffer (top of heap plus space for string length)
   movq $4096, %rdx                    // buffer length
   movq $SYS_READ, %rax
   syscall
   movq %rax, (%r15)                   // string length
   movq %rax, %rbx                     // save string length
   movq %r15, %rax                     // return address in RAX
   addq $15, %rbx                      // add space for length plus alignment
   addq %rbx, %r15                     // update heap pointer
   andq $0xfffffffffffffff8, %r15      // align 8 bytes
   ret


.align 3
.globl f$_getchar
f$_getchar:
   subq $16, %rsp
   movq $STD_INPUT, %rdi
   movq %rsp, %rsi
   movq $1, %rdx
   movq $SYS_READ, %rax
   syscall
   cmpq $0, %rax
   jne got_input
   movq $-1, %rax
   jmp done_input
got_input:
   movb (%rsi), %al
   andq $0x00000000000000ff, %rax
done_input:
   addq $16, %rsp
   ret


/*
.align 3
.global f$_putchar
f$_putchar:
   movb 16(%rsp), %al
   movq $STD_OUTPUT, %rdi
   movq output_buffer@GOTPCREL(%rip), %rsi
   movb %al, (%rsi)
   movq $1, %rdx
   movq $SYS_WRITE, %rax
   syscall
   ret
*/

.align 3
.globl f$_putchar
f$_putchar:
   movq $STD_OUTPUT, %rdi
   leaq 16(%rsp), %rsi
   movq $1, %rdx
   movq $SYS_WRITE, %rax
   syscall
   ret
   

.align 3
.globl f$_write
f$_write:
   pushq %rbx
   pushq %rcx
   movq $STD_OUTPUT, %rdi
   movq 32(%rsp), %rbx                  // string parameter
   movq (%rbx), %rdx                    // string length field
   leaq 8(%rbx), %rsi                   // start of string
   movq $SYS_WRITE, %rax
   syscall
   popq %rcx
   popq %rbx
   ret


.align 3
.globl f$_writeln
f$_writeln:
   movq 16(%rsp), %rax
   movq %rax, 8(%rsp)
   call f$_write
   movq newline@GOTPCREL(%rip), %rax
   movq %rax, 16(%rsp)
   jmp f$_write


.align 3
.globl f$_str
f$_str:
   pushq %rbx
   pushq %rcx
   leaq 8(%r15), %rdi                   // output string
   movq str_fmt@GOTPCREL(%rip), %rsi    // format string
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


.data

.align 3
newline:
   .quad 1
   .asciz "\n"

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

