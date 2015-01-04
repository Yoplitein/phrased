#libsengine
libsengine is an application/library for evaluating [phrasal templates](https://en.wikipedia.org/wiki/Phrasal_template).

<!-- TODO: flesh this out a bit more -->

##Template syntax
The syntax is composed of three basic elements:

* Words
* Macros
* Choices

###Words
A word is a sequence of chracters that are either

* not whitespace, as defined by Unicode
* not an unescaped character used to delimit macro or choice constructs

###Macros
A macro is a construct of the form `$macroName` or  `$(macroName arg1 arg2 ...)`.

Macros are either a D function, or a category of word resolved from a database.
Function macros can (theoretically) perform any kind of processing on the arguments, returning the output to the parser for reevaluation, or modifying the word database, or perhaps other functions still.
Variable macros 

###Choices
A choice is a construct of the form `{first choice|second choice|...}`.

When building a sentence one of the options, delimited by the pipe (`|`), appears in the final output.

###Nesting
Macros can be nested within choices, and likewise for choices within macros.

###Examples and potential results
```
She $verbs $(optional $adjective) $nouns by the $adjective {sea shore|lemonade stand}.

She punches huge baskets by the vengeful lemonade stand.
```

```
* Gadget touches $target with a $(optional $adjective) $noun$(optional , $adverb).

* Gadget touches goppend with a flashlight, slowly.
```
