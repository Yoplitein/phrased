/++
    Public imports of all modules and types that didn't fit anywhere else.
+/
module phrased;

public import phrased.expression;

/++
    Base class for any exceptions thrown by the library.
+/
class PhrasedException: Exception
{
    this(string msg)
    {
        super(msg);
    }
}
