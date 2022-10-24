program compile;
{$mode objfpc}
{$H+}

uses sysutils, symbols, parsers, nodes, utils, ops, bindings, types, semant, externals;


procedure emit_expression(n: node; si, nest: longint); forward;


const prologue =
   '.text' + lineending +
   '.align 3' + lineending +
   '.globl f$_tiger_entry' + lineending +
   'f$_tiger_entry:' + lineending;


const epilogue =
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
           '    .quad %d' + lineending +
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
           'f%d$_%s:' + lineending +
           '    pushq %%rbp', [f^.binding^.id, f^.name^.id]);
      emit_expression(f^.expr, -8, f^.binding^.nesting_level + 1);
      emit('    popq %%rbp' + lineending +
           '    ret', []);
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
      stack_index := n^.env^.stack_index * -8 - 8; (* room for pushed %rbp *)
      it := n^.list^.first;
      while it <> nil do begin
         emit_expression(it^.node, stack_index, nest);
         it := it^.next;
      end;
      emit_expression(n^.expr, stack_index, nest);
   end;


   procedure emit_if_else();
   var
      lbl1, lbl2: string;
   begin
      lbl1 := new_label();
      lbl2 := new_label();
      emit_expression(n^.cond, si, nest);
      emit('    cmpq $0, %%rax' + lineending +
           '    jz %s', [lbl1]);
      emit_expression(n^.expr, si, nest);
      emit('    jmp %s', [lbl2]);
      emit('%s:', [lbl1]);
      emit_expression(n^.expr2, si, nest);
      emit('%s:', [lbl2]);
   end;


   procedure emit_if();
   var
      lbl: string;
   begin
      lbl := new_label();
      emit_expression(n^.cond, si, nest);
      emit('    cmpq $0, %%rax' + lineending +
           '    jz %s', [lbl]);
      emit_expression(n^.expr, si, nest);
      emit('%s:', [lbl]);
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
      if offset > 0 then offset := offset + 8; (* space for %rbp pushed *)
      if n^.binding^.nesting_level = nest then
         emit('    movq %d(%%rsp), %%rax', [offset])
      else begin
         emit('    movq 16(%%rsp), %%rbp', []);
         for i := nest - 2 downto n^.binding^.nesting_level do
            emit('    movq 16(%%rbp), %%rbp', []);
         emit('    movq %d(%%rbp), %%rax', [offset]);
      end;
   end;


   procedure emit_simple_assign();
   var
      offset: longint;
      i: integer;
      b: binding;
   begin
      emit_expression(n^.expr, si, nest);
      b := n^.expr2^.binding;
      offset := b^.stack_index * -8;
      if offset > 0 then offset := offset + 8; (* space for pushed %rbp *)
      if b^.nesting_level = nest then
         emit('    movq %%rax, %d(%%rsp)', [offset])
      else begin
         emit('    movq 16(%%rsp), %%rbp', []);
         for i := nest - 2 downto b^.nesting_level do
            emit('    movq 16(%%rbp), %%rbp', []);
         emit('    movq %%rax, %d(%%rbp)', [offset]);
      end;
   end;


   procedure emit_indexed_assign();
   begin
      emit('    movq %%rbx, %d(%%rsp)', [si]);
      emit('    movq %%rsi, %d(%%rsp)', [si - 8]);
      emit_expression(n^.expr2^.expr2, si - 16, nest);
      emit('    movq %%rax, %%rsi', []);
      emit_expression(n^.expr2^.expr, si - 16, nest);
      emit('    movq %%rax, %%rbx', []);
      emit_expression(n^.expr, si - 16, nest);
      emit('    movq %%rax, 8(%%rsi, %%rbx, 8)', []);
      emit('    movq %d(%%rsp), %%rsi',  [si - 8]);
      emit('    movq %d(%%rsp), %%rbx',  [si]);
   end;


   procedure emit_field_assign();
   var
      offset: longint;
      variable: node;
      ty: spec;
   begin
      variable :=  n^.expr2;
      ty := variable^.expr^.binding^.ty;
      offset := get_field(ty, variable^.name, variable^.line, variable^.col)^.offset;
      emit('    movq %%rsi, %d(%%rsp)', [si]);
      emit_expression(variable^.expr, si - 8, nest);
      emit('    movq %%rax, %%rsi', []);
      emit_expression(n^.expr, si - 8, nest);
      emit('    movq %%rax, %d(%%rsi)', [offset * 8]);
      emit('    movq %d(%%rsp), %%rsi', [si]);
   end;


   procedure emit_assign();
   begin
      case n^.expr2^.tag of
         simple_var_node:
            emit_simple_assign();
         indexed_var_node:
            emit_indexed_assign();
         field_var_node:
            emit_field_assign();
      end;
      emit ('    xorq %%rax, %%rax', []);
   end;


   procedure emit_call();
   var
      stack_size, target, i: longint;
      arg: node_list_item;
      pos: longint;
   begin
      target := n^.binding^.nesting_level;
      stack_size := ((8 * n^.list^.length) - si + 15);
      stack_size := stack_size - (stack_size mod 16);
      pos := -stack_size;
      { link }
      if target = nest then
         emit('    movq %%rsp, %d(%%rsp)', [pos])
      else begin
         emit('    movq 16(%%rsp), %%rbp', []);
         for i := nest - 2 downto target do
            emit('    movq 16(%%rbp), %%rbp', []);
         emit('    movq %%rbp, %d(%%rsp)', [pos]);
      end;
      pos := pos + 8;
      arg := n^.list^.first;
      while arg <> nil do begin
         emit_expression(arg^.node, -(stack_size + 8), nest);
         emit('    movq %%rax, %d(%%rsp)', [pos]);
         pos := pos + 8;
         arg := arg^.next;
      end;
      emit('    subq $%d, %%rsp', [stack_size]);
      if n^.binding^.external then

         emit('    call f$_%s', [n^.name^.id])
      else
         emit('    call f%d$_%s', [n^.binding^.id, n^.name^.id]);
      emit('    addq $%d, %%rsp', [stack_size]);
   end;


   procedure emit_sequence();
   var
      it: node_list_item;
   begin
      it := n^.list^.first;
      while it <> nil do begin
         emit_expression(it^.node, si, nest);
         it := it^.next;
      end;
   end;


   procedure emit_array();
   var
      lbl: string;
   begin
      lbl := new_label();
      emit_expression(n^.expr2, si, nest);
      emit('    movq %%rax, %%rcx' + lineending +
           '    movq %%rcx, (%%r15)', []);
      emit_expression(n^.expr, si, nest);
      emit('%s:' + lineending +
           '    movq %%rax, (%%r15, %%rcx, 8)' + lineending +
           '    decq %%rcx' + lineending +
           '    jg %s' + lineending +
           '    movq %%r15, %%rax' + lineending +
           '    movq (%%r15), %%rcx' + lineending +
           '    leaq 8(%%r15, %%rcx, 8), %%r15', [lbl, lbl]);
   end;


   procedure emit_record();
   var
      ty: spec;
      it: node_list_item;
      value: node;
      offset, size, stack_index, i: longint;
   begin
      size := n^.list^.length;
      stack_index := si + (size * -8);
      ty := n^.binding^.ty;
      it := n^.list^.first;
      while it <> nil do begin
         value := it^.node;
         emit('// record field %s', [value^.name^.id]);
         emit_expression(value^.expr, stack_index, nest);
         offset := get_field(ty, value^.name, value^.line, value^.col)^.offset;
         emit('    movq %%rax, %d(%%rsp)', [si - offset * 8]);
         it := it^.next;
      end;
      for i := 0 to size - 1 do begin
         emit('    movq %d(%%rsp), %%rax', [si - i * 8]);
         emit('    movq %%rax, %d(%%r15)', [i * 8]);
      end;
      emit('    movq %%r15, %%rax' + lineending +
           '    addq $%d, %%r15', [size * 8]);
   end;


   procedure emit_indexed_var();
   begin
      emit_expression(n^.expr2, si, nest);
      emit('    movq %%rsi, %d(%%rsp)', [si]);
      emit('    movq %%rax, %%rsi', []);
      emit('    movq %%rsi, %d(%%rsp)', [si - 8]);
      emit_expression(n^.expr, si - 16, nest);
      emit('    movq %d(%%rsp), %%rsi', [si - 8]);
      emit('    movq 8(%%rsi, %%rax, 8), %%rax', []);
      emit('    movq %d(%%rsp), %%rsi', [si]);
   end;


   procedure emit_field_var();
   var
      ty: spec;
      offset: longint;
   begin
      ty := n^.expr^.binding^.ty;
      offset := get_field(ty, n^.name, n^.line, n^.col)^.offset;
      emit_expression(n^.expr, si, nest);
      emit('    movq %%rsi, %d(%%rsp)', [si]);
      emit('    movq %%rax, %%rsi', []);
      emit('    movq %d(%%rsi), %%rax', [8 * offset]);
      emit('    movq %d(%%rsp), %%rsi', [si]);
   end;


   procedure emit_for();
   var
      offset, stack_index: longint;
      lbl1, lbl2: string;
   begin
      lbl1 := new_label();
      lbl2 := new_label();
      offset := n^.binding^.stack_index * -8;
      stack_index := offset - 40;
      emit('    movq %%rcx, %d(%%rsp)', [offset - 8]);
      emit('    movq %%rbx, %d(%%rsp)', [offset - 16]);
      emit_expression(n^.expr2, stack_index, nest);
      emit('    movq %%rax, %%rcx', []);
      emit('    movq %%rax, %d(%%rsp)', [offset]);
      emit('    movq %%rcx, %d(%%rsp)', [offset - 24]);
      emit_expression(n^.cond, stack_index, nest);
      emit('    movq %d(%%rsp), %%rcx', [offset - 24]);
      emit('    movq %%rax, %%rbx', []);
      emit('%s:', [lbl1]);
      emit('    cmpq %%rcx, %%rbx', []);
      emit('    jl %s', [lbl2]);
      emit('    movq %%rcx, %d(%%rsp)', [offset - 24]);
      emit('    movq %%rbx, %d(%%rsp)', [offset - 32]);
      emit_expression(n^.expr, stack_index, nest);
      emit('    movq %d(%%rsp), %%rbx', [offset - 32]);
      emit('    movq %d(%%rsp), %%rcx', [offset - 24]);
      emit('    incq %%rcx', []);
      emit('    movq %%rcx, %d(%%rsp)', [offset]);
      emit('    jmp %s', [lbl1]);
      emit('%s:', [lbl2]);
      emit('    movq %d(%%rsp), %%rbx', [offset - 16]);
      emit('    movq %d(%%rsp), %%rcx', [offset - 8]);
   end;


   procedure emit_while();
   var
      lbl1, lbl2: string;
   begin
      lbl1 := new_label();
      lbl2 := new_label();
      emit('%s:', [lbl1]);
      emit_expression(n^.cond, si, nest);
      emit('    cmpq $0, %%rax' + lineending +
           '    jz %s', [lbl2]);
      emit_expression(n^.expr, si, nest);
      emit('    jmp %s' + lineending +
           '%s:', [lbl1, lbl2]);
   end;

begin
   case n^.tag of
      integer_node:
         emit('    movq $%d, %%rax', [n^.int_val]);
      unary_op_node: begin
         emit_expression(n^.expr, si, nest);
         emit('    negq %%rax', []);
      end;
      binary_op_node: begin
         tmp := inttostr(si) + '(%rsp)';
         emit_expression(n^.expr2, si, nest);
         emit('    movq %%rax, %s', [tmp]);
         emit_expression(n^.expr, si - 8, nest);
         case n^.op of
            plus_op:
               emit('    addq %s, %%rax', [tmp]);
            minus_op:
               emit('    subq %s, %%rax', [tmp]);
            mul_op:
               emit('    imulq %s, %%rax', [tmp]);
            div_op:
               emit('    cqto' + lineending +
                    '    idivq %s', [tmp]);
            mod_op:
               emit('    cqto' + lineending +
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
               writeln(n^.op);
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
         emit_expression(n^.expr, si, nest);
         emit('    movq %%rax, %d(%%rsp)', [n^.binding^.stack_index * -8]);
      end;
      fun_decl_node:
         if n^.expr <> nil then
            add_function(n);
      type_decl_node:
         (* do nothing *);
      simple_var_node:
         emit_var();
      array_node:
         emit_array();
      record_node:
         emit_record();
      indexed_var_node:
         emit_indexed_var();
      field_var_node:
         emit_field_var();
      call_node:
         emit_call();
      if_else_node:
         emit_if_else();
      if_node:
         emit_if();
      sequence_node:
         emit_sequence();
      assign_node:
         emit_assign();
      for_node:
         emit_for();
      while_node:
         emit_while();
      else begin
         writeln(n^.tag);
         err('emit: feature not supported yet!', n^.line, n^.col);
      end;
   end;
end;


begin
   load_externals();
   ast := parse(paramstr(1));
   type_check(ast, 1, 1, add_scope(global_env), add_scope(global_tenv));
   assign(f, 'output.s');
   rewrite(f);
   emit(prologue, []);
   emit_expression(ast, -8, 1);
   emit(epilogue, []);
   emit_functions();
   emit_data();
   close(f);
end.
