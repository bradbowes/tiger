{$mode objfpc}

unit arraylists;

interface

type
   generic transform<T, U> = function(x: T): U;
   generic predicate<T> = function(x: T): boolean;

   generic arraylist<T> = class
   private
   type
      iterator = class
      private
         index: longint;
         list: arraylist;
      public
         constructor create(ls: arraylist);
         function getCurrent(): T; inline;
         function moveNext(): boolean; inline;
         procedure reset();
         property current: T read getCurrent;
      end;
   const
      default_capacity = 256;
      max_capacity = 1073741824;
      err_max_msg = 'arraylist maximum capacity of 1073741824 exceeded.';
      err_min_msg = 'arraylist capacity must be a positive integer.';
      err_bounds_msg = 'arraylist access out of bounds.';
   var
      items: array of T;
      count: longint;
      capacity: longint;
      increment: longint;
      initial: longint;
   public
      constructor create(cap: longint);
      constructor create();
      destructor destroy(); override;
      property length: longint read count;
      procedure clear();
      procedure add(value: T);
      function get(i: longint): T;
      procedure modify(i: longint; value: T);
      function getEnumerator(): iterator;
   end;

   generic function filter<T>(
         f: specialize predicate<T>;
         ls: specialize arraylist<T>): specialize arraylist<T>;
   generic function map<T, U>(
         f: specialize transform<T, U>;
         ls: specialize arraylist<T>): specialize arraylist<U>;

implementation

uses sysutils, math;

constructor arraylist.create(cap: longint);
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

constructor arraylist.create();
begin
   inherited create();
   count := 0;
   initial := default_capacity;
   increment := default_capacity;
   capacity := default_capacity;
   setlength(items, capacity);
end;

destructor arraylist.destroy();
begin
   setlength(items, 0);
   inherited;
end;

procedure arraylist.clear();
begin
   count := 0;
   increment := initial;
   capacity := initial;
   setlength(items, capacity);
end;

procedure arraylist.add(value: T);
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

function arraylist.get(i: longint): T;
begin
   if (i < 0) or (i >= count) then
      raise exception.create(err_bounds_msg);
   get := items[i];
end;

procedure arraylist.modify(i: longint; value: T);
begin
   if (i < 0) or (i >= count) then
      raise exception.create(err_bounds_msg);
   items[i] := value;
end;

function arraylist.getEnumerator(): arraylist.iterator;
begin
   getEnumerator := iterator.create(self);
end;

generic function filter<T>(
      f: specialize predicate<T>;
      ls: specialize arraylist<T>): specialize arraylist<T>;
var
   item: T;
   i, len: longint;
begin
   len := ls.length;
   result := specialize arraylist<T>.create(len);
   for i := 0 to len - 1 do
      begin
         item := ls.get(i);
         if f(item) then result.add(item);
      end;
end;

generic function map<T, U>(
      f: specialize transform<T, U>;
      ls: specialize arraylist<T>): specialize arraylist<U>;
var
   i, len: longint;
begin
   len := ls.length;
   result := specialize arraylist<U>.create(len);
   for i := 0 to len - 1 do
      result.add(f(ls.get(i)));
end;

constructor arraylist.iterator.create(ls: arraylist);
begin
   inherited create();
   list := ls;
   index := -1;
end;

function arraylist.iterator.getCurrent() : T;
begin
   getCurrent := list.get(index);
end;

function arraylist.iterator.moveNext() : boolean;
begin
   inc(index);
   moveNext := index < list.length;
end;

procedure arraylist.iterator.reset();
begin
   index := -1;
end;

end.
