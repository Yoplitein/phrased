/++
    Functions for evaluating the parse tree into text.
+/
module phrased.eval;

import std.array;
import std.meta;
import std.random;
import std.string;

import phrased.expression;
import phrased.variable;

/++
    Eval a Node. Calls a specialized function.
+/
string eval(Node node, Variables vars)
{
    foreach(Type; AliasSeq!(WordNode, ChoiceNode, SequenceNode, VariableNode))
        if(Type casted = cast(Type)node)
            return eval(casted, vars);
    
    assert(false);
}

/++
    Eval a WordNode.
+/
string eval(WordNode word, Variables vars)
{
    return word.contents;
}

/++
    Eval a ChoiceNode.
+/
string eval(ChoiceNode choice, Variables vars)
{
    if(choice.empty)
        return null;
    else
        return choice
            .children
            .data
            .randomCover
            .front
            .eval(vars)
        ;
}
/++
    Eval a SequenceNode.
+/
string eval(SequenceNode sequence, Variables vars)
{
    Appender!string result;
    
    foreach(child; sequence.children.data)
        result.put(child.eval(vars));
    
    return result.data;
}

/++
    Eval a VariableNode.
+/
string eval(VariableNode variable, Variables vars)
{
    return vars.lookup(variable.name.contents, variable.arguments);
}
