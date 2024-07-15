build:
	ca65 helloppu.s -o helloppu.o
	ld65 helloppu.o -o helloppu.nes -C memory_map.cfg

clean:
	rm *.o *.nes

run:
	fceux helloppu.nes