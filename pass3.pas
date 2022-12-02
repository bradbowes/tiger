unit pass3;
interface

uses nodes;

function trans3(n: node): node;

implementation

uses sysutils, symbols;

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
   line, col: longint;

   function compound(n: node): boolean;
   begin
      compound := not (n^.tag in [empty_node, simple_var_node, integer_node, char_node, string_node, boolean_node, nil_node]);
   end;

   function expand(n: node): node;
   begin
      if decls^.length > 0 then
         expand := make_let_node(decls, n, line, col)
      else
         expand := n;
   end;

   function reduce(n: node): node;
   var
      v: symbol;
   begin
      if compound(n) then
         begin
            v := tmp();
            append(decls, make_var_decl_node(v, nil, trans3(n), n^.line, n^.col));
            reduce := make_simple_var_node(v, n^.line, n^.col);
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
      expand_binary_op := expand(make_binary_op_node(n^.op, left, right, line, col));
   end;

   function expand_call(): node;
   var
      args: node_list;
      it: node_list_item;
   begin
      args := make_list();
      it := n^.list^.first;
      while it <> nil do begin
         append(args, reduce(it^.node));
         it := it^.next;
      end;
      expand_call := expand(make_call_node(n^.name, args, line, col));
   end;

   function expand_if_else(): node;
   var
      cond: node;
   begin
      cond := reduce(n^.cond);
      expand_if_else := expand(make_if_else_node(cond, trans3(n^.left), trans3(n^.right), line, col));
   end;

begin
   line := n^.line;
   col := n^.col;
   decls := make_list();

   case n^.tag of
      call_node, tail_call_node: trans3 := expand_call();
      if_else_node: trans3 := expand_if_else();
      binary_op_node: trans3 := expand_binary_op();
      else
         trans3 := copy_node(n, tf);
   end;
end;

end.
