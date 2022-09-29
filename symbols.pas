unit symbols;

interface

type
   symbol = ^symbol_t;
   symbol_t = record
      id: string;
      next: symbol;
   end;

function intern (s: string): symbol;


implementation

const
   hash_size = 1021;


type
   hash_table = array [0 .. hash_size - 1] of symbol;


var
   tbl : hash_table;


function hash(s: string): integer;
var
   h: longint;
   i: integer;
begin
   h := 31;
   for i := 1 to length(s) do
      h := (ord(s[i]) + (h * 37)) mod 514229;
   hash := h mod hash_size;
end;


function make_symbol(s: string): symbol;
var
   sym: symbol;
begin
   new(sym);
   sym^.id := s;
   make_symbol := sym;
end;


function intern(s: string): symbol;
var
   h: integer;
   sym: symbol;
begin
   h := hash (s);
   if tbl[h] = nil then begin
      tbl[h] := make_symbol(s);
      sym := tbl[h];
   end
   else begin
      sym := tbl[h];
      while sym^.id <> s do begin
         if sym^.next = nil then
            sym^.next := make_symbol(s);
         sym := sym^.next;
      end;
   end;
   intern := sym;
end;

end.
