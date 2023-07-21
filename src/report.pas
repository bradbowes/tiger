program report;
uses
   nodes, bindings, semant, pass1, analysis, parser;
var
   ast: node;
begin
   ast := parse(paramstr(1));
   type_check(ast, 1, 1, add_scope(global_env), add_scope(global_tenv));
   ast := trans1(ast);
   type_check(ast, 1, 1, add_scope(global_env), add_scope(global_tenv));
   ast := trans1(ast);
   type_check(ast, 1, 1, add_scope(global_env), add_scope(global_tenv));
   analyze(ast);
end.
