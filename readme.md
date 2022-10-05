# Tiger compiler

- compiler for Andrew Appel's Tiger language with a few tweaks.
- written in Free Pascal, following the green (c) tiger book but not very closely.
- compiles to inefficient as assembly language for Mac OS X86_64.
- compilation strategy similar Abdulaziz Ghuloum's scheme compiler article http://scheme2006.cs.uchicago.edu/11-ghuloum.pdf. Function arguments, local variables and temporaries are on the stack.
- compiles to assembly from type checked AST with no IR.
- plan to implement IR and optimization passes down the road. Also plan register allocaion compatible with X86_64 ABI.

# Differences from the Tiger book

- added 'mod' operator.
- '&' operator changed to 'and'.
- '|' operator changed to 'or'.
- added boolean data type. Relational operators return booleans, `true` and `false` are keyword literals.
- let in clause is a single expression. `let <decls> in <exp>`. (No `end` keyword. The Tiger "sequence expression" can be used for multiple expression let bodies).
- variable declarations: var keyword not used, format is `<id>`[`: <type>`]` = <exp>` (uses `=` instead of `:=`).
- function declarations: function keyword not used. format is `<id>(`[`<id>: <type> `{`, <id>: <type>`}]`) = <exp>`.
- strings are VB style (for now). Strings can include linebreaks and span multiple lines.
- type aliases are not implemented.

# To do

- while loops
- builtin library functions
- builtin inline functions (abs, ord, etc)
- records
- lists?
- escapes in strings
- tail calls
- lambdas, first class functions
- closures
- use abi registers, IR and optimization

# Library

## IO

- read(): string                (done)
- write(s: string)              (done)
- writeln(s: string)            (appends newline to string, done)

## Conversion

- str(i: int): string           (converts int to string, done)
- str2int(s: string): int

## Strings

- uppercase(s: string): string
- lowercase(s: string): string
- string_length(s: string): int
- string_compare(s1: string, s2: string): int
- string_concat(s1: string, s2: string): string
- substring(s: string, start: int, len: int): string
- string_find(src: string, find: string): int

