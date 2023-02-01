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


function opt(n: node; tf: tf_function): node;
var
   ast: node;
begin
   ast := tf(n);
   delete_node(n);
   opt := ast;
   check(opt);
end;


function transform(n: node): node;

var
   ast: node;
begin
   ast := n;
   check(ast);
   ast := opt(ast, @trans2);
   ast := opt(ast, @trans1);
   ast := opt(ast, @trans1);
   ast := opt(ast, @trans3);
   transform := ast;
end;

end.

