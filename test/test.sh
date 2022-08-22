#!/bin/zsh

test_code () {
   echo $1 > tt.t
   ../compile tt.t
   cc -o test test.c output.s
   if [ "$(./test)" = "$2" ]; then
      echo '\e[0;32mOK\e[0m' $1 '=>' $2
   else
      echo '\e[0;31mFAIL\e[0m' $1
   fi
   rm output.s
   rm test
   rm tt.t
}
: <<'END COMMENT'
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
END COMMENT

test_code "let var a := 10 in a" "10"
test_code "let var a := 15 + 29
     var b :=  6
     in
     a + b + 9" "59"


