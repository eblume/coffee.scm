# coffee.scm
by Erich Blume <blume.erich@gmail.com>

This work hereby placed in the public domain, including all other files in
this directory or in this project.

Convert selected Scheme (guile) expressions in to equivalent CoffeeScript
expressions.

# About this project

This scheme file was created for a homework assignment in Johny Martin's San Jose State University [Programming Language Principles](http://cs.sjsu.edu/~martin/2012spring/152/htdocs/index.html) class.

In its current state, it is not what I would consider feature-complete nor bug-free. In particular, see the 'Known Limitations' section. Personally, I suspect a 'complete' solution will need an entirely different approach from the ground up.

Patches are accepted!

# Supported Expressions

* Basic arithmetic: +, -, /, *, and, and or.
* Basic comparison: =, <, >, <=, and >=.
* "if/else" (and bare-"if") statements.
* Numeric, String, and boolean (#t and #f) literals
* Quoted lists (which become literal arrays)
* Bare identifiers (in other words, variables get their names returned
  rather than having their values dumped).
* Lambda forms (eg. "(lambda (x y z) (x+y+z))")
* Define statements, including both basic defines (eg (define a 3)) and
  the shortcut lambda syntax (eg (define (foo x) (+ x 2)))
* Both lambda forms and define-lambda forms may have multiple statements.
* Lambda forms may be evaluated anonymously (ie. without being 'defined')
* Arbitrary nesting of supported expressions. IE, you can nest an
  arbitrary amount of if/else constructs or lambda constructs. Indentation
  is tracked properly. Note that depending on the situation you may need
  to append a newline to a generated code block in order to properly
  delimit the scope in CoffeeScript. (This should feel natural.)
    
# Known Limitations

* Only the supported expressions (above) are defined, behavior when using
  any other expression is completely undefined (and likely to cause totally
  insane output).
* All basic arithmetic operators are converted to infix two-argument
  equivalents. If the scheme expression had more than two arguments, they
  will be parenthesized in a right-assosciative way. For example, (+ 2 3 4)
  becomes "(2 + (3 + 4))". In some cases this may produce unequivalent code.
  Also, single or no-operator scheme arithmetic expressions are not
  supported at all, any will likely cause an error (or could cause undefined
  behavior). Example: (and 3). Advice on resolving this limitation is 
  definitely accepted.

