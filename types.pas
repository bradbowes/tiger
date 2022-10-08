unit types;

interface

uses symbols;

type
   type_tag = (primitive_type, record_type, array_type, function_type);

   spec = ^spec_t;
   field = ^field_t;

   field_t = record
      name: symbol;
      ty: spec;
      next: field
   end;

   spec_t = record
      tag: type_tag;
      fields: field;
      base: spec;
      length: longint;
   end;


const
   _void_type: spec_t = (tag: primitive_type; fields: nil; base: nil; length: 0);
   void_type: spec = @_void_type;
   _nil_type: spec_t = (tag: primitive_type; fields: nil; base: nil; length: 0);
   nil_type: spec = @_nil_type;
   _int_type: spec_t = (tag: primitive_type; fields: nil; base: nil; length: 0);
   int_type: spec = @_int_type;
   _bool_type: spec_t = (tag: primitive_type; fields: nil; base: nil; length: 0);
   bool_type: spec = @_bool_type;
   _string_type: spec_t = (tag: primitive_type; fields: nil; base: nil; length: 0);
   string_type: spec = @string_type;


procedure add_field(rec: spec; name: symbol; ty: spec; line, col: longint);
function get_field(rec: spec; name: symbol; line, col: longint): spec;
function make_array_type(base: spec): spec;
function make_record_type(): spec;
function make_function_type(return: spec): spec;


implementation

uses utils;


function make_record_type(): spec;
var s: spec;
begin
   new(s);
   s^.tag := record_type;
   s^.fields := nil;
   s^.base := nil;
   s^.length := 0;
   make_record_type := s;
end;


function make_function_type(return: spec): spec;
var s: spec;
begin
   new(s);
   s^.tag := function_type;
   s^.fields := nil;
   s^.base := return;
   make_function_type := s;
end;


procedure append(list: field; f: field; line, col: longint);
begin
   if list^.name = f^.name then
      err('field ''' + f^.name^.id + ''' specified more than once', line, col)
   else if list^.next = nil then
      list^.next := f
   else
      append(list^.next, f, line, col);
end;       


procedure add_field(rec: spec; name: symbol; ty: spec; line, col: longint);
var f: field;
begin
   new(f);
   f^.name := name;
   f^.ty := ty;
      
   if rec^.fields = nil then 
      rec^.fields := f
   else
      append(rec^.fields, f, line, col);
   rec^.length := rec^.length + 1;
end;


function lookup(list: field; name: symbol): spec;
begin
   if list = nil then
      lookup := nil
   else if list^.name = name then
      lookup := list^.ty
   else
      lookup := lookup(list^.next, name);
end;


function get_field(rec: spec; name: symbol; line, col: longint): spec;
var ty: spec;
begin
   ty := lookup(rec^.fields, name);
   if ty = nil then
      err('object has no field ''' + name^.id + '''', line, col);
   get_field := ty;
end;


function make_array_type(base: spec): spec;
var s: spec;
begin
   new(s);
   s^.tag := array_type;
   s^.fields := nil;
   s^.base := base;
   make_array_type := s;
end;

end.

