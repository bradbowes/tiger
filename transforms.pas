unit transforms;

interface

uses nodes;

type tf_function = function(n: node): node;

function transform(n: node): node;

implementation

uses symbols, ops, bindings, types, semant;

function trans1(n: node): node; forward;
function trans2(n: node): node; forward;

var
   tf1: tf_function = @trans1;
   tf2: tf_function = @trans2;


procedure delete_tree(t: tree);
begin
   if t^.left <> nil then delete_tree(t^.left);
   if t^.right <> nil then delete_tree(t^.right);
   dispose(t^.binding);
   dispose(t);
end;


procedure delete_scope(var env: scope);
begin
   if (env <> global_env) and (env <> global_tenv) then begin
      if (env^.bindings <> nil) then
         delete_tree(env^.bindings);
      dispose(env);
      env := nil;
   end;
end;


procedure delete_node(var n: node);
var
   it, tmp: node_list_item;
begin
   if n^.cond <> nil then delete_node(n^.cond);
   if n^.left <> nil then delete_node(n^.left);
   if n^.right <> nil then delete_node(n^.right);
   if n^.list <> nil then begin
      it := n^.list^.first;
      while it <> nil do begin
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
      if n = nil then
         cp := nil
      else
         cp := tf(n);
   end;

var
   new_node, tmp: node;
   ls: node_list;
   it: node_list_item;
begin
   new(new_node);
   new_node^.tag := n^.tag;
   new_node^.line := n^.line;
   new_node^.col := n^.col;
   new_node^.int_val := n^.int_val;
   new_node^.string_val := n^.string_val;
   new_node^.bool_val := n^.bool_val;
   new_node^.name := n^.name;
   new_node^.type_name := n^.type_name;
   new_node^.cond := cp(n^.cond);
   new_node^.left := cp(n^.left);
   new_node^.right := cp(n^.right);
   new_node^.op := n^.op;
   if n^.list <> nil then begin
      ls := make_list();
      it := n^.list^.first;
      while it <> nil do begin
         tmp := tf(it^.node);
         if tmp^.tag <> empty_node then
            append(ls, tmp);
         it := it^.next;
      end;
      new_node^.list := ls;
   end;
   copy_node := new_node;
end;


function transform(n: node): node;

var
   ast1, ast2, ast3, ast4: node;

   procedure check(n: node);
   begin
      type_check(n, 1, 1, add_scope(global_env), add_scope(global_tenv));
   end;


begin
   ast1 := n;
   check(ast1);
   ast2 := trans1(ast1);
   check(ast2);
   ast3 := trans1(ast2);
   delete_node(ast2);
   delete_node(ast1);
   check(ast3);
   ast4 := trans2(ast3);
   delete_node(ast3);
   check(ast4);
   transform := ast4;
end;

function trans1(n: node): node;
var
   line, col: longint;
   bind: binding;
   e1, e2, cond, left, right: node;
   op: op_tag;

begin
   line := n^.line;
   col := n^.col;
   bind := n^.binding;
   cond := n^.cond;
   left := n^.left;
   right := n^.right;
   op := n^.op;

   case n^.tag of
      simple_var_node:
         if (not bind^.mutates) and (bind^.const_value) then
            if bind^.ty = int_type then
               trans1 := make_integer_node(bind^.int_val, line, col)
            else if bind^.ty = char_type then
               trans1 := make_char_node(bind^.int_val, line, col)
            else if bind^.ty = bool_type then
               trans1 := make_boolean_node(bind^.bool_val, line, col)
            else if bind^.ty = string_type then
               trans1 := make_string_node(bind^.string_val, line, col)
            else
               trans1 := copy_node(n, tf1)
         else
            trans1 := copy_node(n, tf1);
      unary_op_node: begin
         e1 := trans1(left);
         if e1^.tag = integer_node then
            trans1 := make_integer_node(-(e1^.int_val), line, col)
         else
            trans1 := copy_node(n, tf1);
      end;
      binary_op_node: begin
         e1 := trans1(left);
         e2 := trans1(right);
         if (e1^.tag = integer_node) and (e2^.tag = integer_node) then
            case op of
               plus_op:
                  trans1 := make_integer_node(e1^.int_val + e2^.int_val, line, col);
               minus_op:
                  trans1 := make_integer_node(e1^.int_val - e2^.int_val, line, col);
               mul_op:
                  trans1 := make_integer_node(e1^.int_val * e2^.int_val, line, col);
               div_op:
                  trans1 := make_integer_node(e1^.int_val div e2^.int_val, line, col);
               mod_op:
                  trans1 := make_integer_node(e1^.int_val mod e2^.int_val, line, col);
               lt_op:
                  trans1 := make_boolean_node(e1^.int_val < e2^.int_val, line, col);
               leq_op:
                  trans1 := make_boolean_node(e1^.int_val <= e2^.int_val, line, col);
               gt_op:
                  trans1 := make_boolean_node(e1^.int_val > e2^.int_val, line, col);
               geq_op:
                  trans1 := make_boolean_node(e1^.int_val >= e2^.int_val, line, col);
               eq_op:
                  trans1 := make_boolean_node(e1^.int_val = e2^.int_val, line, col);
               neq_op:
                  trans1 := make_boolean_node(e1^.int_val <> e2^.int_val, line, col);
               else
                  trans1 := copy_node(n, tf1);
            end
         else if (e1^.tag = char_node) and (e2^.tag = char_node) then
            case op of
               plus_op:
                  trans1 := make_char_node(e1^.int_val + e2^.int_val, line, col);
               minus_op:
                  trans1 := make_char_node(e1^.int_val - e2^.int_val, line, col);
               lt_op:
                  trans1 := make_boolean_node(e1^.int_val < e2^.int_val, line, col);
               leq_op:
                  trans1 := make_boolean_node(e1^.int_val <= e2^.int_val, line, col);
               gt_op:
                  trans1 := make_boolean_node(e1^.int_val > e2^.int_val, line, col);
               geq_op:
                  trans1 := make_boolean_node(e1^.int_val >= e2^.int_val, line, col);
               eq_op:
                  trans1 := make_boolean_node(e1^.int_val = e2^.int_val, line, col);
               neq_op:
                  trans1 := make_boolean_node(e1^.int_val <> e2^.int_val, line, col);
               else
                  trans1 := copy_node(n, tf1);
            end
         else if (e1^.tag = boolean_node) and (e2^.tag = boolean_node) then
            case op of
               eq_op:
                  trans1 := make_boolean_node(e1^.bool_val = e2^.bool_val, line, col);
               neq_op:
                  trans1 := make_boolean_node(e1^.bool_val <> e2^.bool_val, line, col);
               and_op:
                  trans1 :=  make_boolean_node(e1^.bool_val and e2^.bool_val, line, col);
               or_op:
                  trans1 := make_boolean_node(e1^.bool_val or e2^.bool_val, line, col);
               else
                  trans1 := copy_node(n, tf1);
            end
         else if (op = and_op) then
            if e1^.tag = boolean_node then
               if e1^.bool_val then
                  trans1 := e2
               else
                  trans1 := e1
            else if (e2^.tag = boolean_node) and e2^.bool_val then
               trans1 := e1
            else
               trans1 := copy_node(n, tf1)
         else if (op = or_op) then
            if e1^.tag = boolean_node then
               if e1^.bool_val then
                  trans1 := e1
               else
                  trans1 := e2
            else if (e2^.tag = boolean_node) and (not e2^.bool_val) then
               trans1 := e1
            else
               trans1 := copy_node(n, tf1)
         else
            trans1 := copy_node(n, tf1);
      end;
      if_node: begin
         e1 := trans1(cond);
         if e1^.tag = boolean_node then
            if e1^.bool_val then
               trans1 := trans1(left)
            else
               trans1 := make_empty_node(line, col)
         else
            trans1 := copy_node(n, tf1);
      end;
      if_else_node: begin
         e1 := trans1(cond);
         if e1^.tag = boolean_node then
            if e1^.bool_val then
               trans1 := trans1(left)
            else
               trans1 := trans1(right)
         else
            trans1 := copy_node(n, tf1);
      end;
      while_node: begin
         e1 := trans1(cond);
         if (e1^.tag = boolean_node) and (not e1^.bool_val) then
            trans1 := make_empty_node(line, col)
         else
            trans1 := copy_node(n, tf1);
      end;
      else
         trans1 := copy_node(n, tf1);
   end;
end;


function trans2(n: node): node;
begin
   if n^.tag = var_decl_node then
      if (n^.binding <> nil) and (not n^.binding^.mutates) and (n^.binding^.const_value) then
         trans2 := make_empty_node(n^.line, n^.col)
      else
         trans2 := copy_node(n, tf2)
   else
      trans2 := copy_node(n, tf2);
end;

end.

