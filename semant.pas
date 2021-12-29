unit semant;

interface

uses bindings, types, nodes;

function type_check(n: node; env, tenv: frame): spec;

implementation

uses utils, ops, symbols;

function type_check(n: node; env, tenv: frame): spec;

   function check_assign(): spec;
   var ty: spec;
   begin
      ty := type_check(n^.variable, env, tenv);
      if ty <> type_check(n^.expression, env, tenv) then
         err('assignment type mismatch', n^.line, n^.col);
      check_assign := ty;
   end;

   function check_type_decl(): spec;
   var
      ty, field_ty: spec;
      tyspec, field: node;
      it: node_list_item;
      line, col: longint;
   begin
      tyspec := n^.type_spec;
      case n^.type_spec^.tag of
         array_desc_node:
            ty := make_array_type(lookup(tenv, tyspec^.base,tyspec^.line, tyspec^.col));
         record_desc_node: begin
            ty := make_record_type(nil);
            it := tyspec^.field_list^.first;
            while it <> nil do
               begin
                  field := it^.node;
                  line := field^.line;
                  col := field^.col;
                  field_ty := lookup(tenv, field^.field_type, line, col);
                  add_field(ty, field^.field_desc_name, field_ty, line, col);
                  it := it^.next;
               end;
            end;
      end;
      bind(tenv, n^.type_name, ty, n^.line, n^.col);
      check_type_decl := void_type;
   end;

   function check_var_decl(): spec;
   var ty1, ty2: spec;
   begin
      ty1 := type_check(n^.initial_value, env, tenv);
      if n^.var_type = nil then
         begin
            if ty1 = nil_type then
               err('variable with nil initializer needs explicit type', n^.line, n^.col);
         end
      else
         begin
            ty2 := lookup(tenv, n^.var_type, n^.line, n^.col);
            if ty1 <> ty2 then
               err('initializer doesn''t match type spec', n^.line, n^.col);
         end;
      bind(env, n^.var_name, ty1, n^.line, n^.col);
      check_var_decl := void_type;
   end;

   function check_unary_op(): spec;
   begin
      { minus is the only unary op }
      if type_check(n^.unary_exp, env, tenv) <> int_type then
         err('sign operator incompatible type', n^.line, n^.col);
      check_unary_op := int_type;
   end;

   function check_binary_op(): spec;
      var op: op_tag; ty1, ty2: spec;
   begin
      op := n^.binary_op;
      ty1 := type_check(n^.left, env, tenv);
      ty2 := type_check(n^.right, env, tenv);
      if ty1 <> ty2 then
         err('operator incompatible types', n^.line, n^.col);
      if op in numeric_ops then
         if ty1 = int_type then
            check_binary_op := int_type
         else
            err('numeric operator incompatible type', n^.line, n^.col)
      else if op in comparison_ops then
         if (ty1 = int_type) or (ty1 = string_type) then
            check_binary_op := bool_type
         else
            err('comparison operator incompatible type', n^.line, n^.col)
      else if op in boolean_ops then
         if ty1 = bool_type then
            check_binary_op := bool_type
         else
            err('boolean operator incompatible type', n^.line, n^.col)
      else
         check_binary_op := bool_type { equality_ops }
   end;

   function check_if_else(): spec;
   var ty: spec;
   begin
      if type_check(n^.if_else_condition, env, tenv) <> bool_type then
         err('if condition is not a boolean value', n^.line, n^.col);
      ty := type_check(n^.if_else_consequent, env, tenv);
      if ty <> type_check(n^.if_else_alternative, env, tenv) then
         err('if and else clauses incompatible types', n^.line, n^.col);
      check_if_else := ty;
   end;

   function check_if(): spec;
   begin
      if type_check(n^.if_condition, env, tenv) <> bool_type then
         err('if condition is not a boolean value', n^.line, n^.col);
      if type_check(n^.if_consequent, env, tenv) <> void_type then
         err('if clause without else cannot return a value', n^.line, n^.col);
      check_if := void_type;
   end;

   function check_while(): spec;
   begin
      if type_check(n^.while_condition, env, tenv) <> bool_type then
         err('while condition is not a boolean value', n^.while_condition^.line, n^.while_condition^.col);
      if type_check(n^.while_body, env, tenv) <> void_type then
         err('while expression cannot return a value', n^.while_body^.line, n^.while_body^.col);
      check_while := void_type;
   end;

   function check_for(): spec;
   begin
      bind(env, n^.iter, int_type, n^.line, n^.col);
      if type_check(n^.start, env, tenv) <> int_type then
         err('for start value must be integer type', n^.start^.line, n^.start^.col);
      if type_check(n^.finish, env, tenv) <> int_type then
         err('for to value must be integer type', n^.finish^.line, n^.finish^.col);
      if type_check(n^.for_body, env, tenv) <> void_type then
         err('for body cannot return a vaule', n^.for_body^.line, n^.for_body^.col);
      check_for := void_type;
   end;

   function check_fun_decl(): spec;
   var
      ty, body_type, param_type: spec;
      fenv: frame;
      it: node_list_item;
      param: node;
      key: symbol;
      line, col: longint;
   begin
      ty := make_function_type(nil, nil);
      ty^.base := lookup(tenv, n^.return_type, n^.line, n^.col);

      fenv := add_frame(env);
      it := n^.params^.first;
      while it <> nil do
         begin
            param := it^.node;
            key := param^.field_desc_name;
            line := param^.line;
            col := param^.col;
            param_type := lookup(tenv, param^.field_type, line, col);
            add_field(ty, key, param_type, line, col);
            bind(fenv, key, param_type, line, col);
            it := it^.next;
         end;

      bind(env, n^.fun_name, ty, n^.line, n^.col);
      body_type := type_check(n^.fun_body, fenv, tenv);
      if ty^.base <> body_type then
         err('function return type doesn''t match declaration', n^.line, n^.col);
      check_fun_decl := void_type;
   end;

   function check_call(): spec;
   var
      fname: string;
      f: spec;
      it: node_list_item;
      arg: node;
      param: field;
   begin
      fname := '''' + n^.call^.id + '''';
      f := lookup(env, n^.call, n^.line, n^.col);
      if f^.tag <> function_type then
         err(fname + ' is not a function', n^.line, n^.col);
      it := n^.args^.first;
      param := f^.fields;
      while it <> nil do
         begin
            if param = nil then
               err('too many arguments to ' + fname, n^.line, n^.col);
            arg := it^.node;
            if type_check(arg, env, tenv) <> param^.ty then
               err('argument is wrong type', arg^.line, arg^.col);
            param := param^.next;
            it := it^.next;
         end;
      if param <> nil then
         err('not enough arguments to ' + fname, n^.line, n^.col);
      check_call := f^.base;
   end;

   function check_field_var(): spec;
   var ty: spec;
   begin
      ty := type_check(n^.obj, env, tenv);
      if ty^.tag <> record_type then
         err('object is not a record.', n^.obj^.line, n^.obj^.col);
      check_field_var := get_field(ty, n^.field, n^.line, n^.col);
   end;

   function check_indexed_var(): spec;
   var ty: spec;
   begin
      ty := type_check(n^.arr, env, tenv);
      if ty^.tag <> array_type then
         err('object is not an array.', n^.arr^.line, n^.arr^.col);
      check_indexed_var := ty^.base;
   end;

   function check_record(): spec;
   type
      field_check = record
         f: field;
         check: boolean;
         next: ^field_check;
      end;

   var
      checks: ^field_check = nil;
      ty: spec;
      rec_type: symbol;
      f: field;

      procedure add_check(f: field);
      var fc: ^field_check;
      begin
         new(fc);
         fc^.field := f;
         fc^.check := False;
         fc^.next := checks;
         checks := fc;
      end;

   begin
      rec_type := n^.record_type;
      ty := lookup(tenv, rec_type, n^.line, n^.col);
      if ty.tag <> record_type then
         err ('''' + rec_type^.id + ''' is not a record');
      f := ty.fields;
      while f <> nil do
         begin
            add_check(f);
            f := f.next;
         end;
      
      
         
         format := n^.record_type^.id + ' {' + format_list(n^.fields, ',', true) + newline + '}';
   end;

begin
   case n^.tag of
      assign_node:
         type_check := check_assign();
      simple_var_node:
         type_check := lookup(env, n^.name, n^.line, n^.col);
      integer_node:
         type_check := int_type;
      string_node:
         type_check := string_type;
      boolean_node:
         type_check := bool_type;
      nil_node:
         type_check := nil_type;
      type_decl_node:
         type_check := check_type_decl();
      var_decl_node:
         type_check := check_var_decl();
      unary_op_node:
         type_check := check_unary_op();
      binary_op_node:
         type_check := check_binary_op();
      if_else_node:
         type_check := check_if_else();
      if_node:
         type_check := check_if();
      while_node:
         type_check := check_while();
      for_node:
         type_check := check_for();
      fun_decl_node:
         type_check := check_fun_decl();
      call_node:
         type_check := check_call();
      field_var_node:
         type_check := check_field_var();
      indexed_var_node:
         type_check := check_indexed_var();
(*
      field_node:
         format := n^.field_name^.id + ' = ' + format(n^.field_value);
*)

(*

      let_node:
         format := 'let' + format_list(n^.decls, '', true) + newline + 'in ' + format(n^.let_body);
      sequence_node:
         format := '(' + format_list(n^.sequence, ';', true) + newline + ')';
      record_node:
         format := n^.record_type^.id + ' {' + format_list(n^.fields, ',', true) + newline + '}';
      array_node:
         format := n^.array_type^.id + '[' + format(n^.size) + '] of ' + format(n^.default_value);
      else begin
         str(n^.tag, s);
         format := '???? ' + s + ' ????';
      end;
      *)
   end;
end;

end.
