all:	tc tprint lib.o

tc:	utils.pas symbols.pas scanner.pas ops.pas nodes.pas \
	parser.pas bindings.pas datatypes.pas semant.pas externals.pas \
	transforms.pas pass1.pas pass2.pas pass3.pas x86_emitter.pas tc.pas
	fpc -Sh -Px86_64 -O3 tc
	strip tc

tprint:	utils.pas symbols.pas scanner.pas ops.pas nodes.pas \
	parser.pas bindings.pas datatypes.pas semant.pas externals.pas \
	transforms.pas pass1.pas pass2.pas pass3.pas formats.pas tprint.pas
	fpc -Sh -Px86_64 -O3 tprint
	strip tprint

test:	tc tprint lib.o
	cd tests; ./run_tests.sh; cd ..

lib.o:	lib/lib.s
	as -o lib.o lib/lib.s

install:	tc lib.o
	install -d /usr/local/bin/
	install -d /usr/local/share/tiger/lib/
	install tc /usr/local/bin/
	install tprint /usr/local/bin/
	install lib.o /usr/local/share/tiger/lib/

uninstall:
	rm -f /usr/local/bin/tc
	rm -f /usr/local/bin/tprint
	rm -rf /usr/local/share/tiger

clean:
	rm -f tc
	rm -f tprint
	rm -f *.o
	rm -f *.s
	rm -f a.out
	rm -f ppas.sh
	rm -f *.ppu
	rm -f lib/lib.o
	rm -f tests/test*
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


