unit scanners;

interface

type
   token_tag = (and_token,
                array_token,
                assign_token,
                begin_token,
                char_token,
                colon_token,
                comma_token,
                comment_token,
                div_token,
                do_token,
                dot_token,
                else_token,
                end_token,
                eof_token,
                eq_token,
                false_token,
                for_token,
                geq_token,
                gt_token,
                id_token,
                if_token,
                in_token,
                lbrace_token,
                lbracket_token,
                leq_token,
                let_token,
                lparen_token,
                lt_token,
                minus_token,
                mod_token,
                mul_token,
                neq_token,
                nil_token,
                number_token,
                of_token,
                or_token,
                plus_token,
                rbrace_token,
                rbracket_token,
                rparen_token,
                semicolon_token,
                string_token,
                then_token,
                to_token,
                true_token,
                type_token,
                while_token);

   token_t = record
                tag: token_tag;
                value: string;
                line, col: longint;
             end;

   scanner = ^scanner_t;
   scanner_t = record
                  open: boolean;
                  src: text;
                  ch: char;
                  x, y: longint;
               end;

function make_scanner(file_name: string): scanner;
procedure scan(s: scanner);

var
   token: token_t;


implementation

uses utils;

procedure scan(s: scanner);

   procedure next;
   begin
      if s^.open then
         if eof(s^.src) then begin
            s^.ch := chr(4);
            close(s^.src);
            s^.open := false;
         end
         else begin
            read(s^.src, s^.ch);
            s^.x := s^.x + 1;
            if s^.ch = chr(10) then begin
               s^.y := s^.y + 1;
               s^.x := 0;
            end
         end
         else
            err('Read past end of file', token.line, token.col);
   end;


   procedure push_char();
   begin
      token.value := token.value + s^.ch;
      next;
   end;


   procedure recognize(TType: token_tag);
   begin
      push_char;
      token.tag := TType;
   end;


   procedure skip_white;
   begin
      while s^.ch in [' ', chr(9) .. chr(13)] do
         next;
   end;


   procedure skip_comment;
   begin
      token.value := '/*';
      repeat
         repeat
            next;
            token.value := token.value + s^.ch;
         until s^.ch = '*';
         next;
         while s^.ch = '*' do
            next;
      until s^.ch = '/';
      next;
      token.value := token.value + '/';
      token.tag := comment_token;
   end;


   procedure get_string;
   var
      escape: string = '';
      code: string;
   begin
      next;
      while s^.ch <> '"' do
         if s^.ch = '\' then begin
            next;
            case s^.ch of
               't': escape := chr(9);   (* tab *)
               'n': escape := chr(10);  (* newline *)
               'r': escape := chr(13);  (* carriage return *)
               '\': escape := '\';
               '"': escape := '"';
               '''': escape := '''';
               '0'..'9': begin
                  code := s^.ch;
                  next;
                  if s^.ch in ['0'..'9'] then
                     code := code + s^.ch
                  else
                     err('illegal escape sequence', s^.x, s^.y);
                  next;
                  if s^.ch in ['0'..'9'] then
                     code := code + s^.ch
                  else
                     err('illegal escape sequence',  s^.x, s^.y);
                  if code > '255' then
                     err('illegal escape sequence',  s^.x, s^.y);
                  escape := chr(atoi(code, s^.x, s^.y));
               end;
               ' ', chr(9) .. chr(13): begin
                  skip_white;
                  if s^.ch = '\' then begin
                     next;
                     continue;
                  end
                  else
                     err('illegal escape sequence',  s^.x, s^.y);
               end;
               else
                  err('illegal escape sequence',  s^.x, s^.y);
            end;
            token.value := token.value + escape;
            next;
         end
         else
            push_char;
      next;
      token.tag := string_token;
   end;


   procedure get_char();
   begin
      next;
      if s^.ch = '"' then
         get_string()
      else
         err('illegal character literal', s^.x, s^.y);
      if length(token.value) <> 1 then
         err('illegal character literal', token.line, token.col);
      token.tag := char_token;
   end;


   procedure get_number;
   begin
      while s^.ch in ['0'..'9'] do
         push_char();
      token.tag := number_token;
   end;


   procedure get_id;
   begin
      while s^.ch in ['a'..'z', 'A'..'Z', '0'..'9', '_'] do
         push_char;
      case token.value of
         'and': token.tag := and_token;
         'array': token.tag := array_token;
         'begin': token.tag := begin_token;
         'do': token.tag := do_token;
         'else': token.tag := else_token;
         'end': token.tag := end_token;
         'false': token.tag := false_token;
         'for': token.tag := for_token;
         'if': token.tag := if_token;
         'in': token.tag := in_token;
         'let': token.tag := let_token;
         'mod': token.tag := mod_token;
         'nil': token.tag := nil_token;
         'of': token.tag := of_token;
         'or': token.tag := or_token;
         'then': token.tag := then_token;
         'to': token.tag := to_token;
         'true': token.tag := true_token;
         'type': token.tag := type_token;
         'while': token.tag := while_token;
      else
         token.tag := id_token;
      end;
   end;

begin
   skip_white;
   token.value := '';
   token.col := s^.x;
   token.line := s^.y;
   if not s^.open then
   begin
      token.tag := eof_token;
      token.value := '<EOF>';
   end
   else
   begin
      case s^.ch of
         ',': recognize(comma_token);
         ';': recognize(semicolon_token);
         '.': recognize(dot_token);
         '(': recognize(lparen_token);
         ')': recognize(rparen_token);
         '[': recognize(lbracket_token);
         ']': recognize(rbracket_token);
         '{': recognize(lbrace_token);
         '}': recognize(rbrace_token);
         '+': recognize(plus_token);
         '-': recognize(minus_token);
         '*': recognize(mul_token);
         '/': begin
            push_char;
            if s^.ch = '*' then skip_comment
            else token.tag := div_token;
         end;
         '=': recognize(eq_token);
         '<': begin
            push_char;
            case s^.ch of
               '>': recognize(neq_token);
               '=': recognize(leq_token);
            else
               token.tag:= lt_token;
            end;
         end;
         '>': begin
            push_char;
            if s^.ch = '=' then recognize(geq_token)
            else token.tag := gt_token;
         end;
         ':': begin
            push_char;
            if s^.ch = '=' then recognize(assign_token)
            else token.tag := colon_token;
         end;
         '0'..'9': get_number;
         '"': get_string;
         '#': get_char;
         'a'..'z', 'A'..'Z': get_id;
      else
         err('Illegal token ''' + s^.ch + '''', token.line, token.col);
      end;
   end;
end;


function make_scanner(file_name: string): scanner;
var s: scanner;
begin
   new(s);
   assign(s^.src, file_name);
   reset(s^.src);
   s^.open := true;
   read(s^.src, s^.ch);
   s^.x := 1;
   s^.y := 1;
   make_scanner := s;
end;


end.
