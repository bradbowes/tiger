{$mode objfpc}

unit arraylists;

interface

type
   generic array_list<t> = class
   private
      items: array of t;
      count: longint;
      capacity: longint;
      increment: longint;
   public
      type
         iterator = class
         private
            index: longint;
            list: specialize array_list<t>;
         public
            constructor create(ls: specialize array_list<t>);
            function getCurrent(): t; inline;
            function moveNext(): boolean; inline;
            procedure reset();
            property current: t read getCurrent;
         end;
      constructor create(n: longint);
      constructor create();
      destructor destroy(); override;
      property length: longint read count;
      procedure add(value: t);
      function get(i: longint): t;
      function getEnumerator(): iterator;
   end;

implementation

uses sysutils;

constructor array_list.create(n: longint);
begin
   inherited create();
   count := 0;
   increment := n;
   capacity := increment;
   setlength(items, capacity);
end;

constructor array_list.create();
begin
   inherited create();
   count := 0;
   increment := 16384;
   capacity := increment;
   setlength(items, capacity);
end;

destructor array_list.destroy();
begin
   setlength(items, 0);
   inherited;
end;

procedure array_list.add(value: t);
begin
   if count = capacity then
      begin
         capacity := capacity + increment;
         setlength(items, capacity);
      end;
   items[count] := value;
   inc(count);
end;

function array_list.get(i: longint): t;
begin
   if (i < 0) or (i >= count) then
      raise exception.create('array_list access out of bounds');
   get := items[i];
end;

function array_list.getEnumerator(): array_list.iterator;
begin
   getEnumerator := iterator.create(self);
end;

constructor array_list.iterator.create(ls: specialize array_list<t>);
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
