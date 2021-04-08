unit formats;

interface

uses ops, nodes;

function format(n: node): string;

implementation

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
         format := format(n^.variable) + ' := ' + format(n^.expression);
      call_node:
         format :=  n^.call^.id + '(' + format_list(n^.args, ', ', false) + ')';
      simple_var_node:
         format := n^.name^.id;
      field_var_node:
         format := format(n^.obj) + '.' + n^.field^.id;
      indexed_var_node:
         format := format(n^.arr) + '[' + format(n^.index) + ']';
      integer_node: begin
         str(n^.int_val, s);
         format := s;
      end;
      string_node:
         format := '"' + n^.string_val^.id + '"';
      boolean_node:
         if n^.bool_val then format := 'true' else format := 'false';
      nil_node:
         format := 'nil';
      type_decl_node:
         format := newline + 'type ' + n^.type_name^.id + ' = ' + format(n^.type_spec);
      var_decl_node: begin
         s := 'var ' + n^.var_name^.id; 
         if n^.var_type <> nil then
            s := s + ': ' + n^.var_type^.id;
         format := s + ' := ' + format( n^.initial_value);
      end;
      fun_decl_node: begin
         s := newline + 'function ' + n^.fun_name^.id + 
              '(' + format_list(n^.params, ', ', false) + ')';
         if n^.return_type <> nil then
            s := s + ': ' + n^.return_type^.id;
         s := s + ' = ';
         indent;
         s := s + newline + format(n^.fun_body);
         dedent;
         format := s;
      end;
      record_desc_node:
         format := '{' + format_list(n^.field_list, ',', true) + newline + '}';
      array_desc_node:
         format := 'array of ' + n^.base^.id;
      unary_op_node:
         format := op_display[n^.unary_op] + ' ' + format(n^.unary_exp);
      binary_op_node:
         format := format(n^.left) + ' ' + op_display[n^.binary_op] + ' ' + format(n^.right);
      field_node:
         format := n^.field_name^.id + ' = ' + format(n^.field_value);
      field_desc_node:
         format := n^.field_desc_name^.id + ': ' + n^.field_type^.id;
      if_else_node: begin
         s := 'if ' + format(n^.if_else_condition) + ' then';
         indent;
         s := s + newline + format(n^.if_else_consequent);
         dedent;
         s := s + newline + 'else';
         indent;
         s := s + newline + format(n^.if_else_alternative);
         dedent;
         format := s;
      end;
      if_node: begin
         s := 'if ' + format(n^.if_condition) + ' then';
         indent;
         s := s + newline + format(n^.if_consequent);
         dedent;
         format := s;
      end;      
      while_node: begin
         s := 'while ' + format(n^.while_condition) + ' do';
         indent;
         s := s + newline + format(n^.while_body);
         dedent;
         format := s;
      end;
      for_node: begin
         s := 'for ' + n^.iter^.id + ' := ' + format(n^.start) + ' to ' + format(n^.finish) + ' do';
         indent;
         s := s + newline + format(n^.for_body);
         dedent;
         format := s;
      end;
      let_node:
         format := 'let' + format_list(n^.decls, '', true) + newline + 'in ' + format(n^.let_body);
      sequence_node:
         format := '(' + format_list(n^.sequence, ';', true) + newline + ')';
      record_node:
         format := n^.record_type^.id + ' {' + format_list(n^.fields, ',', true) + newline + '}';
      array_node:
         format := n^.array_type^.id + '[' + format(n^.size) + '] of ' + format(n^.default_value);
      else begin
         str(n^.tag, s);
         format := '???? ' + s + ' ????';
      end; 
   end;
end;   
end.      


