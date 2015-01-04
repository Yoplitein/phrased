module phrased.expression;

public import phrased.expression.lexer;
public import phrased.expression.parser;

string evaluate(string expression)
{
    return expression.lex.parse.resolve;
}
