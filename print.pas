program print;
uses
   nodes, formats, parsers, transforms, externals;
var
   ast: node;
begin
   load_externals();
   ast := transform(parse(paramstr(1)));
   writeln(format(ast));
end.
