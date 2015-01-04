/++
    Package for an implementation of the phrasal template language used within phrased.
    
    phrased.expression.lexer and phrased.expression.parser are publically imported.
+/
module phrased.expression;

public import phrased.expression.lexer;
public import phrased.expression.parser;

package struct ExpressionRange(Type)
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
    
    Type previous()
    {
        if(index == 0)
            throw new PhrasedException("ExpressionRange error: attempting to fetch previous element of an unpopped range");
        
        if(index - 1 >= data.length)
            throw new PhrasedException("ExpressionRange error: attempting to fetch previous element of an empty range");
        
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

/++
    Shortcut function to lex, parse and resolve a marked up string.
+/
string evaluate(string expression)
{
    return expression.lex.parse.resolve;
}
