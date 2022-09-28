SYS_exit =  0x02000001
SYS_fork =  0x02000002
SYS_read =  0x02000003
SYS_write = 0x02000004
SYS_open =  0x02000005
SYS_close = 0x02000006
SYS_wait4 = 0x02000007
heap_size = 16 * 1024 * 1024

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
   jz fail
   movq %rax, %r15                     // top of heap pointer
   movq %rax, 8(%r14)                  // save base heap pointer

   // main code here
   call _tiger_entry

   movq 8(%r14),  %rdi                // free the heap
   call _free
   jmp exit

fail:
   movq $2, %rdi
   movq heap_err_msg@GOTPCREL(%rip), %rsi
   movq $25, %rdx
   movq $SYS_write, %rax
   syscall

exit:
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


.globl f$_str
.align 3
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
