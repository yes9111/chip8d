module chip;

import stack;
import display;

import std.random;
import std.stdio;
import std.exception;

// SDL functions
import derelict.sdl2.sdl;

class InvalidOpcodeException : Exception
{
	public this(string msg)
	{
		super(msg);
	}
}

class Program
{
private:
	// state variables
	ubyte[0xfff + 1]	_mem; // 4095 bytes of memory
	ubyte[16]			_reg;
	bool[16]			_keystate;
	ubyte				_delaytimer;
	ubyte				_soundtimer;
	
	ushort			_address;
	ushort			_pc;
	
	uint			_fps;
	uint			_ipf;
	uint			_timestamp;
	uint			_interval;
	
	Stack!(ushort)	_stack;
	Display			_display;
	File			_log;public:
	this()
	{
		_pc = 0x200; // programs start at 0x200
		_fps = 60;
		_ipf = 10;
		_interval = 1000 / _fps;
		_timestamp = 0;
		//DerelictSDL.load();
		// initalize display
		if(SDL_Init(SDL_INIT_VIDEO) < 0) throw new SDLException("Could not initialize SDL Video.");
		
		_stack = new Stack!ushort();
		_display = new Display();
		_log = File("chip8-log.txt", "w");
	}
	
	void Load(string source)
	{
		auto f = File(source, "rb");
		f.rawRead(_mem[0x200 .. $]);
	}
	
	void Run()
	{
		/* Enters the fetch and decode loop */
		bool nquit = true;
		SDL_Event event;
		
		while(nquit)
		{
			// parse all events
			while(SDL_PollEvent(&event))
			{
				if(event.type == SDL_KEYDOWN)
					RegisterKeyPress(event);
				else if(event.type == SDL_KEYUP)
					RegisterKeyRelease(event);
				else if(event.type == SDL_QUIT)
					nquit = false;
			}
			
			DecreaseTimers();
			
			for(c; 0 .. _ipf)
			{
				DecodeOp(FetchNextOp());
			}
			WaitFrame();
			DrawFrame();
			
		}
	}
	
	int TranslateKeyPress(ref SDL_Event event){
		int key = -1 ;
		switch( event.key.keysym.sym )
		{
			case SDLK_x : key = 0 ; break ;
			case SDLK_1 : key = 1 ; break ;
			case SDLK_2 : key = 2 ; break ;
			case SDLK_3 : key = 3; break ;
			case SDLK_q : key = 4 ; break ;
			case SDLK_w : key = 5 ; break ;
			case SDLK_e : key = 6 ; break ;
			case SDLK_a : key = 7 ; break ;
			case SDLK_s : key = 8 ; break ;
			case SDLK_d : key = 9 ; break ;
			case SDLK_z : key = 10 ; break ;
			case SDLK_c : key = 11 ; break ;
			case SDLK_4 : key = 12 ; break ;
			case SDLK_r : key = 13 ; break ;
			case SDLK_f : key = 14 ; break ;
			case SDLK_v : key = 15 ; break ;
			default: break ;
		}
		return key;
	}
	
	void RegisterKeyPress(ref SDL_Event event)
	{
		int key = TranslateKeyPress(event);
		if (key != -1)
		{
			_keystate[key] = true;
		}
	}
	
	void RegisterKeyRelease(ref SDL_Event event)
	{
		int key = TranslateKeyPress(event);
		if (key != -1)
		{
			_keystate[key] = false;
		}
	}
	
	void WaitFrame()
	{
		// stalls until it's time to 
		// draw the frame
		// wait until currenttime - timestamp > interval
		while(SDL_GetTicks() - _timestamp < _interval)
		{
		}
		_timestamp = SDL_GetTicks();
	}
	
	void DrawFrame()
	{
		_display.Draw();
	}
	
	private ushort FetchNextOp()
	{
		/* Returns the next Opcode and updates the program counter */
		ushort op = ( _mem[_pc] << 8) | _mem[pc+1];
		pc += 2;
		return op;
	}
	
	private void DecodeOp(ushort op)
	{
		_log.writefln("Decoding op %x", op);
		switch(op & 0xF000)
		{
		case 0x0000:
			// possible opcodes are 0NNN, 00E0, 00EE
			switch(op)
			{
			case 0x00E0:
				Decode00E0();
				break;
			case 0x00EE:
				Decode00EE();
				break;
			case 0xNNNN:
				Decode0NNN(op);
				break;
			default:
				throw new InvalidOpcodeException("Invalid opcode with 0x0---");
			}
			break;
		case 0x1000:
			Decode1NNN(op);
			break;
		case 0x2000:
			Decode2NNN(op);
			break;
		case 0x3000:
			Decode3XNN(op);
			break;
		case 0x4000:
			Decode4XNN(op);
			break;
		case 0x5000:
			Decode5XY0(op);
			break;
		case 0x6000:
			Decode6XNN(op);
			break;
		case 0x7000:
			Decode7XNN(op);
			break;
		case 0x8000:
			switch(op & 0x000F){
			case 0x0:
				Decode8XY0(op); break;
			case 0x1:
				Decode8XY1(op); break;
			case 0x2:
				Decode8XY2(op); break;
			case 0x3:
				Decode8XY3(op); break;
			case 0x4:
				Decode8XY4(op); break;
			case 0x5:
				Decode8XY5(op); break;
			case 0x6:
				Decode8XY6(op); break;
			case 0x7:
				Decode8XY7(op); break;
			case 0xE:
				Decode8XYE(op);	break;
			}
			break;
		case 0x9000:
			Decode9XY0(op);	break;
		case 0xA000:
			DecodeANNN(op);	break;
		case 0xB000:
			DecodeBNNN(op); break;
		case 0xC000:
			DecodeCXNN(op); break;
		case 0xD000:
			DecodeDXYN(op); break;
		case 0xE000:
			switch(op & 0xF)
			{
			case 0xE:
				DecodeEX9E(op);
				break;
			case 0x1:
				DecodeEXA1(op);
				break;
			}
			break;
		case 0xF000:
			switch(op & 0xFF)
			{
			case 0x7: DecodeFX07(op); break;
			case 0xA: DecodeFX0A(op); break;
			case 0x15: DecodeFX15(op); break;
			case 0x18: DecodeFX18(op); break;
			case 0x1E: DecodeFX1E(op); break;
			case 0x29: DecodeFX29(op); break;
			case 0x33: DecodeFX33(op); break;
			case 0x55: DecodeFX55(op); break;
			case 0x65: DecodeFX65(op); break;
			}
			break;
		}
		
	}
	
private:
	// function to return X
	ref ubyte GetX(ushort op)
	{
		return _reg[op.getNibble(3)];
	}
	
	ref ubyte GetY(ushort op)
	{
		return _reg[op.getNibble(2)];
	}
	
	
	
	
	// functions to decode opcodes
	void Decode0NNN(ushort op)
	{
		// 	
		
	}
	
	void Decode00E0()
	{
		// Clears the screen
		_display.clear();
	}
	
	void Decode00EE()
	{
		// Returns from a subroutine.
		_pc = _stack.top;
		_stack.pop();
	}
	
	void Decode1NNN(ushort op)
	{
		_pc = op & 0x0FFF; // set program counter to last three places
	}
	
	void Decode2NNN(ushort op)
	{
		// Calls subroutine at NNN.
		_stack.push(_pc);
		_pc = op & 0x0FFF;
		
	}
	
	void Decode3XNN(ushort op)
	{
		// skips the next instruction if VX equals NN.
		if(GetX(op) == (op & 0x00FF))
		{
			_pc += 2;
		}
	}
	
	void Decode4XNN(ushort op)
	{
		// Skips the next instruction if VX doesn't equal NN.
		if(GetX(op) != (op & 0x00FF))
		{
			_pc += 2;
		}
	}
	
	void Decode5XY0(ushort op)
	{
		// Skips the next instruction if VX equals VY.
		if(GetX(op) == GetY(op))
		{
			_pc += 2;
		}
	}
	
	void Decode6XNN(ushort op)
	{
		// Sets VX to NN.
		GetX(op) = op & 0x00FF;
	}
	
	void Decode7XNN(ushort op)
	{
		// Adds NN to VX.
		GetX(op) += op & 0x00FF;
	}
	
	void Decode8XY0(ushort op)
	{
		// Sets VX to the value of VY.
		_reg[op.getNibble(3)] = _reg[op.getNibble(2)];
	}
	
	void Decode8XY1(ushort op)
	{
		// Sets VX to VX or VY.
		GetX(op) = GetX(op) | GetY(op);
	}
	
	void Decode8XY2(ushort op)
	{
		// Sets VX to VX and VY.
		GetX(op) = GetX(op) & GetY(op);
	}
		
	void Decode8XY3(ushort op)
	{
		// Sets VX to VX xor VY.
		GetX(op) ^= GetY(op);
	}
		
	void Decode8XY4(ushort op)
	{
		// Adds VY to VX. VF is set to 1 when there's a carry, and to 0 when there isn't.
		if(GetX(op) + GetY(op) > 0x00FF)
		{
			_reg[0xf] = 1;
		}
		else
		{
			_reg[0xf] = 0;
		}
		GetX(op) += GetY(op);
	}
	
	void Decode8XY5(ushort op)
	{
		// VY is subtracted from VX. VF is set to 0 when there's a borrow, and 1 when there isn't.
		if(GetX(op) < GetY(op))
			_reg[0xf] = 0;
		else
			_reg[0xf] = 1;		
		GetX(op) -= GetY(op);

	}
	
	void Decode8XY6(ushort op)
	{
		// Shifts VX right by one. VF is set to the value of the least significant bit of VX before the shift.
		_reg[0xF] = op & 0x0001;
		GetX(op) >>= 1;
	}
		
	void Decode8XY7(ushort op)
	{
		// Sets VX to VY minus VX. VF is set to 0 when there's a borrow, and 1 when there isn't.
		if(GetY(op) < GetX(op))
		{
			_reg[0xF] = 0;
		}
		else
		{
			_reg[0xF] = 1;
		}
		
		GetX(op) = cast(ubyte)(GetY(op) - GetX(op));
	}
	
	void Decode8XYE(ushort op)
	{
		// Shifts VX left by one. VF is set to the value of the most significant bit of VX before the shift. 
		_reg[0xF] = cast(ubyte)(GetX(op) >> 7);
		GetX(op) <<= 1;
	}
	
	void Decode9XY0(ushort op)
	{
		// Skips the next instruction if VX doesn't equal VY.
		if(GetX(op) != GetY(op))
			_pc += 2;
	}
	
	void DecodeANNN(ushort op)
	{
		// Sets I to the address NNN.
		_address = op & 0x0FFF;
	}
	
	void DecodeBNNN(ushort op)
	{
		// Jumps to the address NNN plus V0.
		_pc = op & 0x0FFF + _reg[0];
	}
	
	void DecodeCXNN(ushort op)
	{
		// Sets VX to a random number and NN.
		GetX(op) = cast(ubyte)(uniform(0, 0x00FF) & (op & 0x00FF));
	}
	
	void DecodeDXYN(ushort op)
	{
		/* Draws a sprite at coordinate (VX, VY) that has a width of 8 pixels and a height of 
		N pixels. Each row of 8 pixels is read as bit-coded starting from memory location I; 
		I value doesn't change after the execution of this instruction. 
		As described above, VF is set to 1 if any screen pixels are flipped from set to unset when
		the sprite is drawn, and to 0 if that doesn't happen.
		*/
		_reg[0xF] = 0;
		ushort i = _address;
		bool changed = false;
		uint x = GetX(op);
		_log.writefln("Drawing sprite at (%d, %d)", x, GetY(op));
		
		foreach(y; GetY(op) .. GetY(op) + op & 0x000F)
		{
			// draw a byte
			if(_display.DrawByte(x, y, _mem[i++]))
				changed = true;
		}
		
		if(changed)
			_reg[0xF] = 1;
		
	}
	
	void DecodeEX9E(ushort op)
	{
		// Skips the next instruction if the key stored in VX is pressed.
		if(_keystate[GetX(op)])
			_pc += 2;
	}
	
	void DecodeEXA1(ushort op)
	{
		// Skips the next instruction if the key stored in VX isn't pressed.
		if(!_keystate[GetX(op)])
			_pc += 2;
	}
	
	void DecodeFX07(ushort op)
	{
		// Sets VX to the value of the delay timer.
		GetX(op) = _delaytimer;
	}
	
	void DecodeFX0A(ushort op)
	{
		// A key press is awaited, and then stored in VX.
		int key = -1;
		SDL_Event event;
		while(key == -1){
			SDL_WaitEvent(&event);
			key = TranslateKeyPress(event);
		}
		
		GetX(op) = cast(ubyte)key;
	}
	
	void DecodeFX15(ushort op)
	{
		// Sets the delay timer to VX.
		_delaytimer = GetX(op);
	}
	
	void DecodeFX18(ushort op)
	{
		// Sets the sound timer to VX.
		_soundtimer = GetX(op);
	}
	
	void DecodeFX1E(ushort op)
	{
		// Adds VX to I.
		_address += GetX(op);
	}
	
	void DecodeFX29(ushort op)
	{
		// Sets I to the location of the sprite for the character in VX. Characters 0-F (in hexadecimal) are represented by a 4x5 font.
		//!TODO
		_address = cast(ubyte)(GetX(op) * 5);
	}
	
	void DecodeFX33(ushort op)
	{
		//Stores the Binary-coded decimal representation of VX at the addresses I, I plus 1, and I plus 2.
		uint num = GetX(op);
		
		for(auto i = 2; i >= 0; --i){
			_mem[_address + i] = cast(ubyte)(num % 10);
			num /= 10;
		}
	}
	
	void DecodeFX55(ushort op)
	{
		// Stores V0 to VX in memory starting at address I. 
		int num = op.getNibble(3);
		
		for(int i = 0; i <= num; ++i)
		{
			_mem[_address + i] = _reg[i];
		}
		_address += num + 1;
	}
	
	void DecodeFX65(ushort op)
	{
		// Fills V0 to VX with values from memory starting at address I. 
		int  num = op.getNibble(3);
		foreach(i; 0 .. num)
		{
			_reg[i] = _mem[_address + i];
		}
		_address += num + 1;
	}
	
	void DecreaseTimers(){
		if(_delaytimer > 0)
			--_delaytimer;
		if(_soundtimer > 0)
			--_soundtimer;
	}
}

ubyte getNibble(T, R)(T bits, R nibbleNumber)
{
	return (bits >> 4*(nibbleNumber-1)) & 0xF;
}