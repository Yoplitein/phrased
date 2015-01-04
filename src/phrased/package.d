module phrased;

public import phrased.expression;

class PhrasedException: Exception
{
    this(string msg)
    {
        super(msg);
    }
}
