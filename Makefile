all:	compile print lib.o

compile:	utils.pas symbols.pas scanner.pas ops.pas nodes.pas \
	parser.pas bindings.pas datatypes.pas semant.pas externals.pas \
	transforms.pas pass1.pas pass2.pas pass3.pas compile.pas
	fpc -Sh -Px86_64 -O3 compile
	strip compile

print:	utils.pas symbols.pas scanner.pas ops.pas nodes.pas \
	parser.pas bindings.pas datatypes.pas semant.pas externals.pas \
	transforms.pas pass1.pas pass2.pas pass3.pas formats.pas print.pas
	fpc -Sh -Px86_64 -O3 print
	strip print

test:	compile print lib.o
	cd tests; ./run_tests.sh; cd ..

lib.o:	lib/lib.s
	as -o lib.o lib/lib.s

install:	compile lib.o
	install -d /usr/local/bin/
	install -d /usr/local/share/tiger/lib/
	install compile /usr/local/bin/
	install lib.o /usr/local/share/tiger/lib/

uninstall:
	rm -f /usr/local/bin/compile
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
	rm -f examples/*.o
	rm -f examples/*.s
	rm -f examples/binary_trees
	rm -f examples/calc
	rm -f examples/copy
	rm -f examples/euler1
	rm -f examples/euler2
	rm -f examples/euler3
	rm -f examples/euler4
	rm -f examples/euler5
	rm -f examples/euler6
	rm -f examples/euler7
	rm -f examples/euler8
	rm -f examples/euler9
	rm -f examples/euler13
	rm -f examples/euler14
	rm -f examples/euler15
	rm -f examples/euler17
	rm -f examples/merge
	rm -f examples/queens
	rm -f examples/wordcount


