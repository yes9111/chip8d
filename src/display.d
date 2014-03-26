module display;

import derelict.sdl2.sdl;
import std.stdio;
class SDLException : Exception{
	this(string msg){
		super(msg);
	}
}

class Display{
	enum { width = 64, height = 32 }	
	struct Pixel
	{
		bool filled;
			
	}
	
	private Pixel[height][width] _pixels;
	
	// SDL stuff
	SDL_Surface* 	_screen; 
	Uint32 			_filledColor;
	Uint32			_blankColor;
	
	this()
	{
		
		// create surface/screen
		if((_screen = SDL_SetVideoMode(width*10, height*10, 32, SDL_DOUBLEBUF)) == null){
			SDL_Quit();
			throw new SDLException("Could not create surface");
		}
		// create color pixel
		clear();
		_filledColor = SDL_MapRGB(_screen.format, 0, 0, 0); // black
		_blankColor = SDL_MapRGB(_screen.format, 255, 255, 255); // white
		Draw(); // draw screen
	}
	
	void clear()
	{
		foreach(x ; 0 .. width)
		{
			foreach(y ; 0 .. height)
			{
				_pixels[x][y].filled = false;
			}
		}
	}
	
	bool DrawByte(uint x, uint y, ubyte data)
	{
		// returns whether a pixel was changed or not
		bool changed = false;
		foreach(i; 0 .. 8)
		{
			if(data & (1 << i))
			{
				_pixels[x+7-i][y].filled = !_pixels[x+7-i][y].filled;
				
				if(_pixels[x+7-i][y].filled == false)
					changed = true;
			}
		}
		return changed;
	}
	
	void Draw()
	{
		if(SDL_MUSTLOCK(_screen)){
			if(SDL_LockSurface(_screen) < 0){
				return ;
			}
		}
		
		foreach(y; 0 .. height){
			foreach(x ; 0 .. width){
				//writeln("Drawing pixel ", x, " ", y);
				if(_pixels[x][y].filled)
					FillLogicalPixel(x,y);
				else
					ClearLogicalPixel(x, y);
			}
		}
		
		if(SDL_MUSTLOCK(_screen)){
			SDL_UnlockSurface(_screen);
		}
		
		SDL_Flip(_screen);
	}
	
	void FillLogicalPixel(uint logicalx, uint logicaly)
	{
		foreach(y; logicaly * 10 .. (logicaly+1)*10){
			foreach(x ; logicalx * 10 .. (logicalx + 1) * 10){
				DrawPixel(_filledColor, x, y);
			}
		}
	}
	
	void ClearLogicalPixel(uint logicalx, uint logicaly)
	{
		foreach(y; logicaly * 10 .. (logicaly+1)*10){
			foreach(x ; logicalx * 10 .. (logicalx + 1) * 10){
				DrawPixel(_blankColor, x, y);
			}
		}
	}
	
	void DrawPixel(Uint32 color, uint x, uint y)
	{
		//writeln("Pixel offset by ", y*_screen.pitch /4 + x);
		Uint32* pixel = cast(Uint32*)_screen.pixels + y * _screen.pitch/4 + x;
		*pixel = color;
	}
	
}