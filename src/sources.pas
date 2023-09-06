unit sources;

interface

type
   source_location = ^source_location_t;
   source_location_t = record
      line, col: longint;
      file_name: string;
   end;

   source = ^source_t;
   source_t = record
                  file_name: string;
                  open: boolean;
                  src: text;
                  ch: char;
                  line, col: longint;
                  resume: source;
               end;

var
   src: source = nil;


procedure load_source(file_name: string);
procedure getch();
procedure err(msg: string);
procedure err(msg, file_name: string; line, col: longint);
procedure err(msg: string; loc: source_location);
function src_location(): source_location;


implementation

uses sysutils;

procedure load_source(file_name: string);
var s: source;
begin
   new(s);
   s^.file_name := file_name;
   assign(s^.src, file_name);
   reset(s^.src);
   s^.open := true;
   read(s^.src, s^.ch);
   s^.col := 1;
   s^.line := 1;
   s^.resume := src;
   src := s;
end;


procedure getch();
begin
   if src^.open then
      if eof(src^.src) then
         begin
            src^.ch := chr(4);
            close(src^.src);
            src^.open := false;
         end
      else
         begin
            read(src^.src, src^.ch);
            src^.col := src^.col + 1;
            if src^.ch = chr(10) then
               begin
                  src^.line := src^.line + 1;
                  src^.col := 0;
               end
         end
      else
         err('Read past end of file', src^.file_name, src^.line, src^.col);
end;


function src_location(): source_location;
var
   loc: source_location;
begin
   new(loc);
   loc^.line := src^.line;
   loc^.col := src^.col;
   loc^.file_name := src^.file_name;
   src_location := loc;
end;


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
