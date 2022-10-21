unit semant;

interface

uses bindings, types, nodes;

function type_check(n: node; si, nest: longint; env, tenv: scope): spec;

implementation

uses utils, ops, symbols;

function type_check(n: node; si, nest: longint; env, tenv: scope): spec;

   function check_unary_op(): spec;
   begin
      { minus is the only unary op }
      if type_check(n^.expr, si, nest, env, tenv) <> int_type then
         err('sign operator incompatible type', n^.line, n^.col);
      check_unary_op := int_type;
   end;

   function check_binary_op(): spec;
   var op: op_tag; ty1, ty2: spec;
   begin
      check_binary_op := void_type;
      op := n^.op;
      ty1 := type_check(n^.expr, si + 1, nest, env, tenv);
      ty2 := type_check(n^.expr2, si, nest, env, tenv);
      if ty1 <> ty2 then
         if (ty1 <> nil_type) and (ty2 <> nil_type) then
            err('operator incompatible types', n^.line, n^.col) (* both not nil *)
         else (* one side is nil *)
            if (ty1^.tag = primitive_type) and (ty2^.tag = primitive_type) then
               (* both primitive but not both nil *)
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


   procedure check_var_decl(n: node; si, offset: longint; env, tenv: scope);
   var
      ty1, ty2: spec;
   begin
      ty1 := type_check(n^.expr, si, nest, env, tenv);
      if ty1 = void_type then
         err(n^.name^.id + ' variable initializer doesn''t produce a value', n^.expr^.line, n^.expr^.col);

      if n^.type_name = nil then
         begin
            if ty1 = nil_type then
               err('variable with nil initializer needs explicit type', n^.line, n^.col);
         end
      else
         begin
            ty2 := lookup(tenv, n^.type_name, n^.line, n^.col)^.ty;
            if ty1 = nil_type then begin
               if ty2^.tag = primitive_type then
                  err(n^.type_name^.id + ' type can''t be nil', n^.line, n^.col)
               else ty1 := ty2;
            end
            else
               if ty1 <> ty2 then
                  err('initializer doesn''t match type spec', n^.line, n^.col);
         end;
      n^.binding := bind(env, n^.name, ty1, offset, nest, n^.line, n^.col);
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


   procedure check_fun_body(n: node; si: longint; env, tenv: scope);
   var
      ty, body_type: spec;
   begin
      ty := lookup(env, n^.name, n^.line, n^.col)^.ty;
      if n^.expr <> nil then begin
         body_type := type_check(n^.expr, si, nest + 1, n^.env, tenv);
         if ty^.base <> body_type then
            err('function return type doesn''t match declaration', n^.line, n^.col);
      end;
   end;


   procedure check_type_decl(n: node; tenv: scope);
   var
      ty: spec = nil;
      tyspec: node;
   begin
      tyspec := n^.expr;
      case tyspec^.tag of
         array_desc_node:
            ty := make_array_type(lookup(tenv, tyspec^.type_name, tyspec^.line, tyspec^.col)^.ty);
         record_desc_node: begin
            ty := make_record_type();
         end;
      end;

      bind(tenv, n^.name, ty, 0, 0, n^.line, n^.col);
   end;


   procedure check_record_body(n: node; tenv: scope);
   var
      it: node_list_item;
      fld: node;
      offset, line, col: longint;
      ty, fld_ty: spec;
   begin
      offset := 0;
      ty := lookup(tenv, n^.name, n^.line, n^.col)^.ty;
      it := n^.expr^.list^.first;
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
   var
      it: node_list_item;
      has_var_decls: boolean = false;
      has_type_decls: boolean = false;
      has_fun_decls: boolean = false;
      new_env, new_tenv: scope;
      stack_index, offset: longint;
      type_decls: node_list = nil;
      fun_decls: node_list = nil;

   begin
      stack_index := si;
      it := n^.list^.first;
      while it <> nil do begin
         case it^.node^.tag of
            var_decl_node: begin
               stack_index := stack_index + 1;
               has_var_decls := true;
            end;
            fun_decl_node: has_fun_decls := true;
            type_decl_node: has_type_decls := true;
         end;
         it := it^.next;
      end;

      if has_type_decls then begin
         new_tenv := add_scope(tenv);
         type_decls := make_list();
      end
      else
         new_tenv := tenv;

      if has_fun_decls then
         fun_decls := make_list();

      if has_var_decls or has_fun_decls then
         new_env := add_scope(env)
      else
         new_env := env;

      it := n^.list^.first;
      while it <> nil do begin
         case it^.node^.tag of
            fun_decl_node: append(fun_decls, it^.node);
            type_decl_node: append(type_decls, it^.node);
         end;
         it := it^.next;
      end;

      if has_type_decls then begin
         it := type_decls^.first;
         while it <> nil do begin
            check_type_decl(it^.node, new_tenv);
            it := it^.next
         end;
         it := type_decls^.first;
         while it <> nil do begin
            if it^.node^.expr^.tag = record_desc_node then
               check_record_body(it^.node, new_tenv);
            it := it^.next
         end;
      end;

      offset := si;
      if has_fun_decls or has_var_decls then begin
         it := n^.list^.first;
         while it <> nil do begin
            case it^.node^.tag of
               fun_decl_node:
                  check_fun_decl(it^.node, stack_index, new_env, new_tenv);
               var_decl_node: begin
                  check_var_decl(it^.node, stack_index, offset, new_env, new_tenv);
                  offset := offset + 1;
               end;
            end;
            it := it^.next;
         end;
      end;

      if has_fun_decls then begin
         it := fun_decls^.first;
         while it <> nil do begin
            check_fun_body(it^.node, stack_index, new_env, new_tenv);
            it := it^.next
         end;
      end;

      new_env^.stack_index := stack_index;
      n^.env := new_env;
      check_let := type_check(n^.expr, stack_index, nest, new_env, new_tenv);
   end;


   function check_simple_var(): spec;
   var b: binding;
   begin
      b := lookup(env, n^.name, n^.line, n^.col);
      n^.binding := b;
      check_simple_var := b^.ty;
   end;


   function check_if_else(): spec;
   var ty: spec;
   begin
      if type_check(n^.cond, si, nest, env, tenv) <> bool_type then
         err('if condition is not a boolean value', n^.line, n^.col);
      ty := type_check(n^.expr, si, nest, env, tenv);
      if ty <> type_check(n^.expr2, si, nest, env, tenv) then
         err('if and else clauses incompatible types', n^.line, n^.col);
      check_if_else := ty;
   end;


   function check_if(): spec;
   begin
      if type_check(n^.cond, si, nest, env, tenv) <> bool_type then
         err('if condition is not a boolean value', n^.line, n^.col);
      if type_check(n^.expr, si, nest, env, tenv) <> void_type then
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
   begin
      if n^.expr2^.tag = indexed_var_node then
         new_si := si + 2
      else
         new_si := si;
      ty := type_check(n^.expr2, new_si, nest, env, tenv);
      if ty <> type_check(n^.expr, new_si, nest, env, tenv) then
         err('assignment type mismatch', n^.line, n^.col);
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
      if type_check(n^.expr2, si, nest, env, tenv) <> int_type then
         err('Array size must be an integer.', n^.line, n^.col);
      base := ty1^.base;
      ty2 := type_check(n^.expr, si, nest, env, tenv);
      if ty2 = nil_type then begin
         if base^.tag = primitive_type then
            err(ty_name + ' array type can''t have nil values.', n^.line, n^.col);
      end
      else
         if ty2 <> base then
            err(ty_name + ' array initializer is the wrong type.', n^.line, n^.col);
      check_array := ty1;
   end;


   function check_indexed_var(): spec;
   var
      ty: spec;
   begin
      ty := type_check(n^.expr2, si, nest, env, tenv);
      if ty^.tag <> array_type then
         err('Object is not an array.', n^.expr2^.line, n^.expr2^.col);
      if type_check(n^.expr, si + 1, nest, env, tenv) <> int_type then
         err('Array index must be an integer.', n^.expr^.line, n^.expr^.col);
      check_indexed_var := ty^.base;
   end;


   function check_for(): spec;
   var
      new_env: scope;
   begin
      new_env := add_scope(env);
      n^.binding := bind(new_env, n^.name, int_type, si + 1, nest, n^.line, n^.col);
      if type_check(n^.expr2, si + 6, nest, env, tenv) <> int_type then
         err('for start value must be integer type', n^.expr2^.line, n^.expr2^.col);
      if type_check(n^.cond, si + 6, nest, env, tenv) <> int_type then
         err('for to value must be integer type', n^.cond^.line, n^.cond^.col);
      if type_check(n^.expr, si + 6, nest, new_env, tenv) <> void_type then
         err('for body cannot return a vaule', n^.expr^.line, n^.expr^.col);
      check_for := void_type;
   end;


   function check_while(): spec;
   begin
      if type_check(n^.cond, si, nest, env, tenv) <> bool_type then
         err('while condition is not a boolean value', n^.cond^.line, n^.cond^.col);
      if type_check(n^.expr, si, nest, env, tenv) <> void_type then
         err('while body cannot return a value', n^.expr^.line, n^.expr^.col);
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
            err(name^.id + ' field doesn''t exist', value^.line, value ^.col);
         if fc^.check then
            err(name^.id + ' field appears more than once.', value^.line, value^.col);
         field_ty := type_check(value^.expr, si, nest, env, tenv);
         if field_ty = fc^.f^.ty then
            fc^.check := true
         else
            err(name^.id + ' field is wrong type', value^.line, value^.col);
         it  := it^.next;
      end;

      fc := checks;
      while fc <> nil do begin
         if not fc^.check then
            err(fc^.f^.name^.id + ' field is missing from record', n^.line, n^.col);
         fc := fc^.next;
      end;

      n^.binding := b;

      check_record := ty;

   end;
(*
   function check_field_var(): spec;
   var ty: spec;
   begin
      ty := type_check(n^.expr, si, nest, env, tenv);
      if ty^.tag <> record_type then
         err('object is not a record.', n^.expr^.line, n^.expr^.col);
      check_field_var := get_field(ty, n^.name, n^.line, n^.col);
   end;

*)
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
      call_node:
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
      for_node:
         type_check := check_for();
      while_node:
         type_check := check_while();
      else begin
         writeln(n^.tag);
         err('type_check: feature not supported yet!', n^.line, n^.col);
      end;
(*
      field_var_node:
         type_check := check_field_var();
      field_node:
         format := n^.name^.id + ' = ' + format(n^.expr);
      else begin
         str(n^.tag, s);
         format := '???? ' + s + ' ????';
      end;
      *)
   end;
end;

end.
