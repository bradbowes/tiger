program report;
uses
   nodes, bindings, semant, pass1, analysis, parser;
var
   ast: node;
begin
   ast := parse(paramstr(1));
   type_check(ast);
   ast := trans1(ast);
   type_check(ast);
   ast := trans1(ast);
   type_check(ast);
   analyze(ast);
end.
