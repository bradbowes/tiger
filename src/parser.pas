unit parser;

interface

uses nodes;

function parse(file_name: string): node;

implementation

uses sysutils, sources, scanner, symbols;

function parse(file_name: string): node;
var
   lib: node_list;
   expr: node;

   procedure next();
   begin
      scan();
      while token.tag = comment_token do
         scan();
   end;

   procedure set_source(file_name: string);
   begin
      clear_source();
      load_source(file_name);
      next();
   end;

   function get_expression(): node; forward;

   function get_identifier(): symbol;
   var
      value: string;
   begin
      value := token.value;
      get_identifier := nil;
      if token.tag = id_token then
         begin
            get_identifier := intern(value);
            next();
         end
      else
         err('Expected identifier, got ''' + value + '''', token_location());
   end;

   function get_number(): int64;
   var
      i: int64;
      value: string;
   begin
      value := token.value;
      get_number := 0;
      if trystrtoint64(token.value, i) then
         begin
            get_number := i;
            next();
         end
      else
         err('Bad integer format: ''' + value + '''', token_location());
   end;

   procedure advance(t: token_tag; display: string);
   begin
      if token.tag = t then
         next()
      else
         err('Expected ''' + display + ''', got ''' +
             token.value + '''', token_location());
   end;

   function get_expression_list() : node_list;
   var
      list: node_list;
   begin
      list := node_list.create();
      list.append(get_expression());
      while token.tag = comma_token do
         begin
            next();
            list.append(get_expression());
         end;
      get_expression_list := list;
   end;

   function get_sequence() : node;
   var
      loc: source_location;
      list: node_list;
   begin
      loc := token_location();
      list := node_list.create();
      while token.tag <> end_token do
         begin
            list.append(get_expression());
            if token.tag = semicolon_token then next();
         end;
      next();
      get_sequence := make_sequence_node(list, loc);
   end;

   function get_field(): node;
   var
      name: symbol;
      loc: source_location;
   begin
      loc := token_location();
      name := get_identifier();
      advance(eq_token, '=');
      get_field := make_field_node(name, get_expression(), loc);
   end;

   function get_field_list(): node_list;
   var
      list: node_list;
   begin
      list := node_list.create();
      if not (token.tag in [rparen_token, rbrace_token]) then
         begin
            list.append(get_field());
            while token.tag = comma_token do
               begin
                  next();
                  list.append(get_field());
               end;
         end;
      get_field_list := list;
   end;

   function get_factor(): node;
   var
      loc: source_location;
      value: string;
      factor: node = nil;
      id: symbol;
      list: node_list;
   begin
      loc := token_location();
      value := token.value;
      get_factor := nil;
      case token.tag of
         number_token:
            factor := make_integer_node(get_number(), loc);
         string_token:
            begin
               next();
               factor := make_string_node(intern(value), loc);
            end;
         nil_token:
            begin
               next();
               factor := make_nil_node(loc);
            end;
         char_token:
            begin
               next();
               factor := make_char_node(ord(value[1]), loc);
            end;
         array_token:
            begin
               next();
               advance(lbracket_token, '[');
               factor := get_expression(); (* size *)
               advance(rbracket_token, ']');
               advance(of_token, 'of');
               factor := make_array_node(factor, get_expression(), loc);
            end;
         id_token:
            begin
               id := get_identifier();
               if token.tag = lbrace_token then
                  begin
                     next();
                     get_factor := make_record_node(id, get_field_list(), loc);
                     advance(rbrace_token, '}');
                     exit;
                  end
               else
                  factor := make_simple_var_node(id, loc);
            end;
         lbracket_token:
            begin
               next();
               list := get_expression_list();
               advance(rbracket_token, ']');
               factor := make_array_list_node(list, loc);
            end;
         lparen_token:
            begin
               next();
               factor := get_expression();
               advance(rparen_token, ')');
            end;
         else
            begin
               next();
               err('Expected expression, got ''' + value + '''', loc);
            end;
      end;

      get_factor := factor;
   end;

   function get_subscript(): node;
   var
      loc: source_location;
      left: node;
      list: node_list;
   begin
      loc := token_location();
      left := get_factor();

      while token.tag in [dot_token, lbracket_token, lparen_token] do
         case token.tag of
            dot_token:
               begin
                  next();
                  left := make_field_var_node(left, get_identifier(), loc);
               end;
            lbracket_token:
               begin
                  next();
                  left := make_indexed_var_node(left, get_expression(), loc);
                  advance(rbracket_token, ']');
               end;
            lparen_token:
               begin
                  next();
                  if token.tag = rparen_token then
                     list := node_list.create()
                  else
                     list := get_expression_list();
                  advance(rparen_token, ')');
                  left := make_call_node(left, list, loc);
               end;
         end;
      get_subscript := left;
   end;

   function get_unary(): node;
   var
      loc: source_location;
   begin
      loc := token_location;
      if token.tag = minus_token then
         begin
            next();
            get_unary := make_unary_minus_node(get_subscript(), loc);
         end
      else
         get_unary := get_subscript();
   end;

   function get_product(): node;
   var
      loc: source_location;
      left: node;
      op: node_tag = empty_node;
   begin
      loc := token_location();
      left := get_unary();

      while token.tag in [mul_token, div_token, mod_token] do
         begin
            case token.tag of
               mul_token: op := mul_node;
               div_token: op := div_node;
               mod_token: op := mod_node;
            end;
            next();
            left := make_binary_node(op, left, get_unary(), loc);
            loc := token_location();
         end;

      get_product := left;
   end;

   function get_sum(): node;
   var
      loc: source_location;
      left: node;
      op: node_tag = empty_node;
   begin
      loc := token_location();
      left := get_product();

      while token.tag in [plus_token, minus_token] do
         begin
            case token.tag of
               plus_token:  op := plus_node;
               minus_token: op := minus_node;
            end;
            next();
            left := make_binary_node(op, left, get_product(), loc);
            loc := token_location();
         end;

      get_sum := left;
   end;

   function get_boolean(): node;
   var
      loc: source_location;
      left: node;
      op: node_tag = empty_node;
   begin
      loc := token_location();
      left := get_sum();

      while token.tag in [eq_token, neq_token, lt_token, leq_token, gt_token, geq_token] do
         begin
            case token.tag of
               eq_token:  op := eq_node;
               neq_token: op := neq_node;
               lt_token:  op := lt_node;
               leq_token: op := leq_node;
               gt_token:  op := gt_node;
               geq_token: op := geq_node;
            end;
            next();
            left := make_binary_node(op, left, get_sum(), loc);
            loc := token_location();
         end;

      get_boolean := left;
   end;

   function get_conjunction(): node;
   var
      loc: source_location;
      left: node;
   begin
      loc := token_location();
      left := get_boolean();

      while token.tag = and_token do
         begin
            next();
            left := make_and_node(left, get_boolean(), loc);
      end;

      get_conjunction := left;
   end;

   function get_disjunction(): node;
   var
      loc: source_location;
      left: node;
   begin
      loc := token_location();
      left := get_conjunction();
      while token.tag = or_token do
         begin
            next();
            left := make_or_node(left, get_conjunction(), loc);
         end;
      get_disjunction := left;
   end;

   function get_assignment(): node;
   var
      loc: source_location;
      left_side: node;
   begin
      loc := token_location();
      get_assignment := nil;
      left_side := get_disjunction;
      if token.tag = assign_token then
   	    if left_side^.tag in [simple_var_node, field_var_node, indexed_var_node] then
            begin
               next();
               get_assignment := make_assign_node(left_side, get_expression(), loc);
            end
         else
            err('Assignment to non-variable object', loc)
      else
         get_assignment := left_side;
   end;

   function get_if_expression(): node;
   var
      condition: node;
      consequent: node;
      loc: source_location;
   begin
      get_if_expression := nil;
      loc := token_location();
      next();
      condition := get_expression();
      advance(then_token, 'then');
      consequent := get_expression();
      if token.tag = else_token then
         begin
            next();
            get_if_expression := make_if_else_node(
                  condition, consequent, get_expression(), loc);
         end
      else
         get_if_expression := make_if_node(condition, consequent, loc);
   end;

   function get_case_expression(): node;
   var
      arg, default: node;
      clauses: node_list;
      loc: source_location;

      function get_match(): node;
      var
         loc: source_location;
      begin
         get_match := nil;
         loc := token_location();
         case token.tag of
            id_token: get_match := make_simple_var_node(get_identifier(), loc);
            number_token: get_match := make_integer_node(get_number(), loc);
            char_token:
               begin
                  get_match := make_char_node(ord(token.value[1]), loc);
                  next();
               end;
            else err('case must be an integer, char or identifier', loc);
         end;
      end;

      function get_clause(): node;
      var
         match: node;
         loc: source_location;
      begin
         loc := token_location();
         match := get_match();
         advance(colon_token, ':');
         get_clause := make_clause_node(match, get_expression(), loc);
      end;

   begin
      default := nil;
      loc := token_location();
      next();
      arg := get_expression();
      advance(of_token, 'of');
      clauses := node_list.create();
      clauses.append(get_clause());
      while token.tag = pipe_token do
         begin
            next();
            if token.tag in [id_token, number_token, char_token] then
               clauses.append(get_clause())
            else
               err('expected id, number or char, got ''' + token.value + '''', token_location());
         end;
      if token.tag = else_token then
         begin
            next();
            default := get_expression();
         end;
      get_case_expression := make_case_node(arg, clauses, default, loc);
   end;

   function get_while_expression(): node;
   var
      condition: node;
      loc: source_location;
   begin
      get_while_expression := nil;
      loc := token_location();
      next();
      condition := get_expression();
      advance(do_token, 'do');
      get_while_expression := make_while_node(condition, get_expression(), loc);
   end;

   function get_for_expression(): node;
   var
      iter: symbol;
      start, finish, body: node;
      loc: source_location;
   begin
      loc := token_location();
      next();
      iter := get_identifier();
      advance(assign_token, ':=');
      start := get_expression();
      advance(to_token, 'to');
      finish := get_expression();
      advance(do_token, 'do');
      body := get_expression();
      get_for_expression := make_for_node(iter, start, finish, body, loc);
   end;

   function get_field_desc(): node;
   var
      name: symbol;
      loc: source_location;
   begin
      loc := token_location();
      name := get_identifier();
      advance(colon_token, ':');
      get_field_desc := make_field_desc_node(name, get_identifier(), loc);
   end;

   function get_field_desc_list(): node_list;
   var
      list: node_list;
   begin
      list := node_list.create();
      if not (token.tag in [rparen_token, rbrace_token]) then
         begin
            list.append(get_field_desc);
            while token.tag = comma_token do
               begin
                  next();
                  list.append(get_field_desc());
               end;
         end;
      get_field_desc_list := list;
   end;

   function get_enum_list(): node_list;
   var
      list: node_list;
      loc: source_location;
   begin
      list := node_list.create();
      loc := token_location();
      list.append(make_enum_node(get_identifier(), loc));
      while token.tag = pipe_token do
         begin
            next();
            loc := token_location();
            list.append(make_enum_node(get_identifier(), loc));
         end;
      get_enum_list := list;
   end;

   function get_type_spec(): node;
   var
      loc: source_location;
      desc: node = nil;
   begin
      loc := token_location();
      case token.tag of
         lbrace_token:
            begin
               next();
               desc := make_record_desc_node(get_field_desc_list(), loc);
               advance(rbrace_token, '}');
            end;
         array_token:
            begin
               next();
               advance(of_token, 'of');
               desc := make_array_desc_node(get_identifier(), loc);
            end;
         id_token:
            desc := make_enum_desc_node(get_enum_list(), loc);
         else
            err('Expected type spec, got ''' + token.value + '''', loc);
      end;
      get_type_spec := desc;
   end;

   function get_function_declaration(name: symbol): node;
   var
      loc: source_location;
      ty: symbol = nil;
      params: node_list;
      body: node = nil;
   begin
      loc := token_location();
      get_function_declaration := nil;
      next();
      params := get_field_desc_list();
      advance(rparen_token, ')');
      if token.tag = colon_token then
         begin
            next();
            ty := get_identifier();
         end;
      if token.tag = eq_token then
         begin
            next();
            body := get_expression
         end;
      get_function_declaration := make_fun_decl_node(name, params, ty, body, loc);
   end;

   function get_var_declaration(): node;
   var
      loc: source_location;
      name	: symbol;
      ty	: symbol = nil;
      exp	: node = nil;
   begin
      get_var_declaration := nil;
      loc := token_location();
      name := get_identifier();
      if token.tag = lparen_token then
         begin
            get_var_declaration := get_function_declaration(name);
         end
      else
         begin
            if token.tag = colon_token then
               begin
                  next();
                  ty := get_identifier();
               end;
            if token.tag = eq_token then
               begin
                  next();
                  exp := get_expression();
               end
            else
               err('Expected '':'' or ''='', got ''' + token.value + '''', token_location());
            get_var_declaration := make_var_decl_node(name, ty, exp, loc);
         end;
   end;

   function get_type_declaration(): node;
   var
      loc: source_location;
      name: symbol;
   begin
      loc := token_location();
      next();
      name := get_identifier();
      advance(eq_token, '=');
      get_type_declaration := make_type_decl_node(name, get_type_spec(), loc);
   end;

   function get_declaration(): node;
   begin
      get_declaration := nil;
      case token.tag of
         id_token: get_declaration := get_var_declaration();
         type_token: get_declaration := get_type_declaration();
      else
         err('Expected declaration, got ''' + token.value + '''', token_location());
      end;
      if token.tag = semicolon_token then next();
   end;

   function get_declaration_list(): node_list;
   var
      decls: node_list;
      use_file: string;
   begin
      decls := node_list.create();
      while token.tag in [id_token, type_token, use_token] do
         begin
            if token.tag = use_token then
               begin
                  next();
                  if token.tag = string_token then
                     begin
                        use_file := token.value;
                        load_source(use_file);
                        next();
                     end
                  else
                     err('Expected file name', token_location());
               end
            else
               decls.append(get_declaration());
         end;
      get_declaration_list := decls
   end;

   function get_let_expression(): node;
   var
      loc: source_location;
      decls: node_list;
      body: node;
   begin
      loc := token_location();
      next();
      decls := get_declaration_list();
      advance(in_token, 'in');
      body := get_sequence();
      get_let_expression := make_let_node(decls, body, loc);
   end;

   function get_expression(): node;
   begin
      case token.tag of
         if_token: get_expression := get_if_expression();
         case_token: get_expression := get_case_expression();
         while_token: get_expression := get_while_expression();
         for_token: get_expression := get_for_expression();
         let_token: get_expression := get_let_expression();
         begin_token: begin next(); get_expression := get_sequence(); end
         else get_expression := get_assignment();
      end;
   end;

begin
   set_source('/usr/local/share/tiger/lib/core.tlib');
   lib := get_declaration_list();
   set_source(file_name);
   expr := get_expression();
   parse := make_let_node(lib, expr, expr^.loc);
   if token.tag <> eof_token then
      err('extraneous input', token_location());
end;

end.
