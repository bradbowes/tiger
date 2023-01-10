unit bindings;

interface
uses math, symbols, values, datatypes;

type
   binding = ^binding_t;
   binding_t = record
      key: symbol;
      ty: spec;
      id: longint;
      external: boolean;
      stack_index: longint;
      nesting_level: longint;
      mutates: boolean;
      escapes: boolean;
      value: value;
   end;

   tree = ^tree_t;
   tree_t = record
      binding: binding;
      left, right: tree;
      height: integer;
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
procedure delete_scope(var env: scope);
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


function make_tree(binding: binding): tree;
var
   t: tree;
begin
   new(t);
   t^.binding := binding;
   t^.left := nil;
   t^.right := nil;
   t^.height := 1;
   make_tree := t;
end;


function height(t: tree): Integer;
begin
   if t = nil then height := 0
   else height := t^.height;
end;


function balance(t: tree): Integer;
begin
   if t = nil then balance := 0
   else balance := height(t^.left) - height(t^.right);
end;


function rotate_left(t: tree): tree;
var
   t1, tmp: tree;
begin
   t1 := t^.right;
   tmp := t1^.left;
   t1^.left := t;
   t^.right := tmp;
   t^.height := max(height(t^.left), height(t^.right)) + 1;
   t1^.height := max(height(t1^.left), height(t1^.right)) + 1;
   rotate_left := t1;
end;


function rotate_right(t: tree): tree;
var
   t1, tmp: tree;
begin
   t1 := t^.left;
   tmp := t1^.right;
   t1^.right := t;
   t^.left := tmp;
   t^.height := max(height(t^.left), height(t^.right)) + 1;
   t1^.height := max(height(t1^.left), height(t1^.right)) + 1;
   rotate_right := t1;
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
   bal: Integer;
begin
   if t = nil then
      t := make_tree(b)
   else if b^.key < t^.binding^.key then
      t^.left := insert(t^.left, b)
   else
      t^.right := insert(t^.right, b);

   bal := balance(t);

   if (bal > 1) and (b^.key < t^.left^.binding^.key) then
      t := rotate_right(t)
   else if (bal < -1) and (b^.key > t^.right^.binding^.key) then
      t := rotate_left(t)
   else if (bal > 1) and (b^.key >  T^.left^.binding^.key) then
      begin
         t^.left := rotate_left(t^.left);
         t := rotate_right(t);
      end
   else if (bal < -1) and (b^.key <  t^.right^.binding^.key) then
      begin
         t^.right := rotate_right(t^.right);
         t := rotate_left(t);
      end;

   insert := t;
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
   b^.mutates := false;
   b^.escapes := false;
   b^.value := nil;
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


procedure delete_tree(t: tree);
begin
   if t^.left <> nil then delete_tree(t^.left);
   if t^.right <> nil then delete_tree(t^.right);
   dispose(t^.binding);
   dispose(t);
end;


procedure delete_scope(var env: scope);
begin
   if (env <> global_env) and (env <> global_tenv) then
      begin
         if (env^.bindings <> nil) then
            delete_tree(env^.bindings);
         dispose(env);
         env := nil;
      end;
end;


begin
   bind(global_tenv, intern('int'), int_type, 0, 0, 0, 0);
   bind(global_tenv, intern('string'), string_type, 0, 0, 0, 0);
   bind(global_tenv, intern('bool'), bool_type, 0, 0, 0, 0);
   bind(global_tenv, intern('char'), char_type, 0, 0, 0, 0);
   bind(global_tenv, intern('file'), file_type, 0, 0, 0, 0);
end.
