unit parsers;

interface

uses utils, scanners, symbols, ops, nodes;

function parse(file_name: string): node;

implementation

function parse(file_name: string): node;
var
   the_scanner: scanner;

   function get_expression: node; forward;

   procedure next;
   begin
      scan(the_scanner);
      while token.tag = comment_token do
         scan(the_scanner);
   end;

   function get_identifier: symbol;
   var
      value: string;
   begin
      value := token.value;
      get_identifier := nil;
      if token.tag = id_token then
         begin
            get_identifier := intern(value);
            next;
         end
      else
         err('Expected identifier, got ''' + value + '''', token.line, token.col);
   end;


   procedure advance(t: token_tag; display: string);
   begin
      if token.tag = t then
         next
      else
         err('Expected ''' + display + ''', got ''' +
             token.value + '''', token.line, token.col);
   end;


   function get_expression_list() : node_list;
   var
      list: node_list;
   begin
      list := make_list();
      append(list, get_expression());
      while token.tag = comma_token do
      begin
         next;
         append(list, get_expression());
      end;
      get_expression_list := list;
   end;


   function get_sequence() : node;
   var
      line, col: longint;
      list: node_list;
   begin
      line := token.line;
      col := token.col;
      list := make_list();
      repeat
         append(list, get_expression());
         if token.tag = semicolon_token then next;
      until token.tag = end_token;
      next;
      get_sequence := make_sequence_node(list, line, col);
   end;


   function get_field: node;
   var
      name: symbol;
      line, col: longint;
   begin
      line := token.line;
      col := token.col;
      name := get_identifier;
      advance(eq_token, '=');
      get_field := make_field_node(name, get_expression, line, col);
   end;


   function get_field_list(): node_list;
   var
      list: node_list;
   begin
      list := make_list();
      if not (token.tag in [rparen_token, rbrace_token]) then
         begin
            append(list, get_field);
            while token.tag = comma_token do
               begin
                  next;
                  append(list, get_field);
               end;
         end;
      get_field_list := list;
   end;

   function get_factor: node;
   var
      line, col : longint;
      value: string;
      list: node_list;
      factor: node = nil;
      id: symbol;
   begin
      line := token.line;
      col := token.col;
      value := token.value;
      get_factor := nil;
      case token.tag of
         number_token:
            begin
               next;
               factor := make_integer_node(atoi(value, line, col), line, col);
            end;
         string_token:
            begin
               next;
               factor := make_string_node(intern(value), line, col);
            end;
         true_token:
            begin
               next;
               factor := make_boolean_node(true, line, col);
            end;
         false_token:
            begin
               next;
               factor := make_boolean_node(false, line, col);
            end;
         nil_token:
            begin
               next;
               factor := make_nil_node(line, col);
            end;
         char_token:
            begin
               next;
               factor := make_char_node(ord(value[1]), line, col);
            end;
         minus_token:
            begin
               next;
               factor := make_unary_op_node(minus_op, get_factor(), line, col);
            end;
         id_token:
            begin
               id := get_identifier;
               case token.tag of
                  lbrace_token:
                     begin
                        next;
                        get_factor := make_record_node(id, get_field_list, line, col);
                        advance(rbrace_token, '}');
                        exit;
                     end;
                  lparen_token:
                     begin
                        next;
                        if token.tag = rparen_token then
                           list := make_list()
                        else
                           list := get_expression_list();
                        advance(rparen_token, ')');
                        factor := make_call_node(id, list, line, col);
                     end;
                  lbracket_token:
                     begin
                        next;
                        factor := get_expression;
                        advance(rbracket_token, ']');
                        if token.tag = of_token then
                           begin
                              next;
                              get_factor := make_array_node(id, factor, get_expression, line, col);
                              exit;
                           end
                        else
                           factor :=  make_indexed_var_node(make_simple_var_node(id, line, col), factor, line, col);
                     end;

                  else
                     factor := make_simple_var_node(id, line, col);
               end;

               while token.tag in [dot_token, lbracket_token] do
                  case token.tag of
                    dot_token:
                       begin
                          next;
                          factor := make_field_var_node(factor, get_identifier, line, col);
                       end;
                    lbracket_token:
                       begin
                          next;
                          factor := make_indexed_var_node(factor, get_expression, line, col);
                          advance(rbracket_token, '}');
                       end;
                  end;
            end;
         lparen_token:
            begin
               next;
               factor := get_expression();
               advance(rparen_token, ')');
            end;
         else
            begin
               next;
               err('Expected expression or ''end'', got ''' + value + '''', line, col);
            end;
      end;

      get_factor := factor;
   end;

   function get_product: node;
   var
      line, col: longint;

      function helper(left: node): node;

         function make_node(op: op_tag): node;
         begin
            next;
            make_node := make_binary_op_node(op, left, get_factor, line, col);
         end;

      begin
         case token.tag of
            mul_token: helper := helper(make_node(mul_op));
            div_token: helper := helper(make_node(div_op));
            mod_token: helper := helper(make_node(mod_op));
            else helper := left;
         end;
      end;

   begin
      line := token.line;
      col := token.col;
      get_product := helper(get_factor);
   end; { get_product }

   function get_sum: node;
   var
      line, col: longint;

      function helper(left: node): node;

         function make_node(op: op_tag): node;
         begin
            next;
            make_node := make_binary_op_node(op, left, get_product, line, col);
         end;

      begin
         case token.tag of
            plus_token: helper := helper(make_node(plus_op));
            minus_token: helper := helper(make_node(minus_op));
            else helper := left;
         end;
      end;

   begin
      line := token.line;
      col := token.col;
      get_sum := helper(get_product);
   end; { get_sum }


   function get_boolean: node;
   var
      line, col: longint;

      function helper(left: node): node;

         function make_node(op: op_tag): node;
         begin
            next;
            make_node := make_binary_op_node(op, left, get_sum, line, col);
         end;

      begin
         case token.tag of
            eq_token: helper := helper(make_node(eq_op));
            neq_token: helper := helper(make_node(neq_op));
            lt_token: helper := helper(make_node(lt_op));
            leq_token: helper := helper(make_node(leq_op));
            gt_token: helper := helper(make_node(gt_op));
            geq_token: helper := helper(make_node(geq_op));
            else helper := left;
         end;
      end;

   begin
      line := token.line;
      col := token.col;
      get_boolean := helper(get_sum);
   end;


   function get_conjunction: node;
   var
      line, col: longint;

      function helper(left: node): node;
      begin
         if token.tag = and_token then
            begin
               next;
               helper := helper(make_binary_op_node(
                     and_op, left, get_boolean, line, col));
            end
         else
            helper := left;
      end;

   begin
      line := token.line;
      col := token.col;
      get_conjunction := helper(get_boolean);
   end;

   function get_disjunction: node;
   var
      line, col: longint;

      function helper(left: node): node;
      begin
         if token.tag = or_token then
            begin
               next;
               helper := helper(make_binary_op_node(
                     or_op, left, get_conjunction, line, col));
            end
         else
            helper := left;
      end;

   begin
      line := token.line;
      col := token.col;
      get_disjunction := helper(get_conjunction);
   end;

   function get_assignment: node;
   var
      line, col: longint;
      left_side: node;

   begin
      line := token.line;
      col := token.col;
      get_assignment := nil;
      left_side := get_disjunction;
      if token.tag = assign_token then
   	    if left_side^.tag in [simple_var_node, field_var_node, indexed_var_node] then
            begin
               next;
               get_assignment := make_assign_node(left_side, get_expression, line, col);
            end
         else
            err('Assignment to non-variable object', line, col)
      else
         get_assignment := left_side;
   end;


   function get_if_expression: node;
   var
      condition: node;
      consequent: node;
      line, col: longint;
   begin
      get_if_expression := nil;
      line := token.line;
      col := token.col;
      next;
      condition := get_expression;
      advance(then_token, 'then');
      consequent := get_expression;
      if token.tag = else_token then
         begin
            next;
            get_if_expression := make_if_else_node(
                  condition, consequent, get_expression, line, col);
         end
      else
         get_if_expression := make_if_node(condition, consequent, line, col);
   end;


   function get_while_expression: node;
   var
      condition: node;
      line, col: longint;
   begin
      get_while_expression := nil;
      line := token.line;
      col := token.col;
      next;
      condition := get_expression;
      advance(do_token, 'do');
      get_while_expression := make_while_node(condition, get_expression, line, col);
   end;


   function get_for_expression: node;
   var
      iter: symbol;
      start, finish, body: node;
      line, col: longint;
   begin
      line := token.line;
      col := token.col;
      next;
      iter := get_identifier;
      advance(assign_token, ':=');
      start := get_expression;
      advance(to_token, 'to');
      finish := get_expression;
      advance(do_token, 'do');
      body := get_expression;
      get_for_expression := make_for_node(iter, start, finish, body, line, col);
   end;


   function get_field_desc: node;
   var
      name: symbol;
      line, col: longint;
   begin
      line := token.line;
      col := token.col;
      name := get_identifier;
      advance(colon_token, ':');
      get_field_desc := make_field_desc_node(name, get_identifier, line, col);
   end;


   function get_field_desc_list: node_list;
   var
      list: node_list;
   begin
      list := make_list();
      if not (token.tag in [rparen_token, rbrace_token]) then
         begin
            append(list, get_field_desc);
            while token.tag = comma_token do
               begin
                  next;
                  append(list, get_field_desc);
               end;
         end;
      get_field_desc_list := list;
   end;


   function get_type_spec: node;
   var
      line, col: longint;
      desc: node = nil;
   begin
      line := token.line;
      col := token.col;
      case token.tag of
         lbrace_token:
            begin
               next;
               desc := make_record_desc_node(get_field_desc_list, line, col);
               advance(rbrace_token, '}');
            end;
         array_token:
            begin
               next;
               advance(of_token, 'of');
               desc := make_array_desc_node(get_identifier, line, col);
            end;
         else
            err('Expected type spec, got ''' +
               token.value, token.line, token.col);
      end;
      get_type_spec := desc;
   end;


   function get_function_declaration(name: symbol): node;
   var
      line, col: longint;
      ty: symbol = nil;
      params: node_list;
   begin
      line := token.line;
      col := token.col;
      get_function_declaration := nil;
      next;
      params := get_field_desc_list;
      advance(rparen_token, ')');
      if token.tag = colon_token then
         begin
            next;
            ty := get_identifier;
         end;
      advance(eq_token, '=');
      get_function_declaration := make_fun_decl_node(name, params, ty, get_expression, line, col);
   end;


   function get_var_declaration: node;
   var
      line, col	: longint;
      name	: symbol;
      ty	: symbol = nil;
      exp	: node = nil;
   begin
      get_var_declaration := nil;
      line := token.line;
      col := token.col;
      name := get_identifier;
      if token.tag = lparen_token then begin
         get_var_declaration := get_function_declaration(name);
      end
      else begin
         if token.tag = colon_token then
            begin
               next;
               ty := get_identifier;
            end;
         if token.tag = eq_token then
            begin
               next;
               exp := get_expression;
            end
         else
            err('Expected '':'' or ''='', got ''' + token.value + '''',
                token.line, token.col);
         get_var_declaration := make_var_decl_node(name, ty, exp, line, col);
      end;
   end;


   function get_type_declaration: node;
   var
      line, col: longint;
      name: symbol;
   begin
      line := token.line;
      col := token.col;
      next;
      name := get_identifier;
      advance(eq_token, '=');
      get_type_declaration := make_type_decl_node(name, get_type_spec, line, col);
   end;


   function get_declaration: node;
   begin
      get_declaration := nil;
      case token.tag of
         id_token: get_declaration := get_var_declaration;
         type_token: get_declaration := get_type_declaration;
      else
         err('Expected declaration, got ''' + token.value + '''',
             token.line, token.col);
      end;
   end;


   function get_declaration_list: node_list;
   var
      decls: node_list;
   begin
      decls := make_list();
      while token.tag in [id_token, type_token] do
         append(decls, get_declaration);
      get_declaration_list := decls
   end; { get_declaration_list }


   function get_let_expression: node;
   var
      line, col: longint;
      decls: node_list;
      body: node;
   begin
      line := token.line;
      col := token.col;
      next;
      decls := get_declaration_list;
      advance(in_token, 'in');
      body := get_sequence();
      get_let_expression := make_let_node(decls, body, line, col);
   end;


   function get_expression: node;
   begin
      case token.tag of
         if_token: get_expression := get_if_expression;
         while_token: get_expression := get_while_expression;
         for_token: get_expression := get_for_expression;
         let_token: get_expression := get_let_expression;
         begin_token: begin next; get_expression := get_sequence; end
         else get_expression := get_assignment;
      end;
   end;

(*
   function get_program() : node;
   var
      list: node_list;
   begin
      list := make_list();
      repeat
         append(list, get_expression());
         if token.tag = semicolon_token then next;
      until token.tag = eof_token;
      next;
      get_program := make_sequence_node(list, 1, 1);
   end;
*)

begin
   the_scanner := make_scanner(file_name);
   next;
   parse := get_expression();
   if token.tag <> eof_token then
      err('extraneous input', token.line, token.col);
end; { parse }


end.
