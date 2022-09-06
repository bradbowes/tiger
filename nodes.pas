unit nodes;

interface

uses symbols, ops, bindings;

type
   node_tag = (assign_node, call_node,
               simple_var_node, field_var_node, indexed_var_node,
               integer_node, string_node, boolean_node, nil_node,
               type_decl_node, var_decl_node, fun_decl_node,
               record_desc_node, array_desc_node,
               unary_op_node, binary_op_node,
               field_node, field_desc_node, if_else_node, if_node,
               while_node, for_node, let_node, sequence_node,
               record_node, array_node);

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
      line, col: longint;
      case tag: node_tag of
         assign_node:      (variable, expression: node);
         call_node:        (call: symbol; args: node_list);
         simple_var_node:  (name: symbol; binding: binding);
         field_var_node:   (obj: node; field: symbol);
         indexed_var_node: (arr, index: node);
         integer_node:     (int_val: longint);
         string_node:      (string_val: symbol);
         boolean_node:     (bool_val: boolean);
         nil_node:         ();
         type_decl_node:   (type_name: symbol; type_spec: node);
         var_decl_node:    (var_name, var_type: symbol; stack_index: longint; initial_value: node);
         fun_decl_node:    (fun_name: symbol; params: node_list; return_type: symbol; fun_body: node); 
         record_desc_node: (field_list: node_list);
         array_desc_node:  (base: symbol);
         unary_op_node:    (unary_op: op_tag; unary_exp: node);
         binary_op_node:   (binary_op: op_tag; left, right: node);
         field_node:       (field_name: symbol; field_value: node);
         field_desc_node:  (field_desc_name, field_type: symbol);
         if_else_node:     (if_else_condition, if_else_consequent, if_else_alternative: node);
         if_node:          (if_condition, if_consequent: node);
         while_node:       (while_condition, while_body: node);
         for_node:         (iter: symbol; start, finish, for_body: node);
         let_node:         (decls: node_list; let_body: node; env: scope);
         sequence_node:    (sequence: node_list);
         record_node:      (record_type: symbol; fields: node_list);
         array_node:       (array_type: symbol; size, default_value: node);
   end;

function make_list(): node_list;
procedure append(list: node_list; n: node);
function make_assign_node(variable, expression: node; line, col: longint): node;
function make_call_node(call: symbol; args: node_list; line, col: longint): node;
function make_simple_var_node(name: symbol; line, col: longint): node;
function make_field_var_node(obj: node; field: symbol; line, col: longint): node;
function make_indexed_var_node(arr, index: node; line, col: longint): node;
function make_integer_node(val, line, col: longint): node;
function make_string_node(val: symbol; line, col: longint): node;
function make_boolean_node(val: boolean; line, col: longint): node;
function make_nil_node(line, col: longint): node;
function make_type_decl_node(name: symbol; spec: node; line, col: longint): node;
function make_var_decl_node(name, ty: symbol; initial_value: node; line, col: longint): node; 
function make_fun_decl_node(name: symbol; params: node_list; return_type: symbol; body: node; line, col: longint): node;
function make_record_desc_node(field_list: node_list; line, col: longint): node;
function make_array_desc_node(base: symbol; line, col: longint): node;
function make_unary_op_node(op: op_tag; exp: node; line, col: longint): node;
function make_binary_op_node(op: op_tag; left, right: node; line, col: longint): node;
function make_field_node(name: symbol; value: node; line, col: longint): node;
function make_field_desc_node(name, ty: symbol; line, col: longint): node;
function make_if_else_node(condition, consequent, alternative: node; line, col: longint): node;
function make_if_node(condition, consequent: node; line, col: longint): node;
function make_while_node(condition, body: node; line, col: longint): node;
function make_for_node(iter: symbol; start, finish, body: node; line, col: longint): node;
function make_let_node(decls: node_list; body: node; line, col: longint): node;
function make_sequence_node(sequence: node_list; line, col: longint): node;
function make_record_node(ty: symbol; fields: node_list; line, col: longint): node;
function make_array_node(ty: symbol; size, default: node; line, col: longint): node;

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

function make_assign_node(variable, expression: node; line, col: longint): node;
var n: node;
begin
   n := make_node(assign_node, line, col);
   n^.variable := variable;
   n^.expression := expression;
   make_assign_node := n;
end;

function make_call_node(call: symbol; args: node_list; line, col: longint): node;
var n: node;
begin
   n := make_node(call_node, line, col);
   n^.call := call;
   n^.args := args;
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
   n^.obj := obj;
   n^.field := field;
   make_field_var_node := n;
end;

function make_indexed_var_node(arr, index: node; line, col: longint): node;
var n: node;
begin
   n := make_node(indexed_var_node, line, col);
   n^.arr := arr;
   n^.index := index;
   make_indexed_var_node := n;
end;

function make_integer_node(val, line, col: longint): node;
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
   n^.type_name := name;
   n^.type_spec := spec;
   make_type_decl_node := n;
end;

function make_var_decl_node(name, ty: symbol; initial_value: node; line, col: longint): node; 
var n: node;
begin
   n := make_node(var_decl_node, line, col);
   n^.var_name := name;
   n^.var_type := ty;
   n^.initial_value := initial_value;
   make_var_decl_node := n;
end;

function make_fun_decl_node(name: symbol; params: node_list; return_type: symbol; body: node; line, col: longint): node;
var n: node;
begin
   n := make_node(fun_decl_node, line, col);
   n^.fun_name := name;
   n^.params := params;
   n^.return_type := return_type;
   n^.fun_body := body;
   make_fun_decl_node := n;
end;

function make_record_desc_node(field_list: node_list; line, col: longint): node;
var n: node;
begin
   n := make_node(record_desc_node, line, col);
   n^.field_list := field_list;
   make_record_desc_node := n;
end;

function make_array_desc_node(base: symbol; line, col: longint): node;
var n: node;
begin
   n := make_node(array_desc_node, line, col);
   n^.base := base;
   make_array_desc_node := n;
end;

function make_unary_op_node(op: op_tag; exp: node; line, col: longint): node;
var n: node;
begin
   n := make_node(unary_op_node, line, col);
   n^.unary_op := op;
   n^.unary_exp := exp;
   make_unary_op_node := n;
end;

function make_binary_op_node(op: op_tag; left, right: node; line, col: longint): node;
var n: node;
begin
  n := make_node(binary_op_node, line, col);
  n^.binary_op := op;
  n^.left := left;
  n^.right := right;
  make_binary_op_node := n;
end;

function make_field_node(name: symbol; value: node; line, col: longint): node;
var n: node;
begin
   n :=  make_node(field_node, line, col);
   n^.field_name := name;
   n^.field_value := value;
   make_field_node := n;
end;

function make_field_desc_node(name, ty: symbol; line, col: longint): node;
var n: node;
begin
   n := make_node(field_desc_node, line, col);
   n^.field_desc_name := name;
   n^.field_type := ty;
   make_field_desc_node := n;
end;

function make_if_else_node(condition, consequent, alternative: node; line, col: longint): node;
var n: node;
begin
   n := make_node(if_else_node, line, col);
   n^.if_else_condition := condition;
   n^.if_else_consequent := consequent;
   n^.if_else_alternative := alternative;
   make_if_else_node := n
end;

function make_if_node(condition, consequent: node; line, col: longint): node;
var n: node;
begin
   n := make_node(if_node, line, col);
   n^.if_condition := condition;
   n^.if_consequent := consequent;
   make_if_node := n;
end;

function make_while_node(condition, body: node; line, col: longint): node;
var n: node;
begin
   n := make_node(while_node, line, col);
   n^.while_condition := condition;
   n^.while_body := body;
   make_while_node := n;
end;

function make_for_node(iter: symbol; start, finish, body: node; line, col: longint): node;
var n: node;
begin
   n := make_node(for_node, line, col);
   n^.iter := iter;
   n^.start := start;
   n^.finish := finish;
   n^.for_body := body;
   make_for_node := n;
end;

function make_let_node(decls: node_list; body: node; line, col: longint): node;
var n: node;
begin
   n := make_node(let_node, line, col);
   n^.decls := decls;
   n^.let_body := body;
   make_let_node := n;
end;

function make_sequence_node(sequence: node_list; line, col: longint): node;
var n: node;
begin
   n := make_node(sequence_node, line, col);
   n^.sequence := sequence;
   make_sequence_node := n;
end;

function make_record_node(ty: symbol; fields: node_list; line, col: longint): node;
var n: node;
begin
   n := make_node(record_node, line, col);
   n^.record_type := ty;
   n^.fields := fields;
   make_record_node := n;
end;

function make_array_node(ty: symbol; size, default: node; line, col: longint): node;
var n: node;
begin
   n := make_node(array_node, line, col);
   n^.array_type := ty;
   n^.size := size;
   n^.default_value := default;
   make_array_node := n;
end;

end.

