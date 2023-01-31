unit errmsg;

interface

type
   location = ^location_t;
   location_t = record
      line, col: longint;
      file_name: string;
   end;


procedure err(msg: string);
procedure err(msg, file_name: string; line, col: longint);
procedure err(msg: string; loc: location);


implementation

uses sysutils;

procedure err(msg: string);
begin
   writeln(stderr, 'Error: ', msg);
   halt(1);
end;


procedure err(msg, file_name: string; line, col: longint);
begin
   err('in ' + file_name + ', line ' + inttostr(line) + ', column ' + inttostr(col) + ': ' + msg);
end;


procedure err(msg: string; loc: location);
begin
   err(msg, loc^.file_name, loc^.line, loc^.col);
end;


end.
