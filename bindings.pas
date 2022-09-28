unit bindings;

interface
uses symbols, types;

type
   binding = ^binding_t;
   binding_t = record
      key: symbol;
      ty: spec;
      id: longint;
      external: boolean;
      stack_index: longint;
      nesting_level: longint;
   end;

   tree = ^tree_t;
   tree_t = record
      binding: binding;
      left, right: tree;
   end;

   scope = ^scope_t;
   scope_t = record
      bindings: tree;
      stack_index: longint;
      next: scope;
   end;

const
   _global_env: scope_t = (bindings: nil; stack_index: 0; next: nil);
   global_env: scope = @_global_env;
   _global_tenv: scope_t = (bindings: nil; stack_index: 0; next: nil);
   global_tenv: scope = @_global_tenv;


function add_scope(env: scope): scope;
function bind(env: scope; key: symbol; ty: spec; stack_index, nesting_level, line, col: longint): binding;
function lookup(env: scope; key: symbol; line, col: longint): binding;

implementation

uses utils;


var
   next_id: longint = 1;


function add_scope(env: scope): scope;
var
   s: scope;
begin
   new(s);
   s^.bindings := nil;
   s^.next := env;
   add_scope := s;
end;


function make_tree(binding: binding; left, right: tree): tree;
var
   t: tree;
begin
   new(t);
   t^.binding := binding;
   t^.left := left;
   t^.right := right;
   make_tree := t;
end;


function height(t: tree): Integer;
var
   l, r: integer;
begin
   l := 0; r := 0;
   if not (t = nil) then begin
      if not (t^.left = nil) then l := 1 + height(t^.left);
      if not (t^.right = nil) then r := 1 + height(t^.right);
   end;
   if l > r then height := l else height := r
end;


function balance(t: tree): Integer;
begin
   if t = nil then balance := 0
   else balance := height (t^.left) - height (t^.right);
end;


function rotate_left(t: tree): tree;
begin
   rotate_left := make_tree(t^.right^.binding,
                            make_tree(t^.binding,
                                      t^.left,
                                      t^.right^.left),
                            t^.right^.right);
   dispose(t);
end;


function rotate_right(t: tree): tree;
begin
   rotate_right := make_tree(t^.left^.binding,
                             t^.left^.left,
                             make_tree(t^.binding,
                                       t^.left^.right,
                                       t^.right));
   dispose(t);
end;


function find(t: tree; key: symbol): binding;
begin
   if t = nil then
      find := nil
   else if key < t^.binding^.key then
      find := find(t^.left, key)
   else if key > t^.binding^.key then
      find := find(t^.right, key)
   else
      find := t^.binding;
end;


function insert(t: tree; b: binding) : tree;
var
   new_t: tree = nil;
   bal: Integer;
begin
   if t = nil then
      new_t := make_tree(b, nil, nil)
   else if b^.key < t^.binding^.key then
      new_t := make_tree(t^.binding,
                         insert(t^.left, b),
                         t^.right)
   else
      new_t := make_tree(t^.binding,
                         t^.left,
                         insert(t^.right, b));

   bal := balance(new_t);
   while (bal < -1) or (bal > 1) do begin
      if bal > 1 then new_t := rotate_right(new_t)
      else if bal < -1 then new_t := rotate_left(new_t);
      bal := balance(new_t);
   end;

   insert := new_t;
end;


function bind(env: scope; key: symbol; ty: spec; stack_index, nesting_level, line, col: longint): binding;
var
   t: tree;
   b: binding;
begin
   t := env^.bindings;
   if find(t, key) <> nil then
      err('identifier ''' + key^.id + ''' was previously defined in scope', line, col);
   new(b);
   b^.key := key;
   b^.ty := ty;
   b^.id := next_id;
   next_id := next_id + 1;
   b^.stack_index := stack_index;
   b^.nesting_level := nesting_level;
   b^.external := false;
   env^.bindings := insert(t, b);
   bind := b;
end;


function lookup(env: scope; key: symbol; line, col: longint): binding;
var
   b: binding;
begin
   if env = nil then
      err('identifier ''' + key^.id + ''' is not defined', line, col);
   b := find(env^.bindings, key);
   if b = nil then
      lookup := lookup(env^.next, key, line, col)
   else
      lookup := b;
end;


end.
