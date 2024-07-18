build:
	ca65 main.asm -o main.o
	ld65 main.o -o main.nes -C memory_map.cfg

clean:
	rm *.o *.nes

run:
	fceux main.nes