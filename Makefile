all:	compile print

compile:	utils.p symbols.p scanners.p ops.p nodes.p parsers.p \
        bindings.p types.p compile.p 
	fpc -Sh -Px86_64 -O3 compile
	strip compile

print:	utils.p symbols.p scanners.p ops.p nodes.p parsers.p \
        formats.p print.p
	fpc -Sh -Px86_64 -O3 print
	strip print

clean:
	rm -f compile
	rm -f print
	rm -f *.o
	rm -f *.s
	rm -f ppas.sh
	rm -f *.ppu
