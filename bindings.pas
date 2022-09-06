unit bindings;

interface
uses symbols, types;

type
   binding = ^binding_t;
   binding_t = record
      key: symbol;
      ty: spec;
      stack_index: longint;
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
      frame_id: longint;
      next: scope;
   end;

const
   _global_env: scope_t = (bindings: nil; stack_index: 0; frame_id: 0; next: nil);
   global_env: scope = @_global_env;
   _global_tenv: scope_t = (bindings: nil; stack_index: 0; frame_id: 0; next: nil);
   global_tenv: scope = @_global_tenv;

function add_scope(env: scope; frame_id: longint): scope;
procedure bind(env: scope; key: symbol; ty: spec; stack_index, line, col: longint);
function lookup(env: scope; key: symbol; line, col: longint): binding;

implementation

uses utils;


function add_scope(env: scope; frame_id: longint): scope;
var
   f: scope;
begin
   new(f);
   f^.bindings := nil;
   f^.next := env;
   f^.frame_id := frame_id;
   add_scope := f;
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


function make_binding(key: symbol; ty: spec; stack_index: longint): binding;
var
   b: binding;
begin
   new(b);
   b^.key := key;
   b^.ty := ty;
   b^.stack_index := stack_index;
   make_binding := b;
end;

function height(table: tree): Integer;
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


function balance(table: tree): Integer;
begin
   if table = nil then balance := 0
   else balance := height (table^.left) - height (table^.right);
end;


function rotate_left(table: tree): tree;
begin
   rotate_left := make_tree(table^.right^.binding,
                            make_tree(table^.binding,
                                      table^.left,
                                      table^.right^.left),
                            table^.right^.right);
   dispose(table);
end;


function rotate_right(table: tree): tree;
begin
   rotate_right := make_tree(table^.left^.binding,
                             table^.left^.left,
                             make_tree(table^.binding,
                                       table^.left^.right,
                                       table^.right));
   dispose(table);
end;


function find(table: tree; key: symbol): binding;
begin
   if table = nil then
      find := nil
   else if key < table^.binding^.key then
      find := find(table^.left, key)
   else if key > table^.binding^.key then
      find := find(table^.right, key)
   else
      find := table^.binding;
end;


function insert(table: tree; a_binding: binding) : tree;
var
   a_tree: tree = nil;
   bal: Integer;
begin
   if table = nil then
      a_tree := make_tree(a_binding, nil, nil)
   else if a_binding^.key < table^.binding^.key then
      a_tree := make_tree(table^.binding,
                          insert(table^.left, a_binding),
                          table^.right)
   else
      a_tree := make_tree(table^.binding,
                          table^.left,
                          insert(table^.right, a_binding));

   bal := balance(a_tree);
   while (bal < -1) or (bal > 1) do begin
      if bal > 1 then a_tree := rotate_right(a_tree)
      else if bal < -1 then a_tree := rotate_left(a_tree);
      bal := balance(a_tree);
   end;

   insert := a_tree;
end;

procedure bind(env: scope; key: symbol; ty: spec; stack_index, line, col: longint);
var
   a_tree: tree;
begin
   a_tree := env^.bindings;
   if find(a_tree, key) <> nil then
      err('identifier ''' + key^.id + ''' was previously defined in scope', line, col);
   env^.bindings := insert(a_tree, make_binding(key, ty, stack_index));
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


begin
   bind(global_tenv, intern('integer'), int_type, 0, 0, 0);
   bind(global_tenv, intern('string'), string_type, 0, 0, 0);
   bind(global_tenv, intern('boolean'), bool_type, 0, 0, 0);
end.
