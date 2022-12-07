unit semant;

interface

uses bindings, datatypes, nodes;

function type_check(n: node; si, nest: longint; env, tenv: scope): spec;

implementation

uses utils, ops, symbols;

function type_check(n: node; si, nest: longint; env, tenv: scope): spec;


   function compatible(a, b: spec): boolean;
   begin
      compatible := (a = b) or
                    ((b = nil_type) and (a^.tag <> primitive_type)) or
                    ((a = nil_type) and (b^.tag <> primitive_type));
   end;


   function check_unary_op(): spec;
   begin
      { minus is the only unary op }
      if type_check(n^.left, si, nest, env, tenv) <> int_type then
         err('sign operator incompatible type', n^.line, n^.col);
      check_unary_op := int_type;
   end;


   function check_binary_op(): spec;
   var op: op_tag; ty1, ty2: spec;
   begin
      check_binary_op := void_type;
      op := n^.op;
      ty1 := type_check(n^.left, si + 1, nest, env, tenv);
      ty2 := type_check(n^.right, si, nest, env, tenv);
      if not compatible(ty1, ty2) then
         err('operator incompatible types', n^.line, n^.col);

      if (op in numeric_ops) and (ty1 = int_type) then
         check_binary_op := int_type
      else if (op in char_ops) and (ty1 = char_type) then
         check_binary_op := char_type
      else if (op in comparison_ops) and
              ((ty1 = int_type) or (ty1 = char_type)) then
         check_binary_op := bool_type
      else if (op in boolean_ops) and (ty1 = bool_type) then
         check_binary_op := bool_type
      else if op in equality_ops then
         check_binary_op := bool_type
      else
         err('incompatible types for operator ''' + op_display[op] + '''', n^.line, n^.col);
   end;


   procedure check_var_decl(n: node; si, offset: longint; env, tenv: scope);
   var
      ty1, ty2: spec;
      b: binding;
      right: node;
      line, col: longint;
   begin
      right := n^.right;
      line := n^.line;
      col := n^.col;
      ty1 := type_check(right, si, nest, env, tenv);
      ty2 := nil;
      if ty1 = void_type then
         err(n^.name^.id + ' variable initializer doesn''t produce a value', right^.line, right^.col);

      if (n^.type_name = nil) then
         if  (ty1 = nil_type) then
            err('variable with nil initializer needs explicit type', line, col)
         else
            ty2 := ty1
      else
         ty2 := lookup(tenv, n^.type_name, line, col)^.ty;

      if not compatible(ty1, ty2) then
         err('initializer doesn''t match type spec', line, col);

      b := bind(env, n^.name, ty2, offset, nest, line, col);

      if  right^.tag in [integer_node, char_node, string_node, boolean_node] then
         begin
            b^.const_value := true;
            case right^.tag of
               integer_node, char_node: b^.int_val := right^.int_val;
               string_node: b^.string_val := right^.string_val;
               boolean_node: b^.bool_val := right^.bool_val;
            end;
         end;
      n^.binding := b;
   end;


   procedure check_fun_decl(n: node; si: longint; env, tenv: scope);
   var
      ty, param_type, return_type: spec;
      fenv: scope;
      it: node_list_item;
      param: node;
      key: symbol;
      stack_index, line, col: longint;
   begin
      if n^.type_name = nil then
         return_type := void_type
      else
         return_type := lookup(tenv, n^.type_name, n^.line, n^.col)^.ty;

      ty := make_function_type(return_type);
      fenv := add_scope(env);
      it := n^.list^.first;
      stack_index := -2; { args go up from sp; leave space for link address and return address }
      while it <> nil do begin
         param := it^.node;
         key := param^.name;
         line := param^.line;
         col := param^.col;
         param_type := lookup(tenv, param^.type_name, line, col)^.ty;
         add_param(ty, key, param_type, line, col);
         bind(fenv, key, param_type, stack_index, nest + 1, line, col);
         it := it^.next;
         stack_index := stack_index - 1;
      end;
      n^.env := fenv;
      n^.binding := bind(env, n^.name, ty, si, nest, n^.line, n^.col);
   end;


   procedure find_tail_calls(n: node);
   begin
      case n^.tag of
         call_node:
            n^.tag := tail_call_node;
         if_node:
            find_tail_calls(n^.left);
         if_else_node: begin
            find_tail_calls(n^.left);
            find_tail_calls(n^.right);
         end;
         sequence_node:
            if n^.list^.last <> nil then
               find_tail_calls(n^.list^.last^.node);
         let_node:
            find_tail_calls(n^.right);
      end;
   end;


   procedure check_fun_body(n: node; si: longint; env, tenv: scope);
   var
      ty, body_type: spec;
   begin
      ty := n^.binding^.ty;
      if n^.right <> nil then begin
         body_type := type_check(n^.right, si, nest + 1, n^.env, tenv);
         if not compatible(ty^.base, body_type) then
            err('function return type doesn''t match declaration', n^.line, n^.col);
         find_tail_calls(n^.right);
      end;
   end;


   procedure check_type_decl(n: node; tenv: scope);
   var
      ty: spec = nil;
      tyspec: node;
   begin
      tyspec := n^.right;
      case tyspec^.tag of
         array_desc_node:
            ty := make_array_type(lookup(tenv, tyspec^.type_name, tyspec^.line, tyspec^.col)^.ty);
         record_desc_node: begin
            ty := make_record_type();
         end;
      end;

      n^.binding := bind(tenv, n^.name, ty, 0, 0, n^.line, n^.col);
   end;


   procedure check_record_decl_body(n: node; tenv: scope);
   var
      it: node_list_item;
      fld: node;
      offset, line, col: longint;
      ty, fld_ty: spec;
   begin
      offset := 0;
      ty := n^.binding^.ty;
      it := n^.right^.list^.first;
      while it <> nil do begin
         fld := it^.node;
         line := fld^.line;
         col := fld^.col;
         fld_ty := lookup(tenv, fld^.type_name, line, col)^.ty;
         add_field(ty, fld^.name, fld_ty, offset, line, col);
         offset := offset + 1;
         it := it^.next;
      end;
   end;


   function check_let(): spec;
      type
         state_tag = (var_state, fun_state, type_state);

      var
         state: state_tag;
         group: node_list = nil;
         it: node_list_item;
         new_env, new_tenv: scope;
         stack_index, offset: longint;

      procedure dispose_group();
      var
         it, next: node_list_item;
      begin
         it := group^.first;
         while it <> nil do begin
            next := it^.next;
            dispose(it);
            it := next;
         end;
         dispose(group);
         group := nil;
      end;

      procedure update_state(new_state: state_tag);
      var
         it: node_list_item;
      begin
         case state of
            var_state:
               if new_state <> var_state then
                  group := make_list();

            fun_state:
               if new_state <> fun_state then begin
                  it := group^.first;
                  while it <> nil do begin
                     check_fun_body(it^.node, stack_index, new_env, new_tenv);
                     it := it^.next;
                  end;
                  dispose_group();
                  if new_state = type_state then
                     group := make_list();
               end;

            type_state:
               if new_state <> type_state then begin
                  it := group^.first;
                  while it <> nil do begin
                     if it^.node^.right^.tag = record_desc_node then
                        check_record_decl_body(it^.node, new_tenv);
                     it := it^.next
                  end;
                  dispose_group();
                  if new_state = fun_state then
                     group := make_list();
               end;
         end;
         state := new_state;
      end;

   begin
      state := var_state;
      offset := si;
      stack_index := si;

      it := n^.list^.first;
      while it <> nil do begin
         if it^.node^.tag = var_decl_node then
            stack_index := stack_index + 1;
         it := it^.next;
      end;

      new_tenv := add_scope(tenv);
      new_env := add_scope(env);

      it := n^.list^.first;
      while it <> nil do begin
         case it^.node^.tag of
            var_decl_node: begin
               update_state(var_state);
               check_var_decl(it^.node, stack_index, offset, new_env, new_tenv);
               offset := offset + 1;
            end;

            fun_decl_node: begin
               update_state(fun_state);
               check_fun_decl(it^.node, stack_index, new_env, new_tenv);
               append(group, it^.node);
            end;

            type_decl_node: begin
               update_state(type_state);
               check_type_decl(it^.node, new_tenv);
               append(group, it^.node);
            end;
         end;
         it := it^.next;
      end;
      update_state(var_state);

      new_env^.stack_index := stack_index;
      n^.env := new_env;
      n^.tenv := new_tenv;
      check_let := type_check(n^.right, stack_index, nest, new_env, new_tenv);
   end;


   function check_simple_var(): spec;
   var b: binding;
   begin
      b := lookup(env, n^.name, n^.line, n^.col);
      n^.binding := b;
      if b^.nesting_level <> nest then
         b^.escapes := true;
      check_simple_var := b^.ty;
   end;


   function check_if_else(): spec;
   var ty: spec;
   begin
      if type_check(n^.cond, si, nest, env, tenv) <> bool_type then
         err('if condition is not a boolean value', n^.line, n^.col);
      ty := type_check(n^.left, si, nest, env, tenv);
      if not compatible(ty, type_check(n^.right, si, nest, env, tenv)) then
         err('if and else clauses incompatible types', n^.line, n^.col);
      check_if_else := ty;
   end;


   function check_if(): spec;
   begin
      if type_check(n^.cond, si, nest, env, tenv) <> bool_type then
         err('if condition is not a boolean value', n^.line, n^.col);
      if type_check(n^.left, si, nest, env, tenv) <> void_type then
         err('if without else cannot return a value', n^.line, n^.col);
      check_if := void_type;
   end;


   function check_call(): spec;
   var
      fname: string;
      b: binding;
      f: spec;
      it: node_list_item;
      arg: node;
      param: field;
   begin
      fname := '''' + n^.name^.id + '''';
      b := lookup(env, n^.name, n^.line, n^.col);
      f := b^.ty;
      if f^.tag <> function_type then
         err(fname + ' is not a function', n^.line, n^.col);
      it := n^.list^.first;
      param := f^.fields;
      while it <> nil do
         begin
            if param = nil then
               err('too many arguments to ' + fname, n^.line, n^.col);
            arg := it^.node;
            if type_check(arg, si, nest, env, tenv) <> param^.ty then
               err('argument is wrong type', arg^.line, arg^.col);
            param := param^.next;
            it := it^.next;
         end;
      if param <> nil then
         err('not enough arguments to ' + fname, n^.line, n^.col);
      n^.binding := b;
      check_call := f^.base;
   end;


   function check_assign(): spec;
   var
      ty: spec;
      new_si: longint;
      left: node;
   begin
      left := n^.left;
      case left^.tag of
         indexed_var_node: new_si := si + 2;
         field_var_node: new_si := si + 1;
         else new_si := si + 2;
      end;
      ty := type_check(left, new_si, nest, env, tenv);
      if not compatible(ty, type_check(n^.right, new_si, nest, env, tenv)) then
         err('assignment type mismatch', n^.line, n^.col);
      if left^.tag = simple_var_node then
         left^.binding^.mutates := true;
      check_assign := void_type;
   end;


   function check_sequence(): spec;
   var
      ty: spec;
      it: node_list_item;
   begin
      it := n^.list^.first;
      while it <> nil do begin
         ty := type_check(it^.node, si, nest, env, tenv);
         it := it^.next;
      end;
      check_sequence := ty;
   end;


   function check_array(): spec;
   var
      ty1, base, ty2: spec;
      ty_name: string;
   begin
      ty1 := lookup(tenv, n^.type_name, n^.line, n^.col)^.ty;
      ty_name := n^.type_name^.id;
      if ty1^.tag <> array_type then
         err(ty_name + ' isn''t an array type.', n^.line, n^.col);
      if type_check(n^.left, si, nest, env, tenv) <> int_type then
         err('Array size must be an integer.', n^.line, n^.col);
      base := ty1^.base;
      ty2 := type_check(n^.right, si, nest, env, tenv);
      if not compatible(ty2, base) then
         err(ty_name + ' array initializer is the wrong type.', n^.line, n^.col);
      check_array := ty1;
   end;


   function check_indexed_var(): spec;
   var
      ty: spec;
   begin
      ty := type_check(n^.left, si, nest, env, tenv);
      if (ty^.tag <> array_type) and (ty <> string_type) then
         err('Object is not an array or string.', n^.line, n^.col);
      if type_check(n^.right, si + 1, nest, env, tenv) <> int_type then
         err('Index must be an integer.', n^.right^.line, n^.right^.col);
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
      n^.binding := bind(new_env, n^.name, int_type, si + 1, nest, n^.line, n^.col);
      if type_check(n^.left, si + 6, nest, env, tenv) <> int_type then
         err('for start value must be integer type', n^.right^.line, n^.right^.col);
      if type_check(n^.cond, si + 6, nest, env, tenv) <> int_type then
         err('for to value must be integer type', n^.cond^.line, n^.cond^.col);
      if type_check(n^.right, si + 6, nest, new_env, tenv) <> void_type then
         err('for body cannot return a vaule', n^.left^.line, n^.left^.col);
      check_for := void_type;
   end;


   function check_while(): spec;
   begin
      if type_check(n^.cond, si, nest, env, tenv) <> bool_type then
         err('while condition is not a boolean value', n^.cond^.line, n^.cond^.col);
      if type_check(n^.left, si, nest, env, tenv) <> void_type then
         err('while body cannot return a value', n^.left^.line, n^.left^.col);
      check_while := void_type;
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
      it: node_list_item;
      value: node;
      name: symbol;

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
         while fc <> nil do begin
            if fc^.f^.name = name then
               break;
            fc := fc^.next
         end;
         find_check := fc;
      end;


   begin
      rec_type := n^.type_name;
      b := lookup(tenv, rec_type, n^.line, n^.col);
      ty := b^.ty;
      if ty^.tag <> record_type then
         err ('''' + rec_type^.id + ''' is not a record', n^.line, n^.col);
      f := ty^.fields;
      while f <> nil do begin
         add_check(f);
         f := f^.next;
      end;

      it := n^.list^.first;
      while it <> nil do begin
         value := it^.node;
         name := value^.name;
         fc := find_check(name);
         if fc = nil then
            err('''' + name^.id + ''' field doesn''t exist', value^.line, value ^.col);
         if fc^.check then
            err('''' + name^.id + ''' field appears more than once.', value^.line, value^.col);
         field_ty := type_check(value^.left, si + n^.list^.length, nest, env, tenv);
         if compatible(field_ty, fc^.f^.ty) then
            fc^.check := true
         else
            err('''' + name^.id + ''' field is wrong type', value^.line, value^.col);
         it  := it^.next;
      end;

      fc := checks;
      while fc <> nil do begin
         if not fc^.check then
            err('''' + fc^.f^.name^.id + ''' field is missing from record', n^.line, n^.col);
         fc := fc^.next;
      end;

      n^.binding := b;
      check_record := ty;
   end;

   function check_field_var(): spec;
   var ty: spec;
   begin
      ty := type_check(n^.left, si, nest, env, tenv);
      if ty^.tag <> record_type then
         err('object is not a record.', n^.left^.line, n^.left^.col);
      check_field_var := get_field(ty, n^.name, n^.line, n^.col)^.ty;
   end;

begin
   type_check := void_type;
   case n^.tag of
      nil_node:
         type_check := nil_type;
      integer_node:
         type_check := int_type;
      boolean_node:
         type_check := bool_type;
      string_node:
         type_check := string_type;
      char_node:
         type_check := char_type;
      empty_node:
         type_check := void_type;
      unary_op_node:
         type_check := check_unary_op();
      binary_op_node:
         type_check := check_binary_op();
      let_node:
         type_check := check_let();
      simple_var_node:
         type_check := check_simple_var();
      if_else_node:
         type_check := check_if_else();
      if_node:
         type_check := check_if();
      call_node, tail_call_node:
         type_check := check_call();
      assign_node:
         type_check := check_assign();
      sequence_node:
         type_check := check_sequence();
      array_node:
         type_check := check_array();
      record_node:
         type_check := check_record();
      indexed_var_node:
         type_check := check_indexed_var();
      field_var_node:
         type_check := check_field_var();
      for_node:
         type_check := check_for();
      while_node:
         type_check := check_while();
      else begin
         writeln(n^.tag);
         err('type_check: feature not supported yet!', n^.line, n^.col);
      end;
   end;
end;

end.
