#!/bin/zsh

count=1
rm -f test*.out test*.s test*.tiger

test_code () {
   src=test$count.tiger
   output=test$count.s
   exe=test$count.out
   echo
   echo '\e[0;33mtesting' \#$count ...'\e[0m'
   echo $1 > $src
   ../compile $src
   mv output.s $output
   cc -o $exe ../lib/lib.s $output
   echo $1 '=>' $2
   if [ "$(./$exe)" = "$2" ]; then
      echo '\e[0;32mOK\e[0m'
   else
      echo '\e[0;31mFAIL\e[0m'
      echo "$(./$exe)"
   fi
   let count+=1
   sleep .5
}

# : << END_COMMENT

test_code "print(str(12345))" "12345"
test_code "print(str(65536))" "65536"
test_code "print(str(-36545))" "-36545"
test_code "print(str(345 + 678))" "1023"
test_code "print(str(789 - 222))" "567"
test_code "print(str(2435 - 62346))" "-59911"
test_code "print(str(10 - 2 - 2))" "6"
test_code "print(str(10 - (2 - 2)))" "10"
test_code "print(str(10 - 2 + 2))" "10"
test_code "print(str(256*256))" "65536"
test_code "print(str(256*-256))" "-65536"
test_code "print(str(81 / 9))" "9"
test_code "print(str(82 / 9))" "9"
test_code "print(str(16 * (12 + 4)))" "256"
test_code "print(str(16 / (12 + 4)))" "1"
test_code "print(str(81 mod 9))" "0"
test_code "print(str(82 mod 9))" "1"
test_code "print(if 82 = 82 then \"true\" else \"false\")" "true"
test_code "print(if 82 = 83 then \"true\" else \"false\")" "false"
test_code "print(if 82 <> 82 then \"true\" else \"false\")" "false"
test_code "print(if 82 <> 83 then \"true\" else \"false\")" "true"
test_code "print(if 82 < 83 then \"true\" else \"false\")" "true"
test_code "print(if 82 < 82 then \"true\" else \"false\")" "false"
test_code "print(if 82 <= 83 then \"true\" else \"false\")" "true"
test_code "print(if 83 <= 83 then \"true\" else \"false\")" "true"
test_code "print(if 84 <= 83 then \"true\" else \"false\")" "false"
test_code "print(if 153 > 45 then \"true\" else \"false\")" "true"
test_code "print(if 153 > 153 then \"true\" else \"false\")" "false"
test_code "print(if 45 > 153 then \"true\" else \"false\")" "false"
test_code "print(if 153 >= 153 then \"true\" else \"false\")" "true"
test_code "print(if 100 >= 153 then \"true\" else \"false\")" "false"
test_code "print(if 9 - 4 = 5 then \"true\" else \"false\")" "true"
test_code "print(if 9 - 4 = 4 then \"true\" else \"false\")" "false"
test_code "print(if 1 = 1 and 2 = 2 then \"true\" else \"false\")" "true"
test_code "print(if 1 = 1 and 1 = 2 then \"true\" else \"false\")" "false"
test_code "print(if 1 = 2 and 2 = 2 then \"true\" else \"false\")" "false"
test_code "print(if true then \"true\" else \"false\")" "true"
test_code "print(if false then \"true\" else \"false\")" "false"
test_code "print(if true = true then \"true\" else \"false\")" "true"
test_code "print(if true = false then \"true\" else \"false\")" "false"
test_code "print(if true <> false then \"true\" else \"false\")" "true"
test_code "print(if (2 + 2 = 4) = true then \"true\" else \"false\")" "true"
test_code "print(if 2 + 2 = 4 = true then \"true\" else \"false\")" "true"
# test_code "print(if true = 2 + 2 = 4 then \"true\" else \"false\")" ""
test_code "print(if nil = nil then \"true\" else \"false\")" "true"
test_code "print(if nil <> nil then \"true\" else \"false\")" "false"


test_code "let a = 10 in
   let b = a * 2 in
      print(str(a + b))
   end
end" "30"

test_code "let
   a = 10
   b = a * 2
in
   print(str(a + b))
end" "30"

test_code "let
   a = 10
   b = let a = 20 b = 30 in a + b end
in
   print(str(a + b))
end" "60"

test_code "print(\"abcdef\")" "abcdef"
test_code "print(\"this is \\\"line 1\\\"
this is line 2\")" "this is \"line 1\"
this is line 2"

test_code "let square(n: int): int = n * n in print(str(square(5))) end" "25"
test_code "let sum(m: int, n: int): int = m * m + n * n in print(str(sum(3, 4))) end" "25"
test_code "let
   a = 3
   b = 4
   sum(m: int, n: int): int = m * m + n * n
in
   print(str(sum(a, b)))
end" "25"

test_code "let
   a = 1
   b = 2
   sum(m: int, n: int): int = m * m + n * n
in
   print(str(sum(a + b, a + a + a + a + a + a + a + a)))
end" "73"


test_code "let
   fac(n: int): int = if n = 1 then 1 else n * fac(n - 1)
in
   print(str(fac(5)))
end"  "120"

test_code "let
    square(n: int): int = n * n
    a = square(5)
in
   print(str(square(a)))
end" "625"

test_code "let
   square(n: int): int = n * n
in
   print(str(square(square(5))))
end" "625"


test_code "let
   a = 10
   b = 20
in
   let nest(): int = a + b
   in
      print(str(nest()))
   end
end" "30"


test_code "let w = 3 a(x: int): int =
  let b(y: int): int =
     let c(z: int): int = w + x + y + z in c(15) end
  in b(10) end
in print(str(a(5))) end" "33"


test_code "let
   outer(n: int): int =
      let
         inner1(): int = inner2()
         inner2(): int = n
      in
         inner1()
      end
in
   print(str(outer(5)))
end" "5"

# test_code "(print(str(72)); print(str(42)))" "72
# 42"

test_code "let
   a = 0
in
   a := 5;
   print(str(a))
end" "5"

test_code "print(\"Falsches Üben von Xylophonmusik quält jeden größeren Zwerg\")" "Falsches Üben von Xylophonmusik quält jeden größeren Zwerg"
test_code "print(\"Γαζέες καὶ μυρτιὲς δὲν θὰ βρῶ πιὰ στὸ χρυσαφὶ ξέφωτο\")" "Γαζέες καὶ μυρτιὲς δὲν θὰ βρῶ πιὰ στὸ χρυσαφὶ ξέφωτο"

test_code "print(\"イロハニホヘト チリヌルヲ ワカヨタレソ ツネナラム
ウヰノオクヤマ ケフコエテ アサキユメミシ ヱヒモセスン\")" "イロハニホヘト チリヌルヲ ワカヨタレソ ツネナラム
ウヰノオクヤマ ケフコエテ アサキユメミシ ヱヒモセスン"

test_code "let s = str(42) in print(s) end" "42"

test_code "print(str(42))" "42"

test_code "print(\"\")" ""

test_code "let
   odd(n: int): bool = if n = 0 then false else even(n - 1)
   even(n: int): bool = if n = 0 then true else odd(n - 1)
in
   print(if even(100) then \"true\" else \"false\")
end" "true"

test_code "let
   fib(n: int): int =
      if n < 2 then n
      else fib(n - 1) + fib(n - 2)
in print(str(fib(40)))
end" "102334155"

test_code "let
   type int_array = array of int
   a = int_array[3] of 42
in
   a[0] := 50;
   print(str(a[0] + a[1] + a[2]))
end" "134"

test_code "for i := 1 to 5 do
   print(str(i))
" "1
2
3
4
5"

test_code "let
   type int_array = array of int
   a = int_array[5] of 0
in
   for i := 0 to 4 do
      a[i] := (i + 1) * 2;

   for i := 0 to 4 do
      print(str(a[i]))

end" "2
4
6
8
10"



test_code "let
   p(n: int) = let s = str(n) in print(s) end
in
   p(42)
end" "42"

test_code "let
   p(n: int) = let s(n: int): string = str(n) in print(s(n)) end
in
   p(42)
end" "42"

test_code "let
   e(x: int): int =
      let f(y: int): int =
         x + y
      in
         f(3) + f(4)
      end
in
   print(str(e(25)))
end" "57"

test_code "let
   n = 1
in
   while n < 10 do begin
      print(str(n));
      n := n + 1
   end
end" "1
2
3
4
5
6
7
8
9"

test_code "print(str(600851475143 / 2))" "300425737571"
test_code "let
   i = 0
   update() = i := i + 1
in
   update();
   print(str(i))
end" "1"

test_code "let
   type int_array = array of int
   type int_matrix = array of int_array

   numbers = int_matrix[3] of int_array[3] of 0
in
   print(str(numbers[0][0]))
end" "0"

test_code "let
   type int_array = array of int
   type int_matrix = array of int_array
   numbers = int_matrix[3] of nil
in
   for i := 0 to 2 do begin
      numbers[i] := int_array[3] of 0;
      for j := 0 to 2 do
         numbers[i][j] := i * 10 + j
   end;

   for i := 0 to 2 do
      for j := 0 to 2 do
         print(str(numbers[i][j]))

end" "0
1
2
10
11
12
20
21
22"

test_code "print(str(length(\"abcdefg\")))" "7"

test_code "let
   s = \"hello, world!\"
   ss1 = substring(s, 7, 5)
   ss2 = substring(s, 0, 5)
in
   print(ss1);
   print(ss2)
end" "world
hello"


test_code "putchar(chr(97))" "a"
test_code "putchar(chr(ord(#\"b\")))" "b"
test_code "print(str(ord(#\"c\")))" "99"



# test_code "let
#    empty = \"\"
#    ch = chr(97)
# in
#    for i := 1 to 5 do begin
#       empty := concat(ch, empty)
#       print(empty)
#    end
# end" "a
# aa
# aaa
# aaaa
# aaaaa"

test_code 'let path = "c:\\\\home" in print(path) end' 'c:\home'
test_code 'print("hello\nworld")' 'hello
world'
test_code 'print("\\097")' 'a'
test_code 'print("hello \
   \world!")' 'hello world!'


test_code "let
   type item = {name: string, qty: int, next: item, inv: invoice}
   type item_list = {it: item, next: item_list}
   type invoice = {n: int, items: item_list}
in
   0
end" ""

test_code "let
   type person = {name: string, age: int}
in
   0
end" ""

test_code "let
   type person = { name: string, age: int }
   a = person { name = \"Harry Potter\", age = 19 }
   b = person { name = \"Dumbledore\", age = 153 }
in
   print(a.name);
   print(str(a.age));
   print(b.name);
   print(str(b.age))
end" "Harry Potter
19
Dumbledore
153"

test_code "let
   type person = { name: string, age: int }
   a: person = nil
in
   print(if a = nil then \"nil\" else \"?\")
end" "nil"

test_code "let
   type person = { name: string, age: int }
   a = person { name = \"Harry Potter\", age = 19 }
in
   print(a.name);
   print(str(a.age));
   a.age := 20;
   print(str(a.age))
end" "Harry Potter
19
20"

test_code "true or (begin print(\"x\"); false end)" ""
test_code "false or (begin print(\"x\"); false end)" "x"
test_code "true and (begin print(\"x\"); false end)" "x"
test_code "false and (begin print(\"x\"); false end)" ""
test_code "true or (begin print(\"x\"); false end) or (begin print(\"y\"); true end)" ""
test_code "false or (begin print(\"x\"); false end) or (begin print(\"y\"); true end)" "x
y"

test_code "print(if 1 = 1 or 1 = 2 then \"true\" else \"false\")" "true"
test_code "print(if 2 = 3 or 2 = 2 then \"true\" else \"false\")" "true"
test_code "print(if 2 = 3 or 3 = 4 then \"true\" else \"false\")" "false"
test_code "print(if 2 = 2 or 1 = 1 then \"true\" else \"false\")" "true"
test_code "if false then print(\"hello\")" ""

test_code "let s = \"hello\"
in
   for i := 0 to 4 do
      print(str(ord(s[i])))
end" "104
101
108
108
111"

test_code "let
   s = \"hi\"
in
   for i := 1 to 4 do
      let
         len = length(s)
         x = 0
      in
         print(str(i));
         for j := 0 to len - 1 do
            print(str(ord(s[j])))
      end
end" "1
104
105
2
104
105
3
104
105
4
104
105"

test_code "let
   s = string_concat(\"hello\", \" world\")
in
   print(s);
   print(str(length(s)))
end" "hello world
11"

test_code "print(str(string_compare(\"\", \"hello\")))" "-1"
test_code "let
   s = \"hello, world!\"
   ss1 = substring(s, 7, 5)
   ss2 = substring(s, 0, 5)
in
   print(ss1);
   print(ss2)
end" "world
hello"

test_code "let
   type s_array = array of string
   type i_array = array of int
   sa = s_array[5] of \"hello\"
   ia = i_array[5] of 0
in
   sa[0] := \"one\";
   sa[1] := \"two\";
   sa[2] := \"three\";
   sa[3] := \"four\";
   sa[4] := \"five\";

   for i := 0 to 4 do
      ia[i] := length(sa[i]);

   for i := 0 to 4 do
      print(str(ia[i]))

end" "3
3
5
4
4"

# END_COMMENT

test_code "let
   a = 15 + 29
   b =  6
in
   print(str(a + b + 9))
end" "59"
