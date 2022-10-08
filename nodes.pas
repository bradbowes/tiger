unit nodes;

interface

uses symbols, ops, bindings;

type
   node_tag = (assign_node,
               call_node,
               simple_var_node,
               field_var_node,
               indexed_var_node,
               integer_node,
               string_node,
               boolean_node,
               nil_node,
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
      line, col: longint;
      int_val: int64;
      string_val: symbol;
      bool_val: boolean;
      binding: binding;
      name, type_name: symbol;
      cond, expr, expr2: node;
      op: op_tag;
      list: node_list;
      env: scope;
   end;


function make_list(): node_list;
procedure append(list: node_list; n: node);
function make_assign_node(variable, expr: node; line, col: longint): node;
function make_call_node(name: symbol; args: node_list; line, col: longint): node;
function make_simple_var_node(name: symbol; line, col: longint): node;
function make_field_var_node(obj: node; field: symbol; line, col: longint): node;
function make_indexed_var_node(arr, index: node; line, col: longint): node;
function make_integer_node(val: int64; line, col: longint): node;
function make_string_node(val: symbol; line, col: longint): node;
function make_boolean_node(val: boolean; line, col: longint): node;
function make_nil_node(line, col: longint): node;
function make_type_decl_node(name: symbol; spec: node; line, col: longint): node;
function make_var_decl_node(name, ty: symbol; expr: node; line, col: longint): node;
function make_fun_decl_node(name: symbol; params: node_list; return_type: symbol; body: node; line, col: longint): node;
function make_record_desc_node(fields: node_list; line, col: longint): node;
function make_array_desc_node(base: symbol; line, col: longint): node;
function make_unary_op_node(op: op_tag; exp: node; line, col: longint): node;
function make_binary_op_node(op: op_tag; left, right: node; line, col: longint): node;
function make_field_node(name: symbol; expr: node; line, col: longint): node;
function make_field_desc_node(name, ty: symbol; line, col: longint): node;
function make_if_else_node(condition, consequent, alternative: node; line, col: longint): node;
function make_if_node(condition, consequent: node; line, col: longint): node;
function make_while_node(condition, body: node; line, col: longint): node;
function make_for_node(iter: symbol; start, finish, body: node; line, col: longint): node;
function make_let_node(decls: node_list; body: node; line, col: longint): node;
function make_sequence_node(sequence: node_list; line, col: longint): node;
function make_record_node(ty: symbol; fields: node_list; line, col: longint): node;
function make_array_node(ty: symbol; size, value: node; line, col: longint): node;


implementation

function make_list(): node_list;
var list: node_list;
begin
   new(list);
   list^.first := nil;
   list^.last := nil;
   list^.length := 0;
   make_list := list;
end;


function make_list_item(n: node): node_list_item;
var item: node_list_item;
begin
   new(item);
   item^.node := n;
   item^.next := nil;
   make_list_item := item;
end;


procedure append(list: node_list; n: node);
var item: node_list_item;
begin
   item := make_list_item(n);
   if list^.first = nil then
      list^.first := item
   else
      list^.last^.next := item;
  list^.last := item;
  list^.length := list^.length + 1;
end;


function make_node(tag: node_tag; line, col: longint): node;
var n: node;
begin
   new(n);
   n^.tag := tag;
   n^.line := line;
   n^.col := col;
   make_node := n;
end;


function make_assign_node(variable, expr: node; line, col: longint): node;
var n: node;
begin
   n := make_node(assign_node, line, col);
   n^.expr2 := variable;
   n^.expr := expr;
   make_assign_node := n;
end;


function make_call_node(name: symbol; args: node_list; line, col: longint): node;
var n: node;
begin
   n := make_node(call_node, line, col);
   n^.name := name;
   n^.list := args;
   make_call_node := n;
end;


function make_simple_var_node(name: symbol; line, col: longint): node;
var n: node;
begin
   n := make_node(simple_var_node, line, col);
   n^.name := name;
   make_simple_var_node := n;
end;


function make_field_var_node(obj: node; field: symbol; line, col: longint): node;
var n: node;
begin
   n := make_node(field_var_node, line, col);
   n^.expr := obj;
   n^.name := field;
   make_field_var_node := n;
end;


function make_indexed_var_node(arr, index: node; line, col: longint): node;
var n: node;
begin
   n := make_node(indexed_var_node, line, col);
   n^.expr2 := arr;
   n^.expr := index;
   make_indexed_var_node := n;
end;


function make_integer_node(val: int64; line, col: longint): node;
var n: node;
begin
   n := make_node(integer_node, line, col);
   n^.int_val := val;
   make_integer_node := n;
end;


function make_string_node(val: symbol; line, col: longint): node;
var n: node;
begin
   n := make_node(string_node, line, col);
   n^.string_val := val;
   make_string_node := n;
end;


function make_boolean_node(val: boolean; line, col: longint): node;
var n: node;
begin
   n := make_node(boolean_node, line, col);
   n^.bool_val := val;
   make_boolean_node := n;
end;


function make_nil_node(line, col: longint): node;
begin
   make_nil_node := make_node(nil_node, line, col);
end;


function make_type_decl_node(name: symbol; spec: node; line, col: longint): node;
var n: node;
begin
   n := make_node(type_decl_node, line, col);
   n^.name := name;
   n^.expr := spec;
   make_type_decl_node := n;
end;


function make_var_decl_node(name, ty: symbol; expr: node; line, col: longint): node; 
var n: node;
begin
   n := make_node(var_decl_node, line, col);
   n^.name := name;
   n^.type_name := ty;
   n^.expr := expr;
   make_var_decl_node := n;
end;


function make_fun_decl_node(name: symbol; params: node_list; return_type: symbol; body: node; line, col: longint): node;
var n: node;
begin
   n := make_node(fun_decl_node, line, col);
   n^.name := name;
   n^.list := params;
   n^.type_name := return_type;
   n^.expr := body;
   make_fun_decl_node := n;
end;


function make_record_desc_node(fields: node_list; line, col: longint): node;
var n: node;
begin
   n := make_node(record_desc_node, line, col);
   n^.list := fields;
   make_record_desc_node := n;
end;


function make_array_desc_node(base: symbol; line, col: longint): node;
var n: node;
begin
   n := make_node(array_desc_node, line, col);
   n^.type_name := base;
   make_array_desc_node := n;
end;


function make_unary_op_node(op: op_tag; exp: node; line, col: longint): node;
var n: node;
begin
   n := make_node(unary_op_node, line, col);
   n^.op := op;
   n^.expr := exp;
   make_unary_op_node := n;
end;


function make_binary_op_node(op: op_tag; left, right: node; line, col: longint): node;
var n: node;
begin
  n := make_node(binary_op_node, line, col);
  n^.op := op;
  n^.expr := left;
  n^.expr2 := right;
  make_binary_op_node := n;
end;


function make_field_node(name: symbol; expr: node; line, col: longint): node;
var n: node;
begin
   n :=  make_node(field_node, line, col);
   n^.name := name;
   n^.expr := expr;
   make_field_node := n;
end;


function make_field_desc_node(name, ty: symbol; line, col: longint): node;
var n: node;
begin
   n := make_node(field_desc_node, line, col);
   n^.name := name;
   n^.type_name := ty;
   make_field_desc_node := n;
end;


function make_if_else_node(condition, consequent, alternative: node; line, col: longint): node;
var n: node;
begin
   n := make_node(if_else_node, line, col);
   n^.cond := condition;
   n^.expr := consequent;
   n^.expr2 := alternative;
   make_if_else_node := n
end;


function make_if_node(condition, consequent: node; line, col: longint): node;
var n: node;
begin
   n := make_node(if_node, line, col);
   n^.cond := condition;
   n^.expr := consequent;
   make_if_node := n;
end;


function make_while_node(condition, body: node; line, col: longint): node;
var n: node;
begin
   n := make_node(while_node, line, col);
   n^.cond := condition;
   n^.expr := body;
   make_while_node := n;
end;


function make_for_node(iter: symbol; start, finish, body: node; line, col: longint): node;
var n: node;
begin
   n := make_node(for_node, line, col);
   n^.name := iter;
   n^.expr2 := start;
   n^.cond := finish;
   n^.expr := body;
   make_for_node := n;
end;


function make_let_node(decls: node_list; body: node; line, col: longint): node;
var n: node;
begin
   n := make_node(let_node, line, col);
   n^.list := decls;
   n^.expr := body;
   make_let_node := n;
end;


function make_sequence_node(sequence: node_list; line, col: longint): node;
var n: node;
begin
   n := make_node(sequence_node, line, col);
   n^.list := sequence;
   make_sequence_node := n;
end;


function make_record_node(ty: symbol; fields: node_list; line, col: longint): node;
var n: node;
begin
   n := make_node(record_node, line, col);
   n^.type_name := ty;
   n^.list := fields;
   make_record_node := n;
end;


function make_array_node(ty: symbol; size, value: node; line, col: longint): node;
var n: node;
begin
   n := make_node(array_node, line, col);
   n^.type_name := ty;
   n^.expr2 := size;
   n^.expr := value;
   make_array_node := n;
end;

end.

