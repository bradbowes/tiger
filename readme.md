# Tiger compiler

- compiler for Andrew Appel's Tiger language with a few tweaks.
- written in Free Pascal.
- compiles to inefficient assembly language for Mac OS X86_64.
- hand written recursive descent lexer and parser.

# Differences from the Tiger book

- `mod` (integer division remainder) operator.
- `&` operator (logical and) changed to `and`.
- `|` operator (logical or) changed to `or`.
- boolean data type. Relational operators return booleans, `true` and
  `false` are keyword literals.
- char data type. Char literals are `#` followed by a single letter in
  quotation marks. eg `#"a"` or escape sequences `#"\n"`.
- file data type (C `FILE*` pointer) 
- sequences are enclosed in `begin` and `end` instead of
  parentheses.
- semicolon separators are optional between expressions in sequences.
- variable declarations: `var` keyword not used, format is
  `<id>`[`: <type>`]` = <exp>` (uses `=` instead of `:=`).
- function declarations: `function` keyword not used, format is
  `<id>(`[`<id>: <type> `{`, <id>: <type>`}]`) = <exp>`.
- strings can include line breaks and span multiple lines.
- no nested comments
- type aliases are not implemented.
- `break` is not implemented.
- string comparison operators (`<`, `<=`, `>`, `>=`) not implemented --
  use `string_compare` function instead.
- `use "<file_name>"` to include external definition file in `let`
  declaration block

# To do

- array bounds checking
- tail call optimization
- anonymous functions, first class functions
- closures
- enum
- array literals
- garbage collector
- polymorphic types and functions
- modules
- optimization
- ffi
- unicode

# Standard Library

## IO

### Constants

- STD_INPUT
- STD_OUTPUT
- STD_ERROR
- EOF

### Functions

- open_input(path: string): file
- open_output(path: string): file
- close_file(f: file)
- getchar(): char
- putchar(c: char)
- file_getchar(f: file): char
- file_putchar(c: char, f: file)
- write(s: string)
- writeln(s: string)
- file_write(s: string, f: file)
- file_writeln(s: string, f: file)
- command_argcount(): int
- command_arg(n: int): string
- halt(n: int)

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
- string_buffer(size: int): string

## Integers

- min(m: int, n: int): int
- max(m: int, n: int): int
