#phrased
Phrased is a library implementing a markup language for [phrasal templates](https://en.wikipedia.org/wiki/Phrasal_template).

##Template syntax
The syntax is composed of three basic elements:

* Words
* Variables
* Choices

###Words
A word is a sequence of chracters that are not

* whitespace, as defined by Unicode
    * whitespace is preserved, however (represented as separate words in the parse tree)
* a character used to delimit variable or choice expressions, unless they are escaped with a backslash (`\`)

###Variables
A variable is an expression of the form `$variableName` or  `$(variableName arg1 arg2 ...)`.

Variables are either resolved as the result of calls to user-supplied functions, or as strings from a dictionary.

Variables implemented as functions can (theoretically) perform any kind of processing on the arguments,
running them through another lex-parse-resolve sequence, modifying the dictionary (if possible), or perhaps other operations still.

When a variable does not exist as a function, the variable resolver falls back to a dictionary object, looking up the variable name as a category of word.

###Choices
A choice is an expression of the form `{first choice|second choice|...}`.

When building a sentence one of the options, delimited by the pipe (`|`), appears in the final output.

###Nesting
Variables and choices can be nested within themselves and each other as deeply as desired, assuming adequate stack space.

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
