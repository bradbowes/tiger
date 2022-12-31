unit utils;

interface

procedure err(msg: string);
procedure err(msg: string; line, col: longint);
function atoi(s: string; line, col: longint): int64;

implementation

uses sysutils;

procedure err(msg: string);
begin
   writeln(stderr, 'Error: ', msg);
   halt(1);
end;


procedure err(msg: string; line, col: longint);
begin
   err('line ' + inttostr(line) + ', column ' + inttostr(col) + ': ' + msg);
end;


function atoi(s: string; line, col: longint): int64;
var
   i: int64; c: word;
begin
   val(s, i, c);
   if c = 0 then
      atoi := i
   else
      begin
         atoi := 0;
         err('Bad integer format: ''' + s + '''', line, col);
      end;
end;


end.
