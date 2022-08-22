program compile;

uses sysutils, parsers, nodes, utils, ops, bindings, semant;

var
   f: textfile;
   ast: node;

procedure lbl(s: string);
begin
   writeln(f, s, ':');
end;

procedure c_fn(s: string);
begin
   writeln(f, '.globl _', s, #10'.align 3'#10'_', s, ':');
end;

procedure ret();
begin
   writeln(f, #9'ret');
end;

procedure emit(n: node; si: longint);
var tmp: string;
const
   ax = '%eax';
   dx = '%edx';

   procedure mov(src, dest: string);
   begin
      writeln(f, #9'movl ', src, ', ', dest);
   end;

   procedure lit(n: longint);
   begin
      mov('$' + inttostr(n), ax);
   end;

   procedure neg(dest: string);
   begin
      writeln(f, #9'negl ', dest);
   end;

   procedure add(src, dest: string);
   begin
      writeln(f, #9'addl ', src, ', ', dest);
   end;

   procedure subtract(src, dest: string);
   begin
      writeln(f, #9'subl ', src, ', ', dest);
   end;

   procedure multiply(src, dest: string);
   begin
      writeln(f, #9'imull ', src, ', ', dest);
   end;

   procedure divide(src: string);
   begin
      writeln(f, #9'cltd');
      writeln(f, #9'idivl ', src);
   end;

   procedure compare(src, dest, cond: string);
   begin
      writeln(f, #9'cmpl ', src, ', ', dest);
      writeln(f, #9'set', cond, ' %al');
      writeln(f, #9'cbw');
      writeln(f, #9'cwde');
   end;

   procedure logical_and(src, dest: string);
   begin
      writeln(f, #9'andl ', src, ', ', dest);
   end;

   procedure logical_or(src, dest: string);
   begin
      writeln(f, #9'orl ', src, ', ', dest);
   end;

   procedure emit_let(n: node; si: longint);
   var
      it: node_list_item;
      stack_index: longint;
   begin
      stack_index := n^.env^.stack_index * -4;
      it := n^.decls^.first;
      while it <> nil do begin
         emit(it^.node, stack_index);
         it := it^.next;
      end;
      emit(n^.let_body, stack_index);
   end;

begin
   case n^.tag of
      integer_node:
         lit(n^.int_val);
      unary_op_node: begin
         emit(n^.unary_exp, si);
         neg(ax);
      end;
      binary_op_node: begin
         tmp := inttostr(si) + '(%rsp)';
         emit(n^.right, si);
         mov(ax, tmp);
         emit(n^.left, si - 4);
         case n^.binary_op of
            plus_op:
               add(tmp, ax);
            minus_op:
               subtract(tmp, ax);
            mul_op:
               multiply(tmp, ax);
            div_op:
               divide(tmp);
            mod_op: begin
               divide(tmp);
               mov(dx, ax);
            end;
            eq_op:
               compare(tmp, ax, 'e');   
	         neq_op:
	            compare(tmp, ax, 'ne');
	         lt_op:
	            compare(tmp, ax, 'l');
	         leq_op:
	            compare(tmp, ax, 'le');
	         gt_op:
	            compare(tmp, ax, 'g');
	         geq_op:
	            compare(tmp, ax, 'ge');
	         and_op:
	            logical_and(tmp, ax);
	         or_op:
	            logical_or(tmp, ax);
            else begin
               writeln(n^.binary_op);
               err('emit: operator not implemented yet!', n^.line, n^.col);
            end;
         end;
      end;
      boolean_node:
         if n^.bool_val then
            lit(1)
         else
            lit(0);
      nil_node:
         lit(0);
      let_node:
         emit_let(n, si);
      var_decl_node: begin
         emit(n^.initial_value, si);
         mov(ax, inttostr(n^.stack_index * -4) + '(%rsp)');
      end;
      simple_var_node:
         mov(inttostr(n^.binding^.stack_index * -4) + '(%rsp)', ax);
      else begin
         writeln(n^.tag);
         err('emit: feature not supported yet!', n^.line, n^.col);
      end;
   end;
end;

begin
   ast := parse(paramstr(1));
   type_check(ast, 1, global_env, global_tenv);
   assign(f, 'output.s');
   rewrite(f);
   writeln(f, '.text');
   c_fn('entry');
   emit(ast, -4);
   ret;
   close(f);
end.

