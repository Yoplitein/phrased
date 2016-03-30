/++
    Public imports of all modules and types that didn't fit anywhere else.
+/
module phrased;

public import phrased.dictionary;
public import phrased.eval;
public import phrased.expression;
public import phrased.variable;

/++
    Base class for any exceptions thrown by the library.
+/
class PhrasedException: Exception
{
    this(string msg)
    {
        super(msg);
    }
}

/++
    An input range with additional helper functions to aid in lexing and parsing.
+/
struct PhrasedRange(Type)
{
    private Type[] data;
    private size_t index;
    
    ///
    this(Type[] data)
    {
        this.data = data;
    }
    
    /++
        Input range interface. Advances the range by one element.
    +/
    void popFront()
    {
        if(!empty)
            index++;
    }
    
    /++
        Return all elements from a previous index (retrived from $(SYMBOL_LINK PhrasedRange.save)) to the current index.
        
        Throws:
            PhrasedException if previousIndex is larger than the current index.
    +/
    Type[] slice(size_t previousIndex)
    {
        if(previousIndex > index)
            throw new PhrasedException("PhrasedRange error: invalid slice");
        
        return data[previousIndex .. index];
    }
    
    @property:
    
    /++
        Input range interface. Returns the element currently at the front of the range.
        
        Throws:
            PhrasedException if the range is empty
    +/
    Type front()
    {
        if(empty)
            throw new PhrasedException("PhrasedRange error: unexpected end of data");
        
        return data[index];
    }
    
    /++
        Returns the element just before the front.
        
        Throws:
            PhrasedException if the range is at the front or the range is empty
    +/
    Type previous()
    {
        if(index == 0)
            throw new PhrasedException("PhrasedRange error: attempting to fetch previous element of an unpopped range");
        
        if(index - 1 >= data.length)
            throw new PhrasedException("PhrasedRange error: attempting to fetch previous element of an empty range");
        
        return data[index - 1];
    }
    
    /++
        Input range interface. Returns whether there are any elements left in this range.
    +/
    bool empty()
    {
        return index >= data.length;
    }
    
    /++
        Returns the current index within the underlying array. For use with $(SYMBOL_LINK PhrasedRange.slice).
    +/
    size_t save()
    {
        return index;
    }
    
    /++
        Returns the number of elements left in the range.
    +/
    size_t length()
    {
        return data[index .. $].length;
    }
}

unittest
{
    string test = "abcdef";
    auto range = PhrasedRange!char(test.dup);
    
    assert(range.front == 'a');
    assert(range.save == 0);
    range.popFront;
    assert(range.front == 'b');
    assert(range.save == 1);
    
    auto mark = range.save;
    
    range.popFront;
    range.popFront;
    range.popFront;
    range.popFront;
    range.popFront;
    assert(range.empty);
    assert(range.slice(mark) == "bcdef");
}

/++
    Lexes, parses, and evaluates expression and returns the result.
+/
string evaluate(string expression, Variables vars)
{
    return expression.lex.parse.eval(vars);
}
