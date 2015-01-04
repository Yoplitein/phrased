/++
    Data structures and functions for parsing a stream of tokens into a tree of $(SYMBOL_LINK Node)s,
    which can then be resolved into a string.
+/
module phrased.expression.parser;

private
{
    import phrased: PhrasedException;
    import phrased.expression: ExpressionRange;
    import phrased.expression.lexer: Token;
}

/++
    The exception thrown when parsing fails.
+/
class ParserException: PhrasedException
{
    this(string msg)
    {
        super(msg);
    }
}

/++
    Basic interface of a node in the expression tree.
+/
interface Node
{
    /++
        Resolve this node, and any subnodes, into a string.
    +/
    string resolve();
}

/++
    A node containing a sequence of subnodes.
+/
class SequenceNode: Node
{
    import std.array: Appender, appender;
    
    Appender!(Node[]) children; ///The subnodes within this node
    
    ///
    this() {}
    
    ///
    this(Node[] children)
    {
        this.children = appender(children);
    }
    
    /++
        Add a child node to the end of the list of subnodes.
    +/
    void add(Node node)
    {
        children.put(node);
    }
    
    ///See $(SYMBOL_LINK Node.resolve).
    override string resolve()
    {
        auto result = appender!string;
        
        foreach(child; children.data)
            result.put(child.resolve);
        
        return result.data;
    }
}

/++
    A node containing a single word.
+/
class WordNode: Node
{
    string contents; ///The word contained in this node
    
    this(string contents)
    {
        this.contents = contents;
    }
    
    ///See $(SYMBOL_LINK Node.resolve).
    override string resolve()
    {
        return contents;
    }
}

/++
    A node representing a macro expression.
+/
class MacroNode: Node
{
    WordNode name; ///The name of the macro
    SequenceNode arguments; ///The arguments to the macro
    
    ///
    this()
    {
        arguments = new SequenceNode;
    }
    
    ///
    this(WordNode name, SequenceNode arguments)
    {
        this.name = name;
        this.arguments = arguments;
    }
    
    ///See $(SYMBOL_LINK Node.resolve).
    override string resolve()
    {
        import std.string: format;
        
        //TODO: macro system
        return "<macro \"%s\" with arguments \"%s\">".format(name.resolve, arguments.resolve);
    }
}

/++
    A node representing a choice expression.
    
    Inherits from $(SYMBOL_LINK SequenceNode) as the functionality is mostly the same,
    except a single child node is chosen while resolving, instead of concatenating them all.
+/
class ChoiceNode: SequenceNode
{
    ///
    this() {}
    
    ///
    this(Node[] choices)
    {
        super(choices);
    }
    
    ///See $(SYMBOL_LINK Node.resolve).
    override string resolve()
    {
        import std.random: uniform;
        
        return children.data[uniform(0, $)].resolve;
    }
}

/++
    A container for data used during parsing.
    
    See $(SYMBOL_LINK parse) for the recommended way to use this.
+/
struct ExpressionParser
{
    import std.conv: to;
    
    import phrased.expression.lexer: TokenType;
    
    private ExpressionRange!Token tokens;
    SequenceNode result; ///The resulting SequenceNode from a successful parse
    
    /++
        Populate internal data structures and peform parsing.
    +/
    this(Token[] tokens)
    {
        this.tokens = ExpressionRange!Token(tokens);
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
        
        if(tokens.empty && tokens.previous.type != TokenType.CHOICE_END)
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
                
                if(tokens.empty && tokens.previous.type != TokenType.MACRO_END)
                    throw new ParserException("Unterminated macro");
                
                break;
            default:
                throw new ParserException("Internal parser error: unknown macro prefix");
        }
        
        tokens.popFront;
        
        return result;
    }
}

/++
    Shortcut to instantiate $(SYMBOL_LINK ExpressionParser) and get the result.
+/
SequenceNode parse(Token[] tokens)
{
    return ExpressionParser(tokens).result;
}

unittest
{
    //TODO: figure out how to properly test the parser
    //the classes and nesting complicate things a bit
}
