unit semant;

interface

uses bindings, types, nodes;

function type_check(n: node; env, tenv: binding): spec;

implementation

uses utils, ops;

function type_check(n: node; env, tenv: binding): spec;
var ty1, ty2 : spec; op: op_tag;
begin
   case n^.tag of
      assign_node: begin
         ty1 := type_check(n^.variable, env, tenv);
         if ty1 <> type_check(n^.expression, env, tenv) then
            err('assignment type mismatch', n^.line, n^.col);
         type_check := ty1;
      end;
{      
      call_node:
         format :=  n^.call^.id + '(' + format_list(n^.args, ', ', false) + ')';
}
      simple_var_node:
         type_check := lookup(env, n^.name);
{

      field_var_node:
         format := format(n^.obj) + '.' + n^.field^.id;
      indexed_var_node:
         format := format(n^.arr) + '[' + format(n^.index) + ']';
}
      integer_node:
         type_check := int_type;

      string_node:
         type_check := string_type;

      boolean_node:
         type_check := bool_type;

      nil_node:
         type_check := nil_type;
{
      type_decl_node:
         format := newline + 'type ' + n^.type_name^.id + ' = ' + format(n^.type_spec);
}
      var_decl_node: begin
         ty1 := type_check(n^.initial_value, env, tenv);
         if n^.var_type = nil then
            begin
               if ty1 = nil_type then
                  err('variable with nil initializer needs explicit type', n^.line, n^.col);
            end
         else
            begin
               ty2 := lookup(tenv, n^.var_type);
               if ty1 <> ty2 then
                  err('initializer doesn''t match type spec', n^.line, n^.col);
            end;
         bind(env, n^.var_name, ty1);
         type_check := void_type;
      end;
(*
      fun_decl_node: begin
         s := newline + 'function ' + n^.fun_name^.id + 
              '(' + format_list(n^.params, ', ', false) + ')';
         if n^.return_type <> nil then
            s := s + ': ' + n^.return_type^.id;
         s := s + ' = ';
         indent;
         s := s + newline + format(n^.fun_body);
         dedent;
         format := s;
      end;
      record_desc_node:
         format := '{' + format_list(n^.field_list, ',', true) + newline + '}';
      array_desc_node:
         format := 'array of ' + n^.base^.id;
*)         
      unary_op_node: begin
         { minus is the only unary op }
         if type_check(n^.unary_exp, env, tenv) <> int_type then
            err('sign operator incompatible type', n^.line, n^.col);
         type_check := int_type;
      end;

      binary_op_node: begin
         op := n^.binary_op;
         ty1 := type_check(n^.left, env, tenv);
         ty2 := type_check(n^.right, env, tenv);
         if ty1 <> ty2 then
            err('operator incompatible types', n^.line, n^.col);
         if op in numeric_ops then
            if ty1 = int_type then
               type_check := int_type
            else
               err('numeric operator incompatible type', n^.line, n^.col)
         else if op in comparison_ops then
            if (ty1 = int_type) or (ty1 = string_type) then
               type_check := bool_type
            else
               err('comparison operator incompatible type', n^.line, n^.col)
         else if op in boolean_ops then
            if ty1 = bool_type then
               type_check := bool_type
            else
               err('boolean operator incompatible type', n^.line, n^.col)
         else
            type_check := bool_type { equality_ops }
      end;
(*
      field_node:
         format := n^.field_name^.id + ' = ' + format(n^.field_value);
      field_desc_node:
         format := n^.field_desc_name^.id + ': ' + n^.field_type^.id;
*)
      if_else_node: begin
         if type_check(n^.if_else_condition, env, tenv) <> bool_type then
            err('if condition is not a boolean value', n^.line, n^.col);
         ty1 := type_check(n^.if_else_consequent, env, tenv);
         if ty1 <> type_check(n^.if_else_alternative, env, tenv) then
            err('if and else clauses incompatible types', n^.line, n^.col);
         type_check := ty1;
      end;

      if_node: begin
         if type_check(n^.if_condition, env, tenv) <> bool_type then
            err('if condition is not a boolean value', n^.line, n^.col);
         if type_check(n^.if_consequent, env, tenv) <> void_type then
            err('if clause without else cannot return a value', n^.line, n^.col);
         type_check := void_type;
      end;

      while_node: begin
         if type_check(n^.while_condition, env, tenv) <> bool_type then
            err('while condition is not a boolean value', n^.while_condition^.line, n^.while_condition^.col);
         if type_check(n^.while_body, env, tenv) <> void_type then
            err('while expression cannot return a value', n^.while_body^.line, n^.while_body^.col);
         type_check := void_type;
      end;

      for_node: begin
         bind(env, n^.iter, int_type);
         if type_check(n^.start, env, tenv) <> int_type then
            err('for start value must be integer type', n^.start^.line, n^.start^.col);
         if type_check(n^.finish, env, tenv) <> int_type then
            err('for to value must be integer type', n^.finish^.line, n^.finish^.col);
         if type_check(n^.for_body, env, tenv) <> void_type then
            err('for body cannot return a vaule', n^.for_body^.line, n^.for_body^.col);
         type_check := void_type;
      end;

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
