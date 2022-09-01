unit primitives;

interface

uses bindings;

procedure load_primitives(env, tenv: frame);

implementation

uses symbols, nodes, semant;

procedure load_primitives(env, tenv: frame);
var n: node;
begin
   n := make_fun_decl_node(intern('read'), make_list(), intern('string'), nil, 0, 0);
   type_check(n, 1, env, tenv);

end;

end.   
   
