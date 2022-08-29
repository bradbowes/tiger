program compile;

uses sysutils, symbols, parsers, nodes, utils, ops, bindings, semant;

type
   string_list = ^string_list_t;
   
   string_list_t = record
      sym: symbol;
      id: integer;
      next: string_list;
   end;  

var
   f: textfile;
   ast: node;
   strings: string_list = nil;
   next_string_id: integer = 1;
   next_label_id: integer = 1;
   sl: string_list;
   s: string;

function add_string(s: symbol): string_list;
var
   sl: string_list;
begin
   sl := strings;
   while sl <> nil do
      if sl^.sym = s then
         exit(sl)
      else
         sl := sl^.next;
   
   new(sl);
   sl^.sym := s;
   sl^.id := next_string_id;
   sl^.next := strings;
   strings := sl;
   next_string_id := next_string_id + 1;
   add_string := sl;
end;

function new_label(): string;
begin
   new_label := format('L%.5d', [next_label_id]);
   next_label_id := next_label_id + 1;
end;
   
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

procedure push(src: string);
begin
   writeln(f, #9'push ', src);
end;

procedure pop(src: string);
begin
   writeln(f, #9'pop ', src);
end;

procedure emit(n: node; si: longint);
var
   tmp: string;

const
   ax = '%rax';
   dx = '%rdx';


   procedure mov(src, dest: string);
   begin
      writeln(f, #9'movq ', src, ', ', dest);
   end;

   procedure lit(n: longint);
   begin
      mov('$' + inttostr(n), ax);
   end;

   procedure neg(dest: string);
   begin
      writeln(f, #9'negq ', dest);
   end;

   procedure add(src, dest: string);
   begin
      writeln(f, #9'addq ', src, ', ', dest);
   end;

   procedure subtract(src, dest: string);
   begin
      writeln(f, #9'subq ', src, ', ', dest);
   end;

   procedure multiply(src, dest: string);
   begin
      writeln(f, #9'imulq ', src, ', ', dest);
   end;

   procedure divide(src: string);
   begin
      writeln(f, #9'cltd');
      writeln(f, #9'idivq ', src);
   end;

   procedure zero_ax();
   begin
      writeln(f, #9'xorq %rax, %rax');
   end;

   procedure compare(src, dest, cond: string);
   begin
      writeln(f, #9'cmpq ', src, ', ', dest);
      writeln(f, #9'set', cond, ' %al');
      writeln(f, #9'andq $1, %rax');
   end;

   procedure logical_and(src, dest: string);
   begin
      writeln(f, #9'andq ', src, ', ', dest);
   end;

   procedure logical_or(src, dest: string);
   begin
      writeln(f, #9'orq ', src, ', ', dest);
   end;

   procedure emit_let(n: node; si: longint);
   var
      it: node_list_item;
      stack_index: longint;
   begin
      stack_index := n^.env^.stack_index * -8;
      it := n^.decls^.first;
      while it <> nil do begin
         emit(it^.node, stack_index);
         it := it^.next;
      end;
      emit(n^.let_body, stack_index);
   end;

   procedure emit_if_else(n: node; si: longint);
   var
      label_1, label_2: string;
   begin
      label_1 := new_label();
      label_2 := new_label();
      emit(n^.if_else_condition, si);
      writeln(f, #9'jz ', label_1);
      emit(n^.if_else_consequent, si);
      writeln(f, #9'jmp ', label_2);
      lbl(label_1);
      emit(n^.if_else_alternative, si); 
      lbl(label_2); 
   end;

   procedure emit_string(n: node);
   var
      slabel: string;
   begin
      sl := add_string(n^.string_val);
      slabel := 'string_' + inttostr(sl^.id) + '@GOTPCREL(%rip)';
      writeln(f, #9'movq ', slabel, ', %rax');
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
         emit(n^.left, si - 8);
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
            begin
               zero_ax();
               writeln(f, #9'incq %rax');
            end
         else
            zero_ax();
      string_node:
         emit_string(n);
      nil_node:
         lit(0);
      let_node:
         emit_let(n, si);
      var_decl_node: begin
         emit(n^.initial_value, si);
         mov(ax, inttostr(n^.stack_index * -8) + '(%rsp)');
      end;
      simple_var_node:
         mov(inttostr(n^.binding^.stack_index * -8) + '(%rsp)', ax);
      if_else_node:
         emit_if_else(n, si);
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
   push('%r15');
   writeln(f, #9'movq %rdi, %r15');
   emit(ast, -8);
   pop('%r15');
   ret;
   writeln(f, '.data');
   sl := strings;
   while sl <> nil do begin
      lbl('string_' + inttostr(sl^.id));
      s := sl^.sym^.id;
      writeln(f, #9'.align 3');
      writeln(f, #9'.int ', length(s));
      writeln(f, #9'.asciz "', stringreplace(stringreplace(s, '\', '\\', [rfReplaceAll]), '"', '\"', [rfReplaceAll]), '"');
      sl := sl^.next;
   end;
   close(f);
end.

