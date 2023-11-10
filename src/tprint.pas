program tprint;
uses
   nodes, formats, parser, transforms;
var
   ast: node;
begin
   (* ast := transform(parse(paramstr(1))); *)
   ast := parse(paramstr(1));
   writeln(format(ast));
end.
