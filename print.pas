program print;
uses
   formats, parsers;

begin
   writeln(format(parse(paramStr(1))));
end.
