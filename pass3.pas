unit pass3;
interface

uses nodes;

function trans3(n: node): node;

implementation

uses sysutils, symbols;

var
   next_tmp: longint = 0;
   tf: tf_function = @trans3;

function tmp(): symbol;
begin
   next_tmp := next_tmp + 1;
   tmp := intern('tmp$_' + inttostr(next_tmp));
end;


function trans3(n: node): node;
var
   t1, t2: symbol;
   e1, e2: node;
   decls: node_list;
   line, col: longint;

   function compound(n: node): boolean;
   begin
      compound := not (n^.tag in [empty_node, let_node, simple_var_node, integer_node, char_node, string_node, boolean_node, nil_node]);
   end;

begin
   t1 := nil;
   t2 := nil;
   e1 := nil;
   e2 := nil;
   line := n^.line;
   col := n^.col;
   decls := nil;

   case n^.tag of
      binary_op_node: begin
         if compound(n^.left) then begin
            t1 := tmp();
            e1 := make_var_decl_node(t1, nil, trans3(n^.left), line, col);
         end;
         if compound(n^.right) then begin
            t2 := tmp();
            e2 := make_var_decl_node(t2, nil, trans3(n^.right), n^.right^.line, n^.right^.col);
         end;
         if (e1 <> nil) or (e2 <> nil) then begin
            decls := make_list();
            if e1 <> nil then begin
               append(decls, e1);
               if e2 <> nil then begin
                  append(decls, e2);
                  trans3 := make_let_node(decls,
                                          make_binary_op_node(n^.op,
                                                              make_simple_var_node(t1, line, col),
                                                              make_simple_var_node(t2, n^.right^.line, n^.right^.col),
                                                              line,
                                                              col),
                                          line,
                                          col);
               end
               else
                  trans3 := make_let_node(decls,
                                          make_binary_op_node(n^.op,
                                                              make_simple_var_node(t1, line, col),
                                                              trans3(n^.right),
                                                              line,
                                                              col),
                                          line,
                                          col);
            end
            else begin
               append(decls, e2);
               trans3 := make_let_node(decls,
                                       make_binary_op_node(n^.op,
                                                           trans3(n^.left),
                                                           make_simple_var_node(t2, n^.right^.line, n^.right^.col),
                                                           line,
                                                           col),
                                       line,
                                       col);
            end;
         end
         else
            trans3 := copy_node(n, tf);
      end;
   else
      trans3 := copy_node(n, tf);
   end;
end;

end.
