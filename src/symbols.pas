{$mode objfpc}
{$overflowchecks off}
{$h+}

unit symbols;

interface

type
   symbol = class
   protected
      id: string;
      next: symbol;
      constructor create(const s: string);
   public
      property name: string read id;
   end;

function intern (const s: string): symbol;
function gensym(): symbol;

operator < (const left, right: symbol): boolean; inline;
operator > (const left, right: symbol): boolean; inline;

implementation

uses sysutils;

const
   hash_size = 65521;

var
   tbl : array [0 .. hash_size - 1] of symbol;
   next_tmp: longint = 0;

function gensym(): symbol;
begin
   inc(next_tmp);
   gensym := intern('tmp$_' + inttostr(next_tmp));
end;

(* FNV-1a hash algorithm *)
function hash(const s: string): integer;
var
   h: longword;
   i, len: longint;
begin
   h := 2166136261;
   len := length(s);

   for i := 1 to len do
   begin
      h := h xor byte(s[i]);
      h := h * 16777619;
   end;

   h := h xor (h shr 16);
   h := h * $85EBCA6B;
   h := h xor (h shr 13);
   h := h * $C2B2AE35;
   h := h xor (h shr 16);

   hash := integer(h mod hash_size);
end;

constructor symbol.create(const s: string);
begin
   inherited create();
   id := s;
   next := nil;
end;

function intern(const s: string): symbol;
var
   h: integer;
   sym: symbol;
begin
   h := hash(s);
   if tbl[h] = nil then
      begin
         tbl[h] := symbol.create(s);
         sym := tbl[h];
      end
   else
      begin
         sym := tbl[h];
         while sym.id <> s do
            begin
               if sym.next = nil then
                  sym.next := symbol.create(s);
               sym := sym.next;
            end;
      end;
   intern := sym;
end;

operator < (const left, right: symbol): boolean; inline;
begin
  result := pointer(left) < pointer(right);
end;

operator > (const left, right: symbol): boolean; inline;
begin
  result := pointer(left) > pointer(right);
end;

end.
