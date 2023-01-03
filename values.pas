unit values;

interface

uses symbols;

type
   value = ^value_t;

   value_t = record
      string_val: symbol;
      int_val: int64;
      bool_val: boolean
   end;

   function make_integer_value(n: int64): value;
   function make_string_value(s: symbol): value;
   function make_boolean_value(b: boolean): value;

implementation

   function make_value(): value;
   var
      v: value;
   begin
      new(v);
      v^.string_val := nil;
      v^.int_val := 0;
      v^.bool_val := false;
      make_value := v;
   end;


   function make_integer_value(n: int64): value;
   var
      v: value;
   begin
      v := make_value();
      v^.int_val := n;
      make_integer_value := v;
   end;


   function make_string_value(s: symbol): value;
   var
      v: value;
   begin
      v := make_value();
      v^.string_val := s;
      make_string_value := v;
   end;


   function make_boolean_value(b: boolean): value;
   var
      v: value;
   begin
      v := make_value();
      v^.bool_val := b;
      make_boolean_value := v;
   end;


end.
