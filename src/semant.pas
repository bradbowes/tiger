{$mode objfpc}
{$modeswitch nestedprocvars}

unit semant;

interface

uses datatypes, nodes;

function type_check(n: node): spec;

implementation

uses sources, bindings, symbols, values;

function check(n: node; si, nest: integer; env, tenv: scope): spec;

   function compatible(a, b: spec): boolean;
   begin
      compatible := (a = b) or
                    ((b = nil_type) and not (a^.tag in [primitive_type, enum_type, function_type])) or
                    ((a = nil_type) and not (b^.tag in [primitive_type, enum_type, function_type])) or
                    ((a^.tag = array_type) and (b^.tag = array_type) and compatible(a^.base, b^.base));
   end;

   function type_or_nil(a, b: spec): spec;
   begin
      if a = nil_type then
         type_or_nil := b
      else
         type_or_nil := b
   end;

   function check_unary_minus(): spec;
   begin
      if check(n^.left, si, nest, env, tenv) <> int_type then
         err('sign operator incompatible type', n^.loc);
      check_unary_minus := int_type;
   end;

   procedure check_var_decl(n: node; si, offset: integer; env, tenv: scope);
   var
      ty1, ty2: spec;
      b: binding;
      right: node;
      loc: source_location;
   begin
      right := n^.right;
      loc := n^.loc;
      ty1 := check(right, si, nest, env, tenv);
      ty2 := nil;
      if ty1 = void_type then
         err(n^.name^.id + ' variable initializer doesn''t produce a value', right^.loc);
      if (n^.type_name = nil) then
         if  (ty1 = nil_type) then
            err('variable with nil initializer needs explicit type', loc)
         else
            ty2 := ty1
      else
         ty2 := lookup(tenv, n^.type_name, loc)^.ty;
      if not compatible(ty1, ty2) then
         err('initializer doesn''t match type spec', loc);
      b := bind(env, n^.name, ty2, offset, nest, loc);
      if  right^.tag in [integer_node, char_node, string_node, boolean_node] then
         b^.value := right^.value;
      n^.binding := b;
   end;

   procedure check_fun_decl(n: node; si: integer; env, tenv: scope);
   var
      ty, param_type, return_type: spec;
      fenv: scope;
      stack_index: integer;
      bind_param: node_list.iter;

      procedure _bind_param(n: node);
      var
         key: symbol;
         loc: source_location;
      begin
         key := n^.name;
         loc := n^.loc;
         param_type := lookup(tenv, n^.type_name, loc)^.ty;
         add_param(ty, key, param_type, loc);
         bind(fenv, key, param_type, stack_index, nest + 1, loc);
         stack_index := stack_index - 1;
      end;

   begin
      bind_param := @_bind_param;
      if n^.type_name = nil then
         return_type := void_type
      else
         return_type := lookup(tenv, n^.type_name, n^.loc)^.ty;

      ty := make_function_type(return_type);
      fenv := add_scope(env);
      stack_index := -2; { args go up from sp; leave space for link address and return address }
      n^.list.foreach(bind_param);
      n^.env := fenv;
      n^.binding := bind(env, n^.name, ty, si, nest, n^.loc);
   end;

   procedure find_tail_calls(n: node);
   begin
      case n^.tag of
         call_node:
            n^.tag := tail_call_node;
         if_node:
            find_tail_calls(n^.left);
         if_else_node:
            begin
               find_tail_calls(n^.left);
               find_tail_calls(n^.right);
            end;
         sequence_node:
            if n^.list.last <> nil then
               find_tail_calls(n^.list.last.thing);
         let_node:
            find_tail_calls(n^.right);
      end;
   end;

   procedure check_fun_body(n: node; si: integer; env, tenv: scope);
   var
      ty, body_type: spec;
   begin
      if n^.right <> nil then
         begin
            ty := n^.binding^.ty;
            body_type := check(n^.right, si, nest + 1, n^.env, tenv);
            if not compatible(ty^.base, body_type) then
               err('function return type doesn''t match declaration', n^.loc);
            find_tail_calls(n^.right);
         end
      else
         n^.binding^.external := true;
   end;

   procedure check_type_decl(n: node; tenv: scope);
   var
      ty: spec = nil;
      tyspec: node;
   begin
      tyspec := n^.right;
      case tyspec^.tag of
         array_desc_node:
            ty := make_array_type(lookup(tenv, tyspec^.type_name, tyspec^.loc)^.ty);
         record_desc_node:
            ty := make_record_type();
         enum_desc_node:
            ty := make_enum_type();
      end;

      n^.binding := bind(tenv, n^.name, ty, 0, 0, n^.loc);
   end;

   procedure check_record_decl_body(n: node; tenv: scope);
   var
      offset: integer;
      ty: spec;
      check_field: node_list.iter;

      procedure _check_field(n: node);
      var
         fld_ty: spec;
         loc: source_location;
      begin
         loc := n^.loc;
         fld_ty := lookup(tenv, n^.type_name, loc)^.ty;
         add_field(ty, n^.name, fld_ty, offset, loc);
         offset := offset + 1;
      end;

   begin
      check_field := @_check_field;
      offset := 0;
      ty := n^.binding^.ty;
      n^.right^.list.foreach(check_field);
   end;

   procedure check_enum_decl_body(n: node; tenv: scope);
   var
      offset: integer = 0;
      ty: spec;
      bind_enum: node_list.iter;

      procedure _bind_enum(n: node);
      var
         b: binding;
      begin
         b := bind(env, n^.name, ty, 0, 0, n^.loc);
         b^.value := make_integer_value(offset);
         b^.constant := true;
         offset := offset + 1;
         n^.binding := b;
      end;

   begin
      bind_enum := @_bind_enum;
      ty := n^.binding^.ty;
      n^.right^.list.foreach(bind_enum);
   end;

   function check_let(): spec;
      type
         state_tag = (var_state, fun_state, type_state);

      var
         state: state_tag;
         group: node_list = nil;
         new_env, new_tenv: scope;
         stack_index, offset: integer;
         inc_stack, chk_decl: node_list.iter;

      procedure update_state(new_state: state_tag);
      var
         chk_fun, chk_ty: node_list.iter;

         procedure _chk_fun(n: node);
         begin
            check_fun_body(n, stack_index, new_env, new_tenv);
         end;

         procedure _chk_ty(n: node);
         begin
            case n^.right^.tag  of
               record_desc_node:
                  check_record_decl_body(n, new_tenv);
               enum_desc_node:
                  check_enum_decl_body(n, new_tenv);
            end;
         end;
      begin
         chk_fun := @_chk_fun;
         chk_ty := @_chk_ty;
         case state of
            var_state:
               if new_state <> var_state then
                  group := node_list.create();
            fun_state:
               if new_state <> fun_state then
                  begin
                     group.foreach(chk_fun);
                     group.destroy();
                     if new_state = type_state then
                        group := node_list.create();
                  end;
            type_state:
               if new_state <> type_state then
                  begin
                     group.foreach(chk_ty);
                     group.destroy();
                     if new_state = fun_state then
                        group := node_list.create();
                  end;
         end;
         state := new_state;
      end;

      procedure _inc_stack(n: node);
      begin
         if n^.tag = var_decl_node then
            stack_index := stack_index + 1;
      end;

      procedure _chk_decl(n: node);
      begin
         case n^.tag of
            var_decl_node:
               begin
                  update_state(var_state);
                  check_var_decl(n, stack_index, offset, new_env, new_tenv);
                  offset := offset + 1;
               end;
            fun_decl_node:
               begin
                  update_state(fun_state);
                  check_fun_decl(n, stack_index, new_env, new_tenv);
                  group.append(n);
               end;
            type_decl_node:
               begin
                  update_state(type_state);
                  check_type_decl(n, new_tenv);
                  group.append(n);
               end;
         end;
      end;

   begin
      inc_stack := @_inc_stack;
      chk_decl := @_chk_decl;
      state := var_state;
      offset := si;
      stack_index := si;
      n^.list.foreach(inc_stack);
      new_tenv := add_scope(tenv);
      new_env := add_scope(env);
      n^.list.foreach(chk_decl);
      update_state(var_state);
      new_env^.stack_index := stack_index;
      n^.env := new_env;
      n^.tenv := new_tenv;
      if n^.right = nil then
         check_let := void_type
      else
         check_let := check(n^.right, stack_index, nest, new_env, new_tenv);
   end;

   function check_simple_var(): spec;
   var
      b: binding;
   begin
      b := lookup(env, n^.name, n^.loc);
      n^.binding := b;
      if b^.nesting_level <> nest then
         b^.escapes := true;
      check_simple_var := b^.ty;
   end;

   function check_if_else(): spec;
   var ty1, ty2: spec;
   begin
      if check(n^.cond, si, nest, env, tenv) <> bool_type then
         err('if condition is not a boolean value', n^.loc);
      ty1 := check(n^.left, si, nest, env, tenv);
      ty2 := check(n^.right, si, nest, env, tenv);
      if not compatible(ty1, ty2) then
         err('if and else clauses incompatible types', n^.loc);
      check_if_else := type_or_nil(ty1, ty2);
   end;

   function check_if(): spec;
   begin
      if check(n^.cond, si, nest, env, tenv) <> bool_type then
         err('if condition is not a boolean value', n^.loc);
      if check(n^.left, si, nest, env, tenv) <> void_type then
         err('if without else cannot return a value', n^.loc);
      check_if := void_type;
   end;

   function check_call(): spec;
   var
      f: spec;
      param: field;
      chk_arg: node_list.iter;

      procedure _chk_arg(n: node);
      begin
         if param = nil then
            err('too many arguments to function', n^.loc);
         if check(n, si, nest, env, tenv) <> param^.ty then
            err('argument is wrong type', n^.loc);
         param := param^.next;
      end;

   begin
      chk_arg := @_chk_arg;
      f := check(n^.left, si, nest, env, tenv);
      if f^.tag <> function_type then
         err('not a function', n^.loc);
      param := f^.fields;
      n^.list.foreach(chk_arg);
      if param <> nil then
         err('not enough arguments to function call', n^.loc);
      n^.binding := n^.left^.binding;
      check_call := f^.base;
   end;

   function check_assign(): spec;
   var
      ty: spec;
      new_si: integer;
      left: node;
   begin
      left := n^.left;
      case left^.tag of
         indexed_var_node: new_si := si + 2;
         field_var_node: new_si := si + 1;
         else new_si := si + 2;
      end;
      ty := check(left, new_si, nest, env, tenv);
      if not compatible(ty, check(n^.right, new_si, nest, env, tenv)) then
         err('assignment type mismatch', n^.loc);
      if left^.tag = simple_var_node then
         begin
            if left^.binding^.constant then
               err('assignment to constant ' + n^.binding^.key^.id, n^.loc);
            left^.binding^.mutates := true;
         end;
      check_assign := void_type;
   end;

   function check_sequence(): spec;
   var
      ty: spec = nil;
      chk_expr: node_list.iter;

      procedure _chk_expr(n: node);
      begin
         ty := check(n, si, nest, env, tenv);
      end;

   begin
      chk_expr := @_chk_expr;
      n^.list.foreach(chk_expr);
      check_sequence := ty;
   end;

   function check_array(): spec;
   var
      ty: spec;
   begin
      if check(n^.left, si, nest, env, tenv) <> int_type then
         err('Array size must be an integer.', n^.loc);
      check_array := make_array_type(check(n^.right, si, nest, env, tenv));
   end;

   function check_indexed_var(): spec;
   var
      ty, ty2: spec;
   begin
      ty := check(n^.left, si, nest, env, tenv);
      if (ty^.tag <> array_type) and (ty <> string_type) then
         err('Object is not an array or string.', n^.loc);
      ty2 := check(n^.right, si + 1, nest, env, tenv);
      if (ty2 <> int_type) and (ty2 <> char_type) and (ty2^.tag <> enum_type) then
         err('Index must be a cardinal type.', n^.right^.loc);
      if ty^.tag = array_type then
         check_indexed_var := ty^.base
      else
         check_indexed_var := char_type;
   end;

   function check_for(): spec;
   var
      new_env: scope;
   begin
      new_env := add_scope(env);
      n^.binding := bind(new_env, n^.name, int_type, si + 1, nest, n^.loc);
      if check(n^.left, si + 6, nest, env, tenv) <> int_type then
         err('for start value must be integer type', n^.right^.loc);
      if check(n^.cond, si + 6, nest, env, tenv) <> int_type then
         err('for to value must be integer type', n^.cond^.loc);
      if check(n^.right, si + 6, nest, new_env, tenv) <> void_type then
         err('for body cannot return a vaule', n^.left^.loc);
      check_for := void_type;
   end;

   function check_while(): spec;
   begin
      if check(n^.cond, si, nest, env, tenv) <> bool_type then
         err('while condition is not a boolean value', n^.cond^.loc);
      if check(n^.left, si, nest, env, tenv) <> void_type then
         err('while body cannot return a value', n^.left^.loc);
      check_while := void_type;
   end;

   function check_case(): spec;
   var
      ty, ty2, ty_result: spec;
      check_clause: node_list.iter;

      procedure _check_clause(n: node);
      begin
         if check(n^.left, si, nest, env, tenv) <> ty then
            err('match must be same type as case variable', n^.left^.loc);
         ty2 := check(n^.right, si, nest, env, tenv);
         if ty_result = nil then
            ty_result := ty2
         else
            begin
               if not compatible(ty2, ty_result) then
                  err('case clauses are incompatible types', n^.right^.loc);
               ty_result := type_or_nil(ty_result, ty2);
            end;
      end;

   begin
      check_clause := @_check_clause;
      ty_result := nil;
      ty := check(n^.cond, si, nest, env, tenv);
      if (ty <> int_type) and (ty <> char_type) and (ty^.tag <> enum_type) then
         err('case variable must be a cardinal type', n^.cond^.loc);
      n^.list.foreach(check_clause);
      if n^.right <> nil then (* default clause *)
         begin
            ty2 := check(n^.right, si, nest, env, tenv);
            if not compatible(ty2, ty_result) then
               err('case default clause incompatible type', n^.right^.loc);
            ty_result := type_or_nil(ty_result, ty2);
         end;
      check_case := ty_result;
   end;

   function check_record(): spec;
   type
      field_check = ^field_check_t;
      field_check_t = record
         f: field;
         check: boolean;
         next: field_check;
      end;

   var
      checks: field_check = nil;
      fc : field_check;
      b : binding;
      ty, field_ty: spec;
      rec_type: symbol;
      f: field;
      check_field: node_list.iter;

      procedure add_check(f: field);
      var fc: field_check;
      begin
         new(fc);
         fc^.f := f;
         fc^.check := false;
         fc^.next := checks;
         checks := fc;
      end;

      function find_check(name: symbol): field_check;
      var fc: field_check;
      begin
         fc := checks;
         while fc <> nil do
            begin
               if fc^.f^.name = name then
                  break;
               fc := fc^.next
            end;
         find_check := fc;
      end;

      procedure _check_field(value: node);
      var
         name: symbol;
         loc: source_location;
      begin
         name := value^.name;
         loc := value^.loc;
         fc := find_check(name);
         if fc = nil then
            err('''' + name^.id + ''' field doesn''t exist', loc);
         if fc^.check then
            err('''' + name^.id + ''' field appears more than once.', loc);
         field_ty := check(value^.left, si + n^.list.length, nest, env, tenv);
         if compatible(field_ty, fc^.f^.ty) then
            fc^.check := true
         else
            err('''' + name^.id + ''' field is wrong type', loc);
      end;

   begin
      check_field := @_check_field;
      rec_type := n^.type_name;
      b := lookup(tenv, rec_type, n^.loc);
      ty := b^.ty;
      if ty^.tag <> record_type then
         err ('''' + rec_type^.id + ''' is not a record', n^.loc);
      f := ty^.fields;
      while f <> nil do
         begin
            add_check(f);
            f := f^.next;
         end;
      n^.list.foreach(check_field);
      fc := checks;
      while fc <> nil do
         begin
            if not fc^.check then
               err('''' + fc^.f^.name^.id + ''' field is missing from record', n^.loc);
            fc := fc^.next;
         end;
      n^.binding := b;
      check_record := ty;
   end;

   function check_field_var(): spec;
   var ty: spec;
   begin
      ty := check(n^.left, si, nest, env, tenv);
      if ty^.tag <> record_type then
         err('object is not a record.', n^.left^.loc);
      check_field_var := get_field(ty, n^.name, n^.loc)^.ty;
   end;

   function check_ordinal_op(): spec;
   var t1: spec;
   begin
      t1 := check(n^.left, si, nest, env, tenv);
      check_ordinal_op := t1;
      if ((t1 <> char_type) and (t1 <> int_type))
            or (t1 <> check(n^.right, si, nest, env, tenv)) then
         err('incompatible type for operator', n^.loc);
   end;

   function check_int_op(): spec;
   begin
      check_int_op := int_type;
      if (check(n^.left, si, nest, env, tenv) <> int_type)
         or (check(n^.right, si, nest, env, tenv) <> int_type) then
         err('incompatible type for operator', n^.right^.loc);
   end;

   function check_compare_op(): spec;
   var t1: spec;
   begin
      check_compare_op := bool_type;
      t1 := check(n^.left, si, nest, env, tenv);
      if ((t1 <> char_type) and (t1 <> int_type))
            or (t1 <> check(n^.right, si, nest, env, tenv)) then
         err('incompatible type for operator', n^.loc);
   end;

   function check_bool_op(): spec;
   begin
      check_bool_op := bool_type;
      if (check(n^.left, si, nest, env, tenv) <> bool_type)
         or (check(n^.right, si, nest, env, tenv) <> bool_type) then
         err('incompatible type for operator', n^.right^.loc);
   end;

   function check_eq_op(): spec;
   begin
      check_eq_op := bool_type;
      if not compatible(check(n^.left, si, nest, env, tenv),
                        check(n^.right, si, nest, env, tenv)) then
         err('incompatible type for operator', n^.loc);
   end;

begin
   check := void_type;
   case n^.tag of
      nil_node:
         check := nil_type;
      integer_node:
         check := int_type;
      boolean_node:
         check := bool_type;
      string_node:
         check := string_type;
      char_node:
         check := char_type;
      empty_node:
         check := void_type;
      unary_minus_node:
         check := check_unary_minus();
      plus_node, minus_node:
         check := check_ordinal_op();
      mul_node, div_node, mod_node:
         check := check_int_op();
      lt_node, leq_node, gt_node, geq_node:
         check := check_compare_op();
      and_node, or_node:
         check := check_bool_op();
      eq_node, neq_node:
         check := check_eq_op();
      let_node:
         check := check_let();
      simple_var_node:
         check := check_simple_var();
      if_else_node:
         check := check_if_else();
      if_node:
         check := check_if();
      call_node, tail_call_node:
         check := check_call();
      assign_node:
         check := check_assign();
      sequence_node:
         check := check_sequence();
      array_node:
         check := check_array();
      record_node:
         check := check_record();
      indexed_var_node:
         check := check_indexed_var();
      field_var_node:
         check := check_field_var();
      for_node:
         check := check_for();
      while_node:
         check := check_while();
      case_node:
         check := check_case();
      else
         begin
            writeln(n^.tag);
            err('check: feature not supported yet!', n^.loc);
         end;
   end;
end;

function type_check(n: node): spec;
begin
   type_check := check(n, 1, 1, add_scope(global_env), add_scope(global_tenv));
end;

end.
