unit ops;

interface

type
   op_tag = (plus_op, minus_op, mul_op, div_op,
             eq_op, neq_op, lt_op, leq_op, gt_op, geq_op,
             and_op, or_op);

var
   op_display: array[plus_op..or_op] of string;

implementation

begin
   op_display[plus_op] := '+';
   op_display[minus_op] := '-';
   op_display[mul_op] := '*';
   op_display[div_op] := '/';
   op_display[eq_op] := '=';
   op_display[neq_op] := '<>';
   op_display[lt_op] := '<';
   op_display[leq_op] := '<=';
   op_display[gt_op] := '>';
   op_display[geq_op] := '>=';
   op_display[and_op] := '&';
   op_display[or_op] := '|';
end.

   
   