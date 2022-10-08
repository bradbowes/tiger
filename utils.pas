unit utils;

interface

procedure err(msg : string; line, col : longint);
function atoi(s: string; line, col: longint): int64;

implementation

procedure err(msg : string; line, col : longint);
begin
   writeln('Error: ', msg, ', line: ', line, ', col: ', col);
   halt(1);
end;


function atoi(s: string; line, col: longint): int64;
var
   i: int64; c: word;
begin
   val(s, i, c);
   if c = 0 then
      atoi := i
   else begin
      atoi := 0;
      err('Bad integer format: ''' + s + '''', line, col);
   end;
end;

end.
