unit ops;

interface

type
   op_tag = (nul_op, plus_op, minus_op, mul_op, div_op, mod_op,
             eq_op, neq_op, lt_op, leq_op, gt_op, geq_op,
             and_op, or_op);

const
   equality_ops = [eq_op, neq_op];
   numeric_ops = [plus_op, minus_op, mul_op, div_op, mod_op];
   char_ops = [plus_op, minus_op];
   comparison_ops = [lt_op, leq_op, gt_op, geq_op];
   boolean_ops = [and_op, or_op];

   op_display: array[plus_op..or_op] of string =
      ('+', '-', '*', '/', 'mod', '=', '<>', '<', '<=', '>', '>=', 'and', 'or');

implementation

end.
