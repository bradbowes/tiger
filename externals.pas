unit externals;

interface

procedure load_externals();

implementation

uses bindings, symbols, nodes, semant;

procedure make_external(name: string; args: node_list; returns: string);
var n: node;
begin
   n := make_fun_decl_node(intern(name), args, intern(returns), nil, 0, 0);
   type_check(n, 1, 0, global_env, global_tenv);
end;

procedure load_externals();
begin
   make_external('read', make_list(), 'string');
end;

end.   
   
