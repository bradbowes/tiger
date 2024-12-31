unit bindings;

interface
uses lists, maps, sources, symbols, values, datatypes;

type
(*   reachability = (reachable_unknown, reachable_yes, reachable_no); *)
   binding = ^binding_t;
   binding_list = specialize list<binding>;

   binding_t = record
      key: symbol;
      ty: spec;
      id: longint;
      external: boolean;
      stack_index: integer;
      nesting_level: integer;
      value: value;
      mutates: boolean;
      constant: boolean;
      escapes: boolean;
(*
      recursive: boolean;
      reachable: reachability;
      call_count: integer;
      free_vars: binding_list;
      callers: binding_list;
      callees: binding_list;
*)
   end;

   tree = specialize map<symbol, binding>;

   scope = ^scope_t;
   scope_t = record
      bindings: tree;
      stack_index: longint;
      next: scope;
   end;

var
   global_env: scope = nil;
   global_tenv: scope = nil;

function add_scope(env: scope): scope;
procedure delete_scope(var env: scope);
function bind(env: scope; key: symbol; ty: spec; stack_index, nesting_level: longint; loc: source_location): binding;
function lookup(env: scope; key: symbol; loc: source_location): binding;
(*
procedure add_free_var(fn, free_var: binding);
procedure add_caller(fn, caller: binding);
procedure add_callee(fn, callee: binding);
*)

implementation

uses math;

var
   next_id: longint = 1;

(*
procedure add_free_var(fn, free_var: binding);
var
   free_vars: binding_list;
begin
   free_vars := fn^.free_vars;
   if not (free_vars.contains(free_var)) then
      free_vars.append(free_var);
end;

procedure add_caller(fn, caller: binding);
var
   callers: binding_list;
begin
   callers := fn^.callers;
   if not (callers.contains(caller)) then
      callers.append(caller);
end;

procedure add_callee(fn, callee: binding);
var
   callees: binding_list;
begin
   callees := fn^.callees;
   if not (callees.contains(callee)) then
      callees.append(callee);
end;
*)

function add_scope(env: scope): scope;
var
   s: scope;
begin
   new(s);
   s^.bindings := tree.create();
   s^.stack_index := 0;
   s^.next := env;
   add_scope := s;
end;

function bind(env: scope; key: symbol; ty: spec; stack_index, nesting_level: longint; loc: source_location): binding;
var
   t: tree;
   b: binding;
begin
   t := env^.bindings;
   if t.lookup(key) <> nil then
      err('identifier ''' + key^.id + ''' was previously defined in scope', loc);
   new(b);
   b^.key := key;
   b^.ty := ty;
   b^.id := next_id;
   next_id := next_id + 1;
   b^.stack_index := stack_index;
   b^.nesting_level := nesting_level;
   b^.external := false;
   b^.mutates := false;
   b^.constant := false;
   b^.escapes := false;
(*
   b^.recursive := false;
   b^.reachable := reachable_unknown;
   b^.free_vars := binding_list.create();
   b^.callers := binding_list.create();
   b^.callees := binding_list.create();
 *)
   b^.value := nil;
   env^.bindings := tree.insert(t, key, b);
   bind := b;
end;

function lookup(env: scope; key: symbol; loc: source_location): binding;
var
   t: tree;
begin
   if env = nil then
      err('identifier ''' + key^.id + ''' is not defined', loc);
   t := env^.bindings.lookup(key);
   if t = nil then
      lookup := lookup(env^.next, key, loc)
   else
      lookup := t.item;
end;

procedure delete_scope(var env: scope);
begin
   if (env <> global_env) and (env <> global_tenv) then
      begin
         if (env^.bindings <> nil) then
            env^.bindings.destroy();
      end;
end;

begin
   global_env := add_scope(global_env);
   global_tenv := add_scope(global_tenv);
   bind(global_tenv, intern('int'), int_type, 0, 0, nil);
   bind(global_tenv, intern('string'), string_type, 0, 0, nil);
   bind(global_tenv, intern('bool'), bool_type, 0, 0, nil);
   bind(global_tenv, intern('char'), char_type, 0, 0, nil);
   bind(global_tenv, intern('file'), file_type, 0, 0, nil);
end.

