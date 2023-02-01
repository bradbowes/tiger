unit errmsg;

interface

type
   source_location = ^source_location_t;
   source_location_t = record
      line, col: longint;
      file_name: string;
   end;


procedure err(msg: string);
procedure err(msg, file_name: string; line, col: longint);
procedure err(msg: string; loc: source_location);


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


procedure err(msg: string; loc: source_location);
begin
   err(msg, loc^.file_name, loc^.line, loc^.col);
end;


end.
