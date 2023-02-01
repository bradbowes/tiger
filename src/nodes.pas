unit nodes;

interface

uses errmsg, symbols, ops, values, bindings;

type
   node_tag = (assign_node,
               call_node,
               tail_call_node,
               simple_var_node,
               field_var_node,
               indexed_var_node,
               integer_node,
               string_node,
               char_node,
               boolean_node,
               nil_node,
               empty_node,
               type_decl_node,
               var_decl_node,
               fun_decl_node,
               record_desc_node,
               array_desc_node,
               unary_op_node,
               binary_op_node,
               field_node,
               field_desc_node,
               if_else_node,
               if_node,
               while_node,
               for_node,
               let_node,
               sequence_node,
               record_node,
               array_node);


   node = ^node_t;
   node_list_item = ^node_list_item_t;
   node_list = ^node_list_t;


   node_list_item_t = record
      node: node;
      next: node_list_item
   end;


   node_list_t = record
      first: node_list_item;
      last:  node_list_item;
      length: longint;
   end;


   node_t = record
      tag: node_tag;
      loc: source_location;
      value: value;
      binding: binding;
      name, type_name: symbol;
      cond, left, right: node;
      op: op_tag;
      list: node_list;
      env: scope;
      tenv: scope;
   end;

   tf_function = function(n: node): node;


function make_node_list(): node_list;
procedure append_node(list: node_list; n: node);
function make_assign_node(variable, expr: node; loc: source_location): node;
function make_call_node(name: symbol; args: node_list; loc: source_location): node;
function make_simple_var_node(name: symbol; loc: source_location): node;
function make_field_var_node(obj: node; field: symbol; loc: source_location): node;
function make_indexed_var_node(arr, index: node; loc: source_location): node;
function make_integer_node(val: int64; loc: source_location): node;
function make_string_node(val: symbol; loc: source_location): node;
function make_char_node(val: int64; loc: source_location): node;
function make_boolean_node(val: boolean; loc: source_location): node;
function make_nil_node(loc: source_location): node;
function make_empty_node(loc: source_location): node;
function make_type_decl_node(name: symbol; spec: node; loc: source_location): node;
function make_var_decl_node(name, ty: symbol; expr: node; loc: source_location): node;
function make_fun_decl_node(name: symbol; params: node_list; return_type: symbol; body: node; loc: source_location): node;
function make_record_desc_node(fields: node_list; loc: source_location): node;
function make_array_desc_node(base: symbol; loc: source_location): node;
function make_unary_op_node(op: op_tag; exp: node; loc: source_location): node;
function make_binary_op_node(op: op_tag; left, right: node; loc: source_location): node;
function make_field_node(name: symbol; expr: node; loc: source_location): node;
function make_field_desc_node(name, ty: symbol; loc: source_location): node;
function make_if_else_node(condition, consequent, alternative: node; loc: source_location): node;
function make_if_node(condition, consequent: node; loc: source_location): node;
function make_while_node(condition, body: node; loc: source_location): node;
function make_for_node(iter: symbol; start, finish, body: node; loc: source_location): node;
function make_let_node(decls: node_list; body: node; loc: source_location): node;
function make_sequence_node(sequence: node_list; loc: source_location): node;
function make_record_node(ty: symbol; fields: node_list; loc: source_location): node;
function make_array_node(ty: symbol; size, value: node; loc: source_location): node;
procedure delete_node(var n: node);
function copy_node(n: node; tf: tf_function): node;


implementation


function make_node_list(): node_list;
var
   list: node_list;
begin
   new(list);
   list^.first := nil;
   list^.last := nil;
   list^.length := 0;
   make_node_list := list;
end;


function make_list_item(n: node): node_list_item;
var
   item: node_list_item;
begin
   new(item);
   item^.node := n;
   item^.next := nil;
   make_list_item := item;
end;


procedure append_node(list: node_list; n: node);
var
   item: node_list_item;
begin
   item := make_list_item(n);
   if list^.first = nil then
      list^.first := item
   else
      list^.last^.next := item;
  list^.last := item;
  list^.length := list^.length + 1;
end;


function make_node(tag: node_tag; loc: source_location): node;
var
   n: node;
begin
   new(n);
   n^.tag := tag;
   n^.loc := loc;
   n^.value := nil;
   n^.binding := nil;
   n^.name := nil;
   n^.type_name := nil;
   n^.cond := nil;
   n^.left := nil;
   n^.right := nil;
   n^.op := nul_op;
   n^.list := nil;
   n^.env := nil;
   n^.tenv := nil;
   make_node := n;
end;


function make_assign_node(variable, expr: node; loc: source_location): node;
var n: node;
begin
   n := make_node(assign_node, loc);
   n^.left := variable;
   n^.right := expr;
   make_assign_node := n;
end;


function make_call_node(name: symbol; args: node_list; loc: source_location): node;
var n: node;
begin
   n := make_node(call_node, loc);
   n^.name := name;
   n^.list := args;
   make_call_node := n;
end;


function make_simple_var_node(name: symbol; loc: source_location): node;
var n: node;
begin
   n := make_node(simple_var_node, loc);
   n^.name := name;
   make_simple_var_node := n;
end;


function make_field_var_node(obj: node; field: symbol; loc: source_location): node;
var n: node;
begin
   n := make_node(field_var_node, loc);
   n^.left := obj;
   n^.name := field;
   make_field_var_node := n;
end;


function make_indexed_var_node(arr, index: node; loc: source_location): node;
var n: node;
begin
   n := make_node(indexed_var_node, loc);
   n^.left := arr;
   n^.right := index;
   make_indexed_var_node := n;
end;


function make_integer_node(val: int64; loc: source_location): node;
var
   n: node;
begin
   n := make_node(integer_node, loc);
   n^.value := make_integer_value(val);
   make_integer_node := n;
end;


function make_string_node(val: symbol; loc: source_location): node;
var n: node;
begin
   n := make_node(string_node, loc);
   n^.value := make_string_value(val);
   make_string_node := n;
end;


function make_char_node(val: int64; loc: source_location): node;
var n: node;
begin
   n := make_node(char_node, loc);
   n^.value := make_integer_value(val);
   make_char_node := n;
end;


function make_boolean_node(val: boolean; loc: source_location): node;
var n: node;
begin
   n := make_node(boolean_node, loc);
   n^.value := make_boolean_value(val);
   make_boolean_node := n;
end;


function make_nil_node(loc: source_location): node;
begin
   make_nil_node := make_node(nil_node, loc);
end;


function make_empty_node(loc: source_location): node;
begin
   make_empty_node := make_node(empty_node, loc);
end;


function make_type_decl_node(name: symbol; spec: node; loc: source_location): node;
var n: node;
begin
   n := make_node(type_decl_node, loc);
   n^.name := name;
   n^.right := spec;
   make_type_decl_node := n;
end;


function make_var_decl_node(name, ty: symbol; expr: node; loc: source_location): node;
var n: node;
begin
   n := make_node(var_decl_node, loc);
   n^.name := name;
   n^.type_name := ty;
   n^.right := expr;
   make_var_decl_node := n;
end;


function make_fun_decl_node(name: symbol; params: node_list; return_type: symbol; body: node; loc: source_location): node;
var n: node;
begin
   n := make_node(fun_decl_node, loc);
   n^.name := name;
   n^.list := params;
   n^.type_name := return_type;
   n^.right := body;
   make_fun_decl_node := n;
end;


function make_record_desc_node(fields: node_list; loc: source_location): node;
var n: node;
begin
   n := make_node(record_desc_node, loc);
   n^.list := fields;
   make_record_desc_node := n;
end;


function make_array_desc_node(base: symbol; loc: source_location): node;
var n: node;
begin
   n := make_node(array_desc_node, loc);
   n^.type_name := base;
   make_array_desc_node := n;
end;


function make_unary_op_node(op: op_tag; exp: node; loc: source_location): node;
var n: node;
begin
   n := make_node(unary_op_node, loc);
   n^.op := op;
   n^.left := exp;
   make_unary_op_node := n;
end;


function make_binary_op_node(op: op_tag; left, right: node; loc: source_location): node;
var n: node;
begin
  n := make_node(binary_op_node, loc);
  n^.op := op;
  n^.left := left;
  n^.right := right;
  make_binary_op_node := n;
end;


function make_field_node(name: symbol; expr: node; loc: source_location): node;
var n: node;
begin
   n :=  make_node(field_node, loc);
   n^.left := expr;
   n^.name := name;
   make_field_node := n;
end;


function make_field_desc_node(name, ty: symbol; loc: source_location): node;
var n: node;
begin
   n := make_node(field_desc_node, loc);
   n^.name := name;
   n^.type_name := ty;
   make_field_desc_node := n;
end;


function make_if_else_node(condition, consequent, alternative: node; loc: source_location): node;
var n: node;
begin
   n := make_node(if_else_node, loc);
   n^.cond := condition;
   n^.left := consequent;
   n^.right := alternative;
   make_if_else_node := n
end;


function make_if_node(condition, consequent: node; loc: source_location): node;
var n: node;
begin
   n := make_node(if_node, loc);
   n^.cond := condition;
   n^.left := consequent;
   make_if_node := n;
end;


function make_while_node(condition, body: node; loc: source_location): node;
var n: node;
begin
   n := make_node(while_node, loc);
   n^.cond := condition;
   n^.left := body;
   make_while_node := n;
end;


function make_for_node(iter: symbol; start, finish, body: node; loc: source_location): node;
var n: node;
begin
   n := make_node(for_node, loc);
   n^.name := iter;
   n^.left := start;
   n^.cond := finish;
   n^.right := body;
   make_for_node := n;
end;


function make_let_node(decls: node_list; body: node; loc: source_location): node;
var n: node;
begin
   n := make_node(let_node, loc);
   n^.list := decls;
   n^.right := body;
   make_let_node := n;
end;


function make_sequence_node(sequence: node_list; loc: source_location): node;
var n: node;
begin
   n := make_node(sequence_node, loc);
   n^.list := sequence;
   make_sequence_node := n;
end;


function make_record_node(ty: symbol; fields: node_list; loc: source_location): node;
var n: node;
begin
   n := make_node(record_node, loc);
   n^.type_name := ty;
   n^.list := fields;
   make_record_node := n;
end;


function make_array_node(ty: symbol; size, value: node; loc: source_location): node;
var n: node;
begin
   n := make_node(array_node, loc);
   n^.type_name := ty;
   n^.left := size;
   n^.right := value;
   make_array_node := n;
end;


procedure delete_node(var n: node);
var
   it, tmp: node_list_item;
begin
   if n^.cond <> nil then delete_node(n^.cond);
   if n^.left <> nil then delete_node(n^.left);
   if n^.right <> nil then delete_node(n^.right);
   if n^.list <> nil then
      begin
         it := n^.list^.first;
         while it <> nil do
            begin
               tmp := it^.next;
               if it^.node <> nil then delete_node(it^.node);
               dispose(it);
               it := tmp;
            end;
         dispose(n^.list);
      end;
   if n^.tenv <> nil then delete_scope(n^.tenv);
   if n^.env <> nil then delete_scope(n^.env);
   dispose(n);
   n := nil;
end;


function copy_node(n: node; tf: tf_function): node;

   function cp(n: node): node;
   begin
      if (n = nil) or (n^.tag = empty_node) then
         cp := nil
      else
         cp := tf(n);
   end;

var
   new_node, tmp: node;
   ls: node_list;
   it: node_list_item;
begin
   new_node := make_node(n^.tag, n^.loc);
   new_node^.value := n^.value;
   new_node^.name := n^.name;
   new_node^.type_name := n^.type_name;
   new_node^.op := n^.op;
   if n^.list <> nil then
      begin
         ls := make_node_list();
         it := n^.list^.first;
         while it <> nil do
            begin
               tmp := cp(it^.node);
               if tmp <> nil then
                  append_node(ls, tmp);
               it := it^.next;
            end;
         new_node^.list := ls
      end;
   new_node^.cond := cp(n^.cond);
   new_node^.left := cp(n^.left);
   new_node^.right := cp(n^.right);
   copy_node := new_node;
end;


end.
