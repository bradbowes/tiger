unit transforms;

interface

uses nodes;

function transform(n: node): node;

implementation

uses pass1, pass2, pass3, bindings, semant;

procedure check(n: node);
begin
   type_check(n, 1, 1, add_scope(global_env), add_scope(global_tenv));
end;


function transform(n: node): node;

var
   ast1, ast2, ast3, ast4, ast5: node;

begin
   ast1 := n;
   check(ast1);
   ast2 := trans1(ast1);
   check(ast2);
   ast3:= trans1(ast2);
   check(ast3);
   delete_node(ast1);
   delete_node(ast2);
   ast4 := trans2(ast3);
   check(ast4);
   ast5 := trans3(ast4);
   check(ast5);
   transform := ast5;
end;

end.

