module phrased.expression.lexer;

private
{
    import std.conv: to;
    
    import phrased: PhrasedException;
    import phrased.expression: ExpressionRange;
}

alias string_t = dstring;
alias char_t = dchar;

enum TokenType
{
    WORD,
    CHOICE_START,
    CHOICE_END,
    CHOICE_SEPARATOR,
    MACRO_START,
    MACRO_END,
}

class LexerException: PhrasedException
{
    this(string msg)
    {
        super(msg);
    }
}

struct Token
{
    TokenType type;
    string_t value = null;
    //TODO: line, column
}

struct ExpressionLexer
{
    import std.uni: isWhite;
    
    ExpressionRange!char_t data;
    Token[] tokens;
    int macroLevel;
    int choiceLevel;
    
    alias tokens this;
    
    this(string_t expression)
    {
        data = ExpressionRange!char_t(expression.dup);
        
        while(!data.empty)
            lex;
    }
    
    private void add(ValueType)(TokenType type, ValueType value)
    {
        tokens ~= Token(type, value.to!string_t);
    }
    
    private void ensure_nonempty(string message)
    {
        if(data.empty)
            throw new LexerException(message);
    }
    
    private void lex()
    {
        switch(data.front)
        {
            case '\\':
                return lex_escape;
            case '$':
                return lex_macro;
            case '{':
                return lex_choice;
            case '(':
                return lex_symbol;
            case ')':
                if(macroLevel == 0)
                    return lex_symbol;
                
                break;
            case '|':
            case '}':
                if(choiceLevel == 0)
                    return lex_symbol;
                
                break;
            default:
                if(data.front.isWhite)
                    return lex_whitespace;
                
                return lex_word;
        }
    }
    
    private void lex_escape()
    {
        data.popFront;
        ensure_nonempty("Unterminated escape");
        add(TokenType.WORD, data.front);
        data.popFront;
    }
    
    private void lex_macro()
    {
        macroLevel++;
        
        data.popFront;
        ensure_nonempty("Unterminated macro");
        
        if(data.front == '(')
        {
            data.popFront;
            ensure_nonempty("Unterminated macro");
            add(TokenType.MACRO_START, "$(");
            
            lex_word(true);
            
            while(!data.empty && data.front != ')')
                lex;
            
            if(tokens[$ - 2].type == TokenType.MACRO_START && tokens[$ - 1].value == "")
                throw new LexerException("Malformed macro");
            
            ensure_nonempty("Unterminated macro");
            data.popFront;
            
            add(TokenType.MACRO_END, ")");
        }
        else
        {
            add(TokenType.MACRO_START, "$");
            lex_word(true);
            
            if(tokens[$ - 1].value == "")
                throw new LexerException("Malformed macro");
            
            add(TokenType.MACRO_END, "");
        }
        
        macroLevel--;
    }
    
    private void lex_choice()
    {
        choiceLevel++;
        
        data.popFront;
        ensure_nonempty("Unterminated choice");
        add(TokenType.CHOICE_START, "{");
        
        loop: while(!data.empty)
        {
            switch(data.front)
            {
                case '|':
                    data.popFront;
                    add(TokenType.CHOICE_SEPARATOR, "|");
                    
                    goto default;
                case '}':
                    data.popFront;
                    add(TokenType.CHOICE_END, "}");
                    
                    break loop;
                default:
                    lex;
            }
        }
        
        choiceLevel--;
    }
    
    private void lex_whitespace(bool discard = false)
    {
        auto mark = data.save;
        
        while(!data.empty && data.front.isWhite)
            data.popFront;
        
        if(!discard)
            add(TokenType.WORD, data.slice(mark));
    }
    
    private void lex_word(bool simple = false)
    {
        import std.uni: isAlpha;
        
        auto mark = data.save;
        bool delegate() test;
        
        if(simple)
            test = () => data.front.isAlpha;
        else
            test = () => !data.front.isWhite && !data.front.special;
        
        while(!data.empty && test())
            data.popFront;
        
        add(TokenType.WORD, data.slice(mark));
    }
    
    private void lex_symbol()
    {
        add(TokenType.WORD, data.front);
        data.popFront;
    }
}

Token[] lex(StringType)(StringType source)
{
    return ExpressionLexer(source.to!string_t).tokens;
}

//unittest helpers
private void expect(string source, Token[] result)
{
    import std.stdio: writeln;
    
    auto lexed = source.lex;
    bool success = lexed == result;
    
    if(!success)
    {
        writeln("Expression: ", source);
        writeln("Wanted result: ", result);
        writeln("Actual result: ", lexed);
        assert(false);
    }
}

private void expect_exception(string source)
{
    try
    {
        source.lex;
        assert(false, "Expression \"" ~ source ~ "\" should have thrown an exception");
    }
    catch(PhrasedException err) {}
}

unittest
{
    with(TokenType)
    {
        //simple words
        " ".expect(
            [
                Token(WORD, " "),
            ]
        );
        "\\$".expect(
            [
                Token(WORD, "$"),
            ]
        );
        "|}".expect(
            [
                Token(WORD, "|"),
                Token(WORD, "}"),
            ]
        );
        "\\{|}".expect(
            [
                Token(WORD, "{"),
                Token(WORD, "|"),
                Token(WORD, "}"),
            ]
        );
        "\"\"".expect(
            [
                Token(WORD, "\"\""),
            ]
        );
        "abc".expect(
            [
                Token(WORD, "abc"),
            ]
        );
        "(abc)".expect(
            [
                Token(WORD, "("),
                Token(WORD, "abc"),
                Token(WORD, ")"),
            ]
        );
        "abc def".expect(
            [
                Token(WORD, "abc"),
                Token(WORD, " "),
                Token(WORD, "def"),
            ]
        );
        
        //macros
        "$abc".expect(
            [
                Token(MACRO_START, "$"),
                Token(WORD, "abc"),
                Token(MACRO_END, ""),
            ]
        );
        "$abc$def".expect(
            [
                Token(MACRO_START, "$"),
                Token(WORD, "abc"),
                Token(MACRO_END, ""),
                Token(MACRO_START, "$"),
                Token(WORD, "def"),
                Token(MACRO_END, ""),
            ]
        );
        "$(abc)$def".expect(
            [
                Token(MACRO_START, "$("),
                Token(WORD, "abc"),
                Token(MACRO_END, ")"),
                Token(MACRO_START, "$"),
                Token(WORD, "def"),
                Token(MACRO_END, ""),
            ]
        );
        "$abc$(def)".expect(
            [
                Token(MACRO_START, "$"),
                Token(WORD, "abc"),
                Token(MACRO_END, ""),
                Token(MACRO_START, "$("),
                Token(WORD, "def"),
                Token(MACRO_END, ")"),
            ]
        );
        "$abc!".expect(
            [
                Token(MACRO_START, "$"),
                Token(WORD, "abc"),
                Token(MACRO_END, ""),
                Token(WORD, "!"),
            ]
        );
        "$(abc)".expect(
            [
                Token(MACRO_START, "$("),
                Token(WORD, "abc"),
                Token(MACRO_END, ")"),
            ]
        );
        "$(abc!)".expect(
            [
                Token(MACRO_START, "$("),
                Token(WORD, "abc"),
                Token(WORD, "!"),
                Token(MACRO_END, ")"),
            ]
        );
        "$(abc )".expect(
            [
                Token(MACRO_START, "$("),
                Token(WORD, "abc"),
                Token(WORD, " "),
                Token(MACRO_END, ")"),
            ]
        );
        "$(abc def)".expect(
            [
                Token(MACRO_START, "$("),
                Token(WORD, "abc"),
                Token(WORD, " "),
                Token(WORD, "def"),
                Token(MACRO_END, ")"),
            ]
        );
        "$(abc $def)".expect(
            [
                Token(MACRO_START, "$("),
                Token(WORD, "abc"),
                Token(WORD, " "),
                Token(MACRO_START, "$"),
                Token(WORD, "def"),
                Token(MACRO_END, ""),
                Token(MACRO_END, ")"),
            ]
        );
        "$(abc $(def ghi))".expect(
            [
                Token(MACRO_START, "$("),
                Token(WORD, "abc"),
                Token(WORD, " "),
                Token(MACRO_START, "$("),
                Token(WORD, "def"),
                Token(WORD, " "),
                Token(WORD, "ghi"),
                Token(MACRO_END, ")"),
                Token(MACRO_END, ")"),
            ]
        );
        
        //choices
        "{abc|def}".expect(
            [
                Token(CHOICE_START, "{"),
                Token(WORD, "abc"),
                Token(CHOICE_SEPARATOR, "|"),
                Token(WORD, "def"),
                Token(CHOICE_END, "}"),
            ]
        );
        "{abc|}".expect(
            [
                Token(CHOICE_START, "{"),
                Token(WORD, "abc"),
                Token(CHOICE_SEPARATOR, "|"),
                Token(CHOICE_END, "}"),
            ]
        );
        "{1|{2|3}|4}".expect(
            [
                Token(CHOICE_START, "{"),
                Token(WORD, "1"),
                Token(CHOICE_SEPARATOR, "|"),
                Token(CHOICE_START, "{"),
                Token(WORD, "2"),
                Token(CHOICE_SEPARATOR, "|"),
                Token(WORD, "3"),
                Token(CHOICE_END, "}"),
                Token(CHOICE_SEPARATOR, "|"),
                Token(WORD, "4"),
                Token(CHOICE_END, "}"),
            ]
        );
        
        //nesting
        "$(abc {def|ghi})".expect(
            [
                Token(MACRO_START, "$("),
                Token(WORD, "abc"),
                Token(WORD, " "),
                Token(CHOICE_START, "{"),
                Token(WORD, "def"),
                Token(CHOICE_SEPARATOR, "|"),
                Token(WORD, "ghi"),
                Token(CHOICE_END, "}"),
                Token(MACRO_END, ")"),
            ]
        );
        "{abc|$def}".expect(
            [
                Token(CHOICE_START, "{"),
                Token(WORD, "abc"),
                Token(CHOICE_SEPARATOR, "|"),
                Token(MACRO_START, "$"),
                Token(WORD, "def"),
                Token(MACRO_END, ""),
                Token(CHOICE_END, "}"),
            ]
        );
        "{abc|$(def ghi)}".expect(
            [
                Token(CHOICE_START, "{"),
                Token(WORD, "abc"),
                Token(CHOICE_SEPARATOR, "|"),
                Token(MACRO_START, "$("),
                Token(WORD, "def"),
                Token(WORD, " "),
                Token(WORD, "ghi"),
                Token(MACRO_END, ")"),
                Token(CHOICE_END, "}"),
            ]
        );
        
        //expected failures
        "\\".expect_exception;
        "$".expect_exception;
        "($)".expect_exception;
        "{".expect_exception;
        "{|".expect_exception;
    }
}

private bool special(char_t chr)
{
    enum char_t[] specialCharacters = [
        '\\', '$', '(', ')', '{', '|', '}',
    ];
    
    foreach(special; specialCharacters)
        if(chr == special)
            return true;
    
    return false;
}
