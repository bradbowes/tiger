unit externals;

interface

procedure load_externals();

implementation

uses bindings, symbols, types;


procedure load_externals();
var
   s: spec;


procedure bind_external(name: string; s: spec);
var
   b: binding;
begin
   b := bind(global_env, intern(name), s, 0, 0, 0, 0);
   b^.external := true;
end;
   

begin

   (* builtin types *)
   bind(global_tenv, intern('int'), int_type, 0, 0, 0, 0);
   bind(global_tenv, intern('string'), string_type, 0, 0, 0, 0);
   bind(global_tenv, intern('bool'), bool_type, 0, 0, 0, 0);

   (* read *)
   s := make_function_type(string_type);
   bind_external('read', s);

   (* concat *)
   s:= make_function_type(string_type);
   add_field(s, intern('s1'), string_type, 0, 0);
   add_field(s, intern('s2'), string_type, 0, 0);
   bind_external('concat', s);
   
end;

end.   
   
