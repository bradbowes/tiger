{$mode objfpc}
{$H+}
program tc;


uses utils, nodes, parser, sysutils, strutils, process, transforms, x86_emitter;

var
   ast: node;
   source, base, assem, obj, exe, output: string;


function source_name(s: string): string;
begin
   source_name := '';
   if (fileexists(s)) and ((endsstr('.tig', s)) or (endsstr('.tiger', s))) then
      source_name := s
   else if fileexists(s + '.tig') then
      source_name := s + '.tig'
   else if fileexists(s + '.tiger') then
      source_name := s + '.tiger'
   else if fileexists(s) then
      source_name := s
   else
      err('input file not found');
end;


function base_name(s: string): string;
begin
   if endsstr('.tig', s) then
      base_name := copy(s, 1, length(s) - 4)
   else if endsstr('.tiger', s) then
      base_name := copy(s, 1, length(s) - 6)
   else
      base_name := s;
end;


begin
   source := source_name(paramstr(1));
   ast := transform(parse(source));
   base := base_name(source);
   assem := base + '.s';
   emit_x86(ast, assem);
   obj := base + '.o';
   runcommand('as', ['-o', obj, assem], output);
   if base <> source then
      exe := base
   else
      exe := base + '.out';
   runcommand('ld', ['-o', exe, '-lSystem', obj, '/usr/local/share/tiger/lib/lib.o'], output);
end.
