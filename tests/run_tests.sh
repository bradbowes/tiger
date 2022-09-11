#!/bin/zsh

count=1
rm -f test*.s test*.tiger

test_code () {
   src=test$count.tiger
   output=test$count.s
   echo
   echo '\e[0;33mtesting' \#$count ...'\e[0m'
   echo $1 > $src
   ../compile $src
   mv output.s $output
   cc ../lib/lib.s $harness $output
   echo $1 '=>' $2
   if [ "$(./a.out)" = "$2" ]; then
      echo '\e[0;32mOK\e[0m' 
   else
      echo '\e[0;31mFAIL\e[0m'
   fi
   rm -f a.out
   let count+=1
   sleep .5
}

harness=test_int.c

: << END_COMMENT

test_code "12345" "12345"
test_code "65536" "65536"
test_code "-36545" "-36545"
test_code "345 + 678" "1023"
test_code "789 - 222" "567"
test_code "2435 - 62346" "-59911"
test_code "10 - 2 - 2" "6"
test_code "10 - (2 - 2)" "10"
test_code "10 - 2 + 2" "10"
test_code "256*256" "65536"
test_code "81 / 9" "9"
test_code "82 / 9" "9"
test_code "16 * (12 + 4)" "256"
test_code "16 / (12 + 4)" "1"
test_code "81 mod 9" "0"
test_code "82 mod 9" "1"
test_code "82 = 82" "1"
test_code "82 = 83" "0"
test_code "82 <> 82" "0"
test_code "82 <> 83" "1"
test_code "82 < 83" "1"
test_code "82 < 82" "0"
test_code "82 <= 83" "1"
test_code "83 <= 83" "1"
test_code "84 <= 83" "0"
test_code "153 > 45" "1"
test_code "153 > 153" "0"
test_code "45 > 153" "0"
test_code "153 >= 153" "1"
test_code "100 >= 153" "0"
test_code "9 - 4 = 5" "1"
test_code "9 - 4 = 4" "0"
test_code "1 = 1 and 2 = 2" "1"
test_code "1 = 1 and 1 = 2" "0"
test_code "1 = 2 and 2 = 2" "0"
test_code "1 = 1 or 1 = 2" "1"
test_code "2 = 3 or 2 = 2" "1"
test_code "2 = 3 or 3 = 4" "0"
test_code "2 = 2 or 1 = 1" "1"
test_code "true" "1"
test_code "false" "0"
test_code "true = true" "1"
test_code "true = false" "0"
test_code "true <> false" "1"
test_code "2 + 2 = 4 = true" "1"
test_code "nil" "0"
test_code "nil = nil" "1"
test_code "nil <> nil" "0"

test_code "let
   a = 15 + 29
   b =  6
in
   a + b + 9" "59"

test_code "let a = 10 in
   let b = a * 2 in
      a + b" "30"

test_code "let
   a = 10
   b = a * 2
in
   a + b" "30"

test_code "if 1 = 1 then 7 else 9" "7"
test_code "if 1 < 1 then 7 else 9" "9"
test_code "if false then 7 else 9" "9"
test_code "if true then 7 else 9" "7"
test_code "let
   a = 10
   b = let a = 20 b = 30 in a + b
in
   a + b" "60"


harness=test_string.c

test_code "\"abcdef\"" "6  abcdef"
test_code "\"this is \"\"line 1\"\"
this is line 2\"" "31  this is \"line 1\"
this is line 2"

test_code "let path = \"c:\\home\" in path" "7  c:\\home"

harness=test_int.c
test_code "let square(n: int): int = n * n in square(5)" "25"
test_code "let sum(m: int, n: int): int = m * m + n * n in sum(3, 4)" "25"
test_code "let
   a = 3
   b = 4
   sum(m: int, n: int): int = m * m + n * n
in
   sum(a, b)" "25"

test_code "let
   a = 1
   b = 2
   sum(m: int, n: int): int = m * m + n * n
in
   sum(a + b, a + a + a + a + a + a + a + a)" "73"


test_code "let
   fac(n: int): int = if n = 1 then 1 else n * fac(n - 1)
in
   fac(5)"  "120"

test_code "let
    square(n: int): int = n * n
    a = square(5)
in
   square(a)" "625"

test_code "let
   square(n: int): int = n * n
in
   square(square(5))" "625"


harness=test_string.c

test_code "let a = read() in a" ""

harness=test_int.c

END_COMMENT

test_code "let
   odd(n: int): bool = if n = 0 then false else even(n - 1)
   even(n: int): bool = if n = 0 then true else odd(n - 1)
in
   even(100)" "1"

test_code "let
   fib(n: int): int =
      if n < 2 then n
      else fib(n - 1) + fib(n - 2)
in fib(40)" "102334155"

test_code "let
   a = 10
   b = 20
in
   let nest(): int = a + b
in
   nest()" "30"

test_code "let w = 3 a(x: int): int =
  let b(y: int): int =
     let c(z: int): int = w + x + y + z in c(15)
  in b(10)
in a(5)" "33"

test_code "let
   outer(n: int): int =
      let
         inner1(): int = inner2()
         inner2(): int = n
      in
         inner1()
in
      outer(5)" "5"

test_code "(72; 42)" "42"

test_code "let
   a = 0
in
   (a := 5; a)" "5"
