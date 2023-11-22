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
   cond, left, right: node;

   function trans_simple_var(): node;
   var
      b: binding;
   begin
      b := n^.binding;
      if (not b^.mutates) and (b^.value <> nil) then
         if b^.ty = int_type then
            trans_simple_var := make_integer_node(b^.value^.int_val, loc)
         else if b^.ty = char_type then
            trans_simple_var := make_char_node(b^.value^.int_val, loc)
         else if b^.ty = bool_type then
            trans_simple_var := make_boolean_node(b^.value^.bool_val, loc)
         else if b^.ty = string_type then
            trans_simple_var := make_string_node(b^.value^.string_val, loc)
         else
            trans_simple_var := copy_node(n, tf)
      else
         trans_simple_var := copy_node(n, tf);
   end;

   function trans_unary_op(): node;
   var
      e: node;
   begin
      e := trans1(left);
      if e^.tag = integer_node then
         trans_unary_op := make_integer_node(-(e^.value^.int_val), loc)
      else
         trans_unary_op := copy_node(n, tf);
   end;

   function trans_binary_op(): node;
   var
      e1, e2: node;
      op: op_tag;
   begin
      e1 := trans1(left);
      e2 := trans1(right);
      op := n^.op;
      if (e1^.tag = integer_node) and (e2^.tag = integer_node) then
         case op of
            plus_op:
               trans_binary_op := make_integer_node(e1^.value^.int_val + e2^.value^.int_val, loc);
            minus_op:
               trans_binary_op := make_integer_node(e1^.value^.int_val - e2^.value^.int_val, loc);
            mul_op:
               trans_binary_op := make_integer_node(e1^.value^.int_val * e2^.value^.int_val, loc);
            div_op:
               trans_binary_op := make_integer_node(e1^.value^.int_val div e2^.value^.int_val, loc);
            mod_op:
               trans_binary_op := make_integer_node(e1^.value^.int_val mod e2^.value^.int_val, loc);
            lt_op:
               trans_binary_op := make_boolean_node(e1^.value^.int_val < e2^.value^.int_val, loc);
            leq_op:
               trans_binary_op := make_boolean_node(e1^.value^.int_val <= e2^.value^.int_val, loc);
            gt_op:
               trans_binary_op := make_boolean_node(e1^.value^.int_val > e2^.value^.int_val, loc);
            geq_op:
               trans_binary_op := make_boolean_node(e1^.value^.int_val >= e2^.value^.int_val, loc);
            eq_op:
               trans_binary_op := make_boolean_node(e1^.value^.int_val = e2^.value^.int_val, loc);
            neq_op:
               trans_binary_op := make_boolean_node(e1^.value^.int_val <> e2^.value^.int_val, loc);
            else
               trans_binary_op := copy_node(n, tf);
         end
      else if (e1^.tag = char_node) and (e2^.tag = char_node) then
         case op of
            plus_op:
               trans_binary_op := make_char_node(e1^.value^.int_val + e2^.value^.int_val, loc);
            minus_op:
               trans_binary_op := make_char_node(e1^.value^.int_val - e2^.value^.int_val, loc);
            lt_op:
               trans_binary_op := make_boolean_node(e1^.value^.int_val < e2^.value^.int_val, loc);
            leq_op:
               trans_binary_op := make_boolean_node(e1^.value^.int_val <= e2^.value^.int_val, loc);
            gt_op:
               trans_binary_op := make_boolean_node(e1^.value^.int_val > e2^.value^.int_val, loc);
            geq_op:
               trans_binary_op := make_boolean_node(e1^.value^.int_val >= e2^.value^.int_val, loc);
            eq_op:
               trans_binary_op := make_boolean_node(e1^.value^.int_val = e2^.value^.int_val, loc);
            neq_op:
               trans_binary_op := make_boolean_node(e1^.value^.int_val <> e2^.value^.int_val, loc);
            else
               trans_binary_op := copy_node(n, tf);
         end
      else if (e1^.tag = boolean_node) and (e2^.tag = boolean_node) then
         case op of
            eq_op:
               trans_binary_op := make_boolean_node(e1^.value^.bool_val = e2^.value^.bool_val, loc);
            neq_op:
               trans_binary_op := make_boolean_node(e1^.value^.bool_val <> e2^.value^.bool_val, loc);
            and_op:
               trans_binary_op :=  make_boolean_node(e1^.value^.bool_val and e2^.value^.bool_val, loc);
            or_op:
               trans_binary_op := make_boolean_node(e1^.value^.bool_val or e2^.value^.bool_val, loc);
            else
               trans_binary_op := copy_node(n, tf);
         end
      else if (op = and_op) then
         if e1^.tag = boolean_node then
            if e1^.value^.bool_val then
               trans_binary_op := e2
            else
               trans_binary_op := e1
         else if (e2^.tag = boolean_node) and e2^.value^.bool_val then
            trans_binary_op := e1
         else
            trans_binary_op := copy_node(n, tf)
      else if (op = or_op) then
         if e1^.tag = boolean_node then
            if e1^.value^.bool_val then
               trans_binary_op := e1
            else
               trans_binary_op := e2
         else if (e2^.tag = boolean_node) and (not e2^.value^.bool_val) then
            trans_binary_op := e1
         else
            trans_binary_op := copy_node(n, tf)
      else
         trans_binary_op := copy_node(n, tf);
   end;

   function trans_if(): node;
   var
      e: node;
   begin
      e := trans1(cond);
      if e^.tag = boolean_node then
         if e^.value^.bool_val then
            trans_if := trans1(left)
         else
            trans_if := make_empty_node(loc)
      else
         trans_if := copy_node(n, tf);
   end;

   function trans_if_else(): node;
   var
      e: node;
   begin
      e := trans1(cond);
      if e^.tag = boolean_node then
         if e^.value^.bool_val then
            trans_if_else := trans1(left)
         else
            trans_if_else := trans1(right)
      else
         trans_if_else := copy_node(n, tf);
   end;

   function trans_for(): node;
   var
      e1, e2: node;
      list: node_list;
      int_symbol, fin: symbol;
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
      trans_for := e1
   end;

   function trans_while(): node;
   var
      e: node;
   begin
      e := trans1(cond);
      if (e^.tag = boolean_node) and (not e^.value^.bool_val) then
         trans_while := make_empty_node(loc)
      else
         trans_while := copy_node(n, tf);
   end;

   function trans_let(): node;
   var
      list: node_list;
      it: node_list_item;
      e1, e2: node;
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
         trans_let := make_let_node(list, e2, loc)
      else
         trans_let := e2;
   end;

   function trans_sequence(): node;
   begin
      case n^.list^.length of
         0: trans_sequence := make_empty_node(loc);
         1: trans_sequence := trans1(n^.list^.first^.node);
         else trans_sequence := copy_node(n, tf);
      end;
   end;

   function trans_case(): node;
   var
      list: node_list;
      cmp: symbol;

      function build_if(it: node_list_item): node;
      var
         clause: node;
         c, result: node;
         loc: source_location;
      begin
         clause := it^.node;
         loc := clause^.loc;
         result := trans1(clause^.right);
         c := make_binary_op_node(eq_op, make_simple_var_node(cmp,  loc), trans1(clause^.left), loc);
         if it^.next <> nil then
            build_if := make_if_else_node(c, result, build_if(it^.next), loc)
         else if n^.right <> nil then
            build_if := make_if_else_node(c, result, trans1(n^.right), loc)
         else
            build_if := make_if_node(c, result, loc);
      end;

   begin
      cmp := gensym();
      list := make_node_list();
      append_node(list, make_var_decl_node(cmp, nil, trans1(cond), loc));
      trans_case := make_let_node(list, build_if(n^.list^.first), loc)
   end;

begin
   loc := n^.loc;
   cond := n^.cond;
   left := n^.left;
   right := n^.right;

   case n^.tag of
      simple_var_node:
         trans1 := trans_simple_var();
      unary_op_node:
         trans1 := trans_unary_op();
      binary_op_node:
         trans1 := trans_binary_op();
      if_node:
         trans1 := trans_if();
      if_else_node:
         trans1 := trans_if_else();
      for_node:
         trans1 := trans_for();
      while_node:
         trans1 := trans_while();
      let_node:
         trans1 := trans_let();
      sequence_node:
         trans1 := trans_sequence();
      case_node:
         trans1 := trans_case();
      else
         trans1 := copy_node(n, tf);
   end;
end;

end.
