unit transforms;

interface

uses nodes;

type tf_function = function(n: node): node;

function transform(n: node): node;

implementation

uses symbols, ops, bindings, types, semant, externals;

function trans1(n: node): node; forward;


function transform(n: node): node;
begin
   load_externals();
   type_check(n, 1, 1, add_scope(global_env), add_scope(global_tenv));
   n := trans1(n);
   type_check(n, 1, 1, add_scope(global_env), add_scope(global_tenv));
   n := trans1(n);
   type_check(n, 1, 1, add_scope(global_env), add_scope(global_tenv));
   transform := n;
end;

function trans1(n: node): node;
var
   tag: node_tag;
   line, col: longint;
   int_val: int64;
   string_val: symbol;
   bool_val: boolean;
   bind: binding;
   name, type_name: symbol;
   e1, e2, cond, left, right: node;
   op: op_tag;
   list: node_list;
   (* env: scope; *)

   function copy(): node;
   var
      n: node;
      ls: node_list;
      it: node_list_item;
   begin
      new(n);
      n^.tag := tag;
      n^.line := line;
      n^.col := col;
      n^.int_val := int_val;
      n^.string_val := string_val;
      n^.bool_val := bool_val;
      n^.name := name;
      n^.type_name := type_name;
      if cond <> nil then n^.cond := trans1(cond);
      if left <> nil then n^.left := trans1(left);
      if right <> nil then n^.right := trans1(right);
      n^.op := op;
      if list <> nil then begin
         ls := make_list();
         it := list^.first;
         while it <> nil do begin
            append(ls, trans1(it^.node));
            it := it^.next;
         end;
         n^.list := ls;
      end;
      copy := n;
   end;

begin
   tag := n^.tag;
   line := n^.line;
   col := n^.col;
   int_val := n^.int_val;
   string_val := n^.string_val;
   bool_val := n^.bool_val;
   bind := n^.binding;
   name := n^.name;
   type_name := n^.type_name;
   cond := n^.cond;
   left := n^.left;
   right := n^.right;
   op := n^.op;
   list := n^.list;
   (* env := n^.env; *)

   case tag of
      simple_var_node:
         if (not bind^.mutates) and (bind^.const_value) then
            if bind^.ty = int_type then
               trans1 := make_integer_node(bind^.int_val, line, col)
            else if bind^.ty = char_type then
               trans1 := make_char_node(bind^.int_val, line, col)
            else if bind^.ty = bool_type then
               trans1 := make_boolean_node(bind^.bool_val, line, col)
            else if bind^.ty = string_type then
               trans1 := make_string_node(bind^.string_val, line, col)
            else
               trans1 := copy()
         else
            trans1 := copy();
      unary_op_node: begin
         e1 := trans1(left);
         if e1^.tag = integer_node then
            trans1 := make_integer_node(-(e1^.int_val), line, col)
         else
            trans1 := copy();
      end;
      binary_op_node: begin
         e1 := trans1(left);
         e2 := trans1(right);
         if (e1^.tag = integer_node) and (e2^.tag = integer_node) then
            case op of
               plus_op:
                  trans1 := make_integer_node(e1^.int_val + e2^.int_val, line, col);
               minus_op:
                  trans1 := make_integer_node(e1^.int_val - e2^.int_val, line, col);
               mul_op:
                  trans1 := make_integer_node(e1^.int_val * e2^.int_val, line, col);
               div_op:
                  trans1 := make_integer_node(e1^.int_val div e2^.int_val, line, col);
               mod_op:
                  trans1 := make_integer_node(e1^.int_val mod e2^.int_val, line, col);
               lt_op:
                  trans1 := make_boolean_node(e1^.int_val < e2^.int_val, line, col);
               leq_op:
                  trans1 := make_boolean_node(e1^.int_val <= e2^.int_val, line, col);
               gt_op:
                  trans1 := make_boolean_node(e1^.int_val > e2^.int_val, line, col);
               geq_op:
                  trans1 := make_boolean_node(e1^.int_val >= e2^.int_val, line, col);
               eq_op:
                  trans1 := make_boolean_node(e1^.int_val = e2^.int_val, line, col);
               neq_op:
                  trans1 := make_boolean_node(e1^.int_val <> e2^.int_val, line, col);
               else
                  trans1 := copy();
            end
         else if (e1^.tag = char_node) and (e2^.tag = char_node) then
            case op of
               plus_op:
                  trans1 := make_char_node(e1^.int_val + e2^.int_val, line, col);
               minus_op:
                  trans1 := make_char_node(e1^.int_val - e2^.int_val, line, col);
               lt_op:
                  trans1 := make_boolean_node(e1^.int_val < e2^.int_val, line, col);
               leq_op:
                  trans1 := make_boolean_node(e1^.int_val <= e2^.int_val, line, col);
               gt_op:
                  trans1 := make_boolean_node(e1^.int_val > e2^.int_val, line, col);
               geq_op:
                  trans1 := make_boolean_node(e1^.int_val >= e2^.int_val, line, col);
               eq_op:
                  trans1 := make_boolean_node(e1^.int_val = e2^.int_val, line, col);
               neq_op:
                  trans1 := make_boolean_node(e1^.int_val <> e2^.int_val, line, col);
               else
                  trans1 := copy();
            end
         else if (e1^.tag = boolean_node) and (e2^.tag = boolean_node) then
            case op of
               eq_op:
                  trans1 := make_boolean_node(e1^.bool_val = e2^.bool_val, line, col);
               neq_op:
                  trans1 := make_boolean_node(e1^.bool_val <> e2^.bool_val, line, col);
               and_op:
                  trans1 :=  make_boolean_node(e1^.bool_val and e2^.bool_val, line, col);
               or_op:
                  trans1 := make_boolean_node(e1^.bool_val or e2^.bool_val, line, col);
               else
                  trans1 := copy();
            end
         else if (op = and_op) then
            if e1^.tag = boolean_node then
               if e1^.bool_val then
                  trans1 := e2
               else
                  trans1 := e1
            else if (e2^.tag = boolean_node) and e2^.bool_val then
               trans1 := e1
            else
               trans1 := copy()
         else if (op = or_op) then
            if e1^.tag = boolean_node then
               if e1^.bool_val then
                  trans1 := e1
               else
                  trans1 := e2
            else if (e2^.tag = boolean_node) and (not e2^.bool_val) then
               trans1 := e1
            else
               trans1 := copy()
         else
            trans1 := copy();
      end;
      if_node: begin
         e1 := trans1(cond);
         if e1^.tag = boolean_node then
            if e1^.bool_val then
               trans1 := trans1(left)
            else
               trans1 := make_empty_node(line, col)
         else
            trans1 := copy();
      end;
      if_else_node: begin
         e1 := trans1(cond);
         if e1^.tag = boolean_node then
            if e1^.bool_val then
               trans1 := trans1(left)
            else
               trans1 := trans1(right)
         else
            trans1 := copy();
      end;
      while_node: begin
         e1 := trans1(cond);
         if (e1^.tag = boolean_node) and (not e1^.bool_val) then
            trans1 := make_empty_node(line, col)
         else
            trans1 := copy();
      end;
      else
         trans1 := copy();
   end;
end;

end.

