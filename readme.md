* Differences from Tiger book

- added 'mod' operator.
- '&' operator changed to 'and'
- '|' operator changed to 'or'
- added boolean data type. Relational operators return booleans, 'true' and 'false' are keyword literals.
- let in clause is a single expression. No 'end' token. Sequence expression can be used for side effects.
- variable declarations: var keyword not used, format is '<id> = <exp>' (uses '=' instead of ':=')
- function declarations: function keyword not used. format is '<id>(<id>: <type> ...) = <exp>'
- strings are VB style (for now)

* To do

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
