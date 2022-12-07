unit pass2;
interface
uses nodes;

function trans2(n: node): node;

implementation

uses sysutils, symbols, bindings;

var
   tf: tf_function = @trans2;


function var_name(b: binding): symbol;
begin
   var_name := intern('v$_' + b^.key^.id + '_' + inttostr(b^.id));
end;


function fun_name(b: binding): symbol;
begin
   if b^.external then
      fun_name := b^.key
   else
      fun_name := intern('f$_' + b^.key^.id + '_' + inttostr(b^.id));
end;


function trans2(n: node): node;
var
   b: binding;
   line, col: longint;
   list: node_list;
   it: node_list_item;
   arg: node;
begin
   b := n^.binding;
   line := n^.line;
   col := n^.col;

   case n^.tag of
      call_node, tail_call_node:
         begin
            list := make_list();
            it := n^.list^.first;
            while it <> nil do begin
               append(list, trans2(it^.node));
               it := it^.next;
            end;
            trans2 := make_call_node(fun_name(b), list, line, col);
            trans2^.tag := n^.tag;
         end;
      simple_var_node:
         trans2 := make_simple_var_node(var_name(b), n^.line, n^.col);
      var_decl_node:
         trans2 := make_var_decl_node(var_name(b), n^.type_name, trans2(n^.right), line, col);
      fun_decl_node:
         begin
            list := make_list();
            it := n^.list^.first;
            while it <> nil do
               begin
                  arg := it^.node;
                  append(list, make_field_desc_node(var_name(lookup(n^.env, arg^.name, line, col)), arg^.type_name, line, col));
                  it := it^.next;
               end;
            trans2 := make_fun_decl_node(fun_name(b), list, n^.type_name, trans2(n^.right), line, col);
         end;
      for_node:
         trans2 := make_for_node(var_name(b), trans2(n^.left), trans2(n^.cond), trans2(n^.right), line, col);
      else
         trans2 := copy_node(n, tf);
   end;
end;

end.
