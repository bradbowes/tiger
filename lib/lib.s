SYS_exit =  0x02000001
SYS_fork =  0x02000002
SYS_read =  0x02000003
SYS_write = 0x02000004
SYS_open =  0x02000005
SYS_close = 0x02000006
SYS_wait4 = 0x02000007
heap_size = 256 * 1024 * 1024

.text
.align 3
.globl _main

_main:
   subq $40, %rsp                      // space for global variables
   movq %rsp, %r14                     // save global var pointer
   movq %rdi,  32(%r14)                // argc
   movq %rsi,  24(%r14)                // argv
   movq $heap_size, %rdi               // allocate heap
   call _malloc
   cmpq $0, %rax                       // check for null
   jz main_fail
   movq %rax, %r15                     // top of heap pointer
   movq %rax, 8(%r14)                  // save base heap pointer

   // main code here
   call f$_tiger_entry

   movq 8(%r14),  %rdi                // free the heap
   call _free
   jmp main_exit

main_fail:
   movq $2, %rdi
   movq heap_err_msg@GOTPCREL(%rip), %rsi
   movq $25, %rdx
   movq $SYS_write, %rax
   syscall

main_exit:
   addq $56, %rsp
   movq $SYS_exit, %rax
   xorq %rdi, %rdi
   syscall


.align 3
.globl f$_read
f$_read:
   movq $0, %rdi                       // stdin descriptor
   leaq 8(%r15), %rsi                  // read buffer (top of heap plus space for string length)
   movq $4096, %rdx                    // buffer length
   movq $SYS_read, %rax
   syscall
   movq %rax, (%r15)                   // string length
   movq %rax, %rbx                     // save string length
   movq %r15, %rax                     // return address in RAX
   addq $15, %rbx                      // add space for length plus alignment
   addq %rbx, %r15                     // update heap pointer
   andq $0xfffffffffffffff8, %r15      // align 8 bytes
   ret


.align 3
.globl f$_write
f$_write:
   pushq %rbx
   pushq %rcx
   movq $1, %rdi                        // stdout descriptor
   movq 32(%rsp), %rbx                  // string parameter
   movq (%rbx), %rdx                    // string length field
   leaq 8(%rbx), %rsi                   // start of string
   movq $SYS_write, %rax
   syscall
   popq %rcx
   popq %rbx
   ret


.align 3
.globl f$_print
f$_print:
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
.globl f$_sub
f$_sub:
   pushq %rsi
   pushq %rbx
   movq 32(%rsp), %rsi                 // string parameter
   movq 40(%rsp), %rbx                 // position parameter
   movb 8(%rsi, %rbx, 1), %al
   popq %rbx
   popq %rsi
   andq $0x00000000000ff, %rax
   ret


.align 3
.globl f$_ord
f$_ord:
   pushq %rsi
   movq 24(%rsp), %rsi                 // string parameter
   movb 8(%rsi), %al
   andq $0x00000000000ff, %rax
   popq %rsi
   ret


.align 3
.globl f$_chr
f$_chr:
   movq $1, (%r15)
   movq 16(%rsp), %rax
   movb %al, 8(%r15)
   movq %r15, %rax
   addq $16, %r15
   ret


.align 3
copy:
   xorq %rbx, %rbx
copy_loop:
   cmpq %rbx, %rcx
   jl copy_done
   movb (%rsi, %rbx, 1), %al
   movb %al, (%rdi, %rbx, 1)
   incq %rbx
   jmp copy_loop
copy_done:
   movb $0, (%rdi, %rbx, 1)
   ret


.align 3
.globl f$_concat
f$_concat:
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


