/++
    Package for an implementation of the phrasal template language used within phrased.
    
    phrased.expression.lexer and phrased.expression.parser are publically imported.
+/
module phrased.expression;

public import phrased.expression.lexer;
public import phrased.expression.parser;

/++
    Shortcut function to lex, parse and resolve a marked up string.
+/
string evaluate(string expression)
{
    return expression.lex.parse.resolve;
}
