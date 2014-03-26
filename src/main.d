module main;import std.stdio;import chip;import display;import stack;import derelict.sdl2.sdl;

int main(string[] args){	writeln("Running Chip8 emulator...");
	// load a rom into memory
	// enter decode loop
	if(args.length != 2)	{
		// program to be called with 1 argument
		writefln("Emulator must be called with 2 arguments");
		return 1;
	}	// initialize sdl	DerelictSDL2.load();	
	Program prgm = new Program();
	prgm.Load(args[1]);
	prgm.Run();		SDL_Quit();
	return 0;
}