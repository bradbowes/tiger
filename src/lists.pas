{$mode objfpc}
{$modeswitch nestedprocvars}

unit lists;

interface

type
   generic list_item<t> = class
      thing: t;
      next: list_item;
   end;

   generic list<t> = class
   type
      item = specialize list_item<t>;
      iter = procedure(x: t) is nested;
   var
      first, last: item;
      length: integer;
      destructor destroy(); override;
      procedure append(thing: t);
      function contains(thing: t): boolean;
      procedure foreach(fn: iter);
   end;

implementation

procedure list.append(thing: t);
var
   it: item;
begin
   it := item.create();
   it.thing := thing;
   if first = nil then
      first := it
   else
      last.next := it;
   last := it;
   length := length + 1;
end;

function list.contains(thing: t): boolean;

   function find(it: item): boolean;
   begin
      if it = nil then
         find := false
      else if it.thing = thing then
         find := true
      else
         find := find(it.next);
   end;

begin
   contains := find(first);
end;

procedure list.foreach(fn: iter);
var
   it: item;
begin
   it := first;
   while it <> nil do
      begin
         fn(it.thing);
         it := it.next;
      end;
end;

destructor list.destroy();
var
   it, next: item;
begin
   it := first;
   while it <> nil do
      begin
         next := it.next;
         it.destroy();
         it := next;
      end;
   inherited;
end;

end.
