unit symbols;

interface

type
   symbol = ^symbol_t;
   symbol_t = record
      id: string;
      next: symbol;
   end;

function intern (s: String): symbol;

implementation

const
   hash_size = 1021;
   
type
   hash_table = Array [0 .. hash_size - 1] of symbol; 

var
   tbl : hash_table;

function hash(s: string): integer;
var
   h: LongInt;
   i: Integer;
begin
   h := 31;
   for i := 1 to length(s) do
      h := (ord(s[i]) + (h * 37)) mod 514229;
   hash := h mod hash_size;
end;

function make_symbol(s: String): symbol;
var sym: symbol;
begin
  new(sym);
  sym^.id := s;
  make_symbol := sym;
end;

function intern(s: String): symbol;
var
   h: Integer;
   sym: symbol;
begin
   h := hash (s);
   if tbl[h] = nil then
      begin
         tbl[h] := make_symbol(S);
         sym := tbl[h];
      end
   else
      begin
         sym := tbl[h];
         while sym^.id <> s do
            begin
               if sym^.next = nil then
                  sym^.next := make_symbol(s);
               sym := sym^.next;
            end;
      end;
   intern := sym;
end;

end.
