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
         if ty1 = type_check(n^.expression, env, tenv) then
            type_check := ty1
         else
            err('assignment incompatible type', n^.line, n^.col);
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
                  err('variable with nil initializer must specify type', n^.line, n^.col);
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
      unary_op_node:
         { minus is the only unary op }
         if type_check(n^.unary_exp, env, tenv) = int_type then
            type_check := int_type
         else 
            err('sign operator incompatible type', n^.line, n^.col);
      binary_op_node: begin
         op := n^.binary_op;
         ty1 := type_check(n^.left, env, tenv);
         ty2 := type_check(n^.right, env, tenv);
         if ty1 = ty2 then
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
               type_check := bool_type
         else
            err('operator incompatible types', n^.line, n^.col);
      end;
(*
      field_node:
         format := n^.field_name^.id + ' = ' + format(n^.field_value);
      field_desc_node:
         format := n^.field_desc_name^.id + ': ' + n^.field_type^.id;
      if_else_node: begin
         s := 'if ' + format(n^.if_else_condition) + ' then';
         indent;
         s := s + newline + format(n^.if_else_consequent);
         dedent;
         s := s + newline + 'else';
         indent;
         s := s + newline + format(n^.if_else_alternative);
         dedent;
         format := s;
      end;
      if_node: begin
         s := 'if ' + format(n^.if_condition) + ' then';
         indent;
         s := s + newline + format(n^.if_consequent);
         dedent;
         format := s;
      end;      
      while_node: begin
         s := 'while ' + format(n^.while_condition) + ' do';
         indent;
         s := s + newline + format(n^.while_body);
         dedent;
         format := s;
      end;
      for_node: begin
         s := 'for ' + n^.iter^.id + ' := ' + format(n^.start) + ' to ' + format(n^.finish) + ' do';
         indent;
         s := s + newline + format(n^.for_body);
         dedent;
         format := s;
      end;
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