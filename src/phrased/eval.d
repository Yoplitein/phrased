/++
    Functions for evaluating the parse tree into text.
+/
module phrased.eval;

import std.array;
import std.meta;
import std.random;
import std.string;

import phrased.expression;

/++
    Eval a Node. Calls a specialized function.
+/
string eval(Node node)
{
    foreach(Type; AliasSeq!(WordNode, ChoiceNode, SequenceNode, VariableNode))
        if(Type casted = cast(Type)node)
            return eval(casted);
    
    assert(false);
}

/++
    Eval a WordNode.
+/
string eval(WordNode word)
{
    return word.contents;
}

/++
    Eval a ChoiceNode.
+/
string eval(ChoiceNode choice)
{
    if(choice.empty)
        return null;
    else
        return choice
            .children
            .data
            .randomCover
            .front
            .eval
        ;
}
/++
    Eval a SequenceNode.
+/
string eval(SequenceNode sequence)
{
    Appender!string result;
    
    foreach(child; sequence.children.data)
        result.put(child.eval);
    
    return result.data;
}

/++
    Eval a VariableNode.
+/
string eval(VariableNode variable)
{
    //TODO: talk to builtins/dictionaries
    return "<variable `%s` with args `%s`>".format(variable.name.eval, variable.arguments.eval);
}
