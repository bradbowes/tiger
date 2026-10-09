{$mode objfpc}
{$overflowchecks off}

unit symbols;

interface

type
   symbol = ^symbol_t;
   symbol_t = record
      id: string;
      next: symbol;
   end;

function intern (s: string): symbol;
function gensym(): symbol;


implementation

uses sysutils;

const
   hash_size = 65521;

var
   tbl : array [0 .. hash_size - 1] of symbol;
   next_tmp: longint = 0;
   i: integer;

function gensym(): symbol;
begin
   next_tmp := next_tmp + 1;
   gensym := intern('tmp$_' + inttostr(next_tmp));
end;

function hash(s: string): integer;
var
   h: dword;
   i, len: integer;
begin
   h := 2166136261; (* FNV-1a 32-bit offset basis *)
   len := length(s);

   for i := 1 to len do
   begin
      h := h xor byte(s[i]);
      h := h * 16777619; (* FNV-1a 32-bit prime *)
   end;

   h := h xor (h shr 16);
   h := h * $85EBCA6B;
   h := h xor (h shr 13);
   h := h * $C2B2AE35;
   h := h xor (h shr 16);

   hash := integer(h mod hash_size);
end;


function make_symbol(s: string): symbol;
var
   sym: symbol;
begin
   new(sym);
   sym^.id := s;
   sym^.next := nil;
   make_symbol := sym;
end;

function intern(s: string): symbol;
var
   h: integer;
   sym: symbol;
begin
   h := hash (s);
   if tbl[h] = nil then
      begin
         tbl[h] := make_symbol(s);
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

begin
   for i := 0 to hash_size - 1 do
      tbl[i] := nil;
end.
