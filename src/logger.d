module logger;

import std.stdio;

class Logger
{
	private File _output;
	
	this(string filename)
	{
		_output = File("filename", "w");
	}
	
	void writeln(}