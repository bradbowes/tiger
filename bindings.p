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

function bind(table: binding; key: symbol; ty: spec): binding;
function lookup(table: binding; key: symbol): spec;

implementation

function make_binding(
   key: symbol; ty: spec; left, right: binding): binding;
var
   b: binding;
begin
   new (b);
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

function bind(table: binding; key: symbol; ty: spec) : binding;
var
   Item : binding;
   Bal : Integer;
begin
   if table = nil then
      Item := make_binding(key, ty, nil, nil)
   else if key < table^.key then
      Item := make_binding(table^.key, table^.ty,
                          bind(table^.left, key, ty),
                          table^.right)
   else if key > table^.key then
      Item := make_binding(table^.key, table^.ty,
                          table^.left,
                          bind(table^.right, key, ty))
   else
      Item := make_binding(key, ty, table^.left, table^.right);

   Bal := balance(Item);
   while (Bal < -1) or (Bal > 1) do begin
      if Bal > 1 then Item := rotate_right(Item)
      else if Bal < -1 then Item := rotate_left(Item);
      Bal := balance(Item);
   end;
   bind := Item;
end;

function lookup(table: binding; key: symbol): spec;
begin
   if table = nil then
      lookup := nil
   else if key < table^.key then
      lookup := lookup(table^.left, key)
   else if key > table^.key then
      lookup := lookup (table^.right, key)
   else
      lookup := table^.ty;
end;

end.
