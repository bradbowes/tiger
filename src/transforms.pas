unit transforms;

interface

uses nodes;

function transform(n: node): node;

implementation

uses pass1, pass2, pass3, bindings, semant;


function opt(n: node; tf: tf_function): node;
var
   ast: node;
begin
   ast := tf(n);
   delete_node(n);
   opt := ast;
   type_check(opt);
end;


function transform(n: node): node;

var
   ast: node;
begin
   ast := n;
   type_check(ast);
   ast := opt(ast, @trans1);
   ast := opt(ast, @trans1);
   ast := opt(ast, @trans2);
   ast := opt(ast, @trans3);
   transform := ast;
end;

end.

