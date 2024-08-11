{$mode objfpc}
{$modeswitch nestedprocvars}

unit analysis;

interface

uses nodes;

procedure analyze(n: node);


implementation

uses bindings, formats, semant;

procedure annotate(n: node; nest: integer; fn: binding);

   procedure annotate_list();
   var
      annotate_item: node_list.iter;

      procedure _annotate_item(n: node);
      begin
         annotate(n, nest, fn);
      end;

   begin
      annotate_item := @_annotate_item;
      n^.list.foreach(annotate_item);
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
      b: binding;
      body: node;
      annotate_param: node_list.iter;

      procedure _annotate_param(param: node);
      var
         b: binding;
      begin
         b := lookup(n^.env, param^.name, param^.loc);
         b^.nesting_level := nest + 1;
      end;

   begin
      annotate_param := @_annotate_param;
      b := n^.binding;
      b^.nesting_level := nest;
      n^.list.foreach(annotate_param);
      body := n^.right;
      if body <> nil then
         annotate(body, nest + 1, b);
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
      reach: binding_list.iter;

      procedure _reach(caller: binding);
      begin
         if is_reachable(caller) then
            b^.reachable := reachable_yes;
      end;

   begin
      reach := @_reach;
      if (b^.reachable = reachable_unknown) and (b^.call_count > 0) then
         begin
            b^.reachable := reachable_no;
            b^.callers.foreach(reach);
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
   b: binding;
   report_node: node_list.iter;
   report_binding: binding_list.iter;

   procedure _report_node(n: node);
   begin
      report(n);
   end;

   procedure _report_binding(b: binding);
   begin
      if b = nil then
         writeln('    < - - - - >')
      else
         writeln('   ', b^.key^.id);
   end;

begin
   report_node := @_report_node;
   report_binding := @_report_binding;
   if (n^.tag = fun_decl_node) and (not n^.binding^.external) then
      begin
         writeln('----------------------------------------');
         writeln('function: ', n^.name^.id);
         writeln('instruction count: ', n^.ins_count);
         writeln('call count: ', n^.binding^.call_count);
         writeln('recursive: ', n^.binding^.recursive);
         writeln('free variables:');
         n^.binding^.free_vars.foreach(report_binding);
         writeln('callers:');
         n^.binding^.callers.foreach(report_binding);
         writeln('callees:');
         n^.binding^.callees.foreach(report_binding);
         writeln('----------------------------------------');
         writeln();
         if n^.right <> nil then
            report(n^.right);
      end
   else
      begin
         if n^.list <> nil then
            n^.list.foreach(report_node);
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
