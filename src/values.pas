{$mode objfpc}
unit values;

interface

uses symbols;

type

   value_type = (integer_vt, string_vt, bool_vt, empty_vt);

   value = record
      case vt: value_type of
         integer_vt: (int_val: int64);
         string_vt: (string_val: symbol);
         bool_vt: (bool_val: boolean);
         empty_vt: ();
   end;

   function make_integer_value(n: int64): value;
   function make_string_value(s: symbol): value;
   function make_boolean_value(b: boolean): value;
   function make_empty_value(): value;

implementation

function make_empty_value(): value;
begin
   result.vt := empty_vt;
end;

function make_integer_value(n: int64): value;
begin
   result.vt := integer_vt;
   result.int_val := n;
end;

function make_string_value(s: symbol): value;
begin
   result.vt := string_vt;
   result.string_val := s;
end;

function make_boolean_value(b: boolean): value;
begin
   result.vt := bool_vt;
   result.bool_val := b;
end;

end.
