ca65 $1.s -o $1.o
ld65 -C memory_map.cfg $1.o -o $1.nes

rm $1.o
fceux $1.nes