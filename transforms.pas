unit transforms;

interface

uses nodes;

function transform(n: node): node;

implementation

uses symbols, ops, bindings;

function transform(n: node): node;
var
   tag: node_tag;
   line, col: longint;
   int_val: int64;
   string_val: symbol;
   bool_val: boolean;
   (* bind: binding; *)
   name, type_name: symbol;
   e1, e2, cond, left, right: node;
   op: op_tag;
   list: node_list;
   (* env: scope; *)

   function copy(): node;
   var
      n: node;
      ls: node_list;
      it: node_list_item;
   begin
      new(n);
      n^.tag := tag;
      n^.line := line;
      n^.col := col;
      n^.int_val := int_val;
      n^.string_val := string_val;
      n^.bool_val := bool_val;
      n^.name := name;
      n^.type_name := type_name;
      if cond <> nil then n^.cond := transform(cond);
      if left <> nil then n^.left := transform(left);
      if right <> nil then n^.right := transform(right);
      n^.op := op;
      if list <> nil then begin
         ls := make_list();
         it := list^.first;
         while it <> nil do begin
            append(ls, transform(it^.node));
            it := it^.next;
         end;
         n^.list := ls;
      end;
      copy := n;
   end;

begin
   tag := n^.tag;
   line := n^.line;
   col := n^.col;
   int_val := n^.int_val;
   string_val := n^.string_val;
   bool_val := n^.bool_val;
   (* bind := n^.binding; *)
   name := n^.name;
   type_name := n^.type_name;
   cond := n^.cond;
   left := n^.left;
   right := n^.right;
   op := n^.op;
   list := n^.list;
   (* env := n^.env; *)

   case tag of
      unary_op_node: begin
         e1 := transform(left);
         if e1^.tag = integer_node then
            transform := make_integer_node(-(e1^.int_val), line, col)
         else
            transform := copy();
      end;
      binary_op_node: begin
         e1 := transform(left);
         e2 := transform(right);
         if (e1^.tag = integer_node) and (e2^.tag = integer_node) then
            case op of
               plus_op:
                  transform := make_integer_node(e1^.int_val + e2^.int_val, line, col);
               minus_op:
                  transform := make_integer_node(e1^.int_val - e2^.int_val, line, col);
               mul_op:
                  transform := make_integer_node(e1^.int_val * e2^.int_val, line, col);
               div_op:
                  transform := make_integer_node(e1^.int_val div e2^.int_val, line, col);
               mod_op:
                  transform := make_integer_node(e1^.int_val mod e2^.int_val, line, col);
               lt_op:
                  transform := make_boolean_node(e1^.int_val < e2^.int_val, line, col);
               leq_op:
                  transform := make_boolean_node(e1^.int_val <= e2^.int_val, line, col);
               gt_op:
                  transform := make_boolean_node(e1^.int_val > e2^.int_val, line, col);
               geq_op:
                  transform := make_boolean_node(e1^.int_val >= e2^.int_val, line, col);
               eq_op:
                  transform := make_boolean_node(e1^.int_val = e2^.int_val, line, col);
               neq_op:
                  transform := make_boolean_node(e1^.int_val <> e2^.int_val, line, col);
               else
                  transform := copy();
            end
         else if (e1^.tag = char_node) and (e2^.tag = char_node) then
            case op of
               plus_op:
                  transform := make_char_node(e1^.int_val + e2^.int_val, line, col);
               minus_op:
                  transform := make_char_node(e1^.int_val - e2^.int_val, line, col);
               lt_op:
                  transform := make_boolean_node(e1^.int_val < e2^.int_val, line, col);
               leq_op:
                  transform := make_boolean_node(e1^.int_val <= e2^.int_val, line, col);
               gt_op:
                  transform := make_boolean_node(e1^.int_val > e2^.int_val, line, col);
               geq_op:
                  transform := make_boolean_node(e1^.int_val >= e2^.int_val, line, col);
               eq_op:
                  transform := make_boolean_node(e1^.int_val = e2^.int_val, line, col);
               neq_op:
                  transform := make_boolean_node(e1^.int_val <> e2^.int_val, line, col);
               else
                  transform := copy();
            end
         else if (e1^.tag = boolean_node) and (e2^.tag = boolean_node) then
            case op of
               eq_op:
                  transform := make_boolean_node(e1^.bool_val = e2^.bool_val, line, col);
               neq_op:
                  transform := make_boolean_node(e1^.bool_val <> e2^.bool_val, line, col);
               and_op:
                  transform :=  make_boolean_node(e1^.bool_val and e2^.bool_val, line, col);
               or_op:
                  transform := make_boolean_node(e1^.bool_val or e2^.bool_val, line, col);
               else
                  transform := copy();
            end
         else if (op = and_op) then
            if e1^.tag = boolean_node then
               if e1^.bool_val then
                  transform := e2
               else
                  transform := e1
            else if (e2^.tag = boolean_node) and e2^.bool_val then
               transform := e1
            else
               transform := copy()
         else if (op = or_op) then
            if e1^.tag = boolean_node then
               if e1^.bool_val then
                  transform := e1
               else
                  transform := e2
            else if (e2^.tag = boolean_node) and (not e2^.bool_val) then
               transform := e1
            else
               transform := copy()
         else
            transform := copy();
      end;
      if_node: begin
         e1 := transform(cond);
         if e1^.tag = boolean_node then
            if e1^.bool_val then
               transform := transform(left)
            else
               transform := make_empty_node(line, col)
         else
            transform := copy();
      end;
      if_else_node: begin
         e1 := transform(cond);
         if e1^.tag = boolean_node then
            if e1^.bool_val then
               transform := transform(left)
            else
               transform := transform(right)
         else
            transform := copy();
      end;
      while_node: begin
         e1 := transform(cond);
         if (e1^.tag = boolean_node) and (not e1^.bool_val) then
            transform := make_empty_node(line, col)
         else
            transform := copy();
      end;
      else
         transform := copy();
   end;
end;

end.

