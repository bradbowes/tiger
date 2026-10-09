{$mode objfpc}
unit arraylist;

interface

type
   generic array_list<T> = class
   protected
      items: array of T;
      idx: longint;
      capacity: longint;
      increment: longint;
   public
      constructor create(n: longint);
      constructor create();
      destructor destroy(); override;
      property length: longint read idx;
      procedure push(value: T);
      function get(index: longint): T; inline;
   end;

implementation

constructor array_list.create(n: longint);
begin
   inherited create();
   idx := 0;
   increment := n;
   capacity := increment;
   setlength(items, capacity);
end;

constructor array_list.create();
begin
   inherited create();
   idx := 0;
   increment := 16384;
   capacity := increment;
   setlength(items, capacity);
end;

destructor array_list.destroy();
begin
   setlength(items, 0);
   inherited;
end;

procedure array_list.push(value: T);
begin
   if idx = capacity then
      begin
         capacity := capacity + increment;
         setlength(items, capacity);
      end;
   items[idx] := value;
   inc(idx);
end;

function array_list.get(index: longint): T;
begin
   get := items[index];
end;

end.
