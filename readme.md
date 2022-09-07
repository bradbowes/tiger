# Tiger compiler

- compiler for the Andrew Appel's Tiger language with a few tweaks.
- written in Free Pascal, following the tiger book but not very closely.
- partially compiles to as assembly language for Mac OS X86_64.
- compilation strategy similar Abdulaziz Ghuloum's scheme compiler article http://scheme2006.cs.uchicago.edu/11-ghuloum.pdf. Function arguments, local variables and temporaries are on the stack.
- compiles to assembly from type checked AST with no IR.
- plan to implement IR and optimization passes down the road. Also plan register allocaion compatible with X86_64 ABI.

# Differences from Tiger book

- added 'mod' operator.
- '&' operator changed to 'and'
- '|' operator changed to 'or'
- added boolean data type. Relational operators return booleans, `true` and `false` are keyword literals.
- let in clause is a single expression. `let <decls> in <exp>`. (No `end` keyword. The Tiger "sequence expression" can be used for multiple expression let bodies).
- variable declarations: var keyword not used, format is `<id>`[`: <type>`]` = <exp>` (uses `=` instead of `:=`)
- function declarations: function keyword not used. format is `<id>(`[`<id>: <type> `{`, <id>: <type>`}]`) = <exp>`
- strings are VB style (for now)

# To do

- assignments
- sequences
- lists
- mutually recursive functions in a let form (done)
- nested functions
- tail calls
- closures
- use abi registers
- records and arrays
- builtin library functions
- builtin inline functions (abs, ord, etc)
