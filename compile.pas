program compile;
{$mode objfpc}
{$H+}

uses sysutils, symbols, parsers, nodes, utils, ops, bindings, semant, externals;


procedure emit_expression(n: node; si, nest: longint); forward;


const prologue = 
   '.text' + lineending +
   '.align 3' + lineending +
   '.globl _tiger_entry' + lineending +
   '_tiger_entry:' + lineending +
   '    pushq %%rbp' + lineending +
   '    pushq %%r15' + lineending +
   '    movq %%rdi, %%r15';


const epilogue = 
   '    popq %%r15' + lineending +
   '    popq %%rbp' + lineending +
   '    ret';


type
   string_list = ^string_list_t;
   
   string_list_t = record
      sym: symbol;
      id: integer;
      next: string_list;
   end;

   function_list = ^function_list_t;

   function_list_t = record
      fun: node;
      next: function_list;
   end;


var
   f: textfile;
   ast: node;
   strings: string_list = nil;
   functions: function_list = nil;
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


procedure add_function(f: node);
var
   fl, next: function_list;
begin
   new(fl);
   fl^.fun := f;
   fl^.next := nil;
   if functions = nil then
      functions := fl
   else begin
      next := functions;
      while next^.next <> nil do
         next := next^.next;
      next^.next := fl;
   end;
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
   emit(lineending + '.data', []);
   sl := strings;
   while sl <> nil do begin
      s := sl^.sym^.id;
      l := length(s);
      s := stringreplace(stringreplace(s, '\', '\\', [rfReplaceAll]), '"', '\"', [rfReplaceAll]);
      emit(lineending +
           '    .align 3' + lineending +
           'tiger$_string_%d:' + lineending +
           '    .int %d' + lineending +
           '    .asciz "%s"', [sl^.id, l, s]);
      sl := sl^.next;
   end;
end;


procedure emit_functions();
var
   fl: function_list;
   f: node;
begin
   fl := functions;
   while fl <> nil do begin
      f := fl^.fun;
      emit(lineending +
           '    .align 3' + lineending +
           'tiger$_%s:', [f^.fun_name^.id]);
      emit_expression(f^.fun_body, -8, f^.nest);
      emit('    ret', []);
      fl := fl^.next;
   end;
end;
           

procedure emit_expression(n: node; si, nest: longint);
var
   tmp: string;

   procedure emit_let();
   var
      it: node_list_item;
      stack_index: longint;
   begin
      stack_index := n^.env^.stack_index * -8;
      it := n^.decls^.first;
      while it <> nil do begin
         emit_expression(it^.node, stack_index, nest);
         it := it^.next;
      end;
      emit_expression(n^.let_body, stack_index, nest);
   end;


   procedure emit_if_else();
   var
      label_1, label_2: string;
   begin
      label_1 := new_label();
      label_2 := new_label();
      emit_expression(n^.if_else_condition, si, nest);
      emit('    jz %s', [label_1]);
      emit_expression(n^.if_else_consequent, si, nest);
      emit('    jmp %s', [label_2]);
      emit('%s:', [label_1]);
      emit_expression(n^.if_else_alternative, si, nest); 
      emit('%s:', [label_2]); 
   end;
   

   procedure emit_string();
   var
      slabel: string;
      sl: string_list;
   begin
      sl := add_string(n^.string_val);
      slabel := 'tiger$_string_' + inttostr(sl^.id) + '@GOTPCREL(%rip)';
      emit('    movq %s, %%rax', [slabel]);
   end;
   

   procedure emit_var();
   var
      offset: longint;
      i: integer;
   begin
      offset := n^.binding^.stack_index * -8;
      if n^.binding^.nesting_level = nest then
         emit('    movq %d(%%rsp), %%rax', [offset])
      else begin
         emit('    movq 8(%%rsp), %%rbp', []);
         for i := nest - 2 downto n^.binding^.nesting_level do
            emit('    movq 8(%%rbp), %%rbp', []);
         emit('    movq %d(%%rbp), %%rax', [offset]);
      end;
   end;


   procedure emit_assign();
   var
      offset: longint;
      i: integer;
      b: binding;
   begin
      emit_expression(n^.expression, si, nest);
      b := n^.variable^.binding;
      offset := b^.stack_index * -8;
      writeln('offset: ', offset);
      if b^.nesting_level = nest then
         emit('    movq %%rax, %d(%%rsp)', [offset])
      else begin
         emit('    movq 8(%%rsp), %%rbp', []);
         for i := nest - 2 downto n^.binding^.nesting_level do
            emit('    movq 8(%%rbp), %%rbp', []);
         emit('    movq %%rax, %d(%%rbp)', [offset]);
      end;
      emit ('    xorq %%rax, %%rax', []);
   end;


   procedure emit_call();
   var
      stack_size, target, i: longint;
      arg: node_list_item;
      pos: longint;
   begin
      target := n^.target^.nesting_level;
      stack_size := ((8 * n^.args^.length) - si + 15);
      stack_size := stack_size - (stack_size mod 16);
      pos := -stack_size;
      { link }
      if target = nest then
         emit('    movq %%rsp, %d(%%rsp)', [pos])
      else begin
         emit('    movq 8(%%rsp), %%rbp', []);
         for i := nest - 2 downto target do
            emit('   movq 8(%%rbp), %%rbp', []);
         emit('    movq %%rbp, %d(%%rsp)', [pos]);
      end;
      pos := pos + 8;
      arg := n^.args^.first;
      while arg <> nil do begin
         emit_expression(arg^.node, -(stack_size + 8), nest);
         emit('    movq %%rax, %d(%%rsp)', [pos]);
         pos := pos + 8;
         arg := arg^.next;
      end;
      emit('    subq $%d, %%rsp', [stack_size]);
      emit('    call tiger$_%s', [n^.call^.id]);
      emit('    addq $%d, %%rsp', [stack_size]);
   end;


   procedure emit_sequence();
   var
      it: node_list_item;
   begin
      it := n^.sequence^.first;
      while it <> nil do begin
         emit_expression(it^.node, si, nest);
         it := it^.next;
      end;
   end;
   

begin
   case n^.tag of
      integer_node:
         emit('    movq $%d, %%rax', [n^.int_val]);
      unary_op_node: begin
         emit_expression(n^.unary_exp, si, nest);
         emit('    negq %%rax', []);
      end;
      binary_op_node: begin
         tmp := inttostr(si) + '(%rsp)';
         emit_expression(n^.right, si, nest);
         emit('    movq %%rax, %s', [tmp]);
         emit_expression(n^.left, si - 8, nest);
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
         emit_string();
      nil_node:
         emit('    xorq %%rax, %%rax', []);
      let_node:
         emit_let();
      var_decl_node: begin
         emit_expression(n^.initial_value, si, nest);
         emit('    movq %%rax, %d(%%rsp)', [n^.stack_index * -8]);
      end;
      fun_decl_node:
         if n^.fun_body <> nil then
            add_function(n);
      simple_var_node:
         emit_var();
      call_node:
         emit_call();
      if_else_node:
         emit_if_else();
      sequence_node:
         emit_sequence();
      assign_node:
         emit_assign();
      else begin
         writeln(n^.tag);
         err('emit: feature not supported yet!', n^.line, n^.col);
      end;
   end;
end;


begin
   load_externals();
   ast := parse(paramstr(1));
   type_check(ast, 1, 0, global_env, global_tenv);
   assign(f, 'output.s');
   rewrite(f);
   emit(prologue, []);
   emit_expression(ast, -8, 0);
   emit(epilogue, []);
   emit_functions();
   emit_data();
   close(f);
end.
