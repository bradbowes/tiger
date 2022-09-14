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
   movq $0, %rdi                             // stdin descriptor
   leaq 4(%r15), %rsi                           // read buffer
   movq $8192, %rdx                          // buffer length
   movq $SYS_read, %rax
   syscall
   movl %eax, (%r15)
   movq %r15, %rax 




// test write using syscall
/*
   movq %rax, %rbx
   movq %rax, %rdx
   movq $SYS_write, %rax
   movq $1, %rdi
   movq read_buffer@GOTPCREL(%rip), %rsi
   syscall
*/
// test write using puts
/*
   movq %rsi, %rdi

   pushq %r15
   movq %rsp, %r15
   andq $0xfffffffffffffff0, %rsp
   call _puts
   movq %r15, %rsp
   popq %r15
*/
   
   ret

.data
.align 3
read_buffer:
.skip 8192

