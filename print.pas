program print;
uses
   nodes, formats, parsers, transforms;
var
   ast: node;
begin
   ast := parse(paramstr(1));
   ast := transform(ast);
   writeln(format(ast));
end.
