#phrased
Phrased is a library implementing a markup language for [phrasal templates](https://en.wikipedia.org/wiki/Phrasal_template).

##Template syntax
The syntax is composed of three basic elements:

* Words
* Variables
* Choices

###Words
A word is a sequence of characters that are not

* whitespace, as defined by Unicode
    * whitespace is preserved, however (represented as separate words in the parse tree)
* a character used to delimit variable or choice expressions, unless they are escaped with a backslash (`\`)

###Variables
A variable is a special word which is replaced with other text upon template evaluation.
They are of the form `$variableName` or  `$(variableName arg1 arg2 ...)`.

Variables can be evaluated as the result of calls to user-defined functions, called builtin variables.
If no such function is defined, a given dictionary will attempt to look up the variable name as a category of word.
It is up to the dictionary to take appropriate action if no such category exists.

Variables implemented as functions can (theoretically) perform any kind of processing on the arguments,
running them through another lex-parse-evaluate sequence, modifying the dictionary (if possible), or perhaps other operations still.

###Choices
A choice is a series of subtemplates, separated by a pipe (`|`), where one is chosen at random to replace the entire expression.
They are of the form `{first choice|second choice|...}`.

###Nesting
Variables and choices can be nested within themselves and each other as deeply as desired.

**Note:** in the current implementation, which makes use of recursion, this may be limited by stack space.

###Examples and potential results
```
She $verbs $(optional $adjective) $nouns by the $adjective {sea shore|lemonade stand}.

She punches huge baskets by the vengeful lemonade stand.
```

```
* Gadget touches $target with a $(optional $adjective) $noun$(optional , $adverb).

* Gadget touches goppend with a flashlight, slowly.
```

```
I have \${5|10|15}.

I have $15.
```

##Usage
See the [examples](examples).
