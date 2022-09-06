# Tiger compiler

- compiler for the Andrew Appel's Tiger language with a few tweaks.
- written in Free Pascal, not following the tiger book very closely.
- partially compiles to as assembly language for Mac OS X86_64.
- compilation strategy similar Abdulaziz Ghuloum's scheme compiler article http://scheme2006.cs.uchicago.edu/11-ghuloum.pdf
- compiles to assembly from type checked AST with no IR.
- plan to implement IR and optimization passes down the road.

# Differences from Tiger book

- added 'mod' operator.
- '&' operator changed to 'and'
- '|' operator changed to 'or'
- added boolean data type. Relational operators return booleans, 'true' and 'false' are keyword literals.
- let in clause is a single expression. No 'end' token. Sequence expression can be used for side effects.
- variable declarations: var keyword not used, format is '<id> = <exp>' (uses '=' instead of ':=')
- function declarations: function keyword not used. format is '<id>(<id>: <type> ...) = <exp>'
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
