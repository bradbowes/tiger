# Tiger compiler

- compiler for Andrew Appel's Tiger language with a few tweaks.
- written in Free Pascal.
- compiles to inefficient as assembly language for Mac OS X86_64.
- hand written recursive descent lexer and parser.
- integers are int64

# Differences from the Tiger book

- semicolon is an expression terminator rather than separator and
  may also appear at the end of a sequence.
- semicolons are optional but may change the meaning of a program, for
  example `a - b` isn't the same as `a; -b`.
- added `mod` operator.
- `&` operator (logical and) changed to `and`.
- `|` operator (logical or) changed to `or`.
- added boolean data type. Relational operators return booleans, `true` and
  `false` are keyword literals.
- added char data type. Char literals are `#` followed by a single letter in
  quotation marks. eg `#"a"` or escape sequences `#"\n"`.
- expression sequences are enclosed in `begin` and `end` instead of
  parentheses.
- let and begin must contain at least one expression.
- variable declarations: `var` keyword not used, format is
  `<id>`[`: <type>`]` = <exp>` (uses `=` instead of `:=`).
- function declarations: `function` keyword not used, format is
  `<id>(`[`<id>: <type> `{`, <id>: <type>`}]`) = <exp>`.
- strings can include linebreaks and span multiple lines.
- string escape \^c (control character) not implemented.
- no nested comments
- type aliases are not implemented.
- `break` expression is not implemented.
- string comparison operators (`<`, `<=`, `>`, `>=`) not implemented.
  Use `string_compare` function instead.

# To do

- tail call optimization
- anonymous functions, first class functions
- closures
- file type
- enum
- case expressions
- multi-dimensional arrays
- array literals
- overloads
- garbage collector
- polymorphic types and functions
- modules, separate compilation
- optimization
- ffi
- unicode

# Standard Library

## IO

- read(): string
- write(s: string)
- print(s: string)              (appends newline to write output)
- getchar(): char
- putchar(c: char)

## Conversion

- str(i: int): string           (converts int to string)
- num(s: string): int           (converts string to int) (todo)
- ord(ch: char): int
- chr(n: int): char

## Strings

- length(s: string): int
- substring(s: string, start: int, len: int): string
- string_concat(s1: string, s2: string): string
- string_compare(s1: string, s2: string): int
