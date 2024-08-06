unit analysis;

interface

uses nodes;

procedure analyze(n: node);


implementation

uses bindings, formats, semant;

procedure annotate(n: node; nest: integer; fn: binding);

   procedure annotate_list();
   var
      it: node_list_item;
   begin
      it := n^.list^.first;
      while it <> nil do
         begin
            annotate(it^.node, nest, fn);
            it := it^.next;
         end;
   end;

   procedure annotate_simple_var();
   var
      b: binding;
   begin
      b := n^.binding;
      if b^.nesting_level <> nest then
         begin
            b^.escapes := true;
            add_free_var(fn, b);
         end;
   end;

   procedure annotate_assign();
   var
      left: node;
   begin
      left := n^.left;
      if left^.tag = simple_var_node then
         left^.binding^.mutates := true;
      annotate(left, nest, fn);
      annotate(n^.right, nest, fn);
   end;

   procedure annotate_var_decl();
   begin
      n^.binding^.nesting_level := nest;
      annotate(n^.right, nest, fn);
   end;

   procedure annotate_fun_decl();
   var
      fn_b, param_b: binding;
      it: node_list_item;
      param: node;
      body: node;
   begin
      fn_b := n^.binding;
      fn_b^.nesting_level := nest;
      it := n^.list^.first;
      while it <> nil do
         begin
            param := it^.node;
            param_b := lookup(n^.env, param^.name, param^.loc);
            param_b^.nesting_level := nest + 1;
            it := it^.next;
         end;
      body := n^.right;
      if body <> nil then
         annotate(body, nest + 1, fn_b);
   end;

   procedure annotate_call();
   var
      b: binding;
   begin
      b := n^.binding;
      b^.nesting_level := nest;
      if b <> fn then
         begin
            b^.call_count := b^.call_count + 1;
            if fn = nil then
               b^.reachable := reachable_yes
            else
               begin
                  add_callee(fn, b);
                  add_caller(b, fn);
               end;
         end
      else
         b^.recursive := true;
      annotate_list();
   end;

begin
   case n^.tag of
      unary_minus_node, field_var_node:
         annotate(n^.left, nest, fn);
      plus_node, minus_node, mul_node, div_node, mod_node, eq_node, neq_node,
                 lt_node, leq_node, gt_node, geq_node, indexed_var_node, array_node:
         begin
            annotate(n^.left, nest, fn);
            annotate(n^.right, nest, fn);
         end;
      let_node:
         begin
            annotate_list();
            annotate(n^.right, nest, fn);
         end;
      var_decl_node:
         annotate_var_decl();
      fun_decl_node:
         annotate_fun_decl();
      simple_var_node:
         annotate_simple_var();
      if_else_node:
         begin
            annotate(n^.cond, nest, fn);
            annotate(n^.left, nest, fn);
            annotate(n^.right, nest, fn);
         end;
      if_node, while_node:
         begin
            annotate(n^.cond, nest, fn);
            annotate(n^.left, nest, fn);
         end;
      call_node, tail_call_node:
         annotate_call();
      assign_node:
         annotate_assign();
      sequence_node, record_node:
         annotate_list();
      field_node:
         annotate(n^.left, nest, fn);
   end;
end;

function shake(n: node): node; forward;

var tf: tf_function = @shake;

function shake(n: node): node;

   function is_reachable(b: binding): boolean;
   var
      it: binding_list_item;
      caller: binding;
   begin
      if (b^.reachable = reachable_unknown) and (b^.call_count > 0) then
         begin
            b^.reachable := reachable_no;
            it := b^.callers^.first;
            while it <> nil do
               begin
                  caller := it^.binding;
                  if is_reachable(caller) then
                     b^.reachable := reachable_yes;
                  it := it^.next
               end;
         end;
      is_reachable := b^.reachable = reachable_yes;
   end;

begin
   if n^.tag = fun_decl_node then
      begin
         if is_reachable(n^.binding) then
            shake := copy_node(n, tf)
         else
            shake := make_empty_node(n^.loc);
      end
   else
      shake := copy_node(n, tf);
end;


procedure report(n: node);
var
   node_it: node_list_item;
   binding_it: binding_list_item;
   b: binding;
begin
   if (n^.tag = fun_decl_node) and (not n^.binding^.external) then
      begin
         writeln('----------------------------------------');
         writeln('function: ', n^.name^.id);
         writeln('instruction count: ', n^.ins_count);
         writeln('call count: ', n^.binding^.call_count);
         writeln('recursive: ', n^.binding^.recursive);
         writeln('free variables:');
         binding_it := n^.binding^.free_vars^.first;
         while binding_it <> nil do
            begin
               writeln('   ', binding_it^.binding^.key^.id);
               binding_it := binding_it^.next;
            end;
         writeln('callers:');
         binding_it := n^.binding^.callers^.first;
         while binding_it <> nil do
            begin
               b := binding_it^.binding;
               if b = nil then
                  writeln('    <f$_tiger_entry>')
               else
                  writeln('   ', binding_it^.binding^.key^.id);
               binding_it := binding_it^.next;
            end;
         writeln('callees:');
         binding_it := n^.binding^.callees^.first;
         while binding_it <> nil do
            begin
               writeln('   ', binding_it^.binding^.key^.id);
               binding_it := binding_it^.next;
            end;
         writeln('----------------------------------------');
         writeln();
         if n^.right <> nil then
            report(n^.right);
      end
   else
      begin
         if n^.list <> nil then
            begin
               node_it := n^.list^.first;
               while node_it <> nil do
                  begin
                     report(node_it^.node);
                     node_it := node_it^.next;
                  end;
            end;
         if n^.cond <> nil then report(n^.cond);
         if n^.left <> nil then report(n^.left);
         if n^.right <> nil then report(n^.right);
      end;
end;

procedure analyze(n: node);
var
   shaken: node;
begin
   annotate(n, 0, nil);
   shaken := shake(n);
   type_check(shaken);
   annotate(shaken, 0, nil);
   report(shaken);
   // report(n);
end;



end.
