(*
  TODO:
    need label, goto nodes to transform while loops
*)

{$mode objfpc}
{$modeswitch nestedprocvars}

unit pass3;
interface

uses nodes;

function trans3(n: node): node;

implementation

uses sources, symbols;

var
   tf: tf_function = @trans3;

function trans3(n: node): node;
var
   decls: node_list;
   loc: source_location;

   function compound(n: node): boolean;
   begin
      compound := not (n^.tag in [empty_node, simple_var_node, integer_node, char_node, string_node, boolean_node, nil_node]);
   end;

   function expand(n: node): node;
   begin
      if decls.length > 0 then
         expand := make_let_node(decls, n, loc)
      else
         expand := n;
   end;

   function reduce(n: node): node;
   var
      v: symbol;
      loc: source_location;
   begin
      if compound(n) then
         begin
            v := gensym();
            loc := n^.loc;
            decls.append(make_var_decl_node(v, nil, trans3(n), loc));
            reduce := make_simple_var_node(v, loc);
         end
      else
         reduce := trans3(n);
   end;

   function expand_binary(): node;
   var
      left, right: node;
   begin
      left := reduce(n^.left);
      right := reduce(n^.right);
      expand_binary := expand(make_binary_node(n^.tag, left, right, loc));
   end;

   function expand_unary_minus(): node;
   var
      left: node;
   begin
      left := reduce(n^.left);
      expand_unary_minus := expand(make_unary_minus_node(left, loc));
   end;

   function expand_call(): node;
   var
      args: node_list;
      add_arg: node_list.iter;

      procedure _add_arg(n: node);
      begin
         args.append(reduce(n));
      end;

   begin
      add_arg := @_add_arg;
      args := node_list.create();
      n^.list.foreach(add_arg);
      expand_call := expand(make_call_node(trans3(n^.left), args, loc));
   end;

   function expand_if_else(): node;
   var
      cond: node;
   begin
      cond := reduce(n^.cond);
      expand_if_else := expand(make_if_else_node(cond, trans3(n^.left), trans3(n^.right), loc));
   end;

   function expand_if(): node;
   var
      cond: node;
   begin
      cond := reduce(n^.cond);
      expand_if := expand(make_if_node(cond, trans3(n^.left), loc));
   end;

   function expand_assign(): node;
   var
      left, lleft, right: node;
   begin
      left := n^.left;
      if compound(left) then
         begin
            lleft := reduce(left^.left);
            case left^.tag of
               indexed_var_node:
                  left := make_indexed_var_node(lleft, reduce(left^.right), loc);
               field_var_node:
                  left := make_field_var_node(lleft, left^.name, loc);
            end;
         end
      else
         left := trans3(n^.left);
      right := reduce(n^.right);
      expand_assign := expand(make_assign_node(left, right, loc));
   end;

   function expand_field_var(): node;
   var
      left: node;
   begin
      left := reduce(n^.left);
      expand_field_var := expand(make_field_var_node(left, n^.name, loc));
   end;

   function expand_record(): node;
   var
      value: node;
      list: node_list;
      add_field: node_list.iter;

      procedure _add_field(n: node);
      begin
         value := reduce(n^.left);
         list.append(make_field_node(n^.name, value, n^.loc));
      end;

   begin
      add_field := @_add_field;
      list := node_list.create();
      n^.list.foreach(add_field);
      expand_record := expand(make_record_node(n^.type_name, list, loc));
   end;

begin
   loc := n^.loc;
   decls := node_list.create();

   case n^.tag of
      call_node, tail_call_node:
         trans3 := expand_call();
      if_else_node:
         trans3 := expand_if_else();
      if_node:
         trans3 := expand_if();
      assign_node:
         trans3 := expand_assign();
      unary_minus_node:
         trans3 := expand_unary_minus();
      plus_node, minus_node, mul_node, div_node, mod_node, eq_node, neq_node,
                 lt_node, leq_node, gt_node, geq_node, indexed_var_node:
         trans3 := expand_binary();
      field_var_node:
         trans3 := expand_field_var();
      record_node:
         trans3 := expand_record();
      else trans3 := copy_node(n, tf);
   end;
end;

end.
