unit pass1;

interface

uses nodes;

function trans1(n: node): node;

implementation

uses ops, bindings, types;

var
   tf: tf_function = @trans1;


function trans1(n: node): node;
var
   line, col: longint;
   b: binding;
   e1, e2, cond, left, right: node;
   op: op_tag;
   list: node_list;
   it: node_list_item;

begin
   line := n^.line;
   col := n^.col;
   b := n^.binding;
   cond := n^.cond;
   left := n^.left;
   right := n^.right;
   op := n^.op;

   case n^.tag of
      simple_var_node:
         if (not b^.mutates) and (b^.const_value) then
            if b^.ty = int_type then
               trans1 := make_integer_node(b^.int_val, line, col)
            else if b^.ty = char_type then
               trans1 := make_char_node(b^.int_val, line, col)
            else if b^.ty = bool_type then
               trans1 := make_boolean_node(b^.bool_val, line, col)
            else if b^.ty = string_type then
               trans1 := make_string_node(b^.string_val, line, col)
            else
               trans1 := copy_node(n, tf)
         else
            trans1 := copy_node(n, tf);
      unary_op_node: begin
         e1 := trans1(left);
         if e1^.tag = integer_node then
            trans1 := make_integer_node(-(e1^.int_val), line, col)
         else
            trans1 := copy_node(n, tf);
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
                  trans1 := copy_node(n, tf);
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
                  trans1 := copy_node(n, tf);
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
                  trans1 := copy_node(n, tf);
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
               trans1 := copy_node(n, tf)
         else if (op = or_op) then
            if e1^.tag = boolean_node then
               if e1^.bool_val then
                  trans1 := e1
               else
                  trans1 := e2
            else if (e2^.tag = boolean_node) and (not e2^.bool_val) then
               trans1 := e1
            else
               trans1 := copy_node(n, tf)
         else
            trans1 := copy_node(n, tf);
      end;
      if_node: begin
         e1 := trans1(cond);
         if e1^.tag = boolean_node then
            if e1^.bool_val then
               trans1 := trans1(left)
            else
               trans1 := make_empty_node(line, col)
         else
            trans1 := copy_node(n, tf);
      end;
      if_else_node: begin
         e1 := trans1(cond);
         if e1^.tag = boolean_node then
            if e1^.bool_val then
               trans1 := trans1(left)
            else
               trans1 := trans1(right)
         else
            trans1 := copy_node(n, tf);
      end;
      while_node: begin
         e1 := trans1(cond);
         if (e1^.tag = boolean_node) and (not e1^.bool_val) then
            trans1 := make_empty_node(line, col)
         else
            trans1 := copy_node(n, tf);
      end;
      let_node: begin
         e2 := trans1(n^.right);
         list := make_list();
         it := n^.list^.first;
         while it <> nil do begin
            e1 := it^.node;
            if (e1^.binding <> nil) and ((e1^.binding^.mutates) or (not e1^.binding^.const_value)) then
            append(list, trans1(e1));
            it := it^.next;
         end;
         if list^.length > 0 then
            trans1 := make_let_node(list, e2, line, col)
         else
            trans1 := e2;
      end;
      sequence_node:
         case n^.list^.length of
            0: trans1 := make_empty_node(line, col);
            1: trans1 := trans1(n^.list^.first^.node);
            else trans1 := copy_node(n, tf);
         end;
      else
         trans1 := copy_node(n, tf);
   end;
end;

end.
