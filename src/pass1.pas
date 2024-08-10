{$mode objfpc}
{$modeswitch nestedprocvars}

unit pass1;

interface

uses nodes;

function trans1(n: node): node;

implementation

uses sources, symbols, bindings, datatypes;

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

   function trans_unary_minus(): node;
   var
      e: node;
   begin
      e := trans1(left);
      if e^.tag = integer_node then
         trans_unary_minus := make_integer_node(-(e^.value^.int_val), loc)
      else
         trans_unary_minus := copy_node(n, tf);
   end;

   function trans_mul(): node;
   var
      e1, e2: node;
   begin
      e1 := trans1(left);
      e2 := trans1(right);
      if (e1^.tag = integer_node) and (e2^.tag = integer_node) then
         trans_mul := make_integer_node(e1^.value^.int_val * e2^.value^.int_val, loc)
      else
         trans_mul := copy_node(n, tf);
   end;

   function trans_div(): node;
   var
      e1, e2: node;
   begin
      e1 := trans1(left);
      e2 := trans1(right);
      if (e1^.tag = integer_node) and (e2^.tag = integer_node) then
         trans_div := make_integer_node(e1^.value^.int_val div e2^.value^.int_val, loc)
      else
         trans_div := copy_node(n, tf);
   end;

   function trans_mod(): node;
   var
      e1, e2: node;
   begin
      e1 := trans1(left);
      e2 := trans1(right);
      if (e1^.tag = integer_node) and (e2^.tag = integer_node) then
         trans_mod := make_integer_node(e1^.value^.int_val mod e2^.value^.int_val, loc)
      else
         trans_mod := copy_node(n, tf);
   end;

   function trans_plus(): node;
   var
      e1, e2: node;
   begin
      e1 := trans1(left);
      e2 := trans1(right);
      if (e1^.tag = integer_node) and (e2^.tag = integer_node) then
         trans_plus := make_integer_node(e1^.value^.int_val + e2^.value^.int_val, loc)
      else if (e1^.tag = char_node) and (e2^.tag = char_node) then
         trans_plus := make_char_node(e1^.value^.int_val + e2^.value^.int_val, loc)
      else
         trans_plus := copy_node(n, tf);
   end;

   function trans_minus(): node;
   var
      e1, e2: node;
   begin
      e1 := trans1(left);
      e2 := trans1(right);
      if (e1^.tag = integer_node) and (e2^.tag = integer_node) then
         trans_minus := make_integer_node(e1^.value^.int_val - e2^.value^.int_val, loc)
      else if (e1^.tag = char_node) and (e2^.tag = char_node) then
         trans_minus := make_char_node(e1^.value^.int_val - e2^.value^.int_val, loc)
      else
         trans_minus := copy_node(n, tf);
   end;

   function trans_lt(): node;
   var
      e1, e2: node;
   begin
      e1 := trans1(left);
      e2 := trans1(right);
      if ((e1^.tag = integer_node) and (e2^.tag = integer_node))
         or ((e1^.tag = char_node) and (e2^.tag = char_node)) then
         trans_lt := make_boolean_node(e1^.value^.int_val < e2^.value^.int_val, loc)
      else
         trans_lt := copy_node(n, tf);
   end;

   function trans_leq(): node;
   var
      e1, e2: node;
   begin
      e1 := trans1(left);
      e2 := trans1(right);
      if ((e1^.tag = integer_node) and (e2^.tag = integer_node))
         or ((e1^.tag = char_node) and (e2^.tag = char_node)) then
         trans_leq := make_boolean_node(e1^.value^.int_val <= e2^.value^.int_val, loc)
      else
         trans_leq := copy_node(n, tf);
   end;

   function trans_gt(): node;
   var
      e1, e2: node;
   begin
      e1 := trans1(left);
      e2 := trans1(right);
      if ((e1^.tag = integer_node) and (e2^.tag = integer_node))
         or ((e1^.tag = char_node) and (e2^.tag = char_node)) then
         trans_gt := make_boolean_node(e1^.value^.int_val > e2^.value^.int_val, loc)
      else
         trans_gt := copy_node(n, tf);
   end;

   function trans_geq(): node;
   var
      e1, e2: node;
   begin
      e1 := trans1(left);
      e2 := trans1(right);
      if ((e1^.tag = integer_node) and (e2^.tag = integer_node))
         or ((e1^.tag = char_node) and (e2^.tag = char_node)) then
         trans_geq := make_boolean_node(e1^.value^.int_val >= e2^.value^.int_val, loc)
      else
         trans_geq := copy_node(n, tf);
   end;

   function trans_eq(): node;
   var
      e1, e2: node;
   begin
      e1 := trans1(left);
      e2 := trans1(right);
      if ((e1^.tag = integer_node) and (e2^.tag = integer_node))
         or ((e1^.tag = char_node) and (e2^.tag = char_node)) then
         trans_eq := make_boolean_node(e1^.value^.int_val = e2^.value^.int_val, loc)
      else if (e1^.tag = boolean_node) and (e2^.tag = boolean_node) then
         trans_eq := make_boolean_node(e1^.value^.bool_val = e2^.value^.bool_val, loc)
      else
         trans_eq := copy_node(n, tf);
   end;

   function trans_neq(): node;
   var
      e1, e2: node;
   begin
      e1 := trans1(left);
      e2 := trans1(right);
      if ((e1^.tag = integer_node) and (e2^.tag = integer_node))
         or ((e1^.tag = char_node) and (e2^.tag = char_node)) then
         trans_neq := make_boolean_node(e1^.value^.int_val <> e2^.value^.int_val, loc)
      else if (e1^.tag = boolean_node) and (e2^.tag = boolean_node) then
         trans_neq := make_boolean_node(e1^.value^.bool_val <> e2^.value^.bool_val, loc)
      else
         trans_neq := copy_node(n, tf);
   end;

   function trans_and(): node;
   var
      e1, e2: node;
   begin
      e1 := trans1(left);
      e2 := trans1(right);
      if e1^.tag = boolean_node then
         if e1^.value^.bool_val then
            trans_and := e2
         else
            trans_and := e1
      else if (e2^.tag = boolean_node) then
         if  e2^.value^.bool_val then
            trans_and := e1
         else
            trans_and := e2
      else
         trans_and := make_if_else_node(e1, e2, make_boolean_node(false, loc), loc);
   end;

   function trans_or(): node;
   var
      e1, e2: node;
   begin
      e1 := trans1(left);
      e2 := trans1(right);
      if e1^.tag = boolean_node then
         if e1^.value^.bool_val then
            trans_or := e1
         else
            trans_or := e2
      else if (e2^.tag = boolean_node) then
         if  e2^.value^.bool_val then
            trans_or := e2
         else
            trans_or := e1
      else
         trans_or := make_if_else_node(e1, make_boolean_node(true, loc), e2, loc);
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
      list := node_list.create();
      list.append(trans1(right));
      e1 := make_simple_var_node(n^.name, loc);
      e2 := make_integer_node(1, loc);
      e1 := make_plus_node(e1, e2, loc);
      e2 := make_simple_var_node(n^.name, loc);
      e1 := make_assign_node(e2, e1, loc);
      list.append(e1);
      e2 := make_sequence_node(list, right^.loc);
      list := node_list.create();
      int_symbol := intern('int');
      list.append(make_var_decl_node(n^.name, int_symbol, trans1(left), left^.loc));
      fin := gensym();
      list.append(make_var_decl_node(fin, int_symbol, trans1(cond), cond^.loc));
      e1 := make_leq_node(make_simple_var_node(n^.name, loc),
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
      e: node;
      trans_binding: node_list.iter;

      procedure _trans_binding(n: node);
      begin
         if (n^.binding <> nil) and ((n^.binding^.mutates) or (n^.binding^.value = nil)) then
            list.append(trans1(n));
      end;

   begin
      trans_binding := @_trans_binding;
      list := node_list.create();
      n^.list.foreach(trans_binding);
      e := trans1(n^.right);
      if list.length > 0 then
         trans_let := make_let_node(list, e, loc)
      else
         trans_let := e;
   end;

   function trans_sequence(): node;
   begin
      case n^.list.length of
         0: trans_sequence := make_empty_node(loc);
         1: trans_sequence := trans1(n^.list.first.thing);
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
         c, action: node;
         loc: source_location;
      begin
         clause := it.thing;
         loc := clause^.loc;
         action := trans1(clause^.right);
         c := make_eq_node(make_simple_var_node(cmp,  loc), trans1(clause^.left), loc);
         if it.next <> nil then
            build_if := make_if_else_node(c, action, build_if(it.next), loc)
         else if n^.right <> nil then
            build_if := make_if_else_node(c, action, trans1(n^.right), loc)
         else
            build_if := make_if_node(c, action, loc);
      end;

   begin
      cmp := gensym();
      list := node_list.create();
      list.append(make_var_decl_node(cmp, nil, trans1(cond), loc));
      trans_case := make_let_node(list, build_if(n^.list.first), loc)
   end;

begin
   loc := n^.loc;
   cond := n^.cond;
   left := n^.left;
   right := n^.right;

   case n^.tag of
      simple_var_node:
         trans1 := trans_simple_var();
      unary_minus_node:
         trans1 := trans_unary_minus();
      plus_node:
         trans1 := trans_plus();
      minus_node:
         trans1 := trans_minus();
      mul_node:
         trans1 := trans_mul();
      div_node:
         trans1 := trans_div();
      mod_node:
         trans1 := trans_mod();
      eq_node:
         trans1 := trans_eq();
      neq_node:
         trans1 := trans_neq();
      lt_node:
         trans1 := trans_lt();
      leq_node:
         trans1 := trans_leq();
      gt_node:
         trans1 := trans_gt();
      geq_node:
         trans1 := trans_geq();
      and_node:
         trans1 := trans_and();
      or_node:
         trans1 := trans_or();
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
