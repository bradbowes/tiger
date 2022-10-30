program print;
uses
   nodes, formats, parsers, bindings, transforms, semant, externals;

var
   ast: node;

begin
   load_externals();
   ast := parse(paramstr(1));
   type_check(ast, 1, 1, add_scope(global_env), add_scope(global_tenv));

   ast := transform(ast);
   writeln(format(ast)); 
end.
