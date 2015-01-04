module phrased.util;

struct Stack(Type)
{
    Type[] data;
    size_t index;
    
    @disable this();
    
    this(size_t initialSize)
    {
        data.length = initialSize;
    }
    
    void push(Type datum)
    {
        if(data.length <= index)
            data.length *= 2;
        
        data[index++] = datum;
    }
    
    Type pop()
    {
        if(empty)
            throw new Exception("stack underflow");
        
        return data[--index];
    }
    
    Type[] pop_all()
    {
        auto result = data[0 .. index];
        
        return result;
    }
    
    @property bool empty()
    {
        return index == 0;
    }
}

auto stack(Type)()
{
    return Stack!Type(1);
}

unittest
{
    auto xyz = stack!int;
    
    xyz.push(1);
    xyz.push(2);
    xyz.push(3);
    assert(xyz.pop == 3);
    assert(xyz.pop == 2);
    assert(xyz.pop == 1);
    
    try
    {
        xyz.pop;
        assert(false);
    }
    catch(Exception) {}
}

class BufferException: Exception
{
    this(string msg)
    {
        super(msg);
    }
}

struct Buffer(Type)
{
    Type[] data;
    size_t index;
    
    this(Type[] data)
    {
        this.data = data;
    }
    
    Type peek(size_t offset = 0)
    {
        if(index + offset >= data.length)
            throw new BufferException("buffer overflow");
        else
            return data[index + offset];
    }
    
    void advance()
    {
        index++;
    }
    
    bool finished()
    {
        return index >= data.length;
    }
}
