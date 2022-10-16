# Tiger compiler

- compiler for Andrew Appel's Tiger language with a few tweaks.
- written in Free Pascal, following the green Tiger book but not very closely.
- compiles to inefficient as assembly language for Mac OS X86_64.
- compiles to assembly from type checked AST with no IR.
- integers are int64

# Differences from the Tiger book

- added `mod` operator.
- `&` operator (logical and) changed to `and`.
- `|` operator (logical or) changed to `or`.
- added boolean data type. Relational operators return booleans, `true` and `false` are keyword literals.
- sequence expression is enclosed in `begin` and `end` instead of parenthesis.
- semicolons between expressions in `begin` and `let` bodies are optional.
- semicolon may optionally appear at the end of any expression.
- variable declarations: `var` keyword not used, format is `<id>`[`: <type>`]` = <exp>` (uses `=` instead of `:=`).
- function declarations: `function` keyword not used. format is `<id>(`[`<id>: <type> `{`, <id>: <type>`}]`) = <exp>`.
- strings can include linebreaks and span multiple lines.
- string escape \^c (control character) not implemented.
- no nested comments
- type aliases are not implemented.
- `break` expression is not implemented.

# To do

- builtin library functions
- records
- lists?
- multi-dimensional arrays
- array literals
- tail calls
- anonymous functions, first class functions
- closures
- overloads
- garbage collector
- enum
- case expressions
- tagged unions
- modules, separate compilation
- data types (real, byte, char)
- unicode strings
- optimization
- ffi

# Library

## IO

- read(): string                (done)
- write(s: string)              (done)
- print(s: string)              (appends newline to write output, done)

## Conversion

- str(i: int): string           (converts int to string, done)
- num(s: string): int           (converts string to int)

## Strings

- length(s: string): int        (done)
- sub(s: string, n: int): int   (done)
- ord(s: string): int           (done)
- chr(n: int): string           (done)
- substring(s: string, start: int, len: int): string (done)
- concat(s1: string, s2: string): string (done)
- compare(s1: string, s2: string): int
- find(src: string, find: string): int
