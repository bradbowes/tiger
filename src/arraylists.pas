{$mode objfpc}
{$modeswitch nestedprocvars}

unit arraylists;

interface

type
   generic transform<t, u> = function(x: t): u;
   generic predicate<t> = function(x: t): boolean;

   generic array_list<t> = class
   private
   type
      iterator = class
      private
         index: longint;
         list: array_list;
      public
         constructor create(ls: array_list);
         function getCurrent(): t; inline;
         function moveNext(): boolean; inline;
         procedure reset();
         property current: t read getCurrent;
      end;
   const
      max_capacity = 1073741824;
      err_max_msg = 'array_list maximum capacity of 1073741824 exceeded.';
      err_min_msg = 'array_list capacity must be a positive integer.';
      err_bounds_msg = 'array_list access out of bounds.';
   var
      items: array of t;
      count: longint;
      capacity: longint;
      increment: longint;
      initial: longint;
   public
   type
      constructor create(cap: longint);
      constructor create();
      destructor destroy(); override;
      property length: longint read count;
      procedure clear();
      procedure add(value: t);
      function get(i: longint): t;
      procedure modify(i: longint; value: t);
      function getEnumerator(): iterator;
   end;

   generic function filter<t>(
         f: specialize predicate<t>;
         ls: specialize array_list<t>): specialize array_list<t>;
   generic function map<t, u>(
         f: specialize transform<t, u>;
         ls: specialize array_list<t>): specialize array_list<u>;

implementation

uses sysutils, math;

constructor array_list.create(cap: longint);
begin
   if cap > max_capacity then
      raise exception.create(err_max_msg);
   if cap < 1 then
      raise exception.create(err_min_msg);
   inherited create();
   count := 0;
   initial := cap;
   increment := cap;
   capacity := cap;
   setlength(items, capacity);
end;

constructor array_list.create();
begin
   inherited create();
   count := 0;
   initial := 256;
   increment := 256;
   capacity := 256;
   setlength(items, capacity);
end;

destructor array_list.destroy();
begin
   setlength(items, 0);
   inherited;
end;

procedure array_list.clear();
begin
   count := 0;
   increment := initial;
   capacity := initial;
   setlength(items, capacity);
end;

procedure array_list.add(value: t);
var
   fib: longint;
begin
   if count >= capacity then
      begin
         (*
            increase by fibonacci sequence factor
            converging on golden ratio
         *)
         fib := capacity + increment;
         if capacity >= max_capacity then
            raise exception.create(err_max_msg);
         increment := capacity;
         capacity := min(fib, max_capacity);
         setlength(items, capacity);
      end;
   items[count] := value;
   inc(count);
end;

function array_list.get(i: longint): t;
begin
   if (i < 0) or (i >= count) then
      raise exception.create(err_bounds_msg);
   get := items[i];
end;

procedure array_list.modify(i: longint; value: t);
begin
   if (i < 0) or (i >= count) then
      raise exception.create(err_bounds_msg);
   items[i] := value;
end;

function array_list.getEnumerator(): array_list.iterator;
begin
   getEnumerator := iterator.create(self);
end;

generic function filter<t>(
      f: specialize predicate<t>;
      ls: specialize array_list<t>): specialize array_list<t>;
var
   item: t;
   i, len: longint;
begin
   len := ls.length;
   result := specialize array_list<t>.create(len);
   for i := 0 to len - 1 do
      begin
         item := ls.get(i);
         if f(item) then result.add(item);
      end;
end;

generic function map<t, u>(
      f: specialize transform<t, u>;
      ls: specialize array_list<t>): specialize array_list<u>;
var
   i, len: longint;
begin
   len := ls.length;
   result := specialize array_list<u>.create(len);
   for i := 0 to len - 1 do
      result.add(f(ls.get(i)));
end;

constructor array_list.iterator.create(ls: array_list);
begin
   inherited create();
   list := ls;
   index := -1;
end;

function array_list.iterator.getCurrent() : t;
begin
   getCurrent := list.get(index);
end;

function array_list.iterator.moveNext() : boolean;
begin
   inc(index);
   moveNext := index < list.length;
end;

procedure array_list.iterator.reset();
begin
   index := -1;
end;

end.
