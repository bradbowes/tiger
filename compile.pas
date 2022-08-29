program compile;
{$mode objfpc}

uses sysutils, symbols, parsers, nodes, utils, ops, bindings, semant;

const prologue = 
   '.text' + lineending +
   '.globl _tiger_entry' + lineending +
   '_tiger_entry:' + lineending +
   '    pushq %%r15' + lineending +
   '    movq %%rdi, %%r15' + lineending;


const epilogue = 
   '    popq %%r15' + lineending +
   '    ret' + lineending;


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
   

procedure emit(fmt: string; args: array of const);
begin
   writeln(f, format(fmt, args));
end;


procedure emit_data();
var
   sl: string_list;
   s: string;
   l: longint;
begin
   emit('.data', []);
   sl := strings;
   while sl <> nil do begin
      s := sl^.sym^.id;
      l := length(s);
      s := stringreplace(stringreplace(s, '\', '\\', [rfReplaceAll]), '"', '\"', [rfReplaceAll]);
      emit('    .align 3' + lineending +
           'string_%d:' + lineending +
           '    .int %d' + lineending +
           '    .asciz "%s"', [sl^.id, l, s]);
      sl := sl^.next;
   end;
end;


procedure emit_expression(n: node; si: longint);
var
   tmp: string;

   procedure emit_let(n: node; si: longint);
   var
      it: node_list_item;
      stack_index: longint;
   begin
      stack_index := n^.env^.stack_index * -8;
      it := n^.decls^.first;
      while it <> nil do begin
         emit_expression(it^.node, stack_index);
         it := it^.next;
      end;
      emit_expression(n^.let_body, stack_index);
   end;

   procedure emit_if_else(n: node; si: longint);
   var
      label_1, label_2: string;
   begin
      label_1 := new_label();
      label_2 := new_label();
      emit_expression(n^.if_else_condition, si);
      writeln(f, #9'jz ', label_1);
      emit_expression(n^.if_else_consequent, si);
      writeln(f, #9'jmp ', label_2);
      emit('%s:', [label_1]);
      emit_expression(n^.if_else_alternative, si); 
      emit('%s:', [label_2]); 
   end;

   procedure emit_string(n: node);
   var
      slabel: string;
      sl: string_list;
   begin
      sl := add_string(n^.string_val);
      slabel := 'string_' + inttostr(sl^.id) + '@GOTPCREL(%rip)';
      emit('    movq %s, %%rax', [slabel]);
   end;

begin
   case n^.tag of
      integer_node:
         emit('    movq $%d, %%rax', [n^.int_val]);
      unary_op_node: begin
         emit_expression(n^.unary_exp, si);
         emit('    negq %%rax', []);
      end;
      binary_op_node: begin
         tmp := inttostr(si) + '(%rsp)';
         emit_expression(n^.right, si);
         emit('    movq %%rax, %s', [tmp]);
         emit_expression(n^.left, si - 8);
         case n^.binary_op of
            plus_op:
               emit('    addq %s, %%rax', [tmp]);
            minus_op:
               emit('    subq %s, %%rax', [tmp]);
            mul_op:
               emit('    imulq %s, %%rax', [tmp]);
            div_op:
               emit('    cltd' + lineending +
                    '    idivq %s', [tmp]);
            mod_op:
               emit('    cltd' + lineending +
                    '    idivq %s' + lineending +
                    '    movq %%rdx, %%rax', [tmp]);
            eq_op:
               emit('    cmpq %s, %%rax' + lineending +
                    '    sete %%al' + lineending +
                    '    andq $1, %%rax', [tmp]);
	         neq_op:
               emit('    cmpq %s, %%rax' + lineending +
                    '    setne %%al' + lineending +
                    '    andq $1, %%rax', [tmp]);
	         lt_op:
               emit('    cmpq %s, %%rax' + lineending +
                    '    setl %%al' + lineending +
                    '    andq $1, %%rax', [tmp]);
	         leq_op:
               emit('    cmpq %s, %%rax' + lineending +
                    '    setle %%al' + lineending +
                    '    andq $1, %%rax', [tmp]);
	         gt_op:
               emit('    cmpq %s, %%rax' + lineending +
                    '    setg %%al' + lineending +
                    '    andq $1, %%rax', [tmp]);
	         geq_op:
               emit('    cmpq %s, %%rax' + lineending +
                    '    setge %%al' + lineending +
                    '    andq $1, %%rax', [tmp]);
	         and_op:
	            emit('    andq %s, %%rax', [tmp]);
	         or_op:
	            emit('    orq %s, %%rax', [tmp]);
            else begin
               writeln(n^.binary_op);
               err('emit: operator not implemented yet!', n^.line, n^.col);
            end;
         end;
      end;
      boolean_node: begin
         emit('    xorq %%rax, %%rax', []);
         if n^.bool_val then
            emit('    incq %%rax', []);
      end;
      string_node:
         emit_string(n);
      nil_node:
         emit('    xorq %%rax, %%rax', []);
      let_node:
         emit_let(n, si);
      var_decl_node: begin
         emit_expression(n^.initial_value, si);
         emit('    movq %%rax, %d(%%rsp)', [n^.stack_index * -8]);
      end;
      simple_var_node:
         emit('    movq %d(%%rsp), %%rax', [n^.binding^.stack_index * -8]);
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
   emit(prologue, []);
   emit_expression(ast, -8);
   emit(epilogue, []);
   emit_data();
   close(f);
end.
