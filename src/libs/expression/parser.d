module libs.expression.parser;

private import libs.expression.lexer: Token;

class ParserException: Exception
{
    this(string msg)
    {
        super(msg);
    }
}

interface Node
{
    string resolve();
}

class SequenceNode: Node
{
    import std.array: Appender, appender;
    
    Appender!(Node[]) children;
    
    this() {}
    
    this(Node[] children)
    {
        this.children = appender(children);
    }
    
    void add(Node node)
    {
        children.put(node);
    }
    
    override string resolve()
    {
        auto result = appender!string;
        
        foreach(child; children.data)
            result.put(child.resolve);
        
        return result.data;
    }
}

class WordNode: Node
{
    string contents;
    
    this(string contents)
    {
        this.contents = contents;
    }
    
    override string resolve()
    {
        return contents;
    }
}

class MacroNode: Node
{
    WordNode name;
    SequenceNode arguments;
    
    this()
    {
        arguments = new SequenceNode;
    }
    
    this(WordNode name, SequenceNode arguments)
    {
        this.name = name;
        this.arguments = arguments;
    }
    
    override string resolve()
    {
        import std.string: format;
        
        //TODO: macro system
        return "<macro \"%s\" with arguments \"%s\">".format(name.resolve, arguments.resolve);
    }
}

class ChoiceNode: SequenceNode
{
    this() {}
    
    this(Node[] children)
    {
        super(children);
    }
    
    override string resolve()
    {
        import std.random: uniform;
        
        return children.data[uniform(0, $)].resolve;
    }
}

//TODO: combine this with lexer's DataRange?
private struct TokenRange
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
}

struct ExpressionParser
{
    import std.conv: to;
    
    import libs.expression.lexer: TokenType;
    
    TokenRange tokens;
    SequenceNode result;
    
    this(Token[] tokens)
    {
        this.tokens = TokenRange(tokens);
        result = new SequenceNode;
        
        while(!this.tokens.empty)
            result.add(parse);
    }
    
    private void ensure_nonempty(string message)
    {
        if(tokens.empty)
            throw new ParserException(message);
    }
    
    private Node parse()
    {
        switch(tokens.front.type) with(TokenType)
        {
            case WORD:
                return parse_word;
            case CHOICE_START:
                return parse_choice;
            case MACRO_START:
                return parse_macro;
            default:
                throw new ParserException("Unexpected token: " ~ tokens.front.to!string);
        }
    }
    
    private Node parse_word()
    {
        scope(exit) tokens.popFront;
        
        return new WordNode(tokens.front.value.to!string);
    }
    
    private Node parse_choice()
    {
        auto result = new ChoiceNode;
        auto currentPart = new SequenceNode;
        
        tokens.popFront;
        
        while(!tokens.empty && tokens.front.type != TokenType.CHOICE_END)
        {
            if(tokens.front.type == TokenType.CHOICE_SEPARATOR)
            {
                result.add(currentPart);
                tokens.popFront;
                
                currentPart = new SequenceNode;
            }
            else
                currentPart.add(parse);
        }
        
        if(tokens.empty && tokens.last.type != TokenType.CHOICE_END)
            throw new ParserException("Unterminated choice");
        
        result.add(currentPart);
        tokens.popFront;
        
        return result;
    }
    
    private Node parse_macro()
    {
        auto result = new MacroNode;
        auto startToken = tokens.front;
        
        tokens.popFront;
        ensure_nonempty("Unexpected end of macro");
        
        result.name = cast(WordNode)parse_word;
        
        ensure_nonempty("Unexpected end of macro");
        
        switch(startToken.value)
        {
            case "$":
                if(tokens.front.type != TokenType.MACRO_END)
                    throw new ParserException("Unterminated macro");
                
                break;
            case "$(":
                import std.uni: isWhite;
                
                foreach(chr; tokens.front.value)
                    if(!chr.isWhite)
                        throw new ParserException("Invalid macro: name followed by invalid characters");
                
                tokens.popFront;
                
                while(!tokens.empty && tokens.front.type != TokenType.MACRO_END)
                    result.arguments.add(parse);
                
                if(tokens.empty && tokens.last.type != TokenType.MACRO_END)
                    throw new ParserException("Unterminated macro");
                
                break;
            default:
                throw new ParserException("Internal parser error: unknown macro prefix");
        }
        
        tokens.popFront;
        
        return result;
    }
}

SequenceNode parse(Token[] tokens)
{
    return ExpressionParser(tokens).result;
}

unittest
{
    //TODO: figure out how to properly test the parser
    //the classes and nesting complicate things a bit
}
