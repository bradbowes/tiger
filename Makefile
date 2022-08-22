all:	compile print

compile:	utils.pas symbols.pas scanners.pas ops.pas nodes.pas \
        parsers.pas bindings.pas types.pas compile.pas 
	fpc -Sh -Px86_64 -O3 compile
	strip compile

print:	utils.pas symbols.pas scanners.pas ops.pas nodes.pas parsers.pas \
        formats.pas print.pas
	fpc -Sh -Px86_64 -O3 print
	strip print

clean:
	rm -f compile
	rm -f print
	rm -f test
	rm -f *.o
	rm -f *.s
	rm -f ppas.sh
	rm -f *.ppu
