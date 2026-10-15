{$mode objfpc}

unit arraylists;

interface

type
   generic ArrayList<T> = class
   private
      items: array of T;
      count: longint;
      capacity: longint;
      increment: longint;
   public
      type
         Enumerator = class
         private
            index: longint;
            list: specialize ArrayList<T>;
         public
            constructor create(ls: specialize ArrayList<T>);
            function getCurrent(): T; inline;
            function moveNext(): boolean; inline;
            procedure reset();
            property current: T read getCurrent;
         end;
      constructor create(n: longint);
      constructor create();
      destructor destroy(); override;
      property length: longint read count;
      procedure push(value: T);
      function get(i: longint): T;
      function getEnumerator(): Enumerator;
   end;


implementation

uses sysutils;

constructor ArrayList.create(n: longint);
begin
   inherited create();
   count := 0;
   increment := n;
   capacity := increment;
   setlength(items, capacity);
end;

constructor ArrayList.create();
begin
   inherited create();
   count := 0;
   increment := 16384;
   capacity := increment;
   setlength(items, capacity);
end;

destructor ArrayList.destroy();
begin
   setlength(items, 0);
   inherited;
end;

procedure ArrayList.push(value: T);
begin
   if count = capacity then
      begin
         capacity := capacity + increment;
         setlength(items, capacity);
      end;
   items[count] := value;
   inc(count);
end;

function ArrayList.get(i: longint): T;
begin
   if (i < 0) or (i >= count) then
      raise exception.create('ArrayList access out of bounds');
   get := items[i];
end;

function ArrayList.getEnumerator(): ArrayList.Enumerator;
begin
   getEnumerator := Enumerator.create(self);
end;

constructor ArrayList.Enumerator.create(ls: specialize ArrayList<T>);
begin
   inherited create();
   list := ls;
   index := -1;
end;

function ArrayList.Enumerator.getCurrent() : T;
begin
   getCurrent := list.get(index);
end;

function ArrayList.Enumerator.moveNext() : boolean;
begin
   inc(index);
   moveNext := index < list.length;
end;

procedure ArrayList.Enumerator.reset();
begin
   index := -1;
end;

end.
