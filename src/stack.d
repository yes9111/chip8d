module stack;

class Stack(T)
{
	class Node
	{
		private T value; 
		private Node next;
	}
	
	class Range
	{
	}
	
	//
	private Node _head;
	
	@property T top() const
	{
		return _head.value;
	}
	
	@property bool empty()
	{
		return _head is null;
	}
	
	Range getRange()
	{
		return new Range();
	}
	
	void push(U)(U val)
	{
		auto tmp = new Node();
		tmp.value = val;
		tmp.next = _head;
		_head = tmp;
	}
	
	void pop()
	{
		assert(!empty);
		_head = _head.next;
	}
}

unittest
{
	auto iStack = new Stack!int();
	iStack.push(5);
	iStack.push(10);
	iStack.push(15);
	assert(iStack.top == 15);
	iStack.pop();
	assert(iStack.top == 10);
	iStack.pop();
	assert(iStack.top == 5);
	iStack.pop();
}
