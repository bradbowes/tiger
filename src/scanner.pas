unit scanner;

interface

uses sources;

type
   token_tag = (and_token,
                array_token,
                assign_token,
                begin_token,
                case_token,
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
                pipe_token,
                plus_token,
                rbrace_token,
                rbracket_token,
                rparen_token,
                semicolon_token,
                string_token,
                then_token,
                to_token,
                type_token,
                use_token,
                while_token);

   token_t = record
                tag: token_tag;
                value: string;
             end;

procedure scan();
function token_location(): source_location;

var
   token: token_t;
   line, col: longint;

implementation

uses sysutils;

procedure scan();

   procedure push_char();
   begin
      token.value := token.value + src.ch;
      getch();
   end;

   procedure recognize(tag: token_tag);
   begin
      push_char;
      token.tag := tag;
   end;

   procedure skip_white;
   begin
      while src.ch in [' ', #9 .. #13] do
         getch();
   end;

   procedure skip_comment;
   begin
      token.value := '(*'; (*---*)
      repeat
         repeat
            getch();
            token.value := token.value + src.ch;
         until src.ch = '*';
         getch();
         while src.ch = '*' do
            getch();
      until src.ch = ')';
      getch();
      token.value := token.value + ')';
      token.tag := comment_token;
   end;

   procedure get_string;
   var
      escape: string = '';
      code: string;
   begin
      getch();
      while src.ch <> '"' do
         if src.ch = '\' then
            begin
               getch();
               case src.ch of
                  'a': escape := #7;  (* alert *)
                  'b': escape := #8;  (* backspace *)
                  't': escape := #9;  (* tab *)
                  'n': escape := #10; (* newline *)
                  'v': escape := #11; (* vertical tab *)
                  'f': escape := #12; (* form feed *)
                  'r': escape := #13; (* carriage return *)
                  '\': escape := '\';
                  '"': escape := '"';
                  '^':
                     begin
                        getch();
                        if src.ch in ['A'..'Z'] then
                           escape := chr(ord(src.ch) - 64)
                        else if src.ch in ['a'.. 'z'] then
                           escape := chr(ord(src.ch) - 96)
                        else
                           err('illegal escape sequence', src_location());
                     end;
                  '0'..'9':
                     begin
                        code := src.ch;
                        getch();
                        if src.ch in ['0'..'9'] then
                           code := code + src.ch
                        else
                           err('illegal escape sequence', src_location());
                        getch();
                        if src.ch in ['0'..'9'] then
                           code := code + src.ch
                        else
                           err('illegal escape sequence', src_location());
                        if code > '255' then
                           err('illegal escape sequence', src_location());
                        escape := chr(strtoint(code));
                     end;
                  ' ', chr(9) .. chr(13):
                     begin
                        skip_white;
                        if src.ch = '\' then
                           begin
                              getch();
                              continue;
                           end
                        else
                           err('illegal escape sequence', src_location());
                     end;
                  else
                     err('illegal escape sequence', src_location());
               end;
               token.value := token.value + escape;
               getch();
            end
         else
            push_char;
      getch();
      token.tag := string_token;
   end;

   procedure get_char();
   begin
      getch();
      if src.ch = '"' then
         get_string()
      else
         err('illegal character literal', src_location());
      if length(token.value) <> 1 then
         err('illegal character literal', token_location());
      token.tag := char_token;
   end;

   procedure get_number;
   begin
      while src.ch in ['0'..'9'] do
         push_char();
      token.tag := number_token;
   end;

   procedure get_id;
   begin
      while src.ch in ['a'..'z', 'A'..'Z', '0'..'9', '_'] do
         push_char;
      case token.value of
         'and': token.tag := and_token;
         'array': token.tag := array_token;
         'begin': token.tag := begin_token;
         'case': token.tag := case_token;
         'do': token.tag := do_token;
         'else': token.tag := else_token;
         'end': token.tag := end_token;
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
         'type': token.tag := type_token;
         'use': token.tag := use_token;
         'while': token.tag := while_token;
      else
         token.tag := id_token;
      end;
   end;

begin
   skip_white;
   token.value := '';
   line := src.line;
   col := src.col;
   case src.ch of
      ',': recognize(comma_token);
      ';': recognize(semicolon_token);
      '.': recognize(dot_token);
      '(':
         begin
            push_char;
            if src.ch = '*' then skip_comment
            else token.tag := lparen_token;
         end;
      ')': recognize(rparen_token);
      '[': recognize(lbracket_token);
      ']': recognize(rbracket_token);
      '{': recognize(lbrace_token);
      '}': recognize(rbrace_token);
      '|': recognize(pipe_token);
      '+': recognize(plus_token);
      '-': recognize(minus_token);
      '*': recognize(mul_token);
      '/': recognize(div_token);
      '=': recognize(eq_token);
      '<':
         begin
            push_char;
            case src.ch of
               '>': recognize(neq_token);
               '=': recognize(leq_token);
            else
               token.tag:= lt_token;
            end;
         end;
      '>':
         begin
            push_char;
            if src.ch = '=' then recognize(geq_token)
            else token.tag := gt_token;
         end;
      ':':
         begin
            push_char;
            if src.ch = '=' then recognize(assign_token)
            else token.tag := colon_token;
         end;
      '0'..'9': get_number;
      '"': get_string;
      '#': get_char;
      'a'..'z', 'A'..'Z': get_id;
      #4:
         begin
            token.tag := eof_token;
            token.value := '<EOF>';
         end
   else
      err('Illegal token ''' + src.ch + '''', token_location());
   end;
end;

function token_location(): source_location;
var
   loc: source_location;
begin
   loc := source_location.create();
   loc.line := line;
   loc.col := col;
   loc.file_name := src.file_name;
   token_location := loc;
end;

end.
