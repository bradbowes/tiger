all:	../tc ../tprint

../tc:	errmsg.pas symbols.pas scanner.pas ops.pas nodes.pas \
	values.pas parser.pas bindings.pas datatypes.pas semant.pas \
	transforms.pas pass1.pas pass2.pas pass3.pas x86_emitter.pas tc.pas
	fpc -FE.. -Sh -Px86_64 -O3 tc
	strip ../tc

../tprint:	errmsg.pas symbols.pas scanner.pas ops.pas nodes.pas \
	values.pas parser.pas bindings.pas datatypes.pas semant.pas \
	transforms.pas pass1.pas pass2.pas pass3.pas formats.pas tprint.pas
	fpc -FE.. -Sh -Px86_64 -O3 tprint
	strip ../tprint

