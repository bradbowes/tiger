unit pass2;

interface

uses nodes;

function trans2(n: node): node;


implementation

uses sysutils, errmsg, symbols, bindings;

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
   loc: source_location;
   list: node_list;
   it: node_list_item;
   arg: node;
begin
   b := n^.binding;
   loc := n^.loc;

   case n^.tag of
      call_node, tail_call_node:
         begin
            list := make_node_list();
            it := n^.list^.first;
            while it <> nil do begin
               append_node(list, trans2(it^.node));
               it := it^.next;
            end;
            trans2 := make_call_node(fun_name(b), list, loc);
            trans2^.tag := n^.tag;
         end;
      simple_var_node:
         trans2 := make_simple_var_node(var_name(b), loc);
      var_decl_node:
         trans2 := make_var_decl_node(var_name(b), n^.type_name, trans2(n^.right), loc);
      fun_decl_node:
         if n^.binding^.external then
            trans2 := copy_node(n, tf)
         else
            begin
               list := make_node_list();
               it := n^.list^.first;
               while it <> nil do
                  begin
                     arg := it^.node;
                     append_node(list, make_field_desc_node(var_name(lookup(n^.env, arg^.name, n^.loc)), arg^.type_name, loc));
                     it := it^.next;
                  end;
               trans2 := make_fun_decl_node(fun_name(b), list, n^.type_name, trans2(n^.right), loc);
            end;
      else
         trans2 := copy_node(n, tf);
   end;
end;

end.
