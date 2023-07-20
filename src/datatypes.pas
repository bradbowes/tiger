unit datatypes;

interface

uses errmsg, symbols;

type
   type_tag = (primitive_type, record_type, array_type, function_type, pointer_type);

   spec = ^spec_t;
   field = ^field_t;

   field_t = record
      name: symbol;
      ty: spec;
      offset: longint;
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
   string_type: spec = @_string_type;
   _char_type: spec_t = (tag: primitive_type; fields: nil; base: nil; length: 0);
   char_type: spec = @_char_type;
   _file_type: spec_t = (tag: pointer_type; fields: nil; base: nil; length: 0);
   file_type: spec = @_file_type;


procedure add_param(rec: spec; name: symbol; ty: spec; loc: source_location);
procedure add_field(rec: spec; name: symbol; ty: spec; offset: longint; loc: source_location);
function get_field(rec: spec; name: symbol; loc: source_location): field;
function make_array_type(base: spec): spec;
function make_record_type(): spec;
function make_function_type(return: spec): spec;


implementation


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


procedure append(list: field; f: field; loc: source_location);
begin
   if list^.name = f^.name then
      err('field ''' + f^.name^.id + ''' specified more than once', loc)
   else if list^.next = nil then
      list^.next := f
   else
      append(list^.next, f, loc);
end;


procedure add_param(rec: spec; name: symbol; ty: spec; loc: source_location);
var f: field;
begin
   new(f);
   f^.name := name;
   f^.ty := ty;
   f^.next := nil;

   if rec^.fields = nil then
      rec^.fields := f
   else
      append(rec^.fields, f, loc);
   rec^.length := rec^.length + 1;
end;


procedure add_field(rec: spec; name: symbol; ty: spec; offset: longint; loc: source_location);
var f: field;
begin
   new(f);
   f^.name := name;
   f^.ty := ty;
   f^.offset := offset;
   f^.next := nil;

   if rec^.fields = nil then
      rec^.fields := f
   else
      append(rec^.fields, f, loc);
   rec^.length := rec^.length + 1;
end;


function find(list: field; name: symbol): field;
begin
   if list = nil then
      find := nil
   else if list^.name = name then
      find := list
   else
      find := find(list^.next, name);
end;


function get_field(rec: spec; name: symbol; loc: source_location): field;
var f: field;
begin
   f := find(rec^.fields, name);
   if f = nil then
      err('object has no field ''' + name^.id + '''', loc);
   get_field := f;
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

