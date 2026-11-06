{$mode objfpc}
unit maps;

interface

uses symbols;

type
   generic map<T> = class
      protected
         valid: boolean;
         left, right: map;
         height: integer;
         procedure init(k: symbol; it: T);
         function balance(): integer;
         class function rotate_left(m: map): map;
         class function rotate_right(m: map): map;
      public
         key: symbol;
         item: T;
         constructor create();
         destructor destroy(); override;
         function lookup(k: symbol): T;
         class function insert(m: map; k: symbol; it: T): map;
   end;

implementation

uses math;

constructor map.create();
begin
   inherited;
   valid := false;
   key := nil;
   item := nil;
   left := nil;
   right := nil;
   height := 0;
end;

procedure map.init(k: symbol; it: T);
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

class function map.rotate_left(m: map): map;
var
   t1, tmp: map;
begin
   t1 := m.right;
   tmp := t1.left;
   t1.left := m;
   m.right := tmp;
   m.height := max(m.left.height, m.right.height) + 1;
   t1.height := max(t1.left.height, t1.right.height) + 1;
   rotate_left := t1;
end;

class function map.rotate_right(m: map): map;
var
   t1, tmp: map;
begin
   t1 := m.left;
   tmp := t1.right;
   t1.right := m;
   m.left := tmp;
   m.height := max(m.left.height, m.right.height) + 1;
   t1.height := max(t1.left.height, t1.right.height) + 1;
   rotate_right := t1;
end;

function map.lookup(k: symbol): T;
begin
   if (not valid) then
      lookup := nil
   else if k < key then
      lookup := left.lookup(k)
   else if k > key then
      lookup := right.lookup(k)
   else
      lookup := self.item;
end;

class function map.insert(m: map; k: symbol; it: T): map;
var
   bal: integer;
begin
   if (not m.valid) then
      m.init(k, it)
   else if k < m.key then
      m.left := insert(m.left, k, it)
   else if k > m.key then
      m.right := insert(m.right, k, it);

   m.height := max(m.left.height, m.right.height) + 1;

   bal := m.balance();

   if (bal > 1) and (k < m.left.key) then
      insert := rotate_right(m)
   else if (bal < -1) and (k > m.right.key) then
      insert := rotate_left(m)
   else if (bal > 1) and (k > m.left.key) then
      begin
         m.left := rotate_left(m.left);
         insert := rotate_right(m);
      end
   else if (bal < -1) and (k < m.right.key) then
      begin
         m.right := rotate_right(m.right);
         insert := rotate_left(m);
      end
   else
      insert := m;
end;

destructor map.destroy();
begin
   left.free();
   right.free();
   dispose(item);
   inherited;
end;

end.
