;; Convert selected Scheme expressions to Coffeescript
; by Erich Blume
; see README for information and licensing

(use-modules (ice-9 syncase))

;; 'coffee' macro :: control expansion of a scheme expression.
; Sets up the environment for parsing and then hands it off to parse-expression
; (For now, doesn't do anything.)
(define-syntax coffee (syntax-rules ()
    ((_ expression) (parse-expression expression))
))

;; 'parse-expression' macro :: Parse an expression, duh!
(define-syntax parse-expression (syntax-rules (if define)

    ;; "if/else" conditional
    ((_ (if conditional a b))
        (string-append
            "if " (parse-statement conditional) "\n"
            (indent (parse-expression a)) "\n"
            "else\n"
            (indent (parse-expression b))
        )
    )

    ;; "if" conditional
    ((_ (if conditional a))
        (string-append "if " (parse-statement conditional) "\n"
            (indent (parse-expression a))
        )
    )

    ;; Lambda-implied define no-arg
    ((_ (define (f) b ...))
        (parse-expression (define f (lambda () b ...)))
    )
    ; with-arg
    ((_ (define (f arg ...) b ...))
        (parse-expression (define f (lambda (arg ...) b ...)))
    )

    ;; Basic name->value define
    ((_ (define a b))
        (string-append (smartconvert->string 'a) " = " (parse-statement b))
    )

    ;; For anything else, assume it's a statement
    ((_ unknown) (parse-statement unknown))
))

;; parse-expressions: turn multiple expressions in to a body of expressions
;   In some forms, we can have multiple adjacent statements (like with
;   (define (foo) s1 s2 s3) - this handles s1 s2 s3
(define-syntax parse-expressions (syntax-rules ()
    ;; bottom out
    ((_ stmt) (string-append "\n" (indent (parse-expression stmt))))
    
    ;; multiple stmts
    ((_ stmt nextmt ...)
        (string-append "\n"
            (indent (parse-expression stmt))
            (parse-expressions nextmt ...)
        )
    )
))

;; parse-statement: convert a statement to the equivalent coffeescript
; Note that a statement is defined as "Any guile expression which can be
; translated to a CoffeeScript expression that may be on the right side of an
; assignment operation". Not that they need to be on the right side of an
; assignment operaiton, just that they *can* be.
(define-syntax parse-statement (syntax-rules
    ;; SYNTAX-RULES bindings - quite a few here to support arithmetic
    (= + - / * and or lambda quote < > <= >=)
    ;; END bindings

    ;; OPERATORS - pass these off to a general form (parse-operator)
    ((_ (+ a b ...)) (parse-operator (+ a b ...)))
    ((_ (- a b ...)) (parse-operator (- a b ...)))
    ((_ (* a b ...)) (parse-operator (* a b ...)))
    ((_ (/ a b ...)) (parse-operator (/ a b ...)))
    ((_ (> a b ...)) (parse-operator (> a b ...)))
    ((_ (< a b ...)) (parse-operator (< a b ...)))
    ((_ (<= a b ...)) (parse-operator (<= a b ...)))
    ((_ (>= a b ...)) (parse-operator (>= a b ...)))
    ((_ (= a b ...)) (parse-operator (= a b ...)))
    ((_ (and a b ...)) (parse-operator (and a b ...)))
    ((_ (or a b ...)) (parse-operator (or a b ...)))

    ;; Lambda forms (first, no-arg)
    ((_ (lambda () body ...))
        (string-append "() -> " (parse-expressions body ...))
    )
    ; with-arg
    ((_ (lambda (arg ...) body ...))
        (string-append "(" (list-expand arg ...) ") -> "
            (parse-expressions body ...)
        )
    )

    ;; Lambda Forms w/ immediate evaluation
    ; no-arg
    ((_ ((lambda () body ...)))
        (string-append "(" (parse-statement (lambda () body ...)) ")()")
    )
    ; with-arg
    ((_ ((lambda (arg ...) body ...) earg ...))
        (string-append
            "("
            (parse-statement (lambda (arg ...) body ...))
            ")("
            (list-expand earg ...)
            ")"
        )
    )

    ;; list-literals (empty)
    ((_ (quote ())) "[]")
    ; not-empty
    ((_ (quote (a ...))) (string-append "[" (list-expand a ...) "]"))

    ;; No-arg call-syntax functors
    ((_ (func)) (string-append (smartconvert->string 'func) "()"))
    ;; With-arg call-syntax functors
    ((_ (func a ... ))
        (string-append (smartconvert->string 'func) "(" (list-expand a ...) ")")
    )

    ;; For anything else, convert it to a string and return it.
    ((_ unknown) (smartconvert->string 'unknown))
))


;; Helper to parse-inner-operator that wraps each operator form in parens
; Operators are a special class of functions that occur in infix notation in
; coffeescript, such as the arithmetic and logical functions (+, -, and, etc.)
; Note that the guile
(define-syntax parse-operator (syntax-rules ()
    ((_ (op a b ...))
        (string-append "(" (parse-inner-operator (op a b ...)) ")")
    )
))

;; Actually parse the operator
(define-syntax parse-inner-operator (syntax-rules ()
    ;; two-operand
    ((_ (op a b))
        (string-append
            (parse-statement a)
            " " (smartconvert->string 'op) " "
            (parse-statement b)
        )
    )
    ; multi-operand
    ((_ (op a b ...))
        (string-append
            (parse-statement a)
            " " (smartconvert->string 'op) " "
            (parse-inner-operator (op b ...))
        )
    )

))


;; Convert argument lists to comma-seperated lists
(define-syntax list-expand (syntax-rules ()

    ;; Bottom out
    ((_ a) (parse-statement a))

    ;; Expand
    ((_ a b ...)
        (string-append (parse-statement a) ", " (list-expand b ...))
    )
    
))

;; Convert (almost) any binding to a representative string
(define (smartconvert->string item)
    (cond
        ((number? item) (number->string item))
        ((string? item) (string-append "\"" item "\""))
        ((boolean? item) (if item "true" "false"))
        ((symbol? item)
            (if (eq? item '=)   ; coffeescript comparison is ==, not =
                "=="
                (symbol->string item)
            )
        )
        (else (throw 'unknown-expression))
    )
)

;; Append a level of indentation after each newline in the arg, plus at the
;; beginning.
(define (indent arg)
    (string-append
        "  "
        (string-join
            (string-split arg #\newline)
            "\n  "
        )
    )
)




;;;;;; IMPLEMENTATION ENDS HERE. The rest is purely for demonstration.

;; Stupid coffee_displayn function to append newlines (eg print() from Python)
;; This is only to be used for getting guile to 'print nicely' the output of
;; the 'coffee' macro so that it can be interpreted by coffeescript
(define (coffee_displayn arg) 
    (display (string-append arg "\n"))
)

;;;;; examples below: (thar be display-using code)

(define (coffee_test)
    (coffee_displayn (coffee (+ 6 3)))
    (coffee_displayn (coffee (+ (+ 6 5) (+ (+ 7 5) 3))))
    (coffee_displayn (coffee (- (+ 1 9) (+ (- 3 8) 3))))
    (coffee_displayn (coffee (+ (* 3 (/ 4 2)) (* 4 5))))
    (coffee_displayn (coffee 3))
    (coffee_displayn (coffee (+ 4 9 2)))
    (coffee_displayn (coffee '(2 3 4)))
    (coffee_displayn (coffee '((+ 2 3) 3 4)))
    (coffee_displayn (coffee (if #t 3 4)))
    (coffee_displayn (coffee (if #f 5)))
    (coffee_displayn (coffee (foo)))
    (coffee_displayn (coffee (+ (bar) 3)))
    (coffee_displayn (coffee (foo 3 4 5)))
    (coffee_displayn (coffee (/ (foo) (bar 3 (bar 5 (foo))))))
    (coffee_displayn (coffee (print "Hello " "World!")))
    (coffee_displayn (coffee (and 2 3 (foo 4))))
    (coffee_displayn (coffee (if (= 3 4 5) 6 7)))
    (coffee_displayn (coffee a))
    (coffee_displayn (coffee (define a 3)))
    (coffee_displayn (coffee (lambda () 3)))
    (coffee_displayn (coffee (lambda (x y z) (+ (* x x) (* y y) (* z z)))))
    (coffee_displayn (coffee (define (a) 5)))
    (coffee_displayn (coffee (define (foo x y) (+ x y))))
    (coffee_displayn (coffee (lambda () 3 4)))
    (coffee_displayn (coffee (lambda (a b) (foo a b) (+ a b))))
    (coffee_displayn (coffee (define (c a b) (bar a b) (* a b))))
    (coffee_displayn (coffee ((lambda () 5))))
    (coffee_displayn (coffee ((lambda (x y) (/ x y)) 2 5)))
    (coffee_displayn (coffee (define a '())))
    (coffee_displayn (coffee (define a '(1 2 3))))
    (coffee_displayn (coffee (if #t (if #f 1 2) 3)))

    ; And now let's combine those to do something cool, like calculate fibonac.
    (coffee_displayn (coffee
        (define (fibonacci n)
            (if (<= n 1)
                n
                (+ (fibonacci (- n 2)) (fibonacci (- n 1)))
            )
        )
    ))
)



