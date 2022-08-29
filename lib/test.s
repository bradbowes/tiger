.text
.globl _entry
.align 3

_entry:
   pushq %r15
   movq %rsp, %r15
   andq $0xfffffffffffffff0, %rsp
   call tiger_read
   movq %r15, %rsp
   popq %r15
   xret
