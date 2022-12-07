unit formats;

interface

uses nodes;

function format(n: node): string;

implementation

uses ops, sysutils;

var indent_level: integer;

function escape(s: string): string;
var
   out: string = '';
   i: longint;
begin
   for i := 1 to length(s) do
      case s[i] of
         #9: out := out + '\t';
         #10: out := out + '\n';
         #11: out := out + '\v';
         #12: out := out + '\f';
         #13: out := out + '\r';
         '\': out := out + '\\';
         '"': out := out + '\"';
         #0..#8, #14..#31, #127..#255: out := out + '\' + formatfloat('000', ord(s[i]));
         else out := out + s[i];
      end;
   escape := out;
end;

function newline: string;
begin
   newline := chr(10) + space(indent_level * 3);
end;

procedure indent;
begin
  indent_level := indent_level + 1;
end;

procedure dedent;
begin
  if indent_level > 0 then
     indent_level := indent_level - 1;
end;

function format_list(l: node_list; sep: string; break_lines: boolean): string;
var it: node_list_item;
    s: string;
begin
   indent;
   s := '';
   it := l^.first;
   while it <> nil do
      begin
         if break_lines then s := s + newline;
         s := s + format(it^.node);
         if it^.next <> nil then
            s := s + sep;
         it := it^.next;
      end;
   dedent;
   format_list := s;
end;

function format(n: node): string;
var s: string;
begin
   case n^.tag of
      assign_node:
         format := format(n^.left) + ' := ' + format(n^.right);
      call_node, tail_call_node:
         format :=  n^.name^.id + '(' + format_list(n^.list, ', ', false) + ')';
      simple_var_node:
         format := n^.name^.id;
      field_var_node:
         format := format(n^.left) + '.' + n^.name^.id;
      indexed_var_node:
         format := format(n^.left) + '[' + format(n^.right) + ']';
      integer_node:
         begin
            str(n^.int_val, s);
            format := s;
         end;
      string_node:
         format := '"' + escape(n^.string_val^.id) + '"';
      char_node:
         format := '#"' + escape(chr(n^.int_val)) + '"';
      boolean_node:
         if n^.bool_val then format := 'true' else format := 'false';
      nil_node:
         format := 'nil';
      type_decl_node:
         format := newline + 'type ' + n^.name^.id + ' = ' + format(n^.right);
      var_decl_node:
         begin
            s := n^.name^.id;
            if n^.type_name <> nil then
               s := s + ': ' + n^.type_name^.id;
            format := s + ' = ' + format( n^.right);
         end;
      fun_decl_node:
         begin
            s := n^.name^.id +
                 '(' + format_list(n^.list, ', ', false) + ')';
            if n^.type_name <> nil then
               s := s + ': ' + n^.type_name^.id;
            s := s + ' = ';
            indent;
            s := s + newline + format(n^.right);
            dedent;
            format := s + newline;
         end;
      record_desc_node:
         format := '{' + format_list(n^.list, ',', true) + newline + '}' + newline;
      array_desc_node:
         format := 'array of ' + n^.type_name^.id;
      unary_op_node:
         format := op_display[n^.op] + ' ' + format(n^.left);
      binary_op_node:
         format := '(' + format(n^.left) + ' ' + op_display[n^.op] + ' ' + format(n^.right) + ')';
      field_node:
         format := n^.name^.id + ' = ' + format(n^.left);
      field_desc_node:
         format := n^.name^.id + ': ' + n^.type_name^.id;
      if_else_node:
         begin
            s := 'if ' + format(n^.cond) + ' then';
            indent;
            s := s + newline + format(n^.left);
            dedent;
            s := s + newline + 'else';
            indent;
            s := s + newline + format(n^.right);
            dedent;
            format := s;
         end;
      if_node:
         begin
            s := 'if ' + format(n^.cond) + ' then';
            indent;
            s := s + newline + format(n^.left);
            dedent;
            format := s;
         end;
      while_node:
         begin
            s := 'while ' + format(n^.cond) + ' do';
            indent;
            s := s + newline + format(n^.left);
            dedent;
            format := s;
         end;
      for_node:
         begin
            s := 'for ' + n^.name^.id + ' := ' + format(n^.left) + ' to ' + format(n^.cond) + ' do';
            indent;
            s := s + newline + format(n^.right);
            dedent;
            format := s;
         end;
      let_node:
         begin
            s := 'let' + format_list(n^.list, '', true) + newline + 'in ';
            if n^.right^.tag = sequence_node then
               s := s + format_list(n^.right^.list, ';', true)
            else
               begin
                  indent;
                  s := s + newline + format(n^.right);
                  dedent;
               end;
            format := s + newline + 'end';
         end;
      sequence_node:
         begin
            s := 'begin';
            s := s + format_list(n^.list, ';', true) + newline;
            format := s + 'end';
         end;
      record_node:
         format := n^.type_name^.id + ' {' + format_list(n^.list, ',', true) + newline + '}';
      array_node:
         format := n^.type_name^.id + '[' + format(n^.left) + '] of ' + format(n^.right);
      empty_node:
         format := '';
      else
         begin
            str(n^.tag, s);
            format := '???? ' + s + ' ????';
         end;
   end;
end;
end.


