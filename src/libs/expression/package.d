module libs.expression;

public import libs.expression.lexer;
public import libs.expression.parser;

string evaluate(string expression)
{
    return expression.lex.parse.resolve;
}
