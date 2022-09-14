SYS_exit =  0x02000001
SYS_fork =  0x02000002
SYS_read =  0x02000003
SYS_write = 0x02000004
SYS_open =  0x02000005
SYS_close = 0x02000006
SYS_wait4 = 0x02000007

.text
.globl f$_read
.align 3

f$_read:
   movq $0, %rdi                       // stdin descriptor
   leaq 8(%r15), %rsi                  // read buffer (top of heap plus space for string length)
   movq $8192, %rdx                    // buffer length
   movq $SYS_read, %rax
   syscall
   movq %rax, (%r15)                   // string length
   movq %rax, %rbx                     // save string length
   movq %r15, %rax                     // return address in RAX
   addq $15, %rbx                      // add space for length plus alignment
   addq %rbx, %r15                     // update heap pointer
   andq $0xfffffffffffffff8, %r15      // align 8 bytes
   ret


.globl f$_write
.align 3

f$_write:
   movq $1, %rdi                        // stdout descriptor
   movq 16(%rsp), %rbx                  // string parameter
   movq (%rbx), %rdx                    // string length field
   leaq 8(%rbx), %rsi                   // start of string
   movq $SYS_write, %rax
   syscall
   ret


.data

