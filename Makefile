ifeq ($(OS),Windows_NT)
	TARGET = compile.exe
else
	TARGET = compile
endif

$(TARGET):	utils.p symbols.p scanners.p ops.p nodes.p parsers.p \
        formats.p compile.p
	fpc -Sh -Px86_64 -O3 compile
	strip $(TARGET)

clean:
	rm -f $(TARGET)
	rm -f *.o
	rm -f *.s
	rm -f ppas.sh
	rm -f *.ppu


