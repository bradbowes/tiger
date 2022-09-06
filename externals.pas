unit externals;

interface

procedure load_externals();

implementation

uses bindings, symbols, types;


procedure load_externals();
var s: spec;
begin

   (* read *)
   s := make_function_type(string_type);
   bind(global_env, intern('read'), s, 0, 0, 0, 0);

   (* concat *)
   s:= make_function_type(string_type);
   add_field(s, intern('s1'), string_type, 0, 0);
   add_field(s, intern('s2'), string_type, 0, 0);
   bind(global_env, intern('concat'), s, 0, 0, 0, 0);
   
end;

end.   
   
