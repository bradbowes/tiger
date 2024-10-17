{$mode objfpc}
unit environments;

interface

type
   generic map<t_key, t_item> = class
      key: t_key;
      item: t_item;
      protected valid: boolean;
      protected left, right: map;
      protected height: integer;
      protected procedure init(k: t_key; it: t_item);
      protected function balance(): integer;
      protected function rotate_left(): map;
      protected function rotate_right(): map;
      function lookup(k: t_key): map;
      function insert(k: t_key; it: t_item): map;
   end;

implementation

uses math;

procedure map.init(k: t_key; it: t_item);
begin
   valid := true;
   key := k;
   item := it;
   left := map.create();
   right := map.create();
   height := 1;
end;

function map.balance(): integer;
begin
   balance := left.height - right.height;
end;

function map.rotate_left(): map;
var
   t1, tmp: map;
begin
   t1 := right;
   tmp := t1.left;
   t1.left := self;
   right := tmp;
   height := max(left.height, right.height) + 1;
   t1.height := max(t1.left.height, t1.right.height) + 1;
   rotate_left := t1;
end;

function map.rotate_right(): map;
var
   t1, tmp: map;
begin
   t1 := left;
   tmp := t1.right;
   t1.right := self;
   left := tmp;
   height := max(left.height, right.height) + 1;
   t1.height := max(t1.left.height, t1.right.height) + 1;
   rotate_right := t1;
end;

function map.lookup(k: t_key): map;
begin
   if (not valid) then
      lookup := nil
   else if k < key then
      lookup := left.lookup(k)
   else if k > key then
      lookup := right.lookup(k)
   else
      lookup := self;
end;

function map.insert(k: t_key; it: t_item): map;
var
   bal: integer;
begin
   if (not valid) then
      init(k, it)
   else if k < key then
      left.insert(k, it)
   else
      right.insert(k, it);

   height := max(left.height, right.height) + 1;

   bal := balance();

   if (bal > 1) and (k < left.key) then
      insert := rotate_right()
   else if (bal < -1) and (k > right.key) then
      insert := rotate_left()
   else if (bal > 1) and (k > left.key) then
      begin
         left := left.rotate_left();
         insert := rotate_right();
      end
   else if (bal < -1) and (k < right.key) then
      begin
         right := right.rotate_right();
         insert := rotate_left();
      end
   else
      insert := self;

end;

end.
