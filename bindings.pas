unit bindings;

interface
uses symbols, types;

type
   binding = ^binding_t;
   binding_t = record
      key: symbol;
      ty: spec;
      left, right: binding;
   end;

   frame = ^frame_t;
   frame_t = record
      bindings: binding;
      next: frame;
   end;

const
   _global_env: frame_t = (bindings: nil; next: nil);
   global_env: frame = @_global_env;
   _global_tenv: frame_t = (bindings: nil; next: nil);
   global_tenv: frame = @_global_tenv;

function add_frame(env: frame): frame;
procedure bind(env: frame; key: symbol; ty: spec; line, col: longint);
function lookup(env: frame; key: symbol; line, col: longint): spec;

implementation

uses utils;

function add_frame(env: frame): frame;
var
   f: frame;
begin
   new(f);
   f^.bindings := nil;
   f^.next := env;
   add_frame := f;   
end;

function make_binding(
   key: symbol; ty: spec; left, right: binding): binding;
var
   b: binding;
begin
   new(b);
   b^.key := key;
   b^.ty := ty;
   b^.left := left;
   b^.right := right;
   make_binding := b;
end;

function height(table: binding): Integer;
var
   l, r: integer;
begin
   l := 0; r := 0;
   if not (table = nil) then begin
      if not (table^.left = nil) then l := 1 + height(table^.left);
      if not (table^.right = nil) then r := 1 + height(table^.right);
   end;
   if l > r then height := l else height := r
end;

function balance(table: binding): Integer;
begin
   if table = nil then balance := 0
   else balance := height (table^.left) - height (table^.right);
end;

function rotate_left(table: binding): binding;
begin
   rotate_left := make_binding(table^.right^.key,
                               table^.right^.ty,
                               make_binding(table^.key,
                                            table^.ty,
                                            table^.left,
                                         table^.right^.left),
                               table^.right^.right);
   dispose(table);
end;

function rotate_right(table: binding): binding;
begin
   rotate_right := make_binding(table^.left^.key,
                                table^.left^.ty,
                                table^.left^.left,
                                make_binding(table^.key,
                                             table^.ty,
                                             table^.left^.right,
                                             table^.right));
   dispose(table);
end;

function find(table: binding; key: symbol): spec;
begin
   if table = nil then
      find := nil
   else if key < table^.key then
      find := find(table^.left, key)
   else if key > table^.key then
      find := find(table^.right, key)
   else
      find := table^.ty;
end;

function insert(table: binding; key: symbol; ty: spec): binding;
var
   item: binding;
   bal: Integer;
begin
   if table = nil then
      item := make_binding(key, ty, nil, nil)
   else if key < table^.key then
      item := make_binding(table^.key, table^.ty,
                           insert(table^.left, key, ty),
                           table^.right)
   else if key > table^.key then
      item := make_binding(table^.key, table^.ty,
                           table^.left,
                           insert(table^.right, key, ty));

   bal := balance(item);
   while (bal < -1) or (bal > 1) do begin
      if bal > 1 then item := rotate_right(item)
      else if bal < -1 then item := rotate_left(item);
      bal := balance(item);
   end;

   insert := item;
end;

procedure bind(env: frame; key: symbol; ty: spec; line, col: longint);
var table: binding;
begin
   table := env^.bindings;
   if find(table, key) <> nil then
      err(key^.id + ' already defined in scope', line, col);

   env^.bindings := insert(table, key, ty);
end;

function lookup(env: frame; key: symbol; line, col: longint): spec;
var
   table: binding;
   ty: spec;
begin
   table := env^.bindings;
   if table = nil then
      err('identifier ''' + key^.id + ''' is not bound', line, col)
   else
      begin
         ty := find(table, key);
         if ty = nil then
            lookup := lookup(env^.next, key, line, col)
         else
            lookup := ty;
      end;
end;

end.
