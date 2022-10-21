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

   (* write *)
   s := make_function_type(void_type);
   add_param(s, intern('s'), string_type, 0, 0);
   bind_external('write', s);

   (* print *)
   s := make_function_type(void_type);
   add_param(s, intern('s'), string_type, 0, 0);
   bind_external('print', s);

   (* str *)
   s := make_function_type(string_type);
   add_param(s, intern('n'), int_type, 0, 0);
   bind_external('str', s);

   (* length *)
   s := make_function_type(int_type);
   add_param(s, intern('s'), string_type, 0, 0);
   bind_external('length', s);

   (* sub *)
   s := make_function_type(int_type);
   add_param(s, intern('s'), string_type, 0, 0);
   add_param(s, intern('n'), int_type, 0, 0);
   bind_external('sub', s);

   (* ord *)
   s := make_function_type(int_type);
   add_param(s, intern('s'), string_type, 0, 0);
   bind_external('ord', s);

   (* chr *)
   s := make_function_type(string_type);
   add_param(s, intern('n'), int_type, 0, 0);
   bind_external('chr', s);

   (* substring *)
   s := make_function_type(string_type);
   add_param(s, intern('s'), string_type, 0, 0);
   add_param(s, intern('start'), int_type, 0, 0);
   add_param(s, intern('length'), int_type, 0, 0);
   bind_external('substring', s);

   (* concat *)
   s := make_function_type(string_type);
   add_param(s, intern('s1'), string_type, 0, 0);
   add_param(s, intern('s2'), string_type, 0, 0);
   bind_external('concat', s);

   (* toh *)
   s := make_function_type(int_type);
   bind_external('toh', s);

end;

end.
