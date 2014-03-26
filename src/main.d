﻿module main;

int main(string[] args)
	// load a rom into memory
	// enter decode loop
	if(args.length != 2)
		// program to be called with 1 argument
		writefln("Emulator must be called with 2 arguments");
		return 1;
	}
	Program prgm = new Program();
	prgm.Load(args[1]);
	prgm.Run();
	return 0;
}