all:	compile print lib.o

compile:	utils.pas symbols.pas scanners.pas ops.pas nodes.pas \
	parsers.pas bindings.pas types.pas semant.pas externals.pas \
	transforms.pas compile.pas
	fpc -Sh -Px86_64 -O3 compile
	strip compile

print:	utils.pas symbols.pas scanners.pas ops.pas nodes.pas \
	parsers.pas bindings.pas types.pas semant.pas externals.pas \
	transforms.pas formats.pas print.pas
	fpc -Sh -Px86_64 -O3 print
	strip print

test:	compile
	cd tests; ./run_tests.sh; cd ..

lib.o:	lib/lib.s
	as -o lib.o lib/lib.s

install:	compile lib.o script/tiger
	install -d /usr/local/bin/
	install -d /usr/local/share/tiger/lib/
	install compile /usr/local/bin/
	install lib.o /usr/local/share/tiger/lib/
	install script/tiger /usr/local/bin

uninstall:
	rm -f /usr/local/bin/compile
	rm -f /usr/local/bin/tiger
	rm -rf /usr/local/share/tiger

clean:
	rm -f compile
	rm -f *.o
	rm -f *.s
	rm -f ppas.sh
	rm -f *.ppu
	rm -f lib/lib.o
	rm -f tests/test*.s
	rm -f tests/test*.tiger
	rm -f tests/test*.out
	rm -f examples/a.out
	rm -f examples/output.s


