unit formats;

interface

uses nodes;

function format(n: node): string;

implementation

uses ops;

var indent_level: integer;

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
         format := format(n^.expr2) + ' := ' + format(n^.expr);
      call_node:
         format :=  n^.name^.id + '(' + format_list(n^.list, ', ', false) + ')';
      simple_var_node:
         format := n^.name^.id;
      field_var_node:
         format := format(n^.expr) + '.' + n^.name^.id;
      indexed_var_node:
         format := format(n^.expr2) + '[' + format(n^.expr) + ']';
      integer_node: begin
         str(n^.int_val, s);
         format := s;
      end;
      string_node:
         format := '"' + n^.string_val^.id + '"';
      char_node:
         format := '#"' + chr(n^.int_val) + '"';
      boolean_node:
         if n^.bool_val then format := 'true' else format := 'false';
      nil_node:
         format := 'nil';
      type_decl_node:
         format := newline + 'type ' + n^.name^.id + ' = ' + format(n^.expr);
      var_decl_node: begin
         s := n^.name^.id;
         if n^.type_name <> nil then
            s := s + ': ' + n^.type_name^.id;
         format := s + ' = ' + format( n^.expr);
      end;
      fun_decl_node: begin
         s := n^.name^.id +
              '(' + format_list(n^.list, ', ', false) + ')';
         if n^.type_name <> nil then
            s := s + ': ' + n^.type_name^.id;
         s := s + ' = ';
         indent;
         s := s + newline + format(n^.expr);
         dedent;
         format := s + newline;
      end;
      record_desc_node:
         format := '{' + format_list(n^.list, ',', true) + newline + '}' + newline;
      array_desc_node:
         format := 'array of ' + n^.type_name^.id;
      unary_op_node:
         format := op_display[n^.op] + ' ' + format(n^.expr);
      binary_op_node:
         format := '(' + format(n^.expr) + ' ' + op_display[n^.op] + ' ' + format(n^.expr2) + ')';
      field_node:
         format := n^.name^.id + ' = ' + format(n^.expr);
      field_desc_node:
         format := n^.name^.id + ': ' + n^.type_name^.id;
      if_else_node: begin
         s := 'if ' + format(n^.cond) + ' then';
         indent;
         s := s + newline + format(n^.expr);
         dedent;
         s := s + newline + 'else';
         indent;
         s := s + newline + format(n^.expr2);
         dedent;
         format := s;
      end;
      if_node: begin
         s := 'if ' + format(n^.cond) + ' then';
         indent;
         s := s + newline + format(n^.expr);
         dedent;
         format := s;
      end;
      while_node: begin
         s := 'while ' + format(n^.cond) + ' do';
         indent;
         s := s + newline + format(n^.expr);
         dedent;
         format := s;
      end;
      for_node: begin
         s := 'for ' + n^.name^.id + ' := ' + format(n^.expr2) + ' to ' + format(n^.cond) + ' do';
         indent;
         s := s + newline + format(n^.expr);
         dedent;
         format := s;
      end;
      let_node: begin
         s := 'let' + format_list(n^.list, '', true) + newline + 'in ';
         s := s + format_list(n^.expr^.list, ';', true);
         format := s + newline + 'end';
      end;
      sequence_node: begin
         s := 'begin';
         s := s + format_list(n^.list, ';', true) + newline;
         format := s + 'end';
      end;
      record_node:
         format := n^.type_name^.id + ' {' + format_list(n^.list, ',', true) + newline + '}';
      array_node:
         format := n^.type_name^.id + '[' + format(n^.expr2) + '] of ' + format(n^.expr);
      empty_node:
         format := '';
      else begin
         str(n^.tag, s);
         format := '???? ' + s + ' ????';
      end;
   end;
end;
end.


