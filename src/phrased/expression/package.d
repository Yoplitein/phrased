module phrased.expression;

public import phrased.expression.lexer;
public import phrased.expression.parser;

struct ExpressionRange(Type)
{
    Type[] data;
    size_t index;
    
    this(Type[] data)
    {
        this.data = data;
    }
    
    void popFront()
    {
        index++;
    }
    
    Type[] slice(size_t previousIndex)
    {
        if(previousIndex > index)
            throw new PhrasedException("ExpressionRange error: invalid slice");
        
        return data[previousIndex .. index];
    }
    
    @property:
    
    Type front()
    {
        if(empty)
            throw new PhrasedException("ExpressionRange error: unexpected end of data");
        
        return data[index];
    }
    
    Type last()
    {
        if(index == 0 || index - 1 >= data.length)
            throw new PhrasedException("ExpressionRange error: attempting to fetch last element of an empty range");
        
        return data[index - 1];
    }
    
    bool empty()
    {
        return index >= data.length;
    }
    
    size_t save()
    {
        return index;
    }
}

unittest
{
    string test = "abcdef";
    auto range = ExpressionRange!char(test.dup);
    
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

/*private struct TokenRange
{
    Token[] data;
    size_t index;
    
    this(Token[] data)
    {
        this.data = data;
    }
    
    void popFront()
    {
        index++;
    }
    
    @property:
    
    Token front()
    {
        if(empty)
            throw new ParserException("Internal parser error: unexpected end of tokens");
        
        return data[index];
    }
    
    Token last()
    {
        return data[index - 1];
    }
    
    bool empty()
    {
        return index >= data.length;
    }
}*/

string evaluate(string expression)
{
    return expression.lex.parse.resolve;
}
