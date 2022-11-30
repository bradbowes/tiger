all:	compile print lib.o

compile:	utils.pas symbols.pas scanner.pas ops.pas nodes.pas \
	parser.pas bindings.pas types.pas semant.pas externals.pas \
	transforms.pas pass1.pas pass2.pas pass3.pas compile.pas
	fpc -Sh -Px86_64 -O3 compile
	strip compile

print:	utils.pas symbols.pas scanner.pas ops.pas nodes.pas \
	parser.pas bindings.pas types.pas semant.pas externals.pas \
	transforms.pas pass1.pas pass2.pas pass3.pas formats.pas print.pas
	fpc -Sh -Px86_64 -O3 print
	strip print

test:	compile print lib.o
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
	rm -f print
	rm -f *.o
	rm -f *.s
	rm -f a.out
	rm -f ppas.sh
	rm -f *.ppu
	rm -f lib/lib.o
	rm -f tests/test*.s
	rm -f tests/test*.tig
	rm -f tests/test*.out
	rm -f examples/a.out
	rm -f examples/output.s


