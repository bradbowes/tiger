BINDIR   = /usr/local/bin/
TIGERDIR = /usr/local/share/tiger/
LIBDIR   = $(TIGERDIR)lib/

all:	tc tprint lib.o

tc:	sources.pas symbols.pas scanner.pas ops.pas nodes.pas \
	values.pas parser.pas bindings.pas datatypes.pas semant.pas \
	transforms.pas pass1.pas pass2.pas pass3.pas x86_emitter.pas tc.pas
	fpc -Sh -Px86_64 -O3 tc
	strip tc

tprint:	sources.pas symbols.pas scanner.pas ops.pas nodes.pas \
	values.pas parser.pas bindings.pas datatypes.pas semant.pas \
	transforms.pas pass1.pas pass2.pas pass3.pas formats.pas tprint.pas
	fpc -Sh -Px86_64 -O3 tprint
	strip tprint

test:	tc tprint lib.o
	cd ../tests; ./run_tests.sh; cd ../src

lib.o:	../lib/lib.s
	as -arch x86_64 -o lib.o ../lib/lib.s

install:	tc tprint ../lib/core.tlib lib.o
	install -d $(BINDIR)
	install -d $(LIBDIR)
	install tc $(BINDIR)
	install tprint $(BINDIR)
	install lib.o $(LIBDIR)
	install ../lib/core.tlib $(LIBDIR)

uninstall:
	rm -f $(BINDIR)tc
	rm -f $(BINDIR)tprint
	rm -rf $(TIGERDIR)

clean:
	rm -f tc
	rm -f tprint
	rm -f report
	rm -f *.o
	rm -f *.s
	rm -f *.res
	rm -f a.out
	rm -f ppas.sh
	rm -f *.ppu
	rm -f lib/lib.o
	rm -f ../tests/test*
	rm -f ../examples/*.o
	rm -f ../examples/*.s
	rm -f ../examples/binary_trees
	rm -f ../examples/calc
	rm -f ../examples/copy
	rm -f ../examples/echo
	rm -f ../examples/multiples
	rm -f ../examples/euler2
	rm -f ../examples/euler3
	rm -f ../examples/euler4
	rm -f ../examples/euler5
	rm -f ../examples/euler6
	rm -f ../examples/euler7
	rm -f ../examples/euler8
	rm -f ../examples/euler9
	rm -f ../examples/euler13
	rm -f ../examples/euler14
	rm -f ../examples/euler15
	rm -f ../examples/euler17
	rm -f ../examples/fib
	rm -f ../examples/namescore
	rm -f ../examples/merge
	rm -f ../examples/queens
	rm -f ../examples/wordcount
	rm -f ../boot/*.o
	rm -f ../boot/*.s
