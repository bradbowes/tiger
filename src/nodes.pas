{$mode objfpc}
{$modeswitch nestedprocvars}

unit nodes;

interface

uses lists, sources, symbols, values, bindings;

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
               enum_desc_node,
               unary_minus_node,
               plus_node,
               minus_node,
               mul_node,
               div_node,
               mod_node,
               eq_node,
               neq_node,
               lt_node,
               leq_node,
               gt_node,
               geq_node,
               and_node,
               or_node,
               field_node,
               field_desc_node,
               enum_node,
               if_else_node,
               if_node,
               case_node,
               clause_node,
               while_node,
               for_node,
               let_node,
               sequence_node,
               record_node,
               array_node);

   node = ^node_t;
   node_list = specialize list<node>;
   node_list_item = specialize list_item<node>;
   node_t = record
      tag: node_tag;
      loc: source_location;
      ins_count: integer;
      value: value;
      binding: binding;
      name, type_name: symbol;
      cond, left, right: node;
      list: node_list;
      env: scope;
      tenv: scope;
   end;
   tf_function = function(n: node): node;

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
function make_enum_desc_node(items: node_list; loc: source_location): node;
function make_unary_minus_node(exp: node; loc: source_location): node;
function make_plus_node(left, right: node; loc: source_location): node;
function make_minus_node(left, right: node; loc: source_location): node;
function make_mul_node(left, right: node; loc: source_location): node;
function make_div_node(left, right: node; loc: source_location): node;
function make_mod_node(left, right: node; loc: source_location): node;
function make_eq_node(left, right: node; loc: source_location): node;
function make_neq_node(left, right: node; loc: source_location): node;
function make_lt_node(left, right: node; loc: source_location): node;
function make_leq_node(left, right: node; loc: source_location): node;
function make_gt_node(left, right: node; loc: source_location): node;
function make_geq_node(left, right: node; loc: source_location): node;
function make_and_node(left, right: node; loc: source_location): node;
function make_or_node(left, right: node; loc: source_location): node;
function make_field_node(name: symbol; expr: node; loc: source_location): node;
function make_field_desc_node(name, ty: symbol; loc: source_location): node;
function make_enum_node(name: symbol; loc: source_location): node;
function make_if_else_node(condition, consequent, alternative: node; loc: source_location): node;
function make_if_node(condition, consequent: node; loc: source_location): node;
function make_case_node(arg: node; clauses: node_list; default: node; loc: source_location): node;
function make_clause_node(match, action: node; loc: source_location): node;
function make_while_node(condition, body: node; loc: source_location): node;
function make_for_node(iter: symbol; start, finish, body: node; loc: source_location): node;
function make_let_node(decls: node_list; body: node; loc: source_location): node;
function make_sequence_node(sequence: node_list; loc: source_location): node;
function make_record_node(ty: symbol; fields: node_list; loc: source_location): node;
function make_array_node(ty: symbol; size, value: node; loc: source_location): node;
function make_binary_node(tag: node_tag; left, right: node; loc: source_location): node;
procedure delete_node(var n: node);
function copy_node(n: node; tf: tf_function): node;

implementation

function list_ins_count(ls: node_list): integer;
var
   count: integer = 0;
   add_count: node_list.iter;

   procedure _add_count(n: node);
   begin
      count := count + n^.ins_count;
   end;
begin
   add_count := @_add_count;

   ls.foreach(add_count);
   list_ins_count := count;
end;

function make_node(tag: node_tag; loc: source_location): node;
var
   n: node;
begin
   new(n);
   n^.tag := tag;
   n^.loc := loc;
   n^.ins_count := 0;
   n^.value := nil;
   n^.binding := nil;
   n^.name := nil;
   n^.type_name := nil;
   n^.cond := nil;
   n^.left := nil;
   n^.right := nil;
   n^.list := nil;
   n^.env := nil;
   n^.tenv := nil;
   make_node := n;
end;

function make_binary_node(tag: node_tag; left, right: node; loc: source_location): node;
var
   n: node;
begin
   n := make_node(tag, loc);
   n^.ins_count := left^.ins_count + right^.ins_count + 1;
   n^.left := left;
   n^.right := right;
   make_binary_node := n;
end;

function make_assign_node(variable, expr: node; loc: source_location): node;
var
   n: node;
begin
   n := make_node(assign_node, loc);
   n^.left := variable;
   n^.right := expr;
   n^.ins_count := variable^.ins_count + expr^.ins_count + 1;
   make_assign_node := n;
end;

function make_call_node(name: symbol; args: node_list; loc: source_location): node;
var
   n: node;
begin
   n := make_node(call_node, loc);
   n^.name := name;
   n^.list := args;
   n^.ins_count := list_ins_count(args) + 1;
   make_call_node := n;
end;

function make_simple_var_node(name: symbol; loc: source_location): node;
var
   n: node;
begin
   n := make_node(simple_var_node, loc);
   n^.name := name;
   n^.ins_count := 1;
   make_simple_var_node := n;
end;

function make_field_var_node(obj: node; field: symbol; loc: source_location): node;
var
   n: node;
begin
   n := make_node(field_var_node, loc);
   n^.left := obj;
   n^.name := field;
   n^.ins_count := obj^.ins_count + 1;
   make_field_var_node := n;
end;

function make_indexed_var_node(arr, index: node; loc: source_location): node;
var
   n: node;
begin
   n := make_node(indexed_var_node, loc);
   n^.left := arr;
   n^.right := index;
   n^.ins_count := arr^.ins_count + index^.ins_count + 1;
   make_indexed_var_node := n;
end;

function make_integer_node(val: int64; loc: source_location): node;
var
   n: node;
begin
   n := make_node(integer_node, loc);
   n^.value := make_integer_value(val);
   n^.ins_count := 1;
   make_integer_node := n;
end;

function make_string_node(val: symbol; loc: source_location): node;
var
   n: node;
begin
   n := make_node(string_node, loc);
   n^.value := make_string_value(val);
   n^.ins_count := 1;
   make_string_node := n;
end;

function make_char_node(val: int64; loc: source_location): node;
var
   n: node;
begin
   n := make_node(char_node, loc);
   n^.value := make_integer_value(val);
   n^.ins_count := 1;
   make_char_node := n;
end;

function make_boolean_node(val: boolean; loc: source_location): node;
var
   n: node;
begin
   n := make_node(boolean_node, loc);
   n^.value := make_boolean_value(val);
   n^.ins_count := 1;
   make_boolean_node := n;
end;

function make_nil_node(loc: source_location): node;
var
   n: node;
begin
   n := make_node(nil_node, loc);
   n^.ins_count := 1;
   make_nil_node := n;
end;

function make_empty_node(loc: source_location): node;
var
   n: node;
begin
   n := make_node(empty_node, loc);
   n^.ins_count := 0;
   make_empty_node := n;
end;

function make_type_decl_node(name: symbol; spec: node; loc: source_location): node;
var
   n: node;
begin
   n := make_node(type_decl_node, loc);
   n^.name := name;
   n^.right := spec;
   n^.ins_count := 0;
   make_type_decl_node := n;
end;

function make_var_decl_node(name, ty: symbol; expr: node; loc: source_location): node;
var
   n: node;
begin
   n := make_node(var_decl_node, loc);
   n^.name := name;
   n^.type_name := ty;
   n^.right := expr;
   n^.ins_count := expr^.ins_count + 1;
   make_var_decl_node := n;
end;

function make_fun_decl_node(name: symbol; params: node_list; return_type: symbol; body: node; loc: source_location): node;
var
   n: node;
begin
   n := make_node(fun_decl_node, loc);
   n^.name := name;
   n^.list := params;
   n^.type_name := return_type;
   n^.right := body;
   if body = nil then (* external *)
      n^.ins_count := 0
   else
      n^.ins_count := body^.ins_count;
   make_fun_decl_node := n;
end;

function make_record_desc_node(fields: node_list; loc: source_location): node;
var
   n: node;
begin
   n := make_node(record_desc_node, loc);
   n^.list := fields;
   n^.ins_count := 0;
   make_record_desc_node := n;
end;

function make_array_desc_node(base: symbol; loc: source_location): node;
var
   n: node;
begin
   n := make_node(array_desc_node, loc);
   n^.type_name := base;
   n^.ins_count := 0;
   make_array_desc_node := n;
end;

function make_enum_desc_node(items: node_list; loc: source_location): node;
var
   n: node;
begin
   n := make_node(enum_desc_node, loc);
   n^.list := items;
   n^.ins_count := 0;
   make_enum_desc_node := n;
end;

function make_unary_minus_node(exp: node; loc: source_location): node;
var
   n: node;
begin
   n := make_node(unary_minus_node, loc);
   n^.left := exp;
   n^.ins_count := exp^.ins_count + 1;
   make_unary_minus_node := n;
end;

function make_plus_node(left, right: node; loc: source_location): node;
begin
   make_plus_node := make_binary_node(plus_node, left, right, loc);
end;

function make_minus_node(left, right: node; loc: source_location): node;
begin
   make_minus_node := make_binary_node(minus_node, left, right, loc);
end;

function make_mul_node(left, right: node; loc: source_location): node;
begin
   make_mul_node := make_binary_node(mul_node, left, right, loc);
end;

function make_div_node(left, right: node; loc: source_location): node;
begin
   make_div_node := make_binary_node(div_node, left, right, loc);
end;

function make_mod_node(left, right: node; loc: source_location): node;
begin
   make_mod_node := make_binary_node(mod_node, left, right, loc);
end;

function make_eq_node(left, right: node; loc: source_location): node;
begin
   make_eq_node := make_binary_node(eq_node, left, right, loc);
end;

function make_neq_node(left, right: node; loc: source_location): node;
begin
   make_neq_node := make_binary_node(neq_node, left, right, loc);
end;

function make_lt_node(left, right: node; loc: source_location): node;
begin
   make_lt_node := make_binary_node(lt_node, left, right, loc);
end;

function make_leq_node(left, right: node; loc: source_location): node;
begin
   make_leq_node := make_binary_node(leq_node, left, right, loc);
end;

function make_gt_node(left, right: node; loc: source_location): node;
begin
   make_gt_node := make_binary_node(gt_node, left, right, loc);
end;

function make_geq_node(left, right: node; loc: source_location): node;
begin
   make_geq_node := make_binary_node(geq_node, left, right, loc);
end;

function make_and_node(left, right: node; loc: source_location): node;
begin
   make_and_node := make_binary_node(and_node, left, right, loc);
end;

function make_or_node(left, right: node; loc: source_location): node;
begin
   make_or_node := make_binary_node(or_node, left, right, loc);
end;

function make_field_node(name: symbol; expr: node; loc: source_location): node;
var
   n: node;
begin
   n :=  make_node(field_node, loc);
   n^.left := expr;
   n^.name := name;
   n^.ins_count := expr^.ins_count + 1;
   make_field_node := n;
end;

function make_field_desc_node(name, ty: symbol; loc: source_location): node;
var
   n: node;
begin
   n := make_node(field_desc_node, loc);
   n^.name := name;
   n^.type_name := ty;
   n^.ins_count := 0;
   make_field_desc_node := n;
end;

function make_enum_node(name: symbol; loc: source_location): node;
var
   n: node;
begin
   n := make_node(enum_node, loc);
   n^.name := name;
   n^.ins_count := 0;
   make_enum_node := n;
end;

function make_if_else_node(condition, consequent, alternative: node; loc: source_location): node;
var
   n: node;
begin
   n := make_node(if_else_node, loc);
   n^.cond := condition;
   n^.left := consequent;
   n^.right := alternative;
   n^.ins_count := condition^.ins_count + consequent^.ins_count + alternative^.ins_count + 1;
   make_if_else_node := n
end;

function make_if_node(condition, consequent: node; loc: source_location): node;
var
   n: node;
begin
   n := make_node(if_node, loc);
   n^.cond := condition;
   n^.left := consequent;
   n^.ins_count := condition^.ins_count + consequent^.ins_count + 1;
   make_if_node := n;
end;

function make_case_node(arg: node; clauses: node_list; default: node; loc: source_location): node;
var
   n: node;
begin
   n := make_node(case_node, loc);
   n^.cond := arg;
   n^.list := clauses;
   n^.right := default;
   n^.ins_count := arg^.ins_count + list_ins_count(clauses);
   make_case_node := n;
end;

function make_clause_node(match, action: node; loc: source_location): node;
var
   n: node;
begin
   n := make_node(clause_node, loc);
   n^.left := match;
   n^.right := action;
   n^.ins_count := action^.ins_count + 1;
   make_clause_node := n;
end;

function make_while_node(condition, body: node; loc: source_location): node;
var
   n: node;
begin
   n := make_node(while_node, loc);
   n^.cond := condition;
   n^.left := body;
   n^.ins_count := condition^.ins_count + body^.ins_count + 1;
   make_while_node := n;
end;

function make_for_node(iter: symbol; start, finish, body: node; loc: source_location): node;
var
   n: node;
begin
   n := make_node(for_node, loc);
   n^.name := iter;
   n^.left := start;
   n^.cond := finish;
   n^.right := body;
   n^.ins_count := start^.ins_count + finish^.ins_count + body^.ins_count + 1;
   make_for_node := n;
end;

function make_let_node(decls: node_list; body: node; loc: source_location): node;
var
   n: node;
begin
   n := make_node(let_node, loc);
   n^.list := decls;
   n^.right := body;
   n^.ins_count := list_ins_count(decls) + body^.ins_count;
   make_let_node := n;
end;

function make_sequence_node(sequence: node_list; loc: source_location): node;
var
   n: node;
begin
   n := make_node(sequence_node, loc);
   n^.list := sequence;
   n^.ins_count := list_ins_count(sequence);
   make_sequence_node := n;
end;

function make_record_node(ty: symbol; fields: node_list; loc: source_location): node;
var
   n: node;
begin
   n := make_node(record_node, loc);
   n^.type_name := ty;
   n^.list := fields;
   n^.ins_count := list_ins_count(fields);
   make_record_node := n;
end;

function make_array_node(ty: symbol; size, value: node; loc: source_location): node;
var
   n: node;
begin
   n := make_node(array_node, loc);
   n^.type_name := ty;
   n^.left := size;
   n^.right := value;
   n^.ins_count := size^.ins_count + value^.ins_count + 1;
   make_array_node := n;
end;

procedure delete_node(var n: node);
var
   del_item: node_list.iter;

   procedure _del_item(n: node);
   begin
      if n <> nil then delete_node(n);
   end;

begin
   del_item := @_del_item;
   if n^.cond <> nil then delete_node(n^.cond);
   if n^.left <> nil then delete_node(n^.left);
   if n^.right <> nil then delete_node(n^.right);
   if n^.list <> nil then
   begin
      n^.list.foreach(del_item);
      n^.list.destroy();
   end;
   if n^.tenv <> nil then delete_scope(n^.tenv);
   if n^.env <> nil then delete_scope(n^.env);
   dispose(n);
   n := nil;
end;

function copy_node(n: node; tf: tf_function): node;
var
   new_node: node;
   ls: node_list;
   list_copy: node_list.iter;

   function cp(n: node): node;
   begin
      if (n = nil) or (n^.tag = empty_node) then
         cp := nil
      else
         cp := tf(n);
   end;

   procedure _list_copy(n: node);
   var tmp: node;
   begin
      tmp := cp(n);
      if tmp <> nil then
         ls.append(tmp);
   end;

begin
   list_copy := @_list_copy;
   new_node := make_node(n^.tag, n^.loc);
   new_node^.value := n^.value;
   new_node^.name := n^.name;
   new_node^.type_name := n^.type_name;
   if n^.list <> nil then
      begin
         ls := node_list.create();
         n^.list.foreach(list_copy);
         new_node^.list := ls;
      end;
   new_node^.cond := cp(n^.cond);
   new_node^.left := cp(n^.left);
   new_node^.right := cp(n^.right);
   new_node^.ins_count := n^.ins_count;
   copy_node := new_node;
end;

end.
