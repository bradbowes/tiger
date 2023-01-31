(*
  TODO:
    need label, goto nodes to transform while, for loops
*)

unit pass3;
interface

uses nodes;

function trans3(n: node): node;

implementation

uses sysutils, utils, symbols;

var
   next_tmp: longint = 0;
   tf: tf_function = @trans3;

function tmp(): symbol;
begin
   next_tmp := next_tmp + 1;
   tmp := intern('tmp$_' + inttostr(next_tmp));
end;


function trans3(n: node): node;
var
   decls: node_list;
   loc: location;

   function compound(n: node): boolean;
   begin
      compound := not (n^.tag in [empty_node, simple_var_node, integer_node, char_node, string_node, boolean_node, nil_node]);
   end;

   function expand(n: node): node;
   begin
      if decls^.length > 0 then
         expand := make_let_node(decls, n, loc)
      else
         expand := n;
   end;

   function reduce(n: node): node;
   var
      v: symbol;
      loc: location;
   begin
      if compound(n) then
         begin
            v := tmp();
            loc := n^.loc;
            append_node(decls, make_var_decl_node(v, nil, trans3(n), loc));
            reduce := make_simple_var_node(v, loc);
         end
      else
         reduce := trans3(n);
   end;

   function expand_binary_op(): node;
   var
      left, right: node;
   begin
      left := reduce(n^.left);
      right := reduce(n^.right);
      expand_binary_op := expand(make_binary_op_node(n^.op, left, right, loc));
   end;

   function expand_unary_op(): node;
   var
      left: node;
   begin
      left := reduce(n^.left);
      expand_unary_op := expand(make_unary_op_node(n^.op, left, loc));
   end;

   function expand_call(): node;
   var
      args: node_list;
      it: node_list_item;
   begin
      args := make_node_list();
      it := n^.list^.first;
      while it <> nil do
         begin
            append_node(args, reduce(it^.node));
            it := it^.next;
         end;
      expand_call := expand(make_call_node(n^.name, args, loc));
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

   function expand_for(): node;
   var
      left, cond: node;
   begin
      left := reduce(n^.left);
      cond := reduce(n^.cond);
      expand_for := expand(make_for_node(n^.name, left, cond, trans3(n^.right), loc));
   end;

   function expand_indexed_var(): node;
   var
      left, right: node;
   begin
      left := reduce(n^.left);
      right := reduce(n^.right);
      expand_indexed_var := expand(make_indexed_var_node(left, right, loc));
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
      field, value: node;
      list: node_list;
      it: node_list_item;
   begin
      list := make_node_list();
      it := n^.list^.first;
      while it <> nil do
         begin
            field := it^.node;
            value := reduce(field^.left);
            append_node(list, make_field_node(field^.name, value, field^.loc));
            it := it^.next;
         end;
      expand_record := expand(make_record_node(n^.type_name, list, loc));
   end;

begin
   loc := n^.loc;
   decls := make_node_list();

   case n^.tag of
      call_node, tail_call_node: trans3 := expand_call();
      if_else_node: trans3 := expand_if_else();
      if_node: trans3 := expand_if();
      assign_node: trans3 := expand_assign();
      unary_op_node: trans3 := expand_unary_op();
      binary_op_node: trans3 := expand_binary_op();
      for_node: trans3 := expand_for();
      indexed_var_node: trans3 := expand_indexed_var();
      field_var_node: trans3 := expand_field_var();
      record_node: trans3 := expand_record();
      else trans3 := copy_node(n, tf);
   end;
end;

end.
