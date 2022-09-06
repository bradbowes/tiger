all:	compile print

compile:	utils.pas symbols.pas scanners.pas ops.pas nodes.pas \
        parsers.pas bindings.pas types.pas semant.pas externals.pas \
        compile.pas
	fpc -Sh -Px86_64 -O3 compile
	strip compile

print:	utils.pas symbols.pas scanners.pas ops.pas nodes.pas parsers.pas \
        formats.pas print.pas
	fpc -Sh -Px86_64 -O3 print
	strip print

test:	compile
	cd tests; ./run_tests.sh; cd ..

clean:
	rm -f compile
	rm -f print
	rm -f *.o
	rm -f *.s
	rm -f ppas.sh
	rm -f *.ppu
	rm -f tests/test*.s
	rm -f tests/test*.tiger


