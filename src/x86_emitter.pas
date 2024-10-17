{$mode objfpc}
{$modeswitch nestedprocvars}
{$h+}

unit x86_emitter;

interface

uses nodes;

procedure emit_x86(ast: node; file_name: string);

implementation

uses sysutils, symbols, parser,
     sources, bindings, datatypes;

procedure emit_expression(n: node; si, nest: longint); forward;

const prologue =
   '.text' + lineending +
   '.p2align 3' + lineending +
   '.globl f$_tiger_entry' + lineending +
   'f$_tiger_entry:' + lineending +
   '   pushq %%rbp' + lineending +
   '   movq %%rsp, %%rbp';

const epilogue =
   '   popq %%rbp' + lineending +
   '   ret';

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
   else
      begin
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
   while sl <> nil do
      begin
         s := sl^.sym^.id;
         l := length(s);
         s := stringreplace(stringreplace(s, '\', '\\', [rfReplaceAll]), '"', '\"', [rfReplaceAll]);
         emit(lineending +
              '   .p2align 3' + lineending +
              'tiger$_string_%d:' + lineending +
              '   .quad %d' + lineending +
              '   .asciz "%s"', [sl^.id, l, s]);
         sl := sl^.next;
      end;
end;

procedure emit_functions();
var
   fl: function_list;
   f: node;
begin
   fl := functions;
   while fl <> nil do
      begin
         f := fl^.fun;
         emit(lineending +
              '   .p2align 3' + lineending +
              '%s:' + lineending +
              '   pushq %%rbp' + lineending +
              '   movq %%rsp, %%rbp', [f^.name^.id]);
         emit_expression(f^.right, -8, f^.binding^.nesting_level + 1);
         emit('   popq %%rbp' + lineending +
              '   ret', []);
         fl := fl^.next;
      end;
end;

procedure emit_expression(n: node; si, nest: longint);
var
   tmp: string;

   procedure emit_let();
   var
      stack_index: longint;
      emit_decl: node_list.iter;

      procedure _emit_decl(n: node);
      begin
         emit_expression(n, stack_index, nest);
      end;

   begin
      emit_decl := @_emit_decl;
      stack_index := n^.env^.stack_index * -8 - 8; (* room for pushed %rbp *)
      n^.list.foreach(emit_decl);
      if n^.right <> nil then
         emit_expression(n^.right, stack_index, nest);
   end;

   procedure emit_if_else();
   var
      lbl1, lbl2: string;
   begin
      lbl1 := new_label();
      lbl2 := new_label();
      emit_expression(n^.cond, si, nest);
      emit('   cmpq $0, %%rax' + lineending +
           '   jz %s', [lbl1]);
      emit_expression(n^.left, si, nest);
      emit('   jmp %s', [lbl2]);
      emit('%s:', [lbl1]);
      emit_expression(n^.right, si, nest);
      emit('%s:', [lbl2]);
   end;

   procedure emit_if();
   var
      lbl: string;
   begin
      lbl := new_label();
      emit_expression(n^.cond, si, nest);
      emit('   cmpq $0, %%rax' + lineending +
           '   jz %s', [lbl]);
      emit_expression(n^.left, si, nest);
      emit('%s:', [lbl]);
   end;

   procedure emit_string();
   var
      slabel: string;
      sl: string_list;
   begin
      sl := add_string(n^.value^.string_val);
      slabel := 'tiger$_string_' + inttostr(sl^.id) + '@GOTPCREL(%rip)';
      emit('   movq %s, %%rax', [slabel]);
   end;

   procedure emit_var();
   var
      offset: longint;
      i: integer;
   begin
      offset := n^.binding^.stack_index * -8;
      if offset > 0 then offset := offset + 8; (* space for %rbp pushed *)
      if n^.binding^.nesting_level = nest then
         emit('   movq %d(%%rbp), %%rax', [offset])
      else
         begin
            emit('   movq %%rbp, %%rbx' + lineending +
                 '   movq 16(%%rbx), %%rbx', []);
            for i := nest - 2 downto n^.binding^.nesting_level do
               emit('   movq 16(%%rbx), %%rbx', []);
            emit('   movq %d(%%rbx), %%rax', [offset]);
         end;
   end;

   procedure emit_simple_assign();
   var
      offset: longint;
      i: integer;
      b: binding;
   begin
      emit_expression(n^.right, si, nest);
      b := n^.left^.binding;
      offset := b^.stack_index * -8;
      if offset > 0 then offset := offset + 8; (* space for pushed %rbp *)
      if b^.nesting_level = nest then
         emit('   movq %%rax, %d(%%rbp)', [offset])
      else
         begin
            emit('   movq %%rbp, %%rbx' + lineending +
                 '   movq 16(%%rbx), %%rbx', []);
            for i := nest - 2 downto b^.nesting_level do
               emit('   movq 16(%%rbx), %%rbx', []);
            emit('   movq %%rax, %d(%%rbx)', [offset]);
         end;
   end;

   procedure emit_indexed_assign();
   var
      arr: node;
   begin
      arr := n^.left^.left;
      emit_expression(arr, si - 16, nest);
      emit('   movq %%rax, %%rsi', []);
      emit('   movq %%rsi, %d(%%rbp)', [si - 8]);
      emit_expression(n^.left^.right, si - 16, nest);
      emit('   movq %%rax, %%rbx', []);
      emit('   movq %%rbx, %d(%%rbp)', [si]);
      emit_expression(n^.right, si - 16, nest);
      emit('   movq %d(%%rbp), %%rbx',  [si]);
      emit('   movq %d(%%rbp), %%rsi',  [si - 8]);
      if ((arr^.binding <> nil) and (arr^.binding^.ty = string_type)) then
         emit('   movb %%al, 8(%%rsi, %%rbx, 1)', [])
      else
         emit('   movq %%rax, 8(%%rsi, %%rbx, 8)', []);
   end;

   procedure emit_field_assign();
   var
      offset: longint;
      variable: node;
      ty: spec;
   begin
      variable :=  n^.left;
      ty := variable^.left^.binding^.ty;
      offset := get_field(ty, variable^.name, variable^.loc)^.offset;
      emit('   movq %%rsi, %d(%%rbp)', [si]);
      emit_expression(variable^.left, si - 8, nest);
      emit('   movq %%rax, %%rsi', []);
      emit_expression(n^.right, si - 8, nest);
      emit('   movq %%rax, %d(%%rsi)', [offset * 8]);
      emit('   movq %d(%%rbp), %%rsi', [si]);
   end;

   procedure emit_assign();
   begin
      case n^.left^.tag of
         simple_var_node:
            emit_simple_assign();
         indexed_var_node:
            emit_indexed_assign();
         field_var_node:
            emit_field_assign();
      end;
   end;

   procedure emit_tail_call();
   var
      target, i: longint;
      pos: longint;
      emit_arg: node_list.iter;

      procedure _emit_arg(n: node);
      begin
         emit_expression(n, -8, nest);
         emit('   movq %%rax, %d(%%rbp)', [pos]);
         pos := pos + 8;
      end;

   begin
      emit_arg := @_emit_arg;
      target := n^.binding^.nesting_level;
      pos := 16;
      { link }
      if not n^.binding^.external then
         if target = nest then
            emit('   movq %%rbp, %d(%%rbp)', [pos])
         else
            begin
               emit('   movq %%rbp, %%rbx' + lineending +
                    '   movq 16(%%rbx), %%rbx', []);
               for i := nest - 3 downto target do
                  emit('   movq 16(%%rbx), %%rbx', []);
               emit('   movq %%rbx, %d(%%rbp)', [pos]);
            end;
      pos := pos + 8;
      n^.list.foreach(emit_arg);
      emit('   popq %%rbp', []);
      if n^.binding^.external then
         emit('   jmp f$_%s', [n^.name^.id])
      else
         emit('   jmp f%d$_%s', [n^.binding^.id, n^.name^.id]);
   end;

   procedure emit_call();
   var
      stack_size, target, i: longint;
      pos: longint;
      emit_arg: node_list.iter;

      procedure _emit_arg(n: node);
      begin
         emit_expression(n, -(stack_size + 8), nest);
         emit('   movq %%rax, %d(%%rbp)', [pos]);
         pos := pos + 8;
      end;

   begin
      emit_arg := @_emit_arg;
      target := n^.binding^.nesting_level;
      stack_size := ((8 * n^.list.length) - si + 15);
      stack_size := stack_size - (stack_size mod 16);
      pos := -stack_size;
      { link }
      if not n^.binding^.external then
         if target = nest then
            emit('   movq %%rbp, %d(%%rbp)', [pos])
         else
            begin
               emit('   movq %%rbp, %%rbx' + lineending +
                    '   movq 16(%%rbx), %%rbx', []);
               for i := nest - 2 downto target do
                  emit('   movq 16(%%rbx), %%rbx', []);
               emit('   movq %%rbx, %d(%%rbp)', [pos]);
            end;
      pos := pos + 8;
      n^.list.foreach(emit_arg);
      emit('   subq $%d, %%rsp', [stack_size]);
      if n^.binding^.external then
         emit('   call f$_%s', [n^.name^.id])
      else
         emit('   call %s', [n^.name^.id]);
      emit('   addq $%d, %%rsp', [stack_size]);
   end;

   procedure emit_sequence();
   var
      emit_expr: node_list.iter;

      procedure _emit_expr(n: node);
      begin
         emit_expression(n, si, nest);
      end;

   begin
      emit_expr := @_emit_expr;
      n^.list.foreach(emit_expr);
   end;

   procedure emit_array();
   var
      lbl: string;
   begin
      lbl := new_label();
      emit_expression(n^.left, si, nest);
      emit('   movq %%rax, %%rcx' + lineending +
           '   movq %%rcx, (%%r15)', []);
      emit_expression(n^.right, si, nest);
      emit('%s:' + lineending +
           '   movq %%rax, (%%r15, %%rcx, 8)' + lineending +
           '   decq %%rcx' + lineending +
           '   jg %s' + lineending +
           '   movq %%r15, %%rax' + lineending +
           '   movq (%%r15), %%rcx' + lineending +
           '   leaq 8(%%r15, %%rcx, 8), %%r15', [lbl, lbl]);
   end;

   procedure emit_record();
   var
      ty: spec;
      size, stack_index, i: longint;
      emit_field: node_list.iter;

      procedure _emit_field(n: node);
      var
         offset: longint;
      begin
         emit_expression(n^.left, stack_index, nest);
         offset := get_field(ty, n^.name, n^.loc)^.offset;
         emit('   movq %%rax, %d(%%rbp)', [si - offset * 8]);
      end;

   begin
      emit_field := @_emit_field;
      size := n^.list.length;
      stack_index := si + (size * -8);
      ty := n^.binding^.ty;
      n^.list.foreach(emit_field);
      for i := 0 to size - 1 do
         begin
            emit('   movq %d(%%rbp), %%rax', [si - i * 8]);
            emit('   movq %%rax, %d(%%r15)', [i * 8]);
         end;
      emit('   movq %%r15, %%rax' + lineending +
           '   addq $%d, %%r15', [size * 8]);
   end;

   procedure emit_indexed_var();
   begin
      emit_expression(n^.left, si, nest);
      emit('   movq %%rsi, %d(%%rbp)', [si]);
      emit('   movq %%rax, %%rsi', []);
      emit('   movq %%rsi, %d(%%rbp)', [si - 8]);
      emit_expression(n^.right, si - 16, nest);
      emit('   movq %d(%%rbp), %%rsi', [si - 8]);
      if ((n^.left^.binding <> nil) and (n^.left^.binding^.ty = string_type)) or
         (n^.left^.tag = string_node) then
         emit('   movb 8(%%rsi, %%rax, 1), %%al' + lineending +
              '   andq $0x00000000000000ff, %%rax', [])
      else
         emit('   movq 8(%%rsi, %%rax, 8), %%rax', []);
      emit('   movq %d(%%rbp), %%rsi', [si]);
   end;

   procedure emit_field_var();
   var
      ty: spec;
      offset: longint;
   begin
      ty := n^.left^.binding^.ty;
      offset := get_field(ty, n^.name, n^.loc)^.offset;
      emit('   movq %%rsi, %d(%%rbp)', [si]);
      emit_expression(n^.left, si, nest);
      emit('   movq %%rax, %%rsi', []);
      emit('   movq %d(%%rsi), %%rax', [8 * offset]);
      emit('   movq %d(%%rbp), %%rsi', [si]);
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
      emit('   movq %%rcx, %d(%%rbp)', [offset - 8]);
      emit('   movq %%rbx, %d(%%rbp)', [offset - 16]);
      emit_expression(n^.left, stack_index, nest);
      emit('   movq %%rax, %%rcx', []);
      emit('   movq %%rax, %d(%%rbp)', [offset]);
      emit('   movq %%rcx, %d(%%rbp)', [offset - 24]);
      emit_expression(n^.cond, stack_index, nest);
      emit('   movq %d(%%rbp), %%rcx', [offset - 24]);
      emit('   movq %%rax, %%rbx', []);
      emit('%s:', [lbl1]);
      emit('   cmpq %%rcx, %%rbx', []);
      emit('   jl %s', [lbl2]);
      emit('   movq %%rcx, %d(%%rbp)', [offset - 24]);
      emit('   movq %%rbx, %d(%%rbp)', [offset - 32]);
      emit_expression(n^.right, stack_index, nest);
      emit('   movq %d(%%rbp), %%rbx', [offset - 32]);
      emit('   movq %d(%%rbp), %%rcx', [offset - 24]);
      emit('   incq %%rcx', []);
      emit('   movq %%rcx, %d(%%rbp)', [offset]);
      emit('   jmp %s', [lbl1]);
      emit('%s:', [lbl2]);
      emit('   movq %d(%%rbp), %%rbx', [offset - 16]);
      emit('   movq %d(%%rbp), %%rcx', [offset - 8]);
   end;

   procedure emit_while();
   var
      lbl1, lbl2: string;
   begin
      lbl1 := new_label();
      lbl2 := new_label();
      emit('%s:', [lbl1]);
      emit_expression(n^.cond, si, nest);
      emit('   cmpq $0, %%rax' + lineending +
           '   jz %s', [lbl2]);
      emit_expression(n^.left, si, nest);
      emit('   jmp %s' + lineending +
           '%s:', [lbl1, lbl2]);
   end;

begin
   case n^.tag of
      integer_node, char_node:
         emit('   movq $%d, %%rax', [n^.value^.int_val]);
      unary_minus_node:
         begin
            emit_expression(n^.left, si, nest);
            emit('   negq %%rax', []);
         end;
      plus_node, minus_node, mul_node, div_node, mod_node, eq_node,
                 neq_node, lt_node, leq_node, gt_node, geq_node:
         begin
            tmp := '%rcx';
            emit_expression(n^.right, si, nest);
            emit('   movq %%rax, %s', [tmp]);
            emit_expression(n^.left, si, nest);
            case n^.tag of
               plus_node:
                  emit('   addq %s, %%rax', [tmp]);
               minus_node:
                  emit('   subq %s, %%rax', [tmp]);
               mul_node:
                  emit('   imulq %s, %%rax', [tmp]);
               div_node:
                  emit('   cqto' + lineending +
                       '   idivq %s', [tmp]);
               mod_node:
                  emit('   cqto' + lineending +
                       '   idivq %s' + lineending +
                       '   movq %%rdx, %%rax', [tmp]);
               eq_node:
                  emit('   cmpq %s, %%rax' + lineending +
                       '   sete %%al' + lineending +
                       '   andq $1, %%rax', [tmp]);
   	         neq_node:
                  emit('   cmpq %s, %%rax' + lineending +
                       '   setne %%al' + lineending +
                       '   andq $1, %%rax', [tmp]);
   	         lt_node:
                  emit('   cmpq %s, %%rax' + lineending +
                       '   setl %%al' + lineending +
                       '   andq $1, %%rax', [tmp]);
   	         leq_node:
                  emit('   cmpq %s, %%rax' + lineending +
                       '   setle %%al' + lineending +
                       '   andq $1, %%rax', [tmp]);
   	         gt_node:
                  emit('   cmpq %s, %%rax' + lineending +
                       '   setg %%al' + lineending +
                       '   andq $1, %%rax', [tmp]);
   	         geq_node:
                  emit('   cmpq %s, %%rax' + lineending +
                       '   setge %%al' + lineending +
                       '   andq $1, %%rax', [tmp]);
            end;
         end;
      boolean_node:
         begin
            emit('   xorq %%rax, %%rax', []);
            if n^.value^.bool_val then
               emit('   incq %%rax', []);
         end;
      string_node:
         emit_string();
      nil_node:
         emit('   xorq %%rax, %%rax', []);
      empty_node:
         (* nothing to do *);
      let_node:
         emit_let();
      var_decl_node:
         begin
            emit_expression(n^.right, si, nest);
            emit('   movq %%rax, %d(%%rbp)', [n^.binding^.stack_index * -8]);
         end;
      fun_decl_node:
         if n^.right <> nil then
            add_function(n);
      type_decl_node:
         (* do nothing *);
      simple_var_node:
         if n^.binding^.constant then
            emit('   movq $%d, %%rax', [n^.binding^.value^.int_val])
         else
            emit_var();
      array_node:
         emit_array();
      record_node:
         emit_record();
      indexed_var_node:
         emit_indexed_var();
      field_var_node:
         emit_field_var();
      call_node, tail_call_node:
         emit_call();
      (*
      tail_call_node:
         emit_tail_call();
      *)
      if_else_node:
         emit_if_else();
      if_node:
         emit_if();
      sequence_node:
         emit_sequence();
      assign_node:
         emit_assign();
      while_node:
         emit_while();
      else
         begin
            writeln(n^.tag);
            err('emit: feature not supported yet!', n^.loc);
         end;
   end;
end;


procedure emit_x86(ast: node; file_name: string);
begin
   assign(f, file_name);
   rewrite(f);
   emit(prologue, []);
   emit_expression(ast, -8, 1);
   emit(epilogue, []);
   emit_functions();
   emit_data();
   close(f);
end;

end.
