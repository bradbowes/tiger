{$mode objfpc}

unit sources;

interface

type
   source_location = class
      line, col: longint;
      file_name: string;
   end;

   source = class
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

type
   source_list = class
       file_name: string;
       next: source_list;
   end;

var sl: source_list = nil;

procedure register_source(file_name: string);
var
   current, new_sl: source_list;
begin
   new_sl := source_list.create();
   new_sl.file_name := file_name;
   new_sl.next := nil;
   if sl = nil then
      sl := new_sl
   else
      begin
         current := sl;
         while current.next <> nil do
            current := current.next;
         current.next := new_sl;
      end;
end;

function source_registered(s: source_list; file_name: string): boolean;
begin
   if s = nil then
      source_registered := false
   else if s.file_name = file_name then
      source_registered := true
   else
      source_registered := source_registered(s.next, file_name);
end;

procedure load_source(file_name: string);
var
   s: source;
   path, fn: string;

begin
   fn := expandfilename(file_name);
   if fn <> file_name then
      begin
         if (src = nil) then
            path := extractfilepath('.')
         else
            path := src.path;
         fn := expandfilename(path + file_name);
      end;
   if source_registered(sl, fn) then exit;
   s := source.create();
   s.file_name := fn;
   s.path := extractfilepath(fn);
   assign(s.src, fn);
   reset(s.src);
   s.open := true;
   read(s.src, s.ch);
   s.col := 1;
   s.line := 1;
   if (src <> nil) and src.open then
      s.resume := src
   else
      s.resume := nil;
   src := s;
   register_source(fn);
end;

procedure clear_src(var s: source);
begin
   if (s <> nil) then
      begin
         if (s.resume <> nil) then
            clear_src(s.resume);
         s.destroy();
         s := nil;
      end;
end;

procedure clear_source();
begin
   clear_src(src);
end;

procedure getch();
var
   s: source;
begin
   if src.open then
      if eof(src.src) then
         begin
            src.ch := chr(4);
            close(src.src);
            src.open := false;
            if src.resume <> nil then
               begin
                  s := src;
                  src := src.resume;
                  s.destroy();
                  getch();
               end
         end
      else
         begin
            read(src.src, src.ch);
            src.col := src.col + 1;
            if src.ch = chr(10) then
               begin
                  src.line := src.line + 1;
                  src.col := 0;
               end
         end
   else
      err('Read past end of file', src_location());
end;

function src_location(): source_location;
var
   loc: source_location;
begin
   loc := source_location.create();
   loc.line := src.line;
   loc.col := src.col;
   loc.file_name := src.file_name;
   src_location := loc;
end;

procedure err(msg: string);
begin
   writeln(stderr, 'Error: ', msg);
   halt(1);
end;

procedure err(msg: string; loc: source_location);
begin
   err('in ' + loc.file_name + ', line ' +  inttostr(loc.line) + ', column ' +  inttostr(loc.col) + ': ' + msg);
end;

end.
