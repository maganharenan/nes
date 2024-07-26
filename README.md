# Assembly NES Study Hub

![Platform][Platform] 

<img src = "https://cdnb.artstation.com/p/assets/images/images/051/999/151/large/samuel-cote-nesconsole-002l.jpg?1658715036">

#### About
This repository serves as a learning hub for NES assembly development. If you're a beginner like me, you maybe can find valuable resources to help you understand and improve NES programming here.

#### Getting Started
1. Clone this repo to your local machine;
2. Navigate to the desired study topic;

#### Generating the ROM file
To generate the rom file you will need to install an assembler.
I am currently using the assembler [CC65](https://github.com/cc65/cc65). I work on a macbook so I install it using Homebrew

``` bash
brew install cc65
```

In some project folder I have included a shell script called `ca65.sh`. This script is responsible for generating the ROM. Here is the script content:

``` shell
ca65 $1.s -o $1.o
ld65 -C memory_map.cfg $1.o -o $1.nes

rm $1.o
```

A important thing is that you will probably face an permisson error when trying to run the script. To quickly solve that you can just run this command before executing the script:

``` bash
chmod +x ca65.sh
```

in othe other projects I have used makefile to generating the ROM, so you can just run the command `make` to generate the rom, and them `make run` to execute.
It is important to say that my makefiles tries to execute the rom with [FCEUX emulator](https://fceux.com/web/home.html), so you should install it:

``` bash
brew install fceux
```

And of course you should install make:

``` bash
brew install make
```

[Platform]: https://img.shields.io/badge/platform%20-%20nes%20-%20lightblue