program test;

uses symbols, bindings, types;

var
   env, env1: frame;
   i, s, b: symbol;
   ty, ty1: spec;

begin
   i := intern('integer');
   s := intern('string');
   b := intern('boolean');
   env := global_tenv;
   bind(env, i, int_type, 0, 0);
   bind(env, s, string_type, 0, 0);
   bind(env, b, bool_type, 0, 0);
   ty := make_array_type(lookup(env, i, 0, 0));
   env1 := add_frame(env);
   bind(env1, intern('iarray'), ty, 0, 0);
   ty1 := make_record_type(nil);
   add_field(ty1, intern('the_array'), ty, 0, 0);
   add_field(ty1, intern('next'), ty1, 0, 0);
   bind(env1, intern('list'), ty1, 0, 0);
   { writeln(lookup(env1, intern('list1'), 0, 0)^.tag); }
   writeln(lookup(env1, intern('iarray'), 0, 0)^.tag);
   writeln(lookup(env1, intern('iarray'), 0, 0)^.base^.tag);
   writeln(lookup(env1, intern('list'), 0, 0)^.tag);
   writeln(get_field(lookup(env1, intern('list'), 0, 0), intern('the_array'), 0, 0)^.tag);
   writeln(get_field(lookup(env1, intern('list'), 0, 0), intern('next'), 0, 0)^.tag);
   { add_field(ty1, intern('next'), int_type, 0, 0); }
end.