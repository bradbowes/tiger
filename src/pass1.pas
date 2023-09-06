unit pass1;

interface

uses nodes;

function trans1(n: node): node;

implementation

uses sources, ops, symbols, bindings, datatypes;

var
   tf: tf_function = @trans1;


function trans1(n: node): node;
var
   loc: source_location;
   b: binding;
   e1, e2, cond, left, right: node;
   op: op_tag;
   list: node_list;
   it: node_list_item;
   int_symbol, fin: symbol;

begin
   loc := n^.loc;
   b := n^.binding;
   cond := n^.cond;
   left := n^.left;
   right := n^.right;
   op := n^.op;


   case n^.tag of
      simple_var_node:
         if (not b^.mutates) and (b^.value <> nil) then
            if b^.ty = int_type then
               trans1 := make_integer_node(b^.value^.int_val, loc)
            else if b^.ty = char_type then
               trans1 := make_char_node(b^.value^.int_val, loc)
            else if b^.ty = bool_type then
               trans1 := make_boolean_node(b^.value^.bool_val, loc)
            else if b^.ty = string_type then
               trans1 := make_string_node(b^.value^.string_val, loc)
            else
               trans1 := copy_node(n, tf)
         else
            trans1 := copy_node(n, tf);
      unary_op_node:
         begin
            e1 := trans1(left);
            if e1^.tag = integer_node then
               trans1 := make_integer_node(-(e1^.value^.int_val), loc)
            else
               trans1 := copy_node(n, tf);
         end;
      binary_op_node:
         begin
            e1 := trans1(left);
            e2 := trans1(right);
            if (e1^.tag = integer_node) and (e2^.tag = integer_node) then
               case op of
                  plus_op:
                     trans1 := make_integer_node(e1^.value^.int_val + e2^.value^.int_val, loc);
                  minus_op:
                     trans1 := make_integer_node(e1^.value^.int_val - e2^.value^.int_val, loc);
                  mul_op:
                     trans1 := make_integer_node(e1^.value^.int_val * e2^.value^.int_val, loc);
                  div_op:
                     trans1 := make_integer_node(e1^.value^.int_val div e2^.value^.int_val, loc);
                  mod_op:
                     trans1 := make_integer_node(e1^.value^.int_val mod e2^.value^.int_val, loc);
                  lt_op:
                     trans1 := make_boolean_node(e1^.value^.int_val < e2^.value^.int_val, loc);
                  leq_op:
                     trans1 := make_boolean_node(e1^.value^.int_val <= e2^.value^.int_val, loc);
                  gt_op:
                     trans1 := make_boolean_node(e1^.value^.int_val > e2^.value^.int_val, loc);
                  geq_op:
                     trans1 := make_boolean_node(e1^.value^.int_val >= e2^.value^.int_val, loc);
                  eq_op:
                     trans1 := make_boolean_node(e1^.value^.int_val = e2^.value^.int_val, loc);
                  neq_op:
                     trans1 := make_boolean_node(e1^.value^.int_val <> e2^.value^.int_val, loc);
                  else
                     trans1 := copy_node(n, tf);
               end
            else if (e1^.tag = char_node) and (e2^.tag = char_node) then
               case op of
                  plus_op:
                     trans1 := make_char_node(e1^.value^.int_val + e2^.value^.int_val, loc);
                  minus_op:
                     trans1 := make_char_node(e1^.value^.int_val - e2^.value^.int_val, loc);
                  lt_op:
                     trans1 := make_boolean_node(e1^.value^.int_val < e2^.value^.int_val, loc);
                  leq_op:
                     trans1 := make_boolean_node(e1^.value^.int_val <= e2^.value^.int_val, loc);
                  gt_op:
                     trans1 := make_boolean_node(e1^.value^.int_val > e2^.value^.int_val, loc);
                  geq_op:
                     trans1 := make_boolean_node(e1^.value^.int_val >= e2^.value^.int_val, loc);
                  eq_op:
                     trans1 := make_boolean_node(e1^.value^.int_val = e2^.value^.int_val, loc);
                  neq_op:
                     trans1 := make_boolean_node(e1^.value^.int_val <> e2^.value^.int_val, loc);
                  else
                     trans1 := copy_node(n, tf);
               end
            else if (e1^.tag = boolean_node) and (e2^.tag = boolean_node) then
               case op of
                  eq_op:
                     trans1 := make_boolean_node(e1^.value^.bool_val = e2^.value^.bool_val, loc);
                  neq_op:
                     trans1 := make_boolean_node(e1^.value^.bool_val <> e2^.value^.bool_val, loc);
                  and_op:
                     trans1 :=  make_boolean_node(e1^.value^.bool_val and e2^.value^.bool_val, loc);
                  or_op:
                     trans1 := make_boolean_node(e1^.value^.bool_val or e2^.value^.bool_val, loc);
                  else
                     trans1 := copy_node(n, tf);
               end
            else if (op = and_op) then
               if e1^.tag = boolean_node then
                  if e1^.value^.bool_val then
                     trans1 := e2
                  else
                     trans1 := e1
               else if (e2^.tag = boolean_node) and e2^.value^.bool_val then
                  trans1 := e1
               else
                  trans1 := copy_node(n, tf)
            else if (op = or_op) then
               if e1^.tag = boolean_node then
                  if e1^.value^.bool_val then
                     trans1 := e1
                  else
                     trans1 := e2
               else if (e2^.tag = boolean_node) and (not e2^.value^.bool_val) then
                  trans1 := e1
               else
                  trans1 := copy_node(n, tf)
            else
               trans1 := copy_node(n, tf);
         end;
      if_node:
         begin
            e1 := trans1(cond);
            if e1^.tag = boolean_node then
               if e1^.value^.bool_val then
                  trans1 := trans1(left)
               else
                  trans1 := make_empty_node(loc)
            else
               trans1 := copy_node(n, tf);
         end;
      if_else_node:
         begin
            e1 := trans1(cond);
            if e1^.tag = boolean_node then
               if e1^.value^.bool_val then
                  trans1 := trans1(left)
               else
                  trans1 := trans1(right)
            else
               trans1 := copy_node(n, tf);
         end;
      for_node:
         begin
            list := make_node_list();
            append_node(list, trans1(right));
            e1 := make_simple_var_node(n^.name, loc);
            e2 := make_integer_node(1, loc);
            e1 := make_binary_op_node(plus_op, e1, e2, loc);
            e2 := make_simple_var_node(n^.name, loc);
            e1 := make_assign_node(e2, e1, loc);
            append_node(list, e1);
            e2 := make_sequence_node(list, right^.loc);
            list := make_node_list();
            int_symbol := intern('int');
            append_node(list, make_var_decl_node(n^.name, int_symbol, trans1(left), left^.loc));
            fin := gensym();
            append_node(list, make_var_decl_node(fin, int_symbol, trans1(cond), cond^.loc));
            e1 := make_binary_op_node(leq_op,
                                      make_simple_var_node(n^.name, loc),
                                      make_simple_var_node(fin, cond^.loc),
                                      cond^.loc);
            e2 := make_while_node(e1, e2, right^.loc);
            e1 := make_let_node(list, e2, loc);
            trans1 := e1
         end;
      while_node:
         begin
            e1 := trans1(cond);
            if (e1^.tag = boolean_node) and (not e1^.value^.bool_val) then
               trans1 := make_empty_node(loc)
            else
               trans1 := copy_node(n, tf);
         end;
      let_node:
         begin
            list := make_node_list();
            it := n^.list^.first;
            while it <> nil do
               begin
                  e1 := it^.node;
                  if (e1^.binding <> nil) and ((e1^.binding^.mutates) or (e1^.binding^.value = nil)) then
                     append_node(list, trans1(e1));
                  it := it^.next;
               end;
            e2 := trans1(n^.right);
            if list^.length > 0 then
               trans1 := make_let_node(list, e2, loc)
            else
               trans1 := e2;
         end;
      sequence_node:
         case n^.list^.length of
            0: trans1 := make_empty_node(loc);
            1: trans1 := trans1(n^.list^.first^.node);
            else trans1 := copy_node(n, tf);
         end;
      else
         trans1 := copy_node(n, tf);
   end;
end;

end.
