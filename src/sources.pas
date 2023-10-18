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
                  path: string;
                  open: boolean;
                  src: text;
                  ch: char;
                  line, col: longint;
                  resume: source;
               end;

var
   src: source = nil;


procedure load_source(file_name: string);
procedure clear_source();
procedure getch();
procedure err(msg: string);
procedure err(msg: string; loc: source_location);
function src_location(): source_location;


implementation

uses sysutils;

procedure load_source(file_name: string);
var
   s: source;
   path, fn: string;

begin
   new(s);
   fn := expandfilename(file_name);
   if fn <> file_name then
      begin
         if (src = nil) then
            path := extractfilepath('.')
         else
            path := src^.path;
         fn := expandfilename(path + file_name);
      end;
   s^.file_name := fn;
   s^.path := extractfilepath(fn);
   assign(s^.src, fn);
   reset(s^.src);
   s^.open := true;
   read(s^.src, s^.ch);
   s^.col := 1;
   s^.line := 1;
   if (src <> nil) and src^.open then
      s^.resume := src
   else
      s^.resume := nil;
   src := s;
end;

procedure clear_source();
begin
   src := nil;
end;

procedure getch();
begin
   if src^.open then
      if eof(src^.src) then
         begin
            src^.ch := chr(4);
            close(src^.src);
            src^.open := false;
            if src^.resume <> nil then
               begin
                  src := src^.resume;
                  getch();
               end
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
         err('Read past end of file', src_location());
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

procedure err(msg: string; loc: source_location);
begin
   err('in ' + loc^.file_name + ', line ' +  inttostr(loc^.line) + ', column ' +  inttostr(loc^.col) + ': ' + msg);
end;

end.
