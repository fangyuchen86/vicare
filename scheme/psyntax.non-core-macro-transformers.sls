;;;Copyright (c) 2010-2015 Marco Maggi <marco.maggi-ipsu@poste.it>
;;;Copyright (c) 2006, 2007 Abdulaziz Ghuloum and Kent Dybvig
;;;
;;;Permission is hereby  granted, free of charge,  to any person obtaining  a copy of
;;;this software and associated documentation files  (the "Software"), to deal in the
;;;Software  without restriction,  including without  limitation the  rights to  use,
;;;copy, modify,  merge, publish, distribute,  sublicense, and/or sell copies  of the
;;;Software,  and to  permit persons  to whom  the Software  is furnished  to do  so,
;;;subject to the following conditions:
;;;
;;;The above  copyright notice and  this permission notice  shall be included  in all
;;;copies or substantial portions of the Software.
;;;
;;;THE  SOFTWARE IS  PROVIDED  "AS IS",  WITHOUT  WARRANTY OF  ANY  KIND, EXPRESS  OR
;;;IMPLIED, INCLUDING BUT  NOT LIMITED TO THE WARRANTIES  OF MERCHANTABILITY, FITNESS
;;;FOR A  PARTICULAR PURPOSE AND NONINFRINGEMENT.   IN NO EVENT SHALL  THE AUTHORS OR
;;;COPYRIGHT HOLDERS BE LIABLE FOR ANY  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
;;;AN ACTION OF  CONTRACT, TORT OR OTHERWISE,  ARISING FROM, OUT OF  OR IN CONNECTION
;;;WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


;;;; copyright notice for the original code of the XOR macro
;;;
;;;Copyright (c) 2008 Derick Eddington
;;;
;;;Permission is hereby  granted, free of charge,  to any person obtaining  a copy of
;;;this software and associated documentation files  (the "Software"), to deal in the
;;;Software  without restriction,  including without  limitation the  rights to  use,
;;;copy, modify,  merge, publish, distribute,  sublicense, and/or sell copies  of the
;;;Software,  and to  permit persons  to whom  the Software  is furnished  to do  so,
;;;subject to the following conditions:
;;;
;;;The above  copyright notice and  this permission notice  shall be included  in all
;;;copies or substantial portions of the Software.
;;;
;;;Except as  contained in this  notice, the name(s)  of the above  copyright holders
;;;shall not be  used in advertising or  otherwise to promote the sale,  use or other
;;;dealings in this Software without prior written authorization.
;;;
;;;THE  SOFTWARE IS  PROVIDED  "AS IS",  WITHOUT  WARRANTY OF  ANY  KIND, EXPRESS  OR
;;;IMPLIED, INCLUDING BUT  NOT LIMITED TO THE WARRANTIES  OF MERCHANTABILITY, FITNESS
;;;FOR A  PARTICULAR PURPOSE AND NONINFRINGEMENT.   IN NO EVENT SHALL  THE AUTHORS OR
;;;COPYRIGHT HOLDERS BE LIABLE FOR ANY  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
;;;AN ACTION OF  CONTRACT, TORT OR OTHERWISE,  ARISING FROM, OUT OF  OR IN CONNECTION
;;;WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


;;;;copyright notice for the original code of RECEIVE
;;;
;;;Copyright (C) John David Stone (1999). All Rights Reserved.
;;;
;;;Permission is hereby  granted, free of charge,  to any person obtaining  a copy of
;;;this software and associated documentation files  (the "Software"), to deal in the
;;;Software  without restriction,  including without  limitation the  rights to  use,
;;;copy, modify,  merge, publish, distribute,  sublicense, and/or sell copies  of the
;;;Software,  and to  permit persons  to whom  the Software  is furnished  to do  so,
;;;subject to the following conditions:
;;;
;;;The above  copyright notice and  this permission notice  shall be included  in all
;;;copies or substantial portions of the Software.
;;;
;;;THE  SOFTWARE IS  PROVIDED  "AS IS",  WITHOUT  WARRANTY OF  ANY  KIND, EXPRESS  OR
;;;IMPLIED, INCLUDING BUT  NOT LIMITED TO THE WARRANTIES  OF MERCHANTABILITY, FITNESS
;;;FOR A  PARTICULAR PURPOSE AND  NONINFRINGEMENT. IN NO  EVENT SHALL THE  AUTHORS OR
;;;COPYRIGHT HOLDERS BE LIABLE FOR ANY  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
;;;AN ACTION OF  CONTRACT, TORT OR OTHERWISE,  ARISING FROM, OUT OF  OR IN CONNECTION
;;;WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


(library (psyntax.non-core-macro-transformers)
  (export non-core-macro-transformer)
  (import (except (rnrs)
		  eval
		  environment		environment?
		  null-environment	scheme-report-environment
		  identifier?
		  bound-identifier=?	free-identifier=?
		  generate-temporaries
		  datum->syntax		syntax->datum
		  syntax-violation	make-variable-transformer)
    (psyntax.compat)
    (prefix (rnrs syntax-case) sys.)
    (only (psyntax.syntax-utilities)
	  syntax-unwrap
	  parse-logic-predicate-syntax)
    (psyntax.lexical-environment)
    (psyntax.syntax-match)
    (only (psyntax.syntax-utilities)
	  generate-temporaries
	  parse-logic-predicate-syntax
	  error-invalid-formals-syntax)
    (only (psyntax.syntactic-binding-properties)
	  identifier-unsafe-variant)
    (psyntax.tag-and-tagged-identifiers)
    (only (psyntax.library-manager)
	  current-include-loader
	  source-code-location))

  (include "psyntax.helpers.scm" #t)


(define* (non-core-macro-transformer {x symbol?})
  ;;Map symbols representing non-core macros to their macro transformers.
  ;;
  (case x
    ((exported-define)			exported-define-macro)
    ((define-struct)			define-struct-macro)
    ((define-record-type)		define-record-type-macro)
    ((record-type-and-record?)		record-type-and-record?-macro)
    ((define-condition-type)		define-condition-type-macro)
    ((cond)				cond-macro)
    ((do)				do-macro)
    ((do*)				do*-macro)
    ((dolist)				dolist-macro)
    ((dotimes)				dotimes-macro)
    ((or)				or-macro)
    ((and)				and-macro)
    ((let*)				let*-macro)
    ((let-values)			let-values-macro)
    ((let*-values)			let*-values-macro)
    ((values->list)			values->list-macro)
    ((syntax-rules)			syntax-rules-macro)
    ((quasiquote)			quasiquote-macro)
    ((quasisyntax)			quasisyntax-macro)
    ((with-syntax)			with-syntax-macro)
    ((when)				when-macro)
    ((unless)				unless-macro)
    ((case)				case-macro)
    ((case-identifiers)			case-identifiers-macro)
    ((identifier-syntax)		identifier-syntax-macro)
    ((time)				time-macro)
    ((delay)				delay-macro)
    ((assert)				assert-macro)
    ((guard)				guard-macro)
    ((define-enumeration)		define-enumeration-macro)
    ((let*-syntax)			let*-syntax-macro)
    ((let-constants)			let-constants-macro)
    ((let*-constants)			let*-constants-macro)
    ((letrec-constants)			letrec-constants-macro)
    ((letrec*-constants)		letrec*-constants-macro)
    ((case-define)			case-define-macro)
    ((define*)				define*-macro)
    ((case-define*)			case-define*-macro)
    ((lambda*)				lambda*-macro)
    ((case-lambda*)			case-lambda*-macro)

    ((trace-lambda)			trace-lambda-macro)
    ((trace-define)			trace-define-macro)
    ((trace-let)			trace-let-macro)
    ((trace-define-syntax)		trace-define-syntax-macro)
    ((trace-let-syntax)			trace-let-syntax-macro)
    ((trace-letrec-syntax)		trace-letrec-syntax-macro)

    ((define-syntax-parameter)		define-syntax-parameter-macro)
    ((syntax-parametrise)		syntax-parametrise-macro)

    ((include)				include-macro)
    ((define-integrable)		define-integrable-macro)
    ((define-inline)			define-inline-macro)
    ((define-constant)			define-constant-macro)
    ((define-inline-constant)		define-inline-constant-macro)
    ((define-values)			define-values-macro)
    ((define-constant-values)		define-constant-values-macro)
    ((receive)				receive-macro)
    ((receive-and-return)		receive-and-return-macro)
    ((begin0)				begin0-macro)
    ((xor)				xor-macro)
    ((define-syntax-rule)		define-syntax-rule-macro)
    ((define-auxiliary-syntaxes)	define-auxiliary-syntaxes-macro)
    ((define-syntax*)			define-syntax*-macro)
    ((with-implicits)			with-implicits-macro)
    ((set-cons!)			set-cons!-macro)

    ((with-unwind-protection)		with-unwind-protection-macro)
    ((unwind-protect)			unwind-protect-macro)
    ((with-blocked-exceptions)		with-blocked-exceptions-macro)
    ((with-current-dynamic-environment)	with-current-dynamic-environment-macro)

    ;; non-Scheme style syntaxes
    ((while)				while-macro)
    ((until)				until-macro)
    ((for)				for-macro)
    ((returnable)			returnable-macro)
    ((try)				try-macro)

    ((parameterize)			parameterize-macro)
    ((parametrise)			parameterize-macro)

    ;; compensations
    ((with-compensations)		with-compensations-macro)
    ((with-compensations/on-error)	with-compensations/on-error-macro)
    ((with-compensation-handler)	with-compensation-handler-macro)
    ((compensate)			compensate-macro)
    ((push-compensation)		push-compensation-macro)

    ;; coroutines
    ((concurrently)			concurrently-macro)
    ((monitor)				monitor-macro)

    ((unsafe)				unsafe-macro)

    ((pre-incr)				pre-incr-macro)
    ((pre-decr)				pre-decr-macro)
    ((post-incr)			post-incr-macro)
    ((post-decr)			post-decr-macro)
    ((infix)				infix-macro)

    ((eol-style)
     (lambda (x)
       (%allowed-symbol-macro x '(none lf cr crlf nel crnel ls))))

    ((error-handling-mode)
     (lambda (x)
       (%allowed-symbol-macro x '(ignore raise replace))))

    ((buffer-mode)
     (lambda (x)
       (%allowed-symbol-macro x '(none line block))))

    ((endianness)			endianness-macro)
    ((file-options)			file-options-macro)
    ((expander-options)			expander-options-macro)
    ((compiler-options)			compiler-options-macro)

    ((... => _
	  else unquote unquote-splicing
	  unsyntax unsyntax-splicing
	  fields mutable immutable parent protocol
	  sealed opaque nongenerative parent-rtd
	  catch finally)
     (lambda (expr-stx)
       (syntax-violation #f "incorrect usage of auxiliary keyword" expr-stx)))

    ((__file__)
     (lambda (stx)
       (let ((expr (stx-expr stx)))
	 (if (annotation? expr)
	     (let ((pos (annotation-textual-position expr)))
	       (if (source-position-condition? pos)
		   (bless
		    `(quote ,(source-position-port-id pos)))
		 (bless
		  `(quote ,(source-code-location)))))
	   (bless
	    `(quote ,(source-code-location)))))))

    ((__line__)
     (lambda (stx)
       (let ((expr (stx-expr stx)))
	 (if (annotation? expr)
	     (let ((pos (annotation-textual-position expr)))
	       (if (source-position-condition? pos)
		   (bless
		    `(quote ,(source-position-line pos)))
		 (bless '(quote #f))))
	   (bless '(quote #f))))))

    ((stdin)	(lambda (stx) (bless '(console-input-port))))
    ((stdout)	(lambda (stx) (bless '(console-output-port))))
    ((stderr)	(lambda (stx) (bless '(console-error-port))))

    ;;Expander tags.
    ((<top> <void>
	    <boolean> <char> <symbol> <keyword> <pointer> <transcoder>
	    <procedure> <predicate>
	    <fixnum> <flonum> <ratnum> <bignum> <compnum> <cflonum>
	    <rational-valued> <rational> <integer> <integer-valued>
	    <exact-integer> <real> <real-valued> <complex> <number>
	    <string> <vector> <pair> <list> <bytevector> <hashtable>
	    <record> <record-type-descriptor> <struct> <struct-type-descriptor> <condition>
	    <port> <input-port> <output-port> <input/output-port> <textual-port> <binary-port>
	    <textual-input-port> <textual-output-port> <textual-input/output-port>
	    <binary-input-port> <binary-output-port> <binary-input/output-port>)
     (lambda (expr-stx)
       (syntax-violation #f "incorrect usage of built-in tag keyword" expr-stx)))

    (else
     (assertion-violation/internal-error __who__ "unknown non-core macro name" x))))


;;;; non-core macro: DEFINE

(module (exported-define-macro)

  (define (exported-define-macro input-form.stx)
    ;;Transformer function used  to expand Vicare's DEFINE macros  from the top-level
    ;;built in environment.   Expand the contents of INPUT-FORM.STX;  return a syntax
    ;;object that must be further expanded.
    ;;
    (syntax-match input-form.stx (brace)
      ;;Tagged return values and possibly tagged formals.
      ((_ ((brace ?who ?rv-tag* ... . ?rv-rest-tag) . ?fmls) . ?body)
       (%process-function-definition input-form.stx
				     (lambda (who)
				       `((brace ,who ,@?rv-tag* . ,?rv-rest-tag) . ,?fmls))
				     ?who `((brace _ ,@?rv-tag* . ,?rv-rest-tag) . ,?fmls) ?body))

      ((_ (brace ?id ?tag) ?expr)
       (bless
	`(internal-define () (brace ,?id ,?tag) ,?expr)))

      ((_ (brace ?id ?tag))
       (bless
	`(internal-define () (brace ,?id ,?tag))))

      ;;Untagged return values and possibly tagged formals.
      ((_ (?who . ?fmls) . ?body)
       (%process-function-definition input-form.stx
				     (lambda (who)
				       (cons who ?fmls))
				     ?who ?fmls ?body))

      ((_ ?id ?expr)
       (bless
	`(internal-define () ,?id ,?expr)))

      ((_ ?id)
       (bless
	`(internal-define () ,?id)))
      ))

  (define (%process-function-definition input-form.stx make-define-formals who.id prototype.stx unsafe-body*.stx)
    ;;When the function definition is fully untagged:
    ;;
    ;;   (define (add a b) (+ a b))
    ;;
    ;;we just want to  return the transformed version in which  DEFINE is replaced by
    ;;INTERNAL-DEFINE:
    ;;
    ;;   (internal-define (unsafe) (add a b) (+ a b))
    ;;
    ;;When there are tags:
    ;;
    ;;   (define ({add <real>} {a <real>} {b <real>})
    ;;     (+ a b))
    ;;
    ;;we want the full transformation:
    ;;
    ;;   (begin
    ;;     (internal-define (safe)   ({add <real>} {a <real>} {b <real>})
    ;;       ($add a b))
    ;;     (internal-define (safe-retvals unsafe-formals) ({~add <real>} {a <real>} {b <real>})
    ;;       (+ a b))
    ;;     (begin-for-syntax
    ;;       (set-identifier-unsafe-variant! #'add #'~add)))
    ;;
    (receive (standard-formals.stx signature)
	(parse-tagged-lambda-proto-syntax (bless prototype.stx)
					  input-form.stx)
      (cond ((lambda-signature-fully-unspecified? signature)
	     ;;If  no type  is specified:  just generate  a standard  Scheme function
	     ;;definition.
	     (bless
	      `(internal-define (unsafe) ,(cons who.id standard-formals.stx) . ,unsafe-body*.stx)))

	    ((retvals-signature-fully-unspecified? (lambda-signature-retvals signature))
	     ;;If only  the return values  have specified type signature:  generate a
	     ;;single function definition with type checking for the return values.
	     ;;
	     ;;This is the  case, for example, of predicate functions:  we known that
	     ;;there is a single argument of any  type and a single return value with
	     ;;type "<boolean>".
	     (bless
	      `(internal-define (safe-retvals unsafe-formals) ,(make-define-formals who.id)
		 . ,unsafe-body*.stx)))

	    (else
	     ;;Both  the  arguments  and  the return  values  have  type  signatures:
	     ;;generate 2 function definitions, the safe and the unsafe one.
	     (let* ((UNSAFE-WHO    (identifier-append who.id "~" who.id))
		    (safe-body.stx (if (list? standard-formals.stx)
				       (cons UNSAFE-WHO standard-formals.stx)
				     (receive (arg*.id rest.id)
					 (improper-list->list-and-rest standard-formals.stx)
				       `(apply ,UNSAFE-WHO ,@arg*.id ,rest.id)))))
	       (bless
		`(begin
		   (internal-define (safe) ,(make-define-formals who.id)
		     ,safe-body.stx)
		   (internal-define (safe-retvals unsafe-formals) ,(make-define-formals UNSAFE-WHO)
		     . ,unsafe-body*.stx)
		   (begin-for-syntax
		     (set-identifier-unsafe-variant! (syntax ,who.id) (syntax ,UNSAFE-WHO)))))
	       )))))

  #| end of module |# )


;;;; non-core macro: DEFINE-AUXILIARY-SYNTAXES

(define (define-auxiliary-syntaxes-macro expr-stx)
  ;;Transformer      function      used     to      expand      Vicare's
  ;;DEFINE-AUXILIARY-SYNTAXES  macros   from  the  top-level   built  in
  ;;environment.   Expand  the contents  of  EXPR-STX;  return a  syntax
  ;;object that must be further expanded.
  ;;
  ;;Using an empty SYNTAX-RULES as  transformer function makes sure that
  ;;whenever an auxiliary syntax is referenced an error is raised.
  ;;
  (syntax-match expr-stx ()
    ((_ ?id* ...)
     (for-all identifier? ?id*)
     (bless
      `(begin
	 ,@(map (lambda (id)
		  `(define-syntax ,id (syntax-rules ())))
	     ?id*))))))


;;;; non-core macro: control structures macros

(define (when-macro expr-stx)
  (syntax-match expr-stx ()
    ((_ ?test ?expr ?expr* ...)
     (bless `(if ,?test (begin ,?expr . ,?expr*))))))

(define (unless-macro expr-stx)
  (syntax-match expr-stx ()
    ((_ ?test ?expr ?expr* ...)
     (bless `(if (not ,?test) (begin ,?expr . ,?expr*))))))


;;;; non-core macro: CASE

(module (case-macro)
  ;;Transformer function used to expand R6RS's CASE macros (with extensions) from the
  ;;top-level built in environment.  Expand the contents of EXPR-STX; return a syntax
  ;;object that must be further expanded.
  ;;
  ;;This implementation  supports 2 extensions with  respect to the one  specified by
  ;;R6RS:
  ;;
  ;;1. It supports arrow clauses like COND does.  Example:
  ;;
  ;;      (case 123
  ;;       ((123) => (lambda (num) ...)))
  ;;
  ;;2. When the  datums are strings, bytevectors, pairs or  vectors: it compares them
  ;;   using  STRING=?, BYTEVECTOR=?,  EQUAL? and  EQUAL? rather  than using  EQV? as
  ;;   specified by R6RS.
  ;;
  ;;An example expansion:
  ;;
  ;;   (case ?expr
  ;;     ((1 "a" c)
  ;;      (stuff1))
  ;;     ((2 #t #(1 2))
  ;;      (stuff2))
  ;;     (else
  ;;      (else-stuff)))
  ;;
  ;;is expanded to:
  ;;
  ;;   (letrec ((expr.id ?expr)
  ;;            (g1      (lambda () (stuff1)))
  ;;            (g2      (lambda () (stuff2)))
  ;;            (else.id (lambda () (else-stuff))))
  ;;     (cond ((number? expr.id)
  ;;            (cond ((= expr.id 1)
  ;;                   (g1))
  ;;                  ((= expr.id 2)
  ;;                   (g2))
  ;;                  (else
  ;;                   (else.id)))
  ;;           ((string? expr.id)
  ;;            (cond ((string=? expr.id "a")
  ;;                   (g1))
  ;;                  (else
  ;;                   (else.id)))
  ;;           ((symbol? expr.id)
  ;;            (cond ((eq? expr.id 'c)
  ;;                   (g1))
  ;;                  (else
  ;;                   (else.id)))
  ;;           ((boolean? expr.id)
  ;;            (cond ((boolean=? expr.id #t)
  ;;                   (g2))
  ;;                  (else
  ;;                   (else.id)))
  ;;           ((vector? expr.id)
  ;;            (cond ((equal? expr.id '#(1 2))
  ;;                   (g2))
  ;;                  (else
  ;;                   (else.id)))
  ;;           (else
  ;;            (else.id)))
  ;;
  ;;NOTE This implementation contains ideas from:
  ;;
  ;;    William  D.   Clinger.   "Rapid   case  dispatch  in  Scheme".   Northeastern
  ;;    University.   Proceedings  of  the 2006  Scheme  and  Functional  Programming
  ;;   Workshop.  University of Chicago Technical Report TR-2006-06.
  ;;
  ;;FIXME There is room for improvement.  (Marco Maggi; Thu Apr 17, 2014)
  ;;
  (define-module-who case)

  (define (case-macro input-form.stx)
    (syntax-match input-form.stx (else)
      ;;Without ELSE clause.
      ((_ ?expr ((?datum0* ?datum** ...) ?body0* ?body** ...) ...)
       (%build-output-form input-form.stx ?expr
			   (map cons
			     (map cons ?datum0* ?datum**)
			     (map cons ?body0*  ?body**))
			   (bless '((void)))))

      ;;With else clause.
      ((_ ?expr ((?datum0* ?datum** ...) ?body0* ?body** ...) ... (else ?else-body0 ?else-body* ...))
       (%build-output-form input-form.stx ?expr
			   (map cons
			     (map cons ?datum0* ?datum**)
			     (map cons ?body0*  ?body**))
			   (cons ?else-body0 ?else-body*)))

      (_
       (syntax-violation __module_who__ "invalid syntax" input-form.stx))))

  (define (%build-output-form input-form.stx expr.stx datum-clause*.stx else-body*.stx)
    (let ((expr.id (gensym "expr.id"))
	  (else.id (gensym "else.id")))
      (receive (branch-binding* cond-clause*)
	  (%process-clauses input-form.stx expr.id else.id datum-clause*.stx)
	(bless
	 `(letrec ((,expr.id ,expr.stx)
		   ,@branch-binding*
		   (,else.id (lambda () . ,else-body*.stx)))
	    (cond ,@cond-clause* (else (,else.id))))))))

  (define (%process-clauses input-form.stx expr.id else.id clause*.stx)
    (receive (closure*.stx closure*.id entry**)
	(%clauses->entries input-form.stx clause*.stx)
      (define boolean-entry*		'())
      (define char-entry*		'())
      (define null-entry*		'())
      (define symbol-entry*		'())
      (define number-entry*		'())
      (define string-entry*		'())
      (define bytevector-entry*		'())
      (define pair-entry*		'())
      (define vector-entry*		'())
      (define-syntax-rule (mk-datum-clause ?pred.sym ?compar.sym ?entry*)
	(%make-datum-clause input-form.stx expr.id else.id (core-prim-id '?pred.sym) (core-prim-id '?compar.sym) ?entry*))
      (let loop ((entry* (apply append entry**)))
	(when (pair? entry*)
	  (let ((datum (syntax->datum (caar entry*))))
	    (cond ((boolean? datum)
		   (set-cons! boolean-entry* (car entry*))
		   (loop (cdr entry*)))

		  ((char? datum)
		   (set-cons! char-entry* (car entry*))
		   (loop (cdr entry*)))

		  ((symbol? datum)
		   (set-cons! symbol-entry* (car entry*))
		   (loop (cdr entry*)))

		  ((number? datum)
		   (set-cons! number-entry* (car entry*))
		   (loop (cdr entry*)))

		  ((string? datum)
		   (set-cons! string-entry* (car entry*))
		   (loop (cdr entry*)))

		  ((bytevector? datum)
		   (set-cons! bytevector-entry* (car entry*))
		   (loop (cdr entry*)))

		  ((pair? datum)
		   (set-cons! pair-entry* (car entry*))
		   (loop (cdr entry*)))

		  ((null? datum)
		   (set-cons! null-entry* (car entry*))
		   (loop (cdr entry*)))

		  ((vector? datum)
		   (set-cons! vector-entry* (car entry*))
		   (loop (cdr entry*)))

		  (else
		   (syntax-violation __module_who__ "invalid datum type" input-form.stx datum))))))
      (values (map list closure*.id closure*.stx)
	      ($fold-left/stx (lambda (knil clause)
				(if (null? clause)
				    knil
				  (cons clause knil)))
		'()
		(list
		 (mk-datum-clause boolean?	boolean=?	boolean-entry*)
		 (mk-datum-clause char?		$char=		char-entry*)
		 (mk-datum-clause symbol?	eq?		symbol-entry*)
		 (%make-numbers-clause input-form.stx expr.id else.id number-entry*)
		 (mk-datum-clause string?	$string=	string-entry*)
		 (mk-datum-clause bytevector?	$bytevector=	bytevector-entry*)
		 (mk-datum-clause pair?		equal?		pair-entry*)
		 (mk-datum-clause vector?	equal?		vector-entry*)
		 (%make-null-clause input-form.stx expr.id null-entry*)
		 )))))

  (define (%clauses->entries input-form.stx clause*.stx)
    (syntax-match clause*.stx ()
      (()
       (values '() '() '()))
      ((?clause . ?other-clause*)
       (let-values
	   (((closure.stx closure.id entry*)
	     (%process-single-clause input-form.stx ?clause))
	    ((closure*.stx closure*.id entry**)
	     (%clauses->entries input-form.stx ?other-clause*)))
	 (values (cons closure.stx closure*.stx)
		 (cons closure.id  closure*.id)
		 (cons entry*      entry**))))
      (_
       (syntax-violation __module_who__ "invalid syntax" input-form.stx))))

  (define (%process-single-clause input-form.stx clause.stx)
    (syntax-match clause.stx (=>)
      ((?datum* => ?closure)
       (let ((closure.id (gensym)))
	 (values (bless
		  `(tag-assert-and-return (<procedure>) ,?closure))
		 closure.id
		 (let next-datum ((datums  ?datum*)
				  (entries '()))
		   (syntax-match datums ()
		     (()
		      entries)
		     ((?datum . ?datum*)
		      (next-datum ?datum*
				  (cons (cons* ?datum closure.id #t) entries)))
		     )))))
      ((?datum* . ?body)
       (let ((closure.id (gensym)))
	 (values (bless `(lambda () . ,?body))
		 closure.id
		 (let next-datum ((datums  ?datum*)
				  (entries '()))
		   (syntax-match datums ()
		     (()
		      entries)
		     ((?datum . ?datum*)
		      (next-datum ?datum*
				  (cons (cons* ?datum closure.id #f) entries)))
		     )))))
      (_
       (syntax-violation __module_who__ "invalid clause syntax" input-form.stx clause.stx))))

  (define (%make-datum-clause input-form.stx expr.id else.id pred.id compar.id entry*)
    (if (pair? entry*)
	(bless
	 `((,pred.id ,expr.id)
	   (cond ,@(map (lambda (entry)
			  (let ((datum      (car entry))
				(closure.id (cadr entry))
				(arrow?     (cddr entry)))
			    `((,compar.id ,expr.id (quote ,datum))
			      ,(if arrow?
				   `(,closure.id ,expr.id)
				 `(,closure.id)))))
		     entry*)
		 (else
		  (,else.id)))))
      '()))

  (define (%make-null-clause input-form.stx expr.id entry*)
    (if (pair? entry*)
	(if (<= 2 (length entry*))
	    (syntax-violation __module_who__ "invalid datums, null is present multiple times" input-form.stx)
	  (bless
	   `((null? ,expr.id)
	     ,(let* ((entry      (car  entry*))
		     (closure.id (cadr entry))
		     (arrow?     (cddr entry)))
		(if arrow?
		    `(,closure.id ,expr.id)
		  `(,closure.id))))))
      '()))

  (define (%make-numbers-clause input-form.stx expr.id else.id entry*)
    ;;For generic  number objects we  use = as comparison  predicate and
    ;;NUMBER?  as type  predicate; but  if  all the  datums are  fixnums
    ;;(which is a common case): we use $FX= as comparison and FIXNUM? as
    ;;type predicate.
    ;;
    (define all-fixnums?
      (for-all (lambda (entry)
		 (let ((datum (car entry)))
		   (fixnum? (syntax->datum datum))))
	entry*))
    (if all-fixnums?
	(%make-datum-clause input-form.stx expr.id else.id (core-prim-id 'fixnum?) (core-prim-id '$fx=) entry*)
      (%make-datum-clause input-form.stx expr.id else.id (core-prim-id 'number?) (core-prim-id '=) entry*)))

  (define-syntax set-cons!
    (syntax-rules ()
      ((_ ?var ?expr)
       (set! ?var (cons ?expr ?var)))))

  #| end of module |# )


;;;; non-core macro: CASE-IDENTIFIERS

(module (case-identifiers-macro)
  (define-constant __who__
    'case-identifiers)

  (define (case-identifiers-macro expr-stx)
    ;;Transformer  function  used  to expand  Vicare's  CASE-IDENTIFIERS
    ;;macros  from  the  top-level  built in  environment.   Expand  the
    ;;contents of EXPR-STX; return a  syntax object that must be further
    ;;expanded.
    ;;
    (syntax-match expr-stx ()
      ((_ ?expr)
       (bless
	`(let ((t ,?expr))
	   (if #f #f))))
      ((_ ?expr ?clause ?clause* ...)
       (bless
	`(let* ((t ,?expr)
		(p (identifier? t)))
	   ,(let recur ((clause  ?clause)
			(clause* ?clause*))
	      (if (null? clause*)
		  (%build-last expr-stx clause)
		(%build-one expr-stx clause (recur (car clause*) (cdr clause*))))))))
      ))

  (define (%build-one expr-stx clause-stx kont)
    (syntax-match clause-stx (=>)
      (((?datum* ...) => ?proc)
       `(if ,(%build-test expr-stx ?datum*)
	    ((tag-assert-and-return (<procedure>) ,?proc) t)
	  ,kont))

      (((?datum* ...) ?expr ?expr* ...)
       `(if ,(%build-test expr-stx ?datum*)
	    (internal-body ,?expr . ,?expr*)
	  ,kont))
      ))

  (define (%build-last expr-stx clause)
    (syntax-match clause (else)
      ((else ?expr ?expr* ...)
       `(internal-body ,?expr . ,?expr*))
      (_
       (%build-one expr-stx clause '(if #f #f)))))

  (define (%build-test expr-stx datum*)
    `(and p (or . ,(map (lambda (datum)
			  (if (identifier? datum)
			      `(free-identifier=? t (syntax ,datum))
			    (syntax-violation __who__
			      "expected identifiers as datums"
			      expr-stx datum)))
		     datum*))))

  #| end of module: CASE-IDENTIFIERS-MACRO |# )


;;;; non-core macro: DEFINE-STRUCT

(module (define-struct-macro)
  ;;Transformer  function  used to  expand  Vicare's  DEFINE-STRUCT macros  from  the
  ;;top-level built in environment.  Expand  the contents of INPUT-FORM.STX; return a
  ;;syntax object that must be further expanded.
  ;;
  (define-module-who define-struct)

  (define (define-struct-macro input-form.stx)
    (syntax-match input-form.stx (nongenerative)
      ((_ (?name ?maker ?predicate) (?field* ...))
       (%build-output-form input-form.stx ?name ?maker ?predicate ?field* #f))

      ((_ ?name (?field* ...))
       (%build-output-form input-form.stx ?name #f     #f         ?field* #f))

      ((_ (?name ?maker ?predicate) (?field* ...) (nongenerative ?uid))
       (identifier? ?uid)
       (%build-output-form input-form.stx ?name ?maker ?predicate ?field* ?uid))

      ((_ ?name (?field* ...) (nongenerative ?uid))
       (identifier? ?uid)
       (%build-output-form input-form.stx ?name #f     #f         ?field* ?uid))
      ))

  (define (%build-output-form input-form.stx type.id maker.id predicate.id field*.stx uid)
    (let* ((string->id (lambda (str)
			 (~datum->syntax type.id (string->symbol str))))
	   (type.sym   (identifier->symbol type.id))
	   (type.str   (symbol->string type.sym)))
      (define-values (field*.id field*.tag)
	(%parse-field-specs input-form.stx type.id field*.stx))
      (let* ((field*.sym     (map syntax->datum  field*.id))
	     (field*.str     (map symbol->string field*.sym))
	     (field*.arg     (map (lambda (id tag)
				    `(brace ,id ,tag))
			       field*.sym field*.tag))
	     (uid            (if uid
				 (identifier->symbol uid)
			       (gensym type.str)))
	     (std            (~datum->syntax type.id (make-struct-type type.str field*.sym uid)))
	     (constructor.id (or maker.id     (string->id (string-append "make-" type.str))))
	     (predicate.id   (or predicate.id (string->id (string-append type.str "?"))))
	     (field*.idx     (enumerate field*.stx)))

	(define the-constructor.id
	  (string->id "the-constructor"))

	(define accessor*.id
	  (map (lambda (x)
		 (string->id (string-append type.str "-" x)))
	    field*.str))

	(define mutator*.id
	  (map (lambda (x)
		 (string->id (string-append "set-" type.str "-" x "!")))
	    field*.str))

	(define unsafe-accessor*.id
	  (map (lambda (x)
		 (string->id (string-append "$" type.str "-" x)))
	    field*.str))

	(define unsafe-mutator*.id
	  (map (lambda (x)
		 (string->id (string-append "$set-" type.str "-" x "!")))
	    field*.str))

	(define accessor-sexp*
	  ;;Safe struct fields accessors.
	  ;;
	  ;;NOTE The  unsafe variant of  the field accessor  must be a  syntax object
	  ;;which, expanded  by itself and  evaluated, returns an  accessor function.
	  ;;We know that: when the compiler finds a form like:
	  ;;
	  ;;   ((lambda (stru)
	  ;;      (unsafe-accessor stru))
	  ;;    the-struct)
	  ;;
	  ;;it integrates the LAMBDA into:
	  ;;
	  ;;   (unsafe-accessor the-struct)
	  ;;
	  ;;(Marco Maggi; Wed Apr 23, 2014)
	  (map (lambda (accessor.id unsafe-accessor.id field.tag)
		 `(begin
		    (internal-define (safe) ((brace ,accessor.id ,field.tag) (brace stru ,type.id))
		      (,unsafe-accessor.id stru))
		    (begin-for-syntax
		      (set-identifier-unsafe-variant! (syntax ,accessor.id)
			(syntax (lambda (stru)
				  (,unsafe-accessor.id stru)))))))
	    accessor*.id unsafe-accessor*.id field*.tag))

	(define mutator-sexp*
	  ;;Safe record fields mutators.
	  ;;
	  ;;NOTE The  unsafe variant  of the  field mutator must  be a  syntax object
	  ;;which, expanded by itself and  evaluated, returns a mutator function.  We
	  ;;know that: when the compiler finds a form like:
	  ;;
	  ;;   ((lambda (stru new-value)
	  ;;      (unsafe-mutator stru new-value))
	  ;;    the-stru the-new-value)
	  ;;
	  ;;it integrates the LAMBDA into:
	  ;;
	  ;;   (unsafe-mutator the-stru the-new-value)
	  ;;
	  ;;(Marco Maggi; Wed Apr 23, 2014)
	  (map (lambda (mutator.id unsafe-mutator.id field.tag)
		 `(begin
		    (internal-define (safe) ((brace ,mutator.id <void>) (brace stru ,type.id) (brace val ,field.tag))
		      (,unsafe-mutator.id stru val))
		    (begin-for-syntax
		      (set-identifier-unsafe-variant! (syntax ,mutator.id)
			(syntax (lambda (stru val)
				  (,unsafe-mutator.id stru val)))))))
	    mutator*.id unsafe-mutator*.id field*.tag))

	(define unsafe-accessor-sexp*
	  (map (lambda (unsafe-accessor.id field.idx field.tag)
		 `(define-syntax-rule (,unsafe-accessor.id ?stru)
		    (tag-unsafe-cast ,field.tag ($struct-ref ?stru ,field.idx))))
	    unsafe-accessor*.id field*.idx field*.tag))

	(define unsafe-mutator-sexp*
	  (map (lambda (unsafe-mutator.id field.idx)
		 `(define-syntax-rule (,unsafe-mutator.id ?stru ?val)
		    ($struct-set! ?stru ,field.idx ?val)))
	    unsafe-mutator*.id field*.idx))

	(define object-type-spec-form
	  (%build-object-type-spec type.id type.sym type.str
				   constructor.id
				   predicate.id field*.sym field*.tag
				   accessor*.id unsafe-accessor*.id
				   mutator*.id  unsafe-mutator*.id))

	(bless
	 `(module (,type.id
		   ,constructor.id ,predicate.id
		   ,@accessor*.id ,@unsafe-accessor*.id
		   ,@mutator*.id  ,@unsafe-mutator*.id)
	    (define ((brace ,predicate.id ,(boolean-tag-id)) obj)
	      ($struct/rtd? obj ',std))
	    ;;By putting  this form  here we  are sure  that PREDICATE.ID  is already
	    ;;bound when the "object-type-spec" is built.
	    (define-syntax ,type.id
	      (make-syntactic-binding-descriptor/struct-type-name ',std))
	    (begin-for-syntax ,object-type-spec-form)
	    (define ((brace ,constructor.id ,type.id) . ,field*.arg)
	      (receive-and-return (S)
		  ($struct ',std ,@field*.sym)
		(when ($std-destructor ',std)
		  ($struct-guardian S))))
	    ,@unsafe-accessor-sexp*
	    ,@unsafe-mutator-sexp*
	    ,@accessor-sexp*
	    ,@mutator-sexp*)))))

;;; --------------------------------------------------------------------

  (define (%parse-field-specs input-form.stx type.id field*.stx)
    (define-syntax-rule (recur ?field*.stx)
      (%parse-field-specs input-form.stx type.id ?field*.stx))
    (if (pair? field*.stx)
	(syntax-match (car field*.stx) (brace)
	  ((brace ?name ?tag)
	   (and (identifier? ?name)
		(or (tag-identifier? ?tag)
		    (free-identifier=? ?tag type.id)))
	   (receive (field*.id field*.tag)
	       (recur (cdr field*.stx))
	     (values (cons ?name field*.id)
		     (cons ?tag  field*.tag))))
	  (?name
	   (identifier? ?name)
	   (receive (field*.id field*.tag)
	       (recur (cdr field*.stx))
	     (values (cons ?name        field*.id)
		     (cons (top-tag-id) field*.tag))))
	  (_
	   (syntax-violation __module_who__
	     "invalid struct field specification syntax"
	     input-form.stx (car field*.stx))))
      (values '() '())))

  (define (%build-object-type-spec type.id type.sym type.str
				   constructor.id
				   predicate.id field*.sym field*.tag
				   accessor*.id unsafe-accessor*.id
				   mutator*.id  unsafe-mutator*.id)
    (define uid
      (gensym type.sym))
    (define %constructor-maker
      (string->symbol (string-append type.str "-constructor-maker")))
    (define %accessor-maker
      (string->symbol (string-append type.str "-accessor-maker")))
    (define %mutator-maker
      (string->symbol (string-append type.str "-mutator-maker")))
    (define %getter-maker
      (string->symbol (string-append type.str "-getter-maker")))
    (define %setter-maker
      (string->symbol (string-append type.str "-setter-maker")))
    `(internal-body
       (import (vicare)
	 (prefix (vicare expander object-type-specs) typ.))

       (define (,%constructor-maker input-form.stx)
	 (syntax ,constructor.id))

       (define (,%accessor-maker field.sym input-form.stx)
	 (case field.sym
	   ,@(map (lambda (field-sym accessor.id)
		    `((,field-sym)	(syntax ,accessor.id)))
	       field*.sym accessor*.id)
	   (else #f)))

       (define (,%mutator-maker field.sym input-form.stx)
	 (case field.sym
	   ,@(map (lambda (field-sym mutator.id)
		    `((,field-sym)	(syntax ,mutator.id)))
	       field*.sym mutator*.id)
	   (else #f)))

       (define (,%getter-maker keys.stx input-form.stx)
	 (define (%invalid-keys)
	   (syntax-violation (quote ,type.id) "invalid keys for getter" input-form.stx keys.stx))
	 (syntax-case keys.stx ()
	   (([?field.sym])
	    (identifier? #'?field.sym)
	    (or (,%accessor-maker (syntax->datum #'?field.sym) input-form.stx)
		(%invalid-keys)))
	   (else
	    (%invalid-keys))))

       (define (,%setter-maker keys.stx input-form.stx)
	 (define (%invalid-keys)
	   (syntax-violation (quote ,type.id) "invalid keys for setter" input-form.stx keys.stx))
	 (syntax-case keys.stx ()
	   (([?field.sym])
	    (identifier? #'?field.sym)
	    (or (,%mutator-maker (syntax->datum #'?field.sym) input-form.stx)
		(%invalid-keys)))
	   (else
	    (%invalid-keys))))

       (define %caster-maker #f)
       (define %dispatcher   #f)

       (define object-type-spec
	 (typ.make-object-type-spec (syntax ,type.id) (typ.struct-tag-id) (syntax ,predicate.id)
				    ,%constructor-maker
				    ,%accessor-maker ,%mutator-maker
				    ,%getter-maker   ,%setter-maker
				    %caster-maker    %dispatcher))

       (typ.set-identifier-object-type-spec! (syntax ,type.id) object-type-spec)))

  (define (enumerate ls)
    (let recur ((i 0) (ls ls))
      (if (null? ls)
	  '()
	(cons i (recur (+ i 1) (cdr ls))))))

  #| end of module: DEFINE-STRUCT-MACRO |# )


;;;; non-core macro: DEFINE-RECORD-TYPE

(module (define-record-type-macro)
  ;;Transformer function used to expand R6RS's DEFINE-RECORD-TYPE macros
  ;;from the  top-level built  in environment.   Expand the  contents of
  ;;INPUT-FORM.STX; return a syntax object that must be further expanded.
  ;;
  (define-constant __module_who__ 'define-record-type)

  (define (define-record-type-macro input-form.stx)
    (syntax-match input-form.stx ()
      ((_ ?namespec ?clause* ...)
       (begin
	 (%verify-clauses input-form.stx ?clause*)
	 (%do-define-record input-form.stx ?namespec ?clause*)))
      ))

;;; --------------------------------------------------------------------

  (define (%do-define-record input-form.stx namespec clause*)
    (case-define synner
      ((message)
       (synner message #f))
      ((message subform)
       (syntax-violation __module_who__ message input-form.stx subform)))

    (define-values (foo make-foo foo?)
      (%parse-full-name-spec namespec))
    (define foo-rtd		(%named-gensym foo "-rtd"))
    (define foo-rcd		(%named-gensym foo "-rcd"))
    (define foo-protocol	(%named-gensym foo "-protocol"))
    (define-values
      (x*
		;A list of identifiers representing all the field names.
       idx*
		;A list  of fixnums  representing all the  field indexes
		;(zero-based).
       foo-x*
		;A list  of identifiers  representing the  safe accessor
		;names.
       unsafe-foo-x*
		;A list of identifiers  representing the unsafe accessor
		;names.
       mutable-x*
		;A list  of identifiers  representing the  mutable field
		;names.
       set-foo-idx*
		;A  list  of  fixnums  representing  the  mutable  field
		;indexes (zero-based).
       foo-x-set!*
		;A list of identifiers representing the mutator names.
       unsafe-foo-x-set!*
		;A list  of identifiers representing the  unsafe mutator
		;names.
       immutable-x*
		;A list of identifiers  representing the immutable field
		;names.
       tag*
		;A list of tag identifiers representing the field tags.
       mutable-tag*
		;A list of tag identifiers representing the mutable field tags.
       immutable-tag*
		;A list of tag identifiers representing the immutable field tags.
       )
      (%parse-field-specs foo (%get-fields clause*) synner))

    ;;Code  for parent  record-type  descriptor  and parent  record-type
    ;;constructor descriptor retrieval.
    (define-values (foo-parent parent-rtd-code parent-rcd-code)
      (%make-parent-rtd+rcd-code clause* synner))

    ;;This can be  a symbol or false.  When  a symbol: the symbol is  the record type
    ;;UID, which will make this record  type non-generative.  When false: this record
    ;;type is generative.
    (define foo-uid
      (%get-uid foo clause* synner))

    ;;Code  for  record-type   descriptor  and  record-type  constructor
    ;;descriptor.
    (define foo-rtd-code
      (%make-rtd-code foo foo-uid clause* parent-rtd-code synner))
    (define foo-rcd-code
      (%make-rcd-code clause* foo-rtd foo-protocol parent-rcd-code))

    ;;Code for protocol.
    (define protocol-code
      (%get-protocol-code clause* synner))

    (define binding-spec
      (%make-binding-spec x* mutable-x*
			  foo-x* foo-x-set!*
			  unsafe-foo-x* unsafe-foo-x-set!*))

    (define object-type-spec-form
      ;;The object-type-spec stuff is used to  add a tag property to the
      ;;record type identifier.
      (%make-object-type-spec-form foo make-foo foo? foo-parent
				   x* foo-x* unsafe-foo-x*
				   mutable-x* foo-x-set!* unsafe-foo-x-set!*
				   immutable-x*))

    (bless
     `(begin
	;;Record type descriptor.
	(define ,foo-rtd ,foo-rtd-code)
	;;Protocol function.
	(define ,foo-protocol ,protocol-code)
	;;Record constructor descriptor.
	(define ,foo-rcd ,foo-rcd-code)
	;;Binding for record type name.
	(define-syntax ,foo
	  (make-syntactic-binding-descriptor/record-type-name (syntax ,foo-rtd) (syntax ,foo-rcd) (quote ,binding-spec)))
	(begin-for-syntax ,object-type-spec-form)
	;;Record instance predicate.
	(define (brace ,foo? <predicate>)
	  (record-predicate ,foo-rtd))
	;;Record instance constructor.
	(define ,make-foo
	  (record-constructor ,foo-rcd))
	(begin-for-syntax
	  (internal-body
	    (import (prefix (vicare expander object-type-specs) typ.))
	    (define %constructor-signature
	      (typ.make-lambda-signature
	       (typ.make-retvals-signature-single-value (syntax ,foo))
	       (typ.make-formals-signature (syntax <list>))))
	    (define %constructor-tag-id
	      (typ.fabricate-procedure-tag-identifier (quote ,make-foo)
						      %constructor-signature))
	    (typ.override-identifier-tag! (syntax ,make-foo) %constructor-tag-id)))
	(module (,@foo-x*
		 ,@foo-x-set!*
		 ,@(if (option.strict-r6rs)
		       '()
		     (append unsafe-foo-x* unsafe-foo-x-set!*)))
	  ,(%gen-unsafe-accessor+mutator-code foo foo-rtd foo-rcd
					      unsafe-foo-x*      x*         idx*
					      unsafe-foo-x-set!* mutable-x* set-foo-idx*
					      tag*)

	  ;;Safe record fields accessors.
	  ;;
	  ;;NOTE The  unsafe variant of  the field accessor  must be a  syntax object
	  ;;which, expanded  by itself and  evaluated, returns an  accessor function.
	  ;;We know that: when the compiler finds a form like:
	  ;;
	  ;;   ((lambda (record)
	  ;;      (unsafe-foo-x record))
	  ;;    the-record)
	  ;;
	  ;;it integrates the LAMBDA into:
	  ;;
	  ;;   (unsafe-foo-x the-record)
	  ;;
	  ;;(Marco Maggi; Wed Apr 23, 2014)
	  ,@(map (lambda (foo-x unsafe-foo-x field-tag)
		   `(begin
		      (internal-define (safe) ((brace ,foo-x ,field-tag) (brace record ,foo))
			(,unsafe-foo-x record))
		      (begin-for-syntax
			(set-identifier-unsafe-variant! (syntax ,foo-x)
			  (syntax (lambda (record)
				    (,unsafe-foo-x record)))))))
	      foo-x* unsafe-foo-x* tag*)

	  ;;Safe record fields mutators (if any).
	  ;;
	  ;;NOTE The  unsafe variant  of the  field mutator must  be a  syntax object
	  ;;which, expanded by itself and  evaluated, returns a mutator function.  We
	  ;;know that: when the compiler finds a form like:
	  ;;
	  ;;   ((lambda (record new-value)
	  ;;      (unsafe-foo-x-set! record new-value))
	  ;;    the-record the-new-value)
	  ;;
	  ;;it integrates the LAMBDA into:
	  ;;
	  ;;   (unsafe-foo-x-set! the-record the-new-value)
	  ;;
	  ;;(Marco Maggi; Wed Apr 23, 2014)
	  ,@(map (lambda (foo-x-set! unsafe-foo-x-set! field-tag)
	  	   `(begin
		      (internal-define (safe) ((brace ,foo-x-set! <void>) (brace record ,foo) (brace new-value ,field-tag))
			(,unsafe-foo-x-set! record new-value))
		      (begin-for-syntax
			(set-identifier-unsafe-variant! (syntax ,foo-x-set!)
			  (syntax (lambda (record new-value)
				    (,unsafe-foo-x-set! record new-value)))))))
	      foo-x-set!* unsafe-foo-x-set!* mutable-tag*)

	  #| end of module: safe and unsafe accessors and mutators |# )
	)))

;;; --------------------------------------------------------------------

  (define (%gen-unsafe-accessor+mutator-code foo foo-rtd foo-rcd
					     unsafe-foo-x*      x*         idx*
					     unsafe-foo-x-set!* mutable-x* set-foo-idx*
					     tag*)
    (define (%make-field-index-varname x.id)
      (string->symbol (string-append foo.str "-" (symbol->string (syntax->datum x.id)) "-index")))
    (define foo.str
      (symbol->string (syntax->datum foo)))
    (define foo-first-field-offset
      (%named-gensym foo "-first-field-offset"))
    `(module (,@unsafe-foo-x* ,@unsafe-foo-x-set!*)
       (define ,foo-first-field-offset
	 ;;The field at index  3 in the RTD is: the index of  the first field of this
	 ;;subtype in the  layout of instances; it  is the total number  of fields of
	 ;;the parent type.
	 ($struct-ref ,foo-rtd 3))

       ;;all fields indexes
       ,@(map (lambda (x idx)
		(let ((the-index (%make-field-index-varname x)))
		  `(define (brace ,the-index <fixnum>)
		     (fx+ ,idx ,foo-first-field-offset))))
	   x* idx*)

       ;;unsafe record fields accessors
       ,@(map (lambda (unsafe-foo-x x field.tag)
		(let ((the-index (%make-field-index-varname x)))
		  `(define-syntax-rule (,unsafe-foo-x ?x)
		     (tag-unsafe-cast ,field.tag ($struct-ref ?x ,the-index)))))
	   unsafe-foo-x* x* tag*)

       ;;unsafe record fields mutators
       ,@(map (lambda (unsafe-foo-x-set! x)
		(let ((the-index (%make-field-index-varname x)))
		  `(define-syntax-rule (,unsafe-foo-x-set! ?x ?v)
		     ($struct-set! ?x ,the-index ?v))))
	   unsafe-foo-x-set!* mutable-x*)
       #| end of module: unsafe accessors and mutators |# ))

;;; --------------------------------------------------------------------

  (define (%parse-full-name-spec spec)
    ;;Given  a  syntax  object  representing  a  full  record-type  name
    ;;specification: return the name identifier.
    ;;
    (syntax-match spec ()
      ((?foo ?make-foo ?foo?)
       (and (identifier? ?foo)
	    (identifier? ?make-foo)
	    (identifier? ?foo?))
       (values ?foo ?make-foo ?foo?))
      (?foo
       (identifier? ?foo)
       (values ?foo
	       (identifier-append ?foo "make-" (syntax->datum ?foo))
	       (identifier-append ?foo ?foo "?")))
      ))

  (define (%get-uid foo clause* synner)
    (let ((clause (%get-clause 'nongenerative clause*)))
      (syntax-match clause ()
	((_)
	 (gensym (syntax->datum foo)))
	((_ ?uid)
	 (identifier? ?uid)
	 (syntax->datum ?uid))
	;;No matching clause found.  This record type will be non-generative.
	(#f
	 #f)
	(_
	 (synner "expected symbol or no argument in nongenerative clause" clause)))))

  (define (%make-rtd-code name foo-uid clause* parent-rtd-code synner)
    ;;Return a  sexp which,  when evaluated,  will return  a record-type
    ;;descriptor.
    ;;
    (define sealed?
      (let ((clause (%get-clause 'sealed clause*)))
	(syntax-match clause ()
	  ((_ #t)	#t)
	  ((_ #f)	#f)
	  ;;No matching clause found.
	  (#f		#f)
	  (_
	   (synner "invalid argument in SEALED clause" clause)))))
    (define opaque?
      (let ((clause (%get-clause 'opaque clause*)))
	(syntax-match clause ()
	  ((_ #t)	#t)
	  ((_ #f)	#f)
	  ;;No matching clause found.
	  (#f		#f)
	  (_
	   (synner "invalid argument in OPAQUE clause" clause)))))
    (define fields
      (let ((clause (%get-clause 'fields clause*)))
	(syntax-match clause ()
	  ((_ field-spec* ...)
	   `(quote ,(list->vector
		     (map (lambda (field-spec)
			    (syntax-match field-spec (mutable immutable brace)
			      ((mutable (brace ?name ?tag) . ?rest)
			       `(mutable ,?name))
			      ((mutable ?name . ?rest)
			       `(mutable ,?name))
			      ((immutable (brace ?name ?tag) . ?rest)
			       `(immutable ,?name))
			      ((immutable ?name . ?rest)
			       `(immutable ,?name))
			      ((brace ?name ?tag)
			       `(immutable ,?name))
			      (?name
			       `(immutable ,?name))))
		       field-spec*))))
	  ;;No matching clause found.
	  (#f
	   (quote (quote #())))

	  (_
	   (synner "invalid syntax in FIELDS clause" clause)))))
    `(make-record-type-descriptor (quote ,name) ,parent-rtd-code
				  (quote ,foo-uid) ,sealed? ,opaque? ,fields))

  (define (%make-rcd-code clause* foo-rtd foo-protocol parent-rcd-code)
    ;;Return a sexp  which, when evaluated, will  return the record-type
    ;;default constructor descriptor.
    ;;
    `(make-record-constructor-descriptor ,foo-rtd ,parent-rcd-code ,foo-protocol))

  (define (%make-parent-rtd+rcd-code clause* synner)
    ;;Return 3 values:
    ;;
    ;;1. An identifier  representing the parent type, or  false if there
    ;;is no  parent or  the parent is  specified through  the procedural
    ;;layer.
    ;;
    ;;2.  A  sexp   which,  when  evaluated,  will   return  the  parent
    ;;record-type descriptor.
    ;;
    ;;3.  A  sexp   which,  when  evaluated,  will   return  the  parent
    ;;record-type default constructor descriptor.
    ;;
    (let ((parent-clause (%get-clause 'parent clause*)))
      (syntax-match parent-clause ()
	;;If there is a PARENT clause insert code that retrieves the RTD
	;;from the parent type name.
	((_ ?name)
	 (identifier? ?name)
	 (values ?name
		 `(record-type-descriptor ,?name)
		 `(record-constructor-descriptor ,?name)))

	;;If there  is no PARENT  clause try to retrieve  the expression
	;;evaluating to the RTD.
	(#f
	 (let ((parent-rtd-clause (%get-clause 'parent-rtd clause*)))
	   (syntax-match parent-rtd-clause ()
	     ((_ ?rtd ?rcd)
	      (values #f ?rtd ?rcd))

	     ;;If  neither the  PARENT  nor the  PARENT-RTD clauses  are
	     ;;present: just return false.
	     (#f
	      (values #f #f #f))

	     (_
	      (synner "invalid syntax in PARENT-RTD clause" parent-rtd-clause)))))

	(_
	 (synner "invalid syntax in PARENT clause" parent-clause)))))

  (define (%get-protocol-code clause* synner)
    ;;Return  a  sexp  which,   when  evaluated,  returns  the  protocol
    ;;function.
    ;;
    (let ((clause (%get-clause 'protocol clause*)))
      (syntax-match clause ()
	((_ ?expr)
	 ?expr)

	;;No matching clause found.
	(#f	#f)

	(_
	 (synner "invalid syntax in PROTOCOL clause" clause)))))

  (define (%get-fields clause*)
    ;;Return   a  list   of  syntax   objects  representing   the  field
    ;;specifications.
    ;;
    (syntax-match clause* (fields)
      (()
       '())
      (((fields ?field-spec* ...) . _)
       ?field-spec*)
      ((_ . ?rest)
       (%get-fields ?rest))))

;;; --------------------------------------------------------------------

  (define (%parse-field-specs foo field-clause* synner)
    ;;Given the  arguments of the  fields specification clause  return 4
    ;;values:
    ;;
    ;;1..The list of identifiers representing all the field names.
    ;;
    ;;2..The  list  of  fixnums  representings all  the  field  relative
    ;;   indexes (zero-based).
    ;;
    ;;3..A list of identifiers representing the safe accessor names.
    ;;
    ;;4..A list of identifiers representing the unsafe accessor names.
    ;;
    ;;5..The list of identifiers representing the mutable field names.
    ;;
    ;;6..The list  of fixnums  representings the mutable  field relative
    ;;   indexes (zero-based).
    ;;
    ;;7..A list of identifiers representing the safe mutator names.
    ;;
    ;;8..A list of identifiers representing the unsafe mutator names.
    ;;
    ;;9..The list of identifiers representing the immutable field names.
    ;;
    ;;10.The list of identifiers representing the field tags.
    ;;
    ;;11.The list of identifiers representing the mutable field tags.
    ;;
    ;;12.The list of identifiers representing the immutable field tags.
    ;;
    ;;Here we assume that FIELD-CLAUSE* is null or a proper list.
    ;;
    (define (gen-safe-accessor-name x)
      (identifier-append  foo foo "-" x))
    (define (gen-unsafe-accessor-name x)
      (identifier-append  foo "$" foo "-" x))
    (define (gen-safe-mutator-name x)
      (identifier-append  foo foo "-" x "-set!"))
    (define (gen-unsafe-mutator-name x)
      (identifier-append  foo "$" foo "-" x "-set!"))
    (let loop ((field-clause*		field-clause*)
	       (i			0)
	       (field*			'())
	       (idx*			'())
	       (accessor*		'())
	       (unsafe-accessor*	'())
	       (mutable-field*		'())
	       (mutable-idx*		'())
	       (mutator*		'())
	       (unsafe-mutator*		'())
	       (immutable-field*	'())
	       (tag*			'())
	       (mutable-tag*		'())
	       (immutable-tag*		'()))
      (syntax-match field-clause* (mutable immutable)
	(()
	 (values (reverse field*) (reverse idx*) (reverse accessor*) (reverse unsafe-accessor*)
		 (reverse mutable-field*) (reverse mutable-idx*) (reverse mutator*) (reverse unsafe-mutator*)
		 (reverse immutable-field*)
		 (reverse tag*)
		 (reverse mutable-tag*) (reverse immutable-tag*)))

	(((mutable   ?name ?accessor ?mutator) . ?rest)
	 (and (identifier? ?accessor)
	      (identifier? ?mutator))
	 (receive (field.id field.tag)
	     (parse-tagged-identifier-syntax ?name)
	   (loop ?rest (+ 1 i)
		 (cons field.id field*)		(cons i idx*)
		 (cons ?accessor accessor*)	(cons (gen-unsafe-accessor-name field.id) unsafe-accessor*)
		 (cons field.id mutable-field*)	(cons i mutable-idx*)
		 (cons ?mutator mutator*)	(cons (gen-unsafe-mutator-name  field.id) unsafe-mutator*)
		 immutable-field*
		 (cons field.tag tag*)
		 (cons field.tag mutable-tag*)	immutable-tag*)))

	(((immutable ?name ?accessor) . ?rest)
	 (identifier? ?accessor)
	 (receive (field.id field.tag)
	     (parse-tagged-identifier-syntax ?name)
	   (loop ?rest (+ 1 i)
		 (cons ?name field*)		(cons i idx*)
		 (cons ?accessor accessor*)	(cons (gen-unsafe-accessor-name ?name) unsafe-accessor*)
		 mutable-field*			mutable-idx*
		 mutator*			unsafe-mutator*
		 (cons ?name immutable-field*)
		 (cons field.tag tag*)
		 mutable-tag*			(cons field.tag immutable-tag*))))

	(((mutable   ?name) . ?rest)
	 (receive (field.id field.tag)
	     (parse-tagged-identifier-syntax ?name)
	   (loop ?rest (+ 1 i)
		 (cons field.id field*)				(cons i idx*)
		 (cons (gen-safe-accessor-name   field.id)	accessor*)
		 (cons (gen-unsafe-accessor-name field.id)	unsafe-accessor*)
		 (cons field.id mutable-field*)			(cons i mutable-idx*)
		 (cons (gen-safe-mutator-name    field.id)	mutator*)
		 (cons (gen-unsafe-mutator-name  field.id)	unsafe-mutator*)
		 immutable-field*
		 (cons field.tag tag*)
		 (cons field.tag mutable-tag*)			immutable-tag*)))

	(((immutable ?name) . ?rest)
	 (receive (field.id field.tag)
	     (parse-tagged-identifier-syntax ?name)
	   (loop ?rest (+ 1 i)
		 (cons field.id field*)				(cons i idx*)
		 (cons (gen-safe-accessor-name   field.id)	accessor*)
		 (cons (gen-unsafe-accessor-name field.id)	unsafe-accessor*)
		 mutable-field*					mutable-idx*
		 mutator*					unsafe-mutator*
		 (cons field.id immutable-field*)
		 (cons field.tag tag*)
		 mutable-tag*					(cons field.tag immutable-tag*))))

	((?name . ?rest)
	 (receive (field.id field.tag)
	     (parse-tagged-identifier-syntax ?name)
	   (loop ?rest (+ 1 i)
		 (cons field.id field*)				(cons i idx*)
		 (cons (gen-safe-accessor-name   field.id)	 accessor*)
		 (cons (gen-unsafe-accessor-name field.id)	unsafe-accessor*)
		 mutable-field*					mutable-idx*
		 mutator*					unsafe-mutator*
		 (cons field.id immutable-field*)
		 (cons field.tag tag*)
		 mutable-tag*					(cons field.tag immutable-tag*))))

	((?spec . ?rest)
	 (synner "invalid field specification in DEFINE-RECORD-TYPE syntax"
		 ?spec)))))

;;; --------------------------------------------------------------------

  (module (%make-binding-spec)
    (import R6RS-RECORD-TYPE-SPEC)

    (define (%make-binding-spec x* mutable-x*
				foo-x* foo-x-set!*
				unsafe-foo-x* unsafe-foo-x-set!*)

      ;;A sexp which will be BLESSed  in the output code.  The sexp will
      ;;evaluate to an alist in which: keys are symbols representing all
      ;;the  field  names; values  are  identifiers  bound to  the  safe
      ;;accessors.
      (define foo-fields-safe-accessors-table
	(%make-alist x* foo-x*))

      ;;A sexp which will be BLESSed  in the output code.  The sexp will
      ;;evaluate to  an alist  in which:  keys are  symbols representing
      ;;mutable  field  names;  values  are identifiers  bound  to  safe
      ;;mutators.
      (define foo-fields-safe-mutators-table
	(%make-alist mutable-x* foo-x-set!*))

      ;;A sexp which will be BLESSed  in the output code.  The sexp will
      ;;evaluate to an alist in which: keys are symbols representing all
      ;;the  field names;  values are  identifiers bound  to the  unsafe
      ;;accessors.
      (define foo-fields-unsafe-accessors-table
	(%make-alist x* unsafe-foo-x*))

      ;;A sexp which will be BLESSed  in the output code.  The sexp will
      ;;evaluate to  an alist  in which:  keys are  symbols representing
      ;;mutable  field names;  values  are identifiers  bound to  unsafe
      ;;mutators.
      (define foo-fields-unsafe-mutators-table
	(%make-alist mutable-x* unsafe-foo-x-set!*))

      (if (option.strict-r6rs)
	  (make-r6rs-record-type-spec foo-fields-safe-accessors-table
				      foo-fields-safe-mutators-table
				      #f #f)
	(make-r6rs-record-type-spec foo-fields-safe-accessors-table
				    foo-fields-safe-mutators-table
				    foo-fields-unsafe-accessors-table
				    foo-fields-unsafe-mutators-table)))

    (define (%make-alist key-id* operator-id*)
      (map (lambda (key-id operator-id)
	     (cons (syntax->datum key-id) operator-id))
	key-id* operator-id*))

    #| end of module: %MAKE-BINDING-SPEC |# )

;;; --------------------------------------------------------------------

  (define (%make-object-type-spec-form foo make-foo foo? foo-parent
				       x* foo-x* unsafe-foo-x*
				       mutable-x* foo-x-set!* unsafe-foo-x-set!*
				       immutable-x*)
    (define type.str
      (symbol->string (syntax->datum foo)))
    (define %constructor-maker
      (string->symbol (string-append type.str "-constructor-maker")))
    (define %accessor-maker
      (string->symbol (string-append type.str "-accessor-maker")))
    (define %mutator-maker
      (string->symbol (string-append type.str "-mutator-maker")))
    (define %getter-maker
      (string->symbol (string-append type.str "-getter-maker")))
    (define %setter-maker
      (string->symbol (string-append type.str "-setter-maker")))
    `(internal-body
       (import (vicare)
	 (prefix (vicare expander object-type-specs) typ.))

       (define (,%constructor-maker input-form.stx)
	 (syntax ,make-foo))

       (define (,%accessor-maker field.sym input-form-stx)
	 (case field.sym
	   ,@(map (lambda (field-name accessor-id)
		    `((,field-name)	(syntax ,accessor-id)))
	       x* foo-x*)
	   (else #f)))

       (define (,%mutator-maker field.sym input-form-stx)
	 (case field.sym
	   ,@(map (lambda (field-name mutator-id)
		    `((,field-name)	(syntax ,mutator-id)))
	       mutable-x* foo-x-set!*)
	   ,@(map (lambda (field-name)
		    `((,field-name)
		      (syntax-violation ',foo
			"requested mutator of immutable record field name"
			input-form-stx field.sym)))
	       immutable-x*)
	   (else #f)))

       (define (,%getter-maker keys-stx input-form-stx)
	 (syntax-case keys-stx ()
	   (([?field-id])
	    (identifier? #'?field-id)
	    (,%accessor-maker (syntax->datum #'?field-id) input-form-stx))
	   (else #f)))

       (define (,%setter-maker keys-stx input-form-stx)
	 (syntax-case keys-stx ()
	   (([?field-id])
	    (identifier? #'?field-id)
	    (,%mutator-maker (syntax->datum #'?field-id) input-form-stx))
	   (else #f)))

       (define %caster-maker #f)
       (define %dispatcher   #f)

       (define parent-id
	 ,(if foo-parent
	      `(syntax ,foo-parent)
	    '(typ.record-tag-id)))

       (define object-type-spec
	 (typ.make-object-type-spec (syntax ,foo) parent-id (syntax ,foo?)
				    ,%constructor-maker
				    ,%accessor-maker ,%mutator-maker
				    ,%getter-maker   ,%setter-maker
				    %caster-maker    %dispatcher))

       (typ.set-identifier-object-type-spec! (syntax ,foo) object-type-spec)))

;;; --------------------------------------------------------------------

  (module (%verify-clauses)

    (define (%verify-clauses input-form.stx cls*)
      (define VALID-KEYWORDS
	(map bless
	  '(fields parent parent-rtd protocol sealed opaque nongenerative)))
      (let loop ((cls*  cls*)
		 (seen* '()))
	(unless (null? cls*)
	  (syntax-match (car cls*) ()
	    ((?kwd . ?rest)
	     (cond ((or (not (identifier? ?kwd))
			(not (%free-id-member? ?kwd VALID-KEYWORDS)))
		    (syntax-violation __module_who__
		      "not a valid DEFINE-RECORD-TYPE keyword"
		      input-form.stx ?kwd))
		   ((bound-id-member? ?kwd seen*)
		    (syntax-violation __module_who__
		      "invalid duplicate clause in DEFINE-RECORD-TYPE"
		      input-form.stx ?kwd))
		   (else
		    (loop (cdr cls*) (cons ?kwd seen*)))))
	    (?cls
	     (syntax-violation __module_who__
	       "malformed define-record-type clause"
	       input-form.stx ?cls))
	    ))))

    (define (%free-id-member? x ls)
      (and (pair? ls)
	   (or (~free-identifier=? x (car ls))
	       (%free-id-member? x (cdr ls)))))

    #| end of module: %VERIFY-CLAUSES |# )

  (define (%get-clause sym clause*)
    ;;Given a symbol SYM representing the  name of a clause and a syntax
    ;;object  CLAUSE*  representing  the clauses:  search  the  selected
    ;;clause and return it as syntax object.  When no matching clause is
    ;;found: return false.
    ;;
    (let next ((id       (bless sym))
	       (clause*  clause*))
      (syntax-match clause* ()
	(()
	 #f)
	(((?key . ?rest) . ?clause*)
	 (if (~free-identifier=? id ?key)
	     `(,?key . ,?rest)
	   (next id ?clause*))))))

  (define (%named-gensym foo suffix)
    (gensym (string-append
	     (symbol->string (syntax->datum foo))
	     suffix)))

  #| end of module: DEFINE-RECORD-TYPE-MACRO |# )


;;;; non-core macro: RECORD-TYPE-AND-RECORD?

(define (record-type-and-record?-macro expr-stx)
  ;;Transformer function used to expand Vicare's RECORD-TYPE-AND-RECORD?
  ;;macros from the top-level built in environment.  Expand the contents
  ;;of EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ ?type-name ?record)
     (identifier? ?type-name)
     (bless
      `(record-and-rtd? ,?record (record-type-descriptor ,?type-name))))
    ))


;;;; non-core macro: DEFINE-CONDITION-TYPE

(define (define-condition-type-macro expr-stx)
  ;;Transformer  function  used  to  expand  R6RS  RECORD-CONDITION-TYPE
  ;;macros from the top-level built in environment.  Expand the contents
  ;;of EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((?ctxt ?name ?super ?constructor ?predicate (?field* ?accessor*) ...)
     (and (identifier? ?name)
	  (identifier? ?super)
	  (identifier? ?constructor)
	  (identifier? ?predicate)
	  (for-all identifier? ?field*)
	  (for-all identifier? ?accessor*))
     (let ((aux-accessor* (map (lambda (x)
				 (gensym))
			    ?accessor*)))
       (bless
	`(module (,?name ,?constructor ,?predicate . ,?accessor*)
	   (define-record-type (,?name ,?constructor ,(gensym))
	     (parent ,?super)
	     (fields ,@(map (lambda (field aux)
			      `(immutable ,field ,aux))
			 ?field* aux-accessor*))
	     (nongenerative)
	     (sealed #f)
	     (opaque #f))
	   (define ,?predicate
	     ;;Remember  that the  predicate has  to recognise  a simple
	     ;;condition object embedded in a compound condition object.
	     (condition-predicate (record-type-descriptor ,?name)))
	   ,@(map
		 (lambda (accessor aux)
		   `(define ,accessor
		      ;;Remember  that  the  accessor has  to  access  a
		      ;;simple condition  object embedded in  a compound
		      ;;condition object.
		      (condition-accessor (record-type-descriptor ,?name) ,aux)))
	       ?accessor* aux-accessor*)
	   #| end of module |# )
	)))
    ))


;;;; non-core macro: PARAMETERIZE and PARAMETRISE

(define (parameterize-macro expr-stx)
  ;;Transformer  function used  to expand  Vicare's PARAMETERIZE  macros
  ;;from the  top-level built  in environment.   Expand the  contents of
  ;;EXPR-STX; return a syntax object that must be further expanded.
  ;;
  ;;Notice that  MAKE-PARAMETER is  a primitive function  implemented in
  ;;"ikarus.compiler.sls"  by   "E-make-parameter".   Under   Vicare,  a
  ;;parameter function  can be  called with  0, 1  or 2  arguments:
  ;;
  ;;* When called with 1 argument: it returns the parameter's value.
  ;;
  ;;* When called with 2 arguments:  it sets the parameter's value after
  ;;  checking the new value with the guard function (if any).
  ;;
  ;;*  When called  with  3  arguments: it  sets  the parameter's  value
  ;;   optionally checking  the new  value with  the guard  function (if
  ;;  any).
  ;;
  ;;Under Vicare,  PARAMETERIZE applies  the guard  function to  the new
  ;;value only the first  time it is set; if the  control flow exits and
  ;;returns multiple times beacuse  escaping continuations are used, the
  ;;guard function is  no more applied; this is achieved  by setting the
  ;;flag variable GUARD?.
  ;;
  (syntax-match expr-stx ()
    ((_ () ?body ?body* ...)
     (bless
      `(internal-body ,?body . ,?body*)))

    ((_ ((?lhs* ?rhs*) ...) ?body ?body* ...)
     (let ((lhs* (generate-temporaries ?lhs*))
	   (rhs* (generate-temporaries ?rhs*)))
       (bless
	`((lambda ,(append lhs* rhs*)
	    (let* ((guard? #t) ;apply the guard function only the first time
		   (swap   (lambda ()
			     ,@(map (lambda (lhs rhs)
				      `(let ((t (,lhs)))
					 (,lhs ,rhs guard?)
					 (set! ,rhs t)))
				 lhs* rhs*)
			     (set! guard? #f))))
	      (dynamic-wind
		  swap
		  (lambda () ,?body . ,?body*)
		  swap)))
	  ,@(append ?lhs* ?rhs*)))))
    ))


;;;; non-core macro: WITH-UNWIND-PROTECTION, UNWIND-PROTECT

(define (with-unwind-protection-macro expr-stx)
  ;;Transformer function  used to expand Vicare's  WITH-UNWIND-PROTECTION macros from
  ;;the top-level  built in environment.  Expand  the contents of EXPR-STX;  return a
  ;;syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ ?unwind-handler ?thunk)
     (let ((terminated?  (gensym))
	   (normal-exit? (gensym))
	   (why          (gensym))
	   (escape       (gensym)))
       (bless
	`(let (	;;True if the dynamic extent of the call to THUNK is terminated.
	       (,terminated?   #f)
	       ;;True  if the  dynamic extent  of the  call to  ?THUNK was  exited by
	       ;;performing a normal return.
	       (,normal-exit?  #f))
	   (dynamic-wind
	       (lambda ()
		 (when ,terminated?
		   (non-reinstatable-violation 'with-unwind-protection
		     "attempt to reenter thunk with terminated dynamic extent")))
	       (lambda ()
		 (begin0
		     (,?thunk)
		   (set! ,normal-exit? #t)))
	       (lambda ()
		 (unless ,terminated? ;be safe
		   (cond ((if ,normal-exit?
			      'return
			    ;;This parameter is set to:
			    ;;
			    ;;* The boolean #f if no unwind handler must be run.
			    ;;
			    ;;* The symbol "exception" if  the unwind handler must be
			    ;;run because an exception has been raised and catched by
			    ;;GUARD.
			    ;;
			    ;;* The symbol "escape" if the unwind handler must be run
			    ;;because an unwinding escape procedure has been called.
			    ;;
			    (run-unwind-protection-cleanup-upon-exit?))
			  => (lambda (,why)
			       (set! ,terminated? #t)
			       ;;We want to discard any exception raised by the cleanup thunk.
			       (call/cc
				   (lambda (,escape)
				     (with-exception-handler
					 ,escape
				       (lambda ()
					 (,?unwind-handler ,why)))))))))))))))
    ))

(define (unwind-protect-macro expr-stx)
  ;;Transformer  function used  to  expand Vicare's  UNWIND-PROTECT  macros from  the
  ;;top-level built in environment.  Expand the contents of EXPR-STX; return a syntax
  ;;object that must be further expanded.
  ;;
  ;;Not a  general UNWIND-PROTECT  mechanism for  Scheme, but fine  when we  do *not*
  ;;create  continuations that  reenter the  ?BODY  again after  having executed  the
  ;;?CLEANUP forms once.
  ;;
  ;;NOTE This implementation works fine with coroutines.
  ;;
  (syntax-match expr-stx ()
    ((_ ?body ?cleanup0 ?cleanup* ...)
     (let ((why (gensym)))
       (bless
	`(with-unwind-protection
	     (lambda (,why) ,?cleanup0 . ,?cleanup*)
	   (lambda () ,?body)))))
    ))


;;;; non-core macro: WITH-IMPLICITS

(define (with-implicits-macro expr-stx)
  ;;Transformer function  used to expand Vicare's  WITH-IMPLICITS macros
  ;;from the  top-level built  in environment.   Expand the  contents of
  ;;EXPR-STX; return a syntax object that must be further expanded.
  ;;
  ;;This  macro  is   a  wrapper  for  WITH-SYNTAX   which  defines  the
  ;;identifiers ?SYMBOL with the same context  of ?CTX.  ?CTX must be an
  ;;expression evaluating to  an identifier; it is  evaluated only once.
  ;;?SYMBOL must be Scheme symbols.  For example:
  ;;
  ;;   (syntax-case stx ()
  ;;     ((id)
  ;;      (identifier? #'id)
  ;;      (with-implicits ((#'id x y))
  ;;        #'(list x y))))
  ;;
  ;;is equivalent to:
  ;;
  ;;   (syntax-case stx ()
  ;;     ((id)
  ;;      (identifier? #'id)
  ;;      (with-syntax ((x (datum->syntax #'id 'x))
  ;;                    (y (datum->syntax #'id 'y)))
  ;;        #'(list x y))))
  ;;
  ;;NOTE This  macro is  derived from  WITH-IMPLICIT, documented  in the
  ;;Chez Scheme User's Guide.  The  two macros have different API; where
  ;;we would use Vicare's variant as:
  ;;
  ;;   (with-implicits ((#'id x y))
  ;;     #'(list x y))
  ;;
  ;;we would use Chez's variant as:
  ;;
  ;;   (with-implicit ((id x y))
  ;;     #'(list x y))
  ;;
  (define (%make-bindings ctx ids)
    (map (lambda (id)
	   `(,id (datum->syntax ,ctx (quote ,id))))
      ids))
  (syntax-match expr-stx ()

    ((_ () ?body0 ?body* ...)
     (bless
      `(begin ,?body0 . ,?body*)))

    ((_ ((?ctx ?symbol0 ?symbol* ...))
	?body0 ?body* ...)
     (let ((BINDINGS (%make-bindings ?ctx (cons ?symbol0 ?symbol*))))
       (bless
	`(with-syntax ,BINDINGS ,?body0 . ,?body*))))

    ((_ ((?ctx ?symbol0 ?symbol* ...) . ?other-clauses)
	?body0 ?body* ...)
     (let ((BINDINGS (%make-bindings ?ctx (cons ?symbol0 ?symbol*))))
       (bless
	`(with-syntax ,BINDINGS (with-implicits ,?other-clauses ,?body0 . ,?body*)))))
    ))


;;;; non-core macro: SET-CONS!

(define (set-cons!-macro expr-stx)
  ;;Transformer function  used to expand Vicare's  SET-CONS! macros from
  ;;the  top-level  built  in   environment.   Expand  the  contents  of
  ;;EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ ?id ?obj)
     (identifier? ?id)
     (bless `(set! ,?id (cons ,?obj ,?id))))
    ))


;;;; non-core macro: compensations

(module (with-compensations/on-error-macro
	 with-compensations-macro)

  (define (with-compensations/on-error-macro expr-stx)
    ;;Transformer     function      used     to      expand     Vicare's
    ;;WITH-COMPENSATIONS/ON-ERROR  macros from  the  top-level built  in
    ;;environment.   Expand the  contents of  EXPR-STX; return  a syntax
    ;;object that must be further expanded.
    ;;
    (syntax-match expr-stx ()
      ((_ ?body0 ?body* ...)
       (let ((store (gensym))
	     (why   (gensym)))
	 (bless
	  `(let ,(%make-store-binding store)
	     (parametrise ((compensations ,store))
	       (with-unwind-protection
		   (lambda (,why)
		     (when (eq? ,why 'exception)
		       (run-compensations-store ,store)))
		 (lambda ()
		   ,?body0 . ,?body*)))))))
      ))

  (define (with-compensations-macro expr-stx)
    ;;Transformer  function used  to expand  Vicare's WITH-COMPENSATIONS
    ;;macros  from  the  top-level  built in  environment.   Expand  the
    ;;contents of EXPR-STX; return a  syntax object that must be further
    ;;expanded.
    ;;
    (syntax-match expr-stx ()
      ((_ ?body0 ?body* ...)
       (let ((store (gensym))
	     (why   (gensym)))
	 (bless
	  `(let ,(%make-store-binding store)
	     (parametrise ((compensations ,store))
	       (with-unwind-protection
		   (lambda (,why)
		     (run-compensations-store ,store))
		 (lambda ()
		   ,?body0 . ,?body*)))))))
      ))

  (define (%make-store-binding store)
    (let ((stack        (gensym))
	  (false/thunk  (gensym)))
      `((,store (let ((,stack '()))
		  (case-lambda
		   (()
		    ,stack)
		   ((,false/thunk)
		    (if ,false/thunk
			(set! ,stack (cons ,false/thunk ,stack))
		      (set! ,stack '())))))))))

  #| end of module |# )

(define (push-compensation-macro expr-stx)
  ;;Transformer  function  used  to  expand  Vicare's  PUSH-COMPENSATION
  ;;macros from the top-level built in environment.  Expand the contents
  ;;of EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ ?release0 ?release* ...)
     (bless
      `(push-compensation-thunk (lambda () ,?release0 ,@?release*))))
    ))

(define (with-compensation-handler-macro expr-stx)
  ;;Transformer  function used  to expand  Vicare's WITH-COMPENSATION-HANDLER  macros
  ;;from the top-level built in environment.  Expand the contents of EXPR-STX; return
  ;;a syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ ?release-thunk ?alloc-thunk)
     (bless
      `(begin
	 (push-compensation-thunk ,?release-thunk)
	 (,?alloc-thunk))))
    ))

(define (compensate-macro expr-stx)
  ;;Transformer function used to  expand Vicare's COMPENSATE macros from
  ;;the  top-level  built  in   environment.   Expand  the  contents  of
  ;;EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (define-constant __who__ 'compensate)
  (define (%synner message subform)
    (syntax-violation __who__ message expr-stx subform))
  (syntax-match expr-stx ()
    ((_ ?alloc0 ?form* ...)
     (let ((free #f))
       (define alloc*
	 (let recur ((form-stx ?form*))
	   (syntax-match form-stx (with)
	     (((with ?release0 ?release* ...))
	      (begin
		(set! free `(push-compensation ,?release0 ,@?release*))
		'()))

	     (()
	      (%synner "invalid compensation syntax: missing WITH keyword"
		       form-stx))

	     (((with))
	      (%synner "invalid compensation syntax: empty WITH keyword"
		       (bless '(with))))

	     ((?alloc ?form* ...)
	      (cons ?alloc (recur ?form*)))
	     )))
       (bless
	`(begin0 (begin ,?alloc0 . ,alloc*) ,free))))
    ))


;;;; non-core macro: CONCURRENTLY, MONITOR

(define (concurrently-macro expr-stx)
  ;;Transformer  function  used  to  expand Vicare's  CONCURRENTLY  macros  from  the
  ;;top-level built in environment.  Expand the contents of EXPR-STX; return a syntax
  ;;object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ ?thunk0 ?thunk* ...)
     (let ((counter (gensym "counter")))
       (bless
	`(let ((,counter 0))
	   (begin
	     (set! ,counter (add1 ,counter))
	     (coroutine (lambda () (,?thunk0) (set! ,counter (sub1 ,counter)))))
	   ,@(map (lambda (thunk)
		    `(begin
		       (set! ,counter (add1 ,counter))
		       (coroutine (lambda () (,thunk)  (set! ,counter (sub1 ,counter))))))
	       ?thunk*)
	   (finish-coroutines (lambda ()
				(zero? ,counter)))))))
    ))

(define (monitor-macro expr-stx)
  ;;Transformer function  used to expand  Vicare's MONITOR macros from  the top-level
  ;;built in  environment.  Expand the contents  of EXPR-STX; return a  syntax object
  ;;that must be further expanded.
  ;;
  ;;Allow only ?CONCURRENT-COROUTINES-MAXIMUM to concurrently enter the monitor.
  ;;
  (syntax-match expr-stx ()
    ((_ ?concurrent-coroutines-maximum ?thunk)
     (let ((KEY (gensym)))
       (bless
	`(do-monitor (quote ,KEY) ,?concurrent-coroutines-maximum ,?thunk))))
    ))


;;;; non-core macro: SYNTAX-RULES, DEFINE-SYNTAX-RULE

(define (syntax-rules-macro expr-stx)
  ;;Transformer function  used to  expand R6RS SYNTAX-RULES  macros from
  ;;the  top-level  built  in  environment.   Process  the  contents  of
  ;;EXPR-STX; return a syntax object that needs to be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ (?literal* ...)
	(?pattern* ?template*)
	...)
     (begin
       (%verify-literals ?literal* expr-stx)
       (bless
	`(lambda (x)
	   (syntax-case x ,?literal*
	     ,@(map (lambda (pattern template)
		      (syntax-match pattern ()
			((_ . ??rest)
			 `((g . ,??rest)
			   (syntax ,template)))
			(_
			 (syntax-violation #f
			   "invalid syntax-rules pattern"
			   expr-stx pattern))))
		 ?pattern* ?template*))))))))

(define (define-syntax-rule-macro expr-stx)
  ;;Transformer  function  used  to expand  Vicare's  DEFINE-SYNTAX-RULE
  ;;macros  from  the  top-level  built  in  environment.   Process  the
  ;;contents  of EXPR-STX;  return  a  syntax object  that  needs to  be
  ;;further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ (?name ?arg* ... . ?rest) ?body0 ?body* ...)
     (identifier? ?name)
     (bless
      `(define-syntax ,?name
	 (syntax-rules ()
	   ((_ ,@?arg* . ,?rest)
	    (begin ,?body0 ,@?body*))))))
    ))


;;;; non-core macro: DEFINE-SYNTAX*

(define (define-syntax*-macro expr-stx)
  ;;Transformer function  used to expand Vicare's  DEFINE-SYNTAX* macros
  ;;from the  top-level built  in environment.   Expand the  contents of
  ;;EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ ?name)
     (identifier? ?name)
     (bless
      `(define-syntax ,?name (syntax-rules ()))))

    ((_ ?name ?expr)
     (identifier? ?name)
     (bless
      `(define-syntax ,?name ,?expr)))

    ((_ (?name ?stx) ?body0 ?body* ...)
     (and (identifier? ?name)
	  (identifier? ?stx))
     (let ((SYNNER (datum->syntax ?name 'synner)))
       (bless
	`(define-syntax ,?name
	   (lambda (,?stx)
	     (fluid-let-syntax
		 ((__who__ (identifier-syntax (quote ,?name))))
	       (letrec
		   ((,SYNNER (case-lambda
			      ((message)
			       (,SYNNER message #f))
			      ((message subform)
			       (syntax-violation __who__ message ,?stx subform)))))
		 ,?body0 ,@?body*)))))))
    ))


;;;; non-core macro: WITH-SYNTAX

(define (with-syntax-macro expr-stx)
  ;;Transformer function used to expand R6RS WITH-SYNTAX macros from the
  ;;top-level built  in environment.   Expand the contents  of EXPR-STX;
  ;;return a syntax object that must be further expanded.
  ;;
  ;;A WITH-SYNTAX form:
  ;;
  ;;   (with-syntax ((?pat0 ?expr0)
  ;;                 (?pat1 ?expr1))
  ;;     ?body0 ?body ...)
  ;;
  ;;is expanded as follows:
  ;;
  ;;   (syntax-case ?expr0 ()
  ;;     (?pat0
  ;;      (syntax-case ?expr1 ()
  ;;       (?pat1
  ;;        (internal-body ?body0 ?body ...))
  ;;       (_
  ;;        (assertion-violation ---))))
  ;;     (_
  ;;      (assertion-violation ---)))
  ;;
  (syntax-match expr-stx ()
    ((_ ((?pat* ?expr*) ...) ?body ?body* ...)
     (let ((idn* (let recur ((pat* ?pat*))
		   (if (null? pat*)
		       '()
		     (receive (pat idn*)
			 (convert-pattern (car pat*) '())
		       (append idn* (recur (cdr pat*))))))))
       (let ((formals (map car idn*)))
	 (unless (standard-formals-syntax? formals)
	   (error-invalid-formals-syntax expr-stx formals)))
       (let ((t* (generate-temporaries ?expr*)))
	 (bless
	  `(let ,(map list t* ?expr*)
	     ,(let recur ((pat* ?pat*)
			  (t*   t*))
		(if (null? pat*)
		    `(internal-body ,?body . ,?body*)
		  `(syntax-case ,(car t*) ()
		     (,(car pat*)
		      ,(recur (cdr pat*) (cdr t*)))
		     (_
		      (assertion-violation 'with-syntax
			"pattern does not match value"
			',(car pat*) ,(car t*)))))))))))
    ))


;;;; non-core macro: IDENTIFIER-SYNTAX

(define (identifier-syntax-macro stx)
  ;;Transformer function  used to  expand R6RS  IDENTIFIER-SYNTAX macros
  ;;from the  top-level built  in environment.   Expand the  contents of
  ;;EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (syntax-match stx (set!)
    ((_ ?expr)
     (bless
      `(lambda (x)
	 (syntax-case x ()
	   (??id
	    (identifier? (syntax ??id))
	    (syntax ,?expr))
	   ((??id ??expr* ...)
	    (identifier? (syntax ??id))
	    (cons (syntax ,?expr) (syntax (??expr* ...))))
	   ))))

    ((_ (?id1
	 ?expr1)
	((set! ?id2 ?expr2)
	 ?expr3))
     (and (identifier? ?id1)
	  (identifier? ?id2)
	  (identifier? ?expr2))
     (bless
      `(make-variable-transformer
	(lambda (x)
	  (syntax-case x (set!)
	    (??id
	     (identifier? (syntax ??id))
	     (syntax ,?expr1))
	    ((set! ??id ,?expr2)
	     (syntax ,?expr3))
	    ((??id ??expr* ...)
	     (identifier? (syntax ??id))
	     (syntax (,?expr1 ??expr* ...))))))))
    ))


;;;; non-core macro: LET*, TRACE-LET

(define (let*-macro expr-stx)
  ;;Transformer  function  used to  expand  R6RS  LET* macros  from  the
  ;;top-level built  in environment.   Expand the contents  of EXPR-STX;
  ;;return a syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ ((?lhs* ?rhs*) ...) ?body ?body* ...)
     ;;Remember that LET* allows bindings with duplicate identifiers, so
     ;;we do *not* use LIST-OF-TAGGED-BINDINGS? here.
     (for-all tagged-identifier-syntax? ?lhs*)
     (bless
      (let recur ((x* (map list ?lhs* ?rhs*)))
	(if (null? x*)
	    `(internal-body ,?body . ,?body*)
	  `(let (,(car x*)) ,(recur (cdr x*)))))))
    ))

(define (trace-let-macro expr-stx)
  ;;Transformer function  used to expand Vicare's  TRACE-LET macros from
  ;;the  top-level  built  in   environment.   Expand  the  contents  of
  ;;EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ ?recur ((?lhs* ?rhs*) ...) ?body ?body* ...)
     (identifier? ?recur)
     (receive (lhs* tag*)
	 (parse-list-of-tagged-bindings ?lhs* expr-stx)
       (bless
	`((letrec ((,?recur (trace-lambda ,?recur ,?lhs*
					  ,?body . ,?body*)))
	    ,?recur)
	  . ,(map (lambda (rhs tag)
		    `(tag-assert-and-return (,tag) ,rhs))
	       ?rhs* tag*)))))
    ))


;;;; non-core macro: LET-VALUES

(module (let-values-macro)
  ;;Transformer function  used to  expand R6RS LET-VALUES  macros from  the top-level
  ;;built in  environment.  Expand  the contents of  INPUT-FORM.STX; return  a syntax
  ;;object that must be further expanded.
  ;;
  ;;A LET-VALUES syntax like:
  ;;
  ;;   (let-values (((a b c) rhs0)
  ;;                ((d e f) rhs1))
  ;;     ?body0 ?body ...)
  ;;
  ;;is expanded to:
  ;;
  ;;   (call-with-values
  ;;       (lambda () rhs0)
  ;;     (lambda (G.a G.b G.c)
  ;;       (call-with-values
  ;;           (lambda () rhs1)
  ;;         (lambda (G.d G.e G.f)
  ;;           (let ((a G.a) (b G.b) (c G.c)
  ;;                 (c G.c) (d G.d) (e G.e))
  ;;             ?body0 ?body)))))
  ;;
  (define-module-who let-values)

  (define (let-values-macro input-form.stx)
    (syntax-match input-form.stx ()
      ((_ () ?body ?body* ...)
       (cons* (bless 'let) '() ?body ?body*))

      ((_ ((?lhs* ?rhs*) ...) ?body ?body* ...)
       (receive (lhs*.standard lhs*.signature)
	   (let loop ((lhs*           ?lhs*)
		      (lhs*.standard  '())
		      (lhs*.signature '()))
	     (if (null? lhs*)
		 (values (reverse lhs*.standard)
			 (reverse lhs*.signature))
	       (receive (lhs.standard lhs.signature)
		   (parse-tagged-formals-syntax (car lhs*) input-form.stx)
		 (loop (cdr lhs*)
		       (cons lhs.standard                           lhs*.standard)
		       (cons (formals-signature-tags lhs.signature) lhs*.signature)))))
	 (bless
	  (let recur ((lhs*.standard  lhs*.standard)
		      (lhs*.signature lhs*.signature)
		      (lhs*.tagged    (syntax-unwrap ?lhs*))
		      (rhs*           ?rhs*)
		      (standard-old*  '())
		      (tagged-old*    '())
		      (new*           '()))
	    (if (null? lhs*.standard)
		`(let ,(map list tagged-old* new*)
		   ,?body . ,?body*)
	      (syntax-match (car lhs*.standard) ()
		((?standard-formal* ...)
		 (receive (y* standard-old* tagged-old* new*)
		     (%rename* ?standard-formal* (car lhs*.tagged) standard-old* tagged-old* new* input-form.stx)
		   `(call-with-values
			(lambda ()
			  (tag-assert-and-return ,(car lhs*.signature) ,(car rhs*)))
		      (lambda ,y*
			,(recur (cdr lhs*.standard) (cdr lhs*.signature) (cdr lhs*.tagged)
				(cdr rhs*) standard-old* tagged-old* new*)))))

		((?standard-formal* ... . ?standard-rest-formal)
		 (receive (tagged-formal* tagged-rest-formal)
		     (improper-list->list-and-rest (car lhs*.tagged))
		   (let*-values
		       (((y  standard-old* tagged-old* new*)
			 (%rename  ?standard-rest-formal tagged-rest-formal standard-old* tagged-old* new* input-form.stx))
			((y* standard-old* tagged-old* new*)
			 (%rename* ?standard-formal*     tagged-formal*     standard-old* tagged-old* new* input-form.stx)))
		     `(call-with-values
			  (lambda () ,(car rhs*))
			(lambda ,(append y* y)
			  ,(recur (cdr lhs*.standard) (cdr lhs*.signature) (cdr lhs*.tagged)
				  (cdr rhs*) standard-old* tagged-old* new*))))))
		(?others
		 (syntax-violation __module_who__ "malformed bindings" input-form.stx ?others))))))))
      ))

  (define (%rename standard-formal tagged-formal standard-old* tagged-old* new* input-form.stx)
    (when (bound-id-member? standard-formal standard-old*)
      (syntax-violation __module_who__ "duplicate binding" input-form.stx standard-formal))
    (let ((y (gensym (syntax->datum standard-formal))))
      (values y (cons standard-formal standard-old*) (cons tagged-formal tagged-old*) (cons y new*))))

  (define (%rename* standard-formal* tagged-formal* standard-old* tagged-old* new* input-form.stx)
    (if (null? standard-formal*)
	(values '() standard-old* tagged-old* new*)
      (let*-values
	  (((y  standard-old* tagged-old* new*)
	    (%rename  (car standard-formal*) (car tagged-formal*) standard-old* tagged-old* new* input-form.stx))
	   ((y* standard-old* tagged-old* new*)
	    (%rename* (cdr standard-formal*) (cdr tagged-formal*) standard-old* tagged-old* new* input-form.stx)))
	(values (cons y y*) standard-old* tagged-old* new*))))

  #| end of module: LET-VALUES-MACRO |# )


;;;; non-core macro: LET*-VALUES

(define (let*-values-macro expr-stx)
  ;;Transformer function used to expand R6RS LET*-VALUES macros from the
  ;;top-level built  in environment.   Expand the contents  of EXPR-STX;
  ;;return a syntax object that must be further expanded.
  ;;
  ;;A LET*-VALUES syntax like:
  ;;
  ;;   (let*-values (((a b c) rhs0)
  ;;                 ((d e f) rhs1))
  ;;     ?body0 ?body ...)
  ;;
  ;;is expanded to:
  ;;
  ;;   (call-with-values
  ;;       (lambda () rhs0)
  ;;     (lambda (a b c)
  ;;       (call-with-values
  ;;           (lambda () rhs1)
  ;;         (lambda (d e f)
  ;;           (begin ?body0 ?body)))))
  ;;
  (syntax-match expr-stx ()
    ((_ () ?body ?body* ...)
     (cons* (bless 'let) '() ?body ?body*))

    ((_ ((?lhs ?rhs)) ?body ?body* ...)
     (bless
      `(let-values ((,?lhs ,?rhs)) ,?body . ,?body*)))

    ((_ ((?lhs0 ?rhs0) (?lhs* ?rhs*) ...) ?body ?body* ...)
     (bless
      `(let-values ((,?lhs0 ,?rhs0))
	 (let*-values ,(map list ?lhs* ?rhs*)
	   ,?body . ,?body*))))
    ))


;;;; non-core macro: VALUES->LIST-MACRO

(define (values->list-macro expr-stx)
  ;;Transformer  function used  to expand  Vicare's VALUES->LIST  macros
  ;;from the  top-level built  in environment.   Expand the  contents of
  ;;EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ ?expr)
     (bless
      `(call-with-values
	   (lambda () ,?expr)
	 list)))))


;;;; non-core macro: LET*-SYNTAX

(define (let*-syntax-macro expr-stx)
  ;;Transformer function used to expand Vicare's LET*-SYNTAX macros from
  ;;the  top-level  built  in   environment.   Expand  the  contents  of
  ;;EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ;;No bindings.
    ((_ () ?body ?body* ...)
     (bless
      `(begin ,?body . ,?body*)))
    ;;Single binding.
    ((_ ((?lhs ?rhs)) ?body ?body* ...)
     (bless
      `(let-syntax ((,?lhs ,?rhs))
	 ,?body . ,?body*)))
    ;;Multiple bindings
    ((_ ((?lhs ?rhs) (?lhs* ?rhs*) ...) ?body ?body* ...)
     (bless
      `(let-syntax ((,?lhs ,?rhs))
	 (let*-syntax ,(map list ?lhs* ?rhs*)
	   ,?body . ,?body*))))
    ))


;;;; non-core macro: LET-CONSTANTS, LET*-CONSTANTS, LETREC-CONSTANTS, LETREC*-CONSTANTS

(define (let-constants-macro expr-stx)
  ;;Transformer function  used to  expand Vicare's  LET-CONSTANTS macros
  ;;from the  top-level built  in environment.   Expand the  contents of
  ;;EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ;;No bindings.
    ((_ () ?body ?body* ...)
     (bless
      `(internal-body ,?body . ,?body*)))
    ;;Multiple bindings
    ((_ ((?lhs ?rhs) (?lhs* ?rhs*) ...) ?body ?body* ...)
     (let ((SHADOW* (generate-temporaries (cons ?lhs ?lhs*))))
       (bless
	`(let ,(map list SHADOW* (cons ?rhs ?rhs*))
	   (let-syntax ,(map (lambda (lhs shadow)
			       `(,lhs (identifier-syntax ,shadow)))
			  (cons ?lhs ?lhs*) SHADOW*)
	     ,?body . ,?body*)))))
    ))

(define (let*-constants-macro expr-stx)
  ;;Transformer function  used to expand Vicare's  LET*-CONSTANTS macros
  ;;from the  top-level built  in environment.   Expand the  contents of
  ;;EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ;;No bindings.
    ((_ () ?body ?body* ...)
     (bless
      `(internal-body ,?body . ,?body*)))
    ;;Multiple bindings
    ((_ ((?lhs ?rhs) (?lhs* ?rhs*) ...) ?body ?body* ...)
     (bless
      `(let-constants ((,?lhs ,?rhs))
	 (let*-constants ,(map list ?lhs* ?rhs*)
	   ,?body . ,?body*))))
    ))

(define (letrec-constants-macro expr-stx)
  ;;Transformer function used to expand Vicare's LETREC-CONSTANTS macros
  ;;from the  top-level built  in environment.   Expand the  contents of
  ;;EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ () ?body0 ?body* ...)
     (bless
      `(internal-body ,?body0 . ,?body*)))

    ((_ ((?lhs* ?rhs*) ...) ?body0 ?body* ...)
     (let ((TMP* (generate-temporaries ?lhs*))
	   (VAR* (generate-temporaries ?lhs*)))
       (bless
	`(let ,(map (lambda (var)
		      `(,var (void)))
		 VAR*)
	   (let-syntax ,(map (lambda (lhs var)
			       `(,lhs (identifier-syntax ,var)))
			  ?lhs* VAR*)
	     ;;Do not enforce the order of evaluation of ?RHS.
	     (let ,(map list TMP* ?rhs*)
	       ,@(map (lambda (var tmp)
			`(set! ,var ,tmp))
		   VAR* TMP*)
	       (internal-body ,?body0 . ,?body*)))))))
    ))

(define (letrec*-constants-macro expr-stx)
  ;;Transformer  function  used  to  expand  Vicare's  LETREC*-CONSTANTS
  ;;macros from the top-level built in environment.  Expand the contents
  ;;of EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ () ?body0 ?body* ...)
     (bless
      `(internal-body ,?body0 . ,?body*)))

    ((_ ((?lhs* ?rhs*) ...) ?body0 ?body* ...)
     (let ((TMP* (generate-temporaries ?lhs*))
	   (VAR* (generate-temporaries ?lhs*)))
       (bless
	`(let ,(map (lambda (var)
		      `(,var (void)))
		 VAR*)
	   (let-syntax ,(map (lambda (lhs var)
			       `(,lhs (identifier-syntax ,var)))
			  ?lhs* VAR*)
	     ;;Do enforce the order of evaluation of ?RHS.
	     (let* ,(map list TMP* ?rhs*)
	       ,@(map (lambda (var tmp)
			`(set! ,var ,tmp))
		   VAR* TMP*)
	       (internal-body ,?body0 . ,?body*)))))))
    ))


;;;; non-core macro: CASE-DEFINE

(define (case-define-macro expr-stx)
  ;;Transformer function used to expand Vicare's CASE-DEFINE macros from
  ;;the  top-level  built  in   environment.   Expand  the  contents  of
  ;;EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ ?who ?cl-clause ?cl-clause* ...)
     (identifier? ?who)
     (bless
      `(define ,?who
	 (fluid-let-syntax ((__who__ (identifier-syntax (quote ,?who))))
	   (case-lambda ,?cl-clause . ,?cl-clause*)))))
    ))


;;;; non-core macro: DEFINE*, LAMBDA*, CASE-DEFINE*, CASE-LAMBDA*

(module (lambda*-macro
	 define*-macro
	 case-lambda*-macro
	 case-define*-macro)

  (define-record argument-validation-spec
    (arg-id
		;Identifier  representing  the  formal  name of  the  argument  being
		;validated.
     pred
		;Syntax object representing the validation logic predicate.
     expr
		;Syntax object representing an argument's validation expression.
     list-arg?
		;Boolean.  True if this struct represents a rest or args argument.
     ))

  (define-record retval-validation-spec
    (rv-id
		;Identifier representing the internal formal name of the return value
		;being validated.
     pred
		;Syntax object representing the validation logic predicate.
     expr
		;Syntax object representing a return value's validation expression.
     ))

;;; --------------------------------------------------------------------

  (module (define*-macro)
    ;;Transformer function used to expand  Vicare's DEFINE* macros from the top-level
    ;;built in environment.  Expand the contents of EXPR.STX.  Return a syntax object
    ;;that must be further expanded.
    ;;
    (define (define*-macro expr.stx)
      (define (%synner message subform)
	(syntax-violation 'define* message expr.stx subform))
      (bless
       (syntax-match expr.stx (brace)
	 ;;No ret-pred.
	 ((_ (?who . ?formals) ?body0 ?body* ...)
	  (identifier? ?who)
	  (%generate-define-output-form/without-ret-pred ?who ?formals (cons ?body0 ?body*) %synner))

	 ;;Return value predicates.
	 ((_ ((brace ?who ?ret-pred0 ?ret-pred* ...) . ?formals) ?body0 ?body* ...)
	  (identifier? ?who)
	  (%generate-define-output-form/with-ret-pred ?who (cons ?ret-pred0 ?ret-pred*) ?formals (cons ?body0 ?body*) %synner))

	 ((_ ?who ?expr)
	  (identifier? ?who)
	  `(define ,?who
	     (fluid-let-syntax ((__who__ (identifier-syntax (quote ,?who))))
	       ,?expr)))

	 ((_ ?who)
	  (identifier? ?who)
	  `(define ,?who (void)))

	 )))

    (define (%generate-define-output-form/without-ret-pred who.id predicate-formals.stx body*.stx synner)
      ;;Build and return a symbolic expression, to be BLESSed later, representing the
      ;;definition.
      ;;
      ;;STANDARD-FORMALS.STX  is an  improper  list of  identifiers representing  the
      ;;standard formals.  ARG-VALIDATION-SPEC* is a list of ARGUMENT-VALIDATION-SPEC
      ;;structures, each representing a validation predicate.
      (receive (standard-formals.stx arg-validation-spec*)
	  (%parse-predicate-formals predicate-formals.stx synner)
	`(define (,who.id . ,standard-formals.stx)
	   (fluid-let-syntax
	       ((__who__ (identifier-syntax (quote ,who.id))))
	     ,(if (option.enable-arguments-validation?)
		  ;;With validation.
		  `(begin
		     ,@(%make-arg-validation-forms arg-validation-spec* synner)
		     (internal-body . ,body*.stx))
		;;Without validation
		`(begin . ,body*.stx))))))

    (define (%generate-define-output-form/with-ret-pred who.id ret-pred*.stx predicate-formals.stx body*.stx synner)
      ;;Build and return a symbolic expression, to be BLESSed later, representing the
      ;;definition.
      ;;
      ;;STANDARD-FORMALS.STX  is an  improper  list of  identifiers representing  the
      ;;standard formals.  ARG-VALIDATION-SPEC* is a list of ARGUMENT-VALIDATION-SPEC
      ;;structures, each representing a validation predicate.
      (receive (standard-formals.stx arg-validation-spec*)
	  (%parse-predicate-formals predicate-formals.stx synner)
	`(define (,who.id . ,standard-formals.stx)
	   (fluid-let-syntax
	       ((__who__ (identifier-syntax (quote ,who.id))))
	     ,(if (option.enable-arguments-validation?)
		  ;;With validation.
		  (let* ((RETVAL*            (generate-temporaries ret-pred*.stx))
			 (RETVAL-VALIDATION* (%make-ret-validation-forms
					      (map (lambda (rv.id pred.stx)
						     (make-retval-validation-spec rv.id pred.stx
										  (%parse-logic-predicate-syntax pred.stx rv.id synner)))
						RETVAL* ret-pred*.stx)
					      synner)))
		    `(begin
		       ,@(%make-arg-validation-forms arg-validation-spec* synner)
		       (receive-and-return ,RETVAL*
			   (internal-body . ,body*.stx)
			 . ,RETVAL-VALIDATION*)))
		;;Without validation.
		`(begin . ,body*.stx))))))

    #| end of module: DEFINE*-MACRO |# )

;;; --------------------------------------------------------------------

  (module (case-define*-macro)

    (define (case-define*-macro expr.stx)
      ;;Transformer function  used to  expand Vicare's  CASE-DEFINE* macros  from the
      ;;top-level built in  environment.  Expand the contents of  EXPR.STX.  Return a
      ;;syntax object that must be further expanded.
      ;;
      (define (%synner message subform)
	(syntax-violation 'case-define* message expr.stx subform))
      (syntax-match expr.stx ()
	((_ ?who ?clause0 ?clause* ...)
	 (identifier? ?who)
	 (bless
	  `(define ,?who
	     (case-lambda
	      ,@(map (lambda (?clause)
		       (%generate-case-define-form ?who ?clause %synner))
		  (cons ?clause0 ?clause*))))))
	))

    (define (%generate-case-define-form ?who ?clause synner)
      (syntax-match ?clause (brace)
	;;Return value predicates.
	((((brace ?underscore ?ret-pred0 ?ret-pred* ...) . ?formals) ?body0 ?body* ...)
	 (underscore-id? ?underscore)
	 (%generate-case-define-clause-form/with-ret-pred ?who (cons ?ret-pred0 ?ret-pred*) ?formals (cons ?body0 ?body*) synner))

	;;No ret-pred.
	((?formals ?body0 ?body* ...)
	 (%generate-case-define-clause-form/without-ret-pred ?who ?formals (cons ?body0 ?body*) synner))
	))

    (define (%generate-case-define-clause-form/without-ret-pred who.id predicate-formals.stx body*.stx synner)
      ;;Build and return  a symbolic expression, to be BLESSed  later, representing a
      ;;definition clause.
      ;;
      ;;STANDARD-FORMALS.STX  is an  improper  list of  identifiers representing  the
      ;;standard formals.  ARG-VALIDATION-SPEC* is a list of ARGUMENT-VALIDATION-SPEC
      ;;structures, each representing a validation predicate.
      (receive (standard-formals.stx arg-validation-spec*)
	  (%parse-predicate-formals predicate-formals.stx synner)
	`(,standard-formals.stx
	  (fluid-let-syntax
	      ((__who__ (identifier-syntax (quote ,who.id))))
	    ,(if (option.enable-arguments-validation?)
		 ;;With validation.
		 `(begin
		    ,@(%make-arg-validation-forms arg-validation-spec* synner)
		    (internal-body . ,body*.stx))
	       ;;Without validation.
	       `(begin . ,body*.stx))))))

    (define (%generate-case-define-clause-form/with-ret-pred who.id ret-pred*.stx predicate-formals.stx body*.stx synner)
      ;;Build and return  a symbolic expression, to be BLESSed  later, representing a
      ;;definition clause.
      ;;
      ;;STANDARD-FORMALS.STX  is an  improper  list of  identifiers representing  the
      ;;standard formals.  ARG-VALIDATION-SPEC* is a list of ARGUMENT-VALIDATION-SPEC
      ;;structures, each representing a validation predicate.
      (receive (standard-formals.stx arg-validation-spec*)
	  (%parse-predicate-formals predicate-formals.stx synner)
	`(,standard-formals.stx
	  (fluid-let-syntax
	      ((__who__ (identifier-syntax (quote ,who.id))))
	    ,(if (option.enable-arguments-validation?)
		 ;;With validation.
		 (let* ((RETVAL*            (generate-temporaries ret-pred*.stx))
			(RETVAL-VALIDATION* (%make-ret-validation-forms
					     (map (lambda (rv.id pred.stx)
						    (make-retval-validation-spec rv.id pred.stx
										 (%parse-logic-predicate-syntax pred.stx rv.id synner)))
					       RETVAL* ret-pred*.stx)
					     synner)))
		   `(begin
		      ,@(%make-arg-validation-forms arg-validation-spec* synner)
		      (receive-and-return ,RETVAL*
			  (internal-body . ,body*.stx)
			. ,RETVAL-VALIDATION*)))
	       ;;Without validation.
	       `(begin . ,body*.stx))))))

    #| end of module: CASE-DEFINE*-MACRO |# )

;;; --------------------------------------------------------------------

  (module (lambda*-macro)

    (define (lambda*-macro expr.stx)
      ;;Transformer  function  used  to  expand  Vicare's  LAMBDA*  macros  from  the
      ;;top-level built in  environment.  Expand the contents of  EXPR.STX.  Return a
      ;;syntax object that must be further expanded.
      ;;
      (define (%synner message subform)
	(syntax-violation 'lambda* message expr.stx subform))
      (bless
       (syntax-match expr.stx (brace)
	 ;;Ret-pred with list spec.
	 ((_ ((brace ?underscore ?ret-pred0 ?ret-pred* ...) . ?formals) ?body0 ?body* ...)
	  (underscore-id? ?underscore)
	  (%generate-lambda-output-form/with-ret-pred (cons ?ret-pred0 ?ret-pred*) ?formals (cons ?body0 ?body*) %synner))

	 ;;No ret-pred.
	 ((_ ?formals ?body0 ?body* ...)
	  (%generate-lambda-output-form/without-ret-pred ?formals (cons ?body0 ?body*) %synner))

	 )))

    (define (%generate-lambda-output-form/without-ret-pred predicate-formals.stx body*.stx synner)
      ;;Build and return a symbolic expression, to be BLESSed later, representing the
      ;;LAMBDA syntax use.
      ;;
      ;;STANDARD-FORMALS.STX  is an  improper  list of  identifiers representing  the
      ;;standard formals.  ARG-VALIDATION-SPEC* is a list of ARGUMENT-VALIDATION-SPEC
      ;;structures, each representing a validation predicate.
      (receive (standard-formals.stx arg-validation-spec*)
	  (%parse-predicate-formals predicate-formals.stx synner)
	`(lambda ,standard-formals.stx
	   (fluid-let-syntax
	       ((__who__ (identifier-syntax (quote _))))
	     ,(if (option.enable-arguments-validation?)
		  ;;With validation.
		  `(begin
		     ,@(%make-arg-validation-forms arg-validation-spec* synner)
		     (internal-body . ,body*.stx))
		;;Without validation.
		`(begin . ,body*.stx))))))

    (define (%generate-lambda-output-form/with-ret-pred ret-pred*.stx predicate-formals.stx body*.stx synner)
      ;;Build and return a symbolic expression, to be BLESSed later, representing the
      ;;LAMBDA syntax use.
      ;;
      ;;STANDARD-FORMALS.STX  is an  improper  list of  identifiers representing  the
      ;;standard formals.  ARG-VALIDATION-SPEC* is a list of ARGUMENT-VALIDATION-SPEC
      ;;structures, each representing a validation predicate.
      (receive (standard-formals.stx arg-validation-spec*)
	  (%parse-predicate-formals predicate-formals.stx synner)
	`(lambda ,standard-formals.stx
	   (fluid-let-syntax
	       ((__who__ (identifier-syntax (quote _))))
	     ,(if (option.enable-arguments-validation?)
		  ;;With validation.
		  (let* ((RETVAL*            (generate-temporaries ret-pred*.stx))
			 (RETVAL-VALIDATION* (%make-ret-validation-forms
					      (map (lambda (rv.id pred.stx)
						     (make-retval-validation-spec rv.id pred.stx
										  (%parse-logic-predicate-syntax pred.stx rv.id synner)))
						RETVAL* ret-pred*.stx)
					      synner)))
		    `(begin
		       ,@(%make-arg-validation-forms arg-validation-spec* synner)
		       (receive-and-return ,RETVAL*
			   (internal-body . ,body*.stx)
			 . ,RETVAL-VALIDATION*)))
		;;Without validation
		`(begin . ,body*.stx))))))

    #| end of module: LAMBDA*-MACRO |# )

;;; --------------------------------------------------------------------

  (module (case-lambda*-macro)

    (define (case-lambda*-macro expr.stx)
      ;;Transformer function  used to  expand Vicare's  CASE-LAMBDA* macros  from the
      ;;top-level built in  environment.  Expand the contents of  EXPR.STX.  Return a
      ;;syntax object that must be further expanded.
      ;;
      (define (%synner message subform)
	(syntax-violation 'case-lambda* message expr.stx subform))
      (syntax-match expr.stx ()
	((_ ?clause0 ?clause* ...)
	 (bless
	  `(case-lambda
	    ,@(map (lambda (clause.stx)
		     (%generate-case-lambda-form clause.stx %synner))
		(cons ?clause0 ?clause*)))))
	))

    (define (%generate-case-lambda-form clause.stx synner)
      (syntax-match clause.stx (brace)
	;;Ret-pred with list spec.
	((((brace ?underscore ?ret-pred0 ?ret-pred* ...) . ?formals) ?body0 ?body* ...)
	 (underscore-id? ?underscore)
	 (%generate-case-lambda-clause-form/with-ret-pred (cons ?ret-pred0 ?ret-pred*) ?formals (cons ?body0 ?body*) synner))

	;;No ret-pred.
	((?formals ?body0 ?body* ...)
	 (%generate-case-lambda-clause-form/without-ret-pred ?formals (cons ?body0 ?body*) synner))
	))

    (define (%generate-case-lambda-clause-form/without-ret-pred predicate-formals.stx body*.stx synner)
      ;;Build and return a symbolic expression, to be BLESSed later, representing the
      ;;CASE-LAMBDA clause.
      ;;
      ;;STANDARD-FORMALS.STX  is an  improper  list of  identifiers representing  the
      ;;standard formals.  ARG-VALIDATION-SPEC* is a list of ARGUMENT-VALIDATION-SPEC
      ;;structures, each representing a validation predicate.
      (receive (standard-formals.stx arg-validation-spec*)
	  (%parse-predicate-formals predicate-formals.stx synner)
	`(,standard-formals.stx
	  (fluid-let-syntax
	      ((__who__ (identifier-syntax (quote _))))
	    ,(if (option.enable-arguments-validation?)
		 ;;With validation.
		 `(begin
		    ,@(%make-arg-validation-forms arg-validation-spec* synner)
		    (internal-body . ,body*.stx))
	       ;;Without validation.
	       `(begin . ,body*.stx))))))

    (define (%generate-case-lambda-clause-form/with-ret-pred ret-pred*.stx predicate-formals.stx body*.stx synner)
      ;;Build and return a symbolic expression, to be BLESSed later, representing the
      ;;CASE-LAMBDA clause.
      ;;
      ;;STANDARD-FORMALS.STX  is an  improper  list of  identifiers representing  the
      ;;standard formals.  ARG-VALIDATION-SPEC* is a list of ARGUMENT-VALIDATION-SPEC
      ;;structures, each representing a validation predicate.
      (receive (standard-formals.stx arg-validation-spec*)
	  (%parse-predicate-formals predicate-formals.stx synner)
	`(,standard-formals.stx
	  (fluid-let-syntax
	      ((__who__ (identifier-syntax (quote _))))
	    ,(if (option.enable-arguments-validation?)
		 ;;With validation
		 (let* ((RETVAL*            (generate-temporaries ret-pred*.stx))
			(RETVAL-VALIDATION* (%make-ret-validation-forms
					     (map (lambda (rv.id pred.stx)
						    (make-retval-validation-spec rv.id pred.stx
										 (%parse-logic-predicate-syntax pred.stx rv.id synner)))
					       RETVAL* ret-pred*.stx)
					     synner)))
		   `(begin
		      ,@(%make-arg-validation-forms arg-validation-spec* synner)
		      (receive-and-return ,RETVAL*
			  (internal-body . ,body*.stx)
			. ,RETVAL-VALIDATION*)))
	       ;;Without validation.
	       `(begin . ,body*.stx))))))

    #| end of module: CASE-LAMBDA*-MACRO |# )

;;; --------------------------------------------------------------------

  (define (%parse-predicate-formals predicate-formals.stx synner)
    ;;Split  formals from  tags.   We  rely on  the  DEFINE,  LAMBDA and  CASE-LAMBDA
    ;;syntaxes in the  output form to further validate the  formals against duplicate
    ;;bindings.
    ;;
    ;;We use  the conventions: ?ID,  ?REST-ID and ?ARGS-ID are  argument identifiers;
    ;;?PRED is a predicate identifier.
    ;;
    ;;We accept the following standard formals formats:
    ;;
    ;;   ?args-id
    ;;   (?id ...)
    ;;   (?id0 ?id ... . ?rest-id)
    ;;
    ;;and in addition the following predicate formals:
    ;;
    ;;   (brace ?args-id ?args-pred)
    ;;   (?arg ...)
    ;;   (?arg0 ?arg ... . ?rest-arg)
    ;;
    ;;where ?ARG is a predicate argument with one of the formats:
    ;;
    ;;   ?id
    ;;   (brace ?id ?pred)
    ;;
    ;;Return 2 values:
    ;;
    ;;* A  list of syntax objects  representing the standard formals  for the DEFINE,
    ;;  LAMBDA and CASE-LAMBDA syntaxes.
    ;;
    ;;*  A  list  of  false booleans  and  ARGUMENT-VALIDATION-SPEC  structures  each
    ;;  representing a validation predicate; when an argument has no logic predicate:
    ;;  the corresponding item in the list is the boolean false.
    ;;
    (syntax-match predicate-formals.stx (brace)

      ;;Tagged args.
      ;;
      ((brace ?args-id ?args-pred)
       (identifier? ?args-id)
       (values ?args-id
	       (list (make-argument-validation-spec ?args-id ?args-pred
						    (%parse-list-logic-predicate-syntax ?args-pred ?args-id synner) #t))))

      ;;Possibly tagged identifiers with tagged rest argument.
      ;;
      ((?pred-arg* ... . (brace ?rest-id ?rest-pred))
       (begin
	 (unless (identifier? ?rest-id)
	   (synner "invalid rest argument specification" (list 'brace ?rest-id ?rest-pred)))
	 (let recur ((?pred-arg* ?pred-arg*))
	   (if (pair? ?pred-arg*)
	       ;;STANDARD-FORMALS.STX is an improper list of identifiers representing
	       ;;the   standard  formals.    ARG-VALIDATION-SPEC*   is   a  list   of
	       ;;ARGUMENT-VALIDATION-SPEC structures, each  representing a validation
	       ;;predicate.
	       (receive (standard-formals.stx arg-validation-spec*)
		   (recur (cdr ?pred-arg*))
		 (let ((?pred-arg (car ?pred-arg*)))
		   (syntax-match ?pred-arg (brace)
		     ;;Untagged argument.
		     (?id
		      (identifier? ?id)
		      (values (cons ?id standard-formals.stx)
			      (cons #f  arg-validation-spec*)))
		     ;;Tagged argument.
		     ((brace ?id ?pred)
		      (identifier? ?id)
		      (values (cons ?id standard-formals.stx)
			      (cons (make-argument-validation-spec ?id ?pred (%parse-logic-predicate-syntax ?pred ?id synner) #f)
				    arg-validation-spec*)))
		     (else
		      (synner "invalid argument specification" ?pred-arg)))))
	     ;;Process rest argument.
	     (values ?rest-id
		     (list (make-argument-validation-spec ?rest-id ?rest-pred
							  (%parse-list-logic-predicate-syntax ?rest-pred ?rest-id synner) #t)))))))

      ;;Possibly tagged identifiers with UNtagged rest argument.
      ;;
      ((?pred-arg* ... . ?rest-id)
       (identifier? ?rest-id)
       (let recur ((?pred-arg* ?pred-arg*))
	 (if (pair? ?pred-arg*)
	     ;;STANDARD-FORMALS.STX is  an improper list of  identifiers representing
	     ;;the   standard   formals.    ARG-VALIDATION-SPEC*   is   a   list   of
	     ;;ARGUMENT-VALIDATION-SPEC  structures, each  representing a  validation
	     ;;predicate.
	     (receive (standard-formals.stx arg-validation-spec*)
		 (recur (cdr ?pred-arg*))
	       (let ((?pred-arg (car ?pred-arg*)))
		 (syntax-match ?pred-arg (brace)
		   ;;Untagged argument.
		   (?id
		    (identifier? ?id)
		    (values (cons ?id standard-formals.stx)
			    (cons #f  arg-validation-spec*)))
		   ;;Tagged argument.
		   ((brace ?id ?pred)
		    (identifier? ?id)
		    (values (cons ?id standard-formals.stx)
			    (cons (make-argument-validation-spec ?id ?pred (%parse-logic-predicate-syntax ?pred ?id synner) #f)
				  arg-validation-spec*)))
		   (else
		    (synner "invalid argument specification" ?pred-arg)))))
	   (values ?rest-id '()))))

      ;;Standard formals: untagged identifiers without rest argument.
      ;;
      ((?id* ...)
       (for-all identifier? ?id*)
       (values ?id* '()))

      ;;Standard formals: untagged identifiers with rest argument.
      ;;
      ((?id* ... . ?rest-id)
       (and (for-all identifier? ?id*)
	    (identifier? ?rest-id))
       (values predicate-formals.stx '()))

      ;;Standard formals: untagged args.
      ;;
      (?args-id
       (identifier? ?args-id)
       (values ?args-id '()))

      ;;Possibly tagged identifiers without rest argument.
      ;;
      ((?pred-arg* ...)
       (let recur ((?pred-arg* ?pred-arg*))
	 (if (pair? ?pred-arg*)
	     ;;STANDARD-FORMALS.STX is  an improper list of  identifiers representing
	     ;;the   standard   formals.    ARG-VALIDATION-SPEC*   is   a   list   of
	     ;;ARGUMENT-VALIDATION-SPEC  structures, each  representing a  validation
	     ;;predicate.
	     (receive (standard-formals.stx arg-validation-spec*)
		 (recur (cdr ?pred-arg*))
	       (let ((?pred-arg (car ?pred-arg*)))
		 (syntax-match ?pred-arg (brace)
		   ;;Untagged argument.
		   (?id
		    (identifier? ?id)
		    (values (cons ?id standard-formals.stx)
			    (cons #f  arg-validation-spec*)))
		   ;;Tagged argument.
		   ((brace ?id ?pred)
		    (identifier? ?id)
		    (values (cons ?id standard-formals.stx)
			    (cons (make-argument-validation-spec ?id ?pred (%parse-logic-predicate-syntax ?pred ?id synner) #f)
				  arg-validation-spec*)))
		   (else
		    (synner "invalid argument specification" ?pred-arg)))))
	   (values '() '()))))
      ))

;;; --------------------------------------------------------------------

  (define (%make-arg-validation-forms arg-validation-spec* synner)
    (reverse
     (cdr ($fold-left/stx (lambda (knil spec)
			    (let ((arg-counter    (car knil))
				  (rev-head-forms (cdr knil)))
			      (if spec
				  ;;This argument HAS a logic predicate specification.
				  (let ((?expr   (argument-validation-spec-expr   spec))
					(?pred   (argument-validation-spec-pred   spec))
					(?arg-id (argument-validation-spec-arg-id spec)))
				    (cons* (fxadd1 arg-counter)
					   (if (argument-validation-spec-list-arg? spec)
					       `(signature-rest-argument-validation-with-predicate
						 __who__ ,arg-counter ,?expr (quote ,?pred) ,?arg-id)
					     `(unless ,?expr
						(procedure-signature-argument-violation __who__
						  "failed argument validation"
						  ,arg-counter (quote ,?pred) ,?arg-id)))
					   rev-head-forms))
				;;This argument HAS NO logic predicate specification.
				(cons (fxadd1 arg-counter) rev-head-forms))))
	    '(1 . ())
	    arg-validation-spec*))))

  (define (%make-ret-validation-forms retval-validation-spec* synner)
    (reverse
     (cdr ($fold-left/stx (lambda (knil spec)
			    (let ((retval-counter (car knil))
				  (rev-head-forms (cdr knil)))
			      (let ((?expr (retval-validation-spec-expr  spec))
				    (?pred (retval-validation-spec-pred  spec))
				    (?ret  (retval-validation-spec-rv-id spec)))
				(if (and (identifier? ?pred)
					 (free-identifier=? ?pred (core-prim-id 'always-true)))
				    ;;This return value HAS NO logic predicate specification.
				    (cons (fxadd1 retval-counter) rev-head-forms)
				  ;;This return value HAS a logic predicate specification.
				  (cons* (fxadd1 retval-counter)
					 `(unless ,?expr
					    (procedure-signature-return-value-violation __who__
					      "failed return value validation"
					      ,retval-counter (quote ,?pred) ,?ret))
					 rev-head-forms)))))
	    '(1 . ())
	    retval-validation-spec*))))

  (define (%parse-logic-predicate-syntax pred.stx var.id synner)
    ;;This is used for normal arguments.
    ;;
    (parse-logic-predicate-syntax pred.stx
				  (lambda (pred.id)
				    (syntax-match pred.id ()
				      (?pred
				       (identifier? ?pred)
				       (list pred.id var.id))
				      (else
				       (synner "expected identifier as predicate name" pred.id))))))

  (define (%parse-list-logic-predicate-syntax pred.stx var.id synner)
    ;;This is used for rest and args arguments.
    ;;
    `(lambda (,var.id)
       ,(parse-logic-predicate-syntax pred.stx
				      (lambda (pred.id)
					(syntax-match pred.id ()
					  (?pred
					   (identifier? ?pred)
					   (list pred.id var.id))
					  (else
					   (synner "expected identifier as predicate name" pred.id)))))))

  #| end of module |# )


;;;; non-core macro: TRACE-LAMBDA, TRACE-DEFINE and TRACE-DEFINE-SYNTAX

(define (trace-lambda-macro expr-stx)
  ;;Transformer  function used  to expand  Vicare's TRACE-LAMBDA  macros
  ;;from the  top-level built  in environment.   Expand the  contents of
  ;;EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ ?who (?formal* ...) ?body ?body* ...)
     (begin
       ;;We parse the formals for validation purposes.
       (parse-tagged-lambda-proto-syntax ?formal* expr-stx)
       (bless
	`(make-traced-procedure ',?who
				(lambda ,?formal*
				  ,?body . ,?body*)))))

    ((_ ?who (?formal* ... . ?rest-formal) ?body ?body* ...)
     (begin
       ;;We parse the formals for validation purposes.
       (parse-tagged-lambda-proto-syntax (append ?formal* ?rest-formal) expr-stx)
       (bless
	`(make-traced-procedure ',?who
				(lambda (,@?formal* . ,?rest-formal)
				  ,?body . ,?body*)))))
    ))

(define (trace-define-macro expr-stx)
  ;;Transformer  function used  to expand  Vicare's TRACE-DEFINE  macros
  ;;from the  top-level built  in environment.   Expand the  contents of
  ;;EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (with-who trace-define
    (syntax-match expr-stx ()
      ((_ (?who ?formal* ...) ?body ?body* ...)
       (begin
	 ;;We parse the formals for validation purposes.
	 (parse-tagged-lambda-proto-syntax ?formal* expr-stx)
	 (bless
	  `(define ,?who
	     (make-traced-procedure ',?who
				    (lambda ,?formal*
				      ,?body . ,?body*))))))

      ((_ (?who ?formal* ... . ?rest-formal) ?body ?body* ...)
       (begin
	 ;;We parse the formals for validation purposes.
	 (parse-tagged-lambda-proto-syntax (append ?formal* ?rest-formal) expr-stx)
	 (bless
	  `(define ,?who
	     (make-traced-procedure ',?who
				    (lambda (,@?formal* . ,?rest-formal)
				      ,?body . ,?body*))))))

      ((_ ?who ?expr)
       (if (identifier? ?who)
	   (bless `(define ,?who
		     (let ((v ,?expr))
		       (if (procedure? v)
			   (make-traced-procedure ',?who v)
			 v))))
	 (syntax-violation __who__ "invalid name" expr-stx)))
      )))

(define (trace-define-syntax-macro expr-stx)
  ;;Transformer  function used  to  expand Vicare's  TRACE-DEFINE-SYNTAX
  ;;macros from the top-level built in environment.  Expand the contents
  ;;of EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (with-who trace-define-syntax
    (syntax-match expr-stx ()
      ((_ ?who ?expr)
       (if (identifier? ?who)
	   (bless
	    `(define-syntax ,?who
	       (make-traced-macro ',?who ,?expr)))
	 (syntax-violation __who__ "invalid name" expr-stx)))
      )))


;;;; non-core macro: TRACE-LET-SYNTAX, TRACE-LETREC-SYNTAX

(module (trace-let-syntax-macro
	 trace-letrec-syntax-macro)

  (define (%trace-let/rec-syntax who)
    (lambda (stx)
      (syntax-match stx ()
	((_ ((?lhs* ?rhs*) ...) ?body ?body* ...)
	 (if (valid-bound-ids? ?lhs*)
	     (let ((rhs* (map (lambda (lhs rhs)
				`(make-traced-macro ',lhs ,rhs))
			   ?lhs* ?rhs*)))
	       (bless
		`(,who ,(map list ?lhs* rhs*)
		       ,?body . ,?body*)))
	   (error-invalid-formals-syntax stx ?lhs*)))
	)))

  (define trace-let-syntax-macro
    ;;Transformer  function  used  to expand  Vicare's  TRACE-LET-SYNTAX
    ;;macros  from  the  top-level  built in  environment.   Expand  the
    ;;contents of EXPR-STX; return a  syntax object that must be further
    ;;expanded.
    ;;
    (%trace-let/rec-syntax 'let-syntax))

  (define trace-letrec-syntax-macro
    ;;Transformer function  used to expand  Vicare's TRACE-LETREC-SYNTAX
    ;;macros  from  the  top-level  built in  environment.   Expand  the
    ;;contents of EXPR-STX; return a  syntax object that must be further
    ;;expanded.
    ;;
    (%trace-let/rec-syntax 'letrec-syntax))

  #| end of module |# )


;;;; non-core macro: GUARD
;;
;;Vicare's implementation of the GUARD syntax  is really sophisticated because it has
;;to  deal with  both the  dynamic environment  requirements of  R6RS and  the unwind
;;protection mechanism defined  by Vicare.  For a through explanation  we should read
;;the documentation  in Texinfo  format, both  the one of  GUARD and  the one  of the
;;unwind protection mechanism.
;;
;;
;;About the dynamic environment
;;-----------------------------
;;
;;In a syntax use like:
;;
;;   (guard (E (?test0 ?expr0)
;;             (?test1 ?expr1)
;;             (else   ?expr2))
;;     ?body0 ?body ...)
;;
;;if the  ?BODY raises an  exception: one of the  clauses will certainly  be executed
;;because there is  an ELSE clause.  The ?BODY might  mutate the dynamic environment;
;;all the ?TEST and ?EXPR expressions must be evaluated in the dynamic environment of
;;the use of GUARD.
;;
;;In a syntax use like:
;;
;;   (guard (E (?test0 ?expr0)
;;             (?test1 ?expr1))
;;     ?body0 ?body ...)
;;
;;if all  the ?TEST  expressions evaluate  to false: we  must re-raise  the exception
;;using RAISE-CONTINUABLE; so the syntax is "almost" equivalent to:
;;
;;   (guard (E (?test0 ?expr0)
;;             (?test1 ?expr1)
;;             (else   (raise-continuable E)))
;;     ?body0 ?body ...)
;;
;;but:  ?BODY  might  mutate  the  dynamic  environment;  all  the  ?TEST  and  ?EXPR
;;expressions must be evaluated  in the dynamic environment of the  use of GUARD; the
;;RAISE-CONTINUABLE in the  ELSE clause must be evaluated the  dynamic environment of
;;the ?BODY.
;;
;;We must remember that, when using:
;;
;;   (with-exception-handler ?handler ?thunk)
;;
;;the ?HANDLER procedure is evaluated in the dynamic environment of the ?THUNK, minus
;;the exception  handler itself.  So, in  pseudo-code, a syntax use  with ELSE clause
;;must be expanded as follows:
;;
;;   (guard (E (?test0 ?expr0)
;;             (?test1 ?expr1)
;;             (else   ?expr2))
;;     ?body0 ?body ...)
;;   ==> (save-guard-continuation
;;        (with-exception-handler
;;            (lambda (E)
;;              (reinstate-guard-continuation
;;               (cond (?test0 ?expr0)
;;                     (?test1 ?expr1)
;;                     (else   ?expr2))))
;;          (lambda () ?body0 ?body ...)))
;;
;;and, also  in pseudo-code,  a syntax use  without ELSE clause  must be  expanded as
;;follows:
;;
;;   (guard (E (?test0 ?expr0)
;;             (?test1 ?expr1))
;;     ?body0 ?body ...)
;;   ==> (save-guard-continuation
;;        (with-exception-handler
;;            (lambda (E)
;;              (save-exception-handler-continuation
;;               (reinstate-guard-continuation
;;                (cond (?test0 ?expr0)
;;                      (?test1 ?expr1)
;;                      (else   (reinstate-exception-handler-continuation
;;                               (raise-continuable E)))))))
;;          (lambda () ?body0 ?body ...)))
;;
;;notice  how, in  the exception  handler, we  have to  jump out  and in  the dynamic
;;environment of the exception handler itself.
;;
;;
;;About the unwind-protection mechanism
;;-------------------------------------
;;
;;There is some serious shit going on here to support the unwind-protection mechanism
;;as  defined by  Vicare; let's  focus  on unwind-proteciton  in the  case of  raised
;;exception.  When using:
;;
;;   (with-unwind-protection ?cleanup ?thunk)
;;
;;the ?CLEANUP is  associated to the dynamic  extent of the call to  ?THUNK: when the
;;dynamic extent is terminated (as defined by Vicare) the ?CLEANUP is called.  If the
;;value  RUN-UNWIND-PROTECTION-CLEANUP-UPON-EXIT?   is set  to  true  and the  dynamic
;;extent of a call  to ?THUNK is exited: the dynamic  extent is considered terminated
;;and ?CLEANUP is called.
;;
;;Vicare defines as termination  event of a GUARD's ?body the  execution of a GUARD's
;;clause that does not re-raise the exception.  For a GUARD use like:
;;
;;   (guard (E (?test0 ?expr0)
;;             (?test1 ?expr1)
;;             (else   ?expr2))
;;     ?body0 ?body ...)
;;
;;we can imagine the pseudo-code:
;;
;;   (guard (E (?test0 (run-unwind-protection-cleanups) ?expr0)
;;             (?test1 (run-unwind-protection-cleanups) ?expr1)
;;             (else   (run-unwind-protection-cleanups) ?expr2))
;;     ?body0 ?body ...)
;;
;;and for a GUARD use like:
;;
;;   (guard (E (?test0 ?expr0)
;;             (?test1 ?expr1))
;;     ?body0 ?body ...)
;;
;;we can imagine the pseudo-code:
;;
;;   (guard (E (?test0 (run-unwind-protection-cleanups) ?expr0)
;;             (?test1 (run-unwind-protection-cleanups) ?expr1)
;;             (else   (raise-continuable E)))
;;     ?body0 ?body ...)
;;
;;By doing  things this  way: an  exception raised by  an ?EXPR  does not  impede the
;;execution of the cleanups.  If a ?TEST raises an exception the cleanups will not be
;;run, and there is  nothing we can do about it; ?TEST  expressions are usually calls
;;to predicates  that recognise  the condition  type of E,  so the  risk of  error is
;;reduced.
;;
;;So, in pseudo-code, a syntax use with ELSE clause must be expanded as follows:
;;
;;   (guard (E (?test0 ?expr0)
;;             (?test1 ?expr1)
;;             (else   ?expr2))
;;     ?body0 ?body ...)
;;   ==> (save-guard-continuation
;;        (with-exception-handler
;;            (lambda (E)
;;              (reinstate-guard-continuation
;;               (cond (?test0 (run-unwind-protection-cleanups) ?expr0)
;;                     (?test1 (run-unwind-protection-cleanups) ?expr1)
;;                     (else   (run-unwind-protection-cleanups) ?expr2))))
;;          (lambda () ?body0 ?body ...)))
;;
;;and, also  in pseudo-code,  a syntax use  without ELSE clause  must be  expanded as
;;follows:
;;
;;   (guard (E (?test0 ?expr0)
;;             (?test1 ?expr1))
;;     ?body0 ?body ...)
;;   ==> (save-guard-continuation
;;        (with-exception-handler
;;            (lambda (E)
;;              (save-exception-handler-continuation
;;               (reinstate-guard-continuation
;;                (cond (?test0 (run-unwind-protection-cleanups) ?expr0)
;;                      (?test1 (run-unwind-protection-cleanups) ?expr1)
;;                      (else   (reinstate-exception-handler-continuation
;;                               (raise-continuable E)))))))
;;          (lambda () ?body0 ?body ...)))
;;
;;But how is RUN-UNWIND-PROTECTION-CLEANUPS implemented?  To cause the cleanups to be
;;called we must set to  true the value RUN-UNWIND-PROTECTION-CLEANUP-UPON-EXIT?, then
;;cause  an  exit  from  the  dynamic  extent  of  the  ?THUNKs.   The  latter  is  a
;;sophisticated operation implemented as follows:
;;
;;   (define (run-unwind-protection-cleanups)
;;     (run-unwind-protection-cleanup-upon-exit? #t)
;;     (save-clause-expression-continuation
;;      (reinstate-exception-handler-continuation
;;       (reinstate-clause-expression-continuation))))
;;
;;we jump in GUARD's exception handler  dynamic environment then immediately jump out
;;in the GUARD's clause expression dynamic environment.  Fucking weird...
;;
;;
;;Expansion example: GUARD with no ELSE clause
;;--------------------------------------------
;;
;;A syntax without else clause like looks like this:
;;
;;   (guard (E
;;           (?test0 ?expr0)
;;           (?test1 ?expr1)))
;;     ?body0 ?body ...)
;;
;;is expanded to:
;;
;;   ((call/cc
;;        (lambda (reinstate-guard-continuation)
;;          (lambda ()
;;            (with-exception-handler
;;                (lambda (raised-obj)
;;                  (let ((E raised-obj))
;;                    ((call/cc
;;                         (lambda (reinstate-exception-handler-continuation)
;;                           (reinstate-guard-continuation
;;                            (lambda ()
;;                              (define (run-unwind-protect-cleanups)
;;                                (run-unwind-protection-cleanup-upon-exit? 'exception)
;;                                (call/cc
;;                                    (lambda (reinstate-clause-expression-continuation)
;;                                      (reinstate-exception-handler-continuation
;;                                       (lambda ()
;;                                         (reinstate-clause-expression-continuation)))))
;;                                (run-unwind-protection-cleanup-upon-exit? #f))
;;                              (if ?test0
;;                                  (begin
;;                                    (run-unwind-protect-cleanups)
;;                                    ?expr0)
;;                                (if ?test1
;;                                    (begin
;;                                      (run-unwind-protect-cleanups)
;;                                      ?expr1)
;;                                  (reinstate-exception-handler-continuation
;;                                   (lambda ()
;;                                     (raise-continuable raised-obj))))))))))))
;;              (lambda ()
;;                ?body0 ?body ...))))))
;;
(module (guard-macro)

  (define-module-who guard)

  (define (guard-macro x)
    ;;Transformer function used to expand R6RS  GUARD macros from the top-level built
    ;;in environment.  Expand  the contents of EXPR-STX; return a  syntax object that
    ;;must be further expanded.
    ;;
    (syntax-match x ()
      ((_ (?variable ?clause* ...) ?body ?body* ...)
       (identifier? ?variable)
       (let ((reinstate-guard-continuation-id  (gensym "reinstate-guard-continuation-id"))
	     (raised-obj-id                    (gensym "raised-obj")))
	 (bless
	  `((call/cc
		(lambda (,reinstate-guard-continuation-id)
		  (lambda ()
		    (with-exception-handler
			(lambda (,raised-obj-id)
			  ;;If we  raise an exception from  a DYNAMIC-WIND's in-guard
			  ;;or out-guard while trying to  call the cleanups: we reset
			  ;;it to avoid leaving it true.
			  (run-unwind-protection-cleanup-upon-exit? #f)
			  (let ((,?variable ,raised-obj-id))
			    ,(gen-clauses raised-obj-id reinstate-guard-continuation-id ?clause*)))
		      (lambda ()
			,?body . ,?body*)))))))))
      ))

  (module (gen-clauses)

    (define (gen-clauses raised-obj-id reinstate-guard-continuation-id clause*)
      (define run-unwind-protect-cleanups-id               (gensym "run-unwind-protect-cleanups"))
      (define reinstate-clause-expression-continuation-id  (gensym "reinstate-clause-expression-continuation"))
      (receive (code-stx reinstate-exception-handler-continuation-id)
	  (%process-multi-cond-clauses raised-obj-id clause* run-unwind-protect-cleanups-id)
	`((call/cc
	      (lambda (,reinstate-exception-handler-continuation-id)
		(,reinstate-guard-continuation-id
		 (lambda ()
		   (define (,run-unwind-protect-cleanups-id)
		     ;;If we are  here: a test in the clauses  returned non-false and
		     ;;the execution  flow is at  the beginning of  the corresponding
		     ;;clause expression.
		     ;;
		     ;;Reinstate the  continuation of  the guard's  exception handler
		     ;;and then immediately reinstate this continuation.  This causes
		     ;;the  dynamic  environment  of  the  exception  handler  to  be
		     ;;reinstated, and the unwind-protection cleanups are called.
		     ;;
		     ;;Yes,  we  must   really  set  the  parameter   to  the  symbol
		     ;;"exception"; this  symbol is used  as argument for  the unwind
		     ;;handlers.
		     (run-unwind-protection-cleanup-upon-exit? 'exception)
		     (call/cc
			 (lambda (,reinstate-clause-expression-continuation-id)
			   (,reinstate-exception-handler-continuation-id
			    (lambda ()
			      (,reinstate-clause-expression-continuation-id)))))
		     (run-unwind-protection-cleanup-upon-exit? #f))
		   ,code-stx)))))))

    (define (%process-multi-cond-clauses raised-obj-id clause* run-unwind-protect-cleanups-id)
      (syntax-match clause* (else)
	;;There is  no ELSE clause: insert  code that reinstates the  continuation of
	;;the exception handler introduced by GUARD and re-raises the exception.
	(()
	 (let ((reinstate-exception-handler-continuation-id (gensym "reinstate-exception-handler-continuation")))
	   (values `(,reinstate-exception-handler-continuation-id
		     (lambda ()
		       (raise-continuable ,raised-obj-id)))
		   reinstate-exception-handler-continuation-id)))

	;;There is  an ELSE  clause: no need  to jump back  to the  exception handler
	;;introduced by GUARD.
	(((else ?else-body ?else-body* ...))
	 (let ((reinstate-exception-handler-continuation-id (gensym "reinstate-exception-handler-continuation")))
	   (values `(begin
		      (,run-unwind-protect-cleanups-id)
		      ,?else-body . ,?else-body*)
		   reinstate-exception-handler-continuation-id)))

	((?clause . ?clause*)
	 (receive (code-stx reinstate-exception-handler-continuation-id)
	     (%process-multi-cond-clauses raised-obj-id ?clause* run-unwind-protect-cleanups-id)
	   (values (%process-single-cond-clause ?clause code-stx run-unwind-protect-cleanups-id)
		   reinstate-exception-handler-continuation-id)))

	(others
	 (syntax-violation __module_who__ "invalid guard clause" others))))

    (define (%process-single-cond-clause clause kont-code-stx run-unwind-protect-cleanups-id)
      (syntax-match clause (=>)
	((?test => ?proc)
	 (let ((t (gensym)))
	   `(let ((,t ,?test))
	      (if ,t
		  (begin
		    (,run-unwind-protect-cleanups-id)
		    (,?proc ,t))
		,kont-code-stx))))

	((?test)
	 (let ((t (gensym)))
	   `(let ((,t ,?test))
	      (if ,t
		  (begin
		    (,run-unwind-protect-cleanups-id)
		    ,t)
		,kont-code-stx))))

	((?test ?expr ?expr* ...)
	 `(if ,?test
	      (begin
		(,run-unwind-protect-cleanups-id)
		,?expr . ,?expr*)
	    ,kont-code-stx))

	(_
	 (syntax-violation __module_who__ "invalid guard clause" clause))))

    #| end of module: GEN-CLAUSES |# )

  #| end of module: GUARD-MACRO |# )

;;; --------------------------------------------------------------------

;;NOTE The  one below is  the old  GUARD implementation.  It  worked fine but  had no
;;integration  with  the  unwind-protection  mechanism.   I am  keeping  it  here  as
;;reference.  Sue me.  (Marco Maggi; Mon Feb 2, 2015)
;;
(commented-out
 (module (guard-macro)

   (define (guard-macro x)
     ;;Transformer function used to expand R6RS GUARD macros from the top-level built
     ;;in environment.  Expand the contents of  EXPR-STX; return a syntax object that
     ;;must be further expanded.
     ;;
     ;;NOTE If we need to reraise the continuation because no GUARD clause handles it
     ;;(and  there is  no  ELSE clause):  we  must  reraise it  in  the same  dynamic
     ;;environment  of the  ?BODY  minus  the exception  handler  installed by  GUARD
     ;;itself.  So,  to reraise the exception,  GUARD must jump back  in reevaluating
     ;;the in-guards of the DYNAMIC-WINDs.
     ;;
     ;;A syntax without else clause like:
     ;;
     ;;   (guard (E
     ;;           (?test0 ?expr0)
     ;;           (?test1 ?expr1)))
     ;;     ?body0 ?body ...)
     ;;
     ;;is expanded to:
     ;;
     ;;   ((call/cc
     ;;        (lambda (outerk)
     ;;          (lambda ()
     ;;            (with-exception-handler
     ;;                (lambda (raised-obj)
     ;;                  (let ((E raised-obj))
     ;;                    ((call/cc
     ;;                         (lambda (return-to-exception-handler-k)
     ;;                           (outerk (lambda ()
     ;;                                     (if ?test0
     ;;                                         ?expr0
     ;;                                       (if ?test1
     ;;                                           ?expr1
     ;;                                         (return-to-exception-handler-k
     ;;                                           (lambda ()
     ;;                                             (raise-continuable raised-obj))))))))))))
     ;;              (lambda ()
     ;;                ?body0 ?body ...))))))
     ;;
     (syntax-match x ()
       ((_ (?variable ?clause* ...) ?body ?body* ...)
	(identifier? ?variable)
	(let ((outerk-id     (gensym))
	      (raised-obj-id (gensym)))
	  (bless
	   `((call/cc
		 (lambda (,outerk-id)
		   (lambda ()
		     (with-exception-handler
			 (lambda (,raised-obj-id)
			   (let ((,?variable ,raised-obj-id))
			     ,(gen-clauses raised-obj-id outerk-id ?clause*)))
		       (lambda ()
			 ,?body . ,?body*))))))
	   )))
       ))

   (define (gen-clauses raised-obj-id outerk-id clause*)

     (define (%process-single-cond-clause clause kont-code-stx)
       (syntax-match clause (=>)
	 ((?test => ?proc)
	  (let ((t (gensym)))
	    `(let ((,t ,?test))
	       (if ,t
		   (,?proc ,t)
		 ,kont-code-stx))))

	 ((?test)
	  (let ((t (gensym)))
	    `(let ((,t ,?test))
	       (if ,t ,t ,kont-code-stx))))

	 ((?test ?expr ?expr* ...)
	  `(if ,?test
	       (begin ,?expr . ,?expr*)
	     ,kont-code-stx))

	 (_
	  (syntax-violation __module_who__ "invalid guard clause" clause))))

     (define (%process-multi-cond-clauses clause*)
       (syntax-match clause* (else)
	 ;;There is no ELSE clause: introduce the raise continuation that
	 ;;rethrows the exception.
	 (()
	  (let ((return-to-exception-handler-k (gensym)))
	    (values `(,return-to-exception-handler-k
		      (lambda ()
			(raise-continuable ,raised-obj-id)))
		    return-to-exception-handler-k)))

	 ;;There  is an  ELSE  clause:  no need  to  introduce the  raise
	 ;;continuation.
	 (((else ?else-body ?else-body* ...))
	  (values `(begin ,?else-body . ,?else-body*)
		  #f))

	 ((?clause . ?clause*)
	  (receive (code-stx return-to-exception-handler-k)
	      (%process-multi-cond-clauses ?clause*)
	    (values (%process-single-cond-clause ?clause code-stx)
		    return-to-exception-handler-k)))

	 (others
	  (syntax-violation __module_who__ "invalid guard clause" others))))

     (receive (code-stx return-to-exception-handler-k)
	 (%process-multi-cond-clauses clause*)
       (if return-to-exception-handler-k
	   `((call/cc
		 (lambda (,return-to-exception-handler-k)
		   (,outerk-id (lambda () ,code-stx)))))
	 `(,outerk-id (lambda () ,code-stx)))))

   #| end of module: GUARD-MACRO |# ))


;;;; non-core macro: DEFINE-ENUMERATION

(define (define-enumeration-macro stx)
  ;;Transformer function  used to expand R6RS  DEFINE-ENUMERATION macros
  ;;from the  top-level built  in environment.   Expand the  contents of
  ;;EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (define-constant __who__ 'define-enumeration)
  (define (set? x)
    (or (null? x)
	(and (not (memq (car x) (cdr x)))
	     (set? (cdr x)))))
  (define (remove-dups ls)
    (if (null? ls)
	'()
      (cons (car ls)
	    (remove-dups (remq (car ls) (cdr ls))))))
  (syntax-match stx ()
    ((_ ?name (?id* ...) ?maker)
     (begin
       (unless (identifier? ?name)
	 (syntax-violation __who__
	   "expected identifier as enumeration type name" stx ?name))
       (unless (for-all identifier? ?id*)
	 (syntax-violation __who__
	   "expected list of symbols as enumeration elements" stx ?id*))
       (unless (identifier? ?maker)
	 (syntax-violation __who__
	   "expected identifier as enumeration constructor syntax name" stx ?maker))
       (let ((symbol*		(remove-dups (syntax->datum ?id*)))
	     (the-constructor	(gensym)))
	 (bless
	  `(begin
	     (define ,the-constructor
	       (enum-set-constructor (make-enumeration ',symbol*)))

	     (define-syntax ,?name
	       ;;Check at macro-expansion time whether the symbol ?ARG
	       ;;is in  the universe associated with ?NAME.   If it is,
	       ;;the result  of the  expansion is equivalent  to ?ARG.
	       ;;It is a syntax violation if it is not.
	       ;;
	       (lambda (x)
		 (define universe-of-symbols ',symbol*)
		 (define (%synner message subform)
		   (syntax-violation ',?name message
				     (syntax->datum x) (syntax->datum subform)))
		 (syntax-case x ()
		   ((_ ?arg)
		    (not (identifier? (syntax ?arg)))
		    (%synner "expected symbol as argument to enumeration validator"
			     (syntax ?arg)))

		   ((_ ?arg)
		    (not (memq (syntax->datum (syntax ?arg)) universe-of-symbols))
		    (%synner "expected symbol in enumeration as argument to enumeration validator"
			     (syntax ?arg)))

		   ((_ ?arg)
		    (syntax (quote ?arg)))

		   (_
		    (%synner "invalid enumeration validator form" #f)))))

	     (define-syntax ,?maker
	       ;;Given  any  finite sequence  of  the  symbols in  the
	       ;;universe, possibly  with duplicates, expands  into an
	       ;;expression that  evaluates to the  enumeration set of
	       ;;those symbols.
	       ;;
	       ;;Check  at  macro-expansion  time  whether  every  input
	       ;;symbol is in the universe  associated with ?NAME; it is
	       ;;a syntax violation if one or more is not.
	       ;;
	       (lambda (x)
		 (define universe-of-symbols ',symbol*)
		 (define (%synner message subform-stx)
		   (syntax-violation ',?maker
		     message
		     (syntax->datum x) (syntax->datum subform-stx)))
		 (syntax-case x ()
		   ((_ . ?list-of-symbols)
		    ;;Check the input  symbols one by one partitioning
		    ;;the ones in the universe from the one not in the
		    ;;universe.
		    ;;
		    ;;If  an input element  is not  a symbol:  raise a
		    ;;syntax violation.
		    ;;
		    ;;After   all   the   input  symbols   have   been
		    ;;partitioned,  if the  list of  collected INvalid
		    ;;ones is not null:  raise a syntax violation with
		    ;;that list as  subform, else return syntax object
		    ;;expression   building  a  new   enumeration  set
		    ;;holding the list of valid symbols.
		    ;;
		    (let loop ((valid-symbols-stx	'())
			       (invalid-symbols-stx	'())
			       (input-symbols-stx	(syntax ?list-of-symbols)))
		      (syntax-case input-symbols-stx ()

			;;No more symbols to collect and non-null list
			;;of collected INvalid symbols.
			(()
			 (not (null? invalid-symbols-stx))
			 (%synner "expected symbols in enumeration as arguments \
                                     to enumeration constructor syntax"
				  (reverse invalid-symbols-stx)))

			;;No more symbols to  collect and null list of
			;;collected INvalid symbols.
			(()
			 (quasisyntax
			  (,the-constructor '(unsyntax (reverse valid-symbols-stx)))))

			;;Error if element is not a symbol.
			((?symbol0 . ?rest)
			 (not (identifier? (syntax ?symbol0)))
			 (%synner "expected symbols as arguments to enumeration constructor syntax"
				  (syntax ?symbol0)))

			;;Collect a symbol in the set.
			((?symbol0 . ?rest)
			 (memq (syntax->datum (syntax ?symbol0)) universe-of-symbols)
			 (loop (cons (syntax ?symbol0) valid-symbols-stx)
			       invalid-symbols-stx (syntax ?rest)))

			;;Collect a symbol not in the set.
			((?symbol0 . ?rest)
			 (loop valid-symbols-stx
			       (cons (syntax ?symbol0) invalid-symbols-stx)
			       (syntax ?rest)))

			))))))
	     )))))
    ))


;;;; non-core macro: DO, DO*, WHILE, UNTIL, FOR

(define (with-escape-fluids escape next-iteration body*)
  ;;NOTE We  define BREAK  as accepting  any number of  arguments and  returning zero
  ;;values  when given  zero arguments.   Returning  zero values  can be  meaningful,
  ;;example:
  ;;
  ;;   (receive args
  ;;       (values)
  ;;     args)
  ;;   => ()
  ;;
  ;;so we  do not want  force "(break)"  to return a  single value like  #<void> just
  ;;because it  is faster to  return one value rather  than return 0  values.  (Marco
  ;;Maggi; Sat Jan 31, 2015)
  ;;
  `(fluid-let-syntax
       ((break    (syntax-rules ()
		    ((_ . ?args)
		     (,escape . ?args))
		    ))
	(continue (syntax-rules ()
		    ((_)
		     (,next-iteration #t)))))
     . ,body*))

;;; --------------------------------------------------------------------

(define (do-macro expr-stx)
  ;;Transformer function  used to expand R6RS  DO macros from the  top-level built in
  ;;environment;  we also  support extended  Vicare syntax.   Expand the  contents of
  ;;EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (with-who 'do
    (define (%normalise-binding binding-stx)
      (syntax-match binding-stx ()
	((?var ?init)
	 (receive (id tag)
	     (parse-tagged-identifier-syntax ?var)
	   `(,?var ,?init ,id)))
	((?var ?init ?step)
	 `(,?var ,?init ,?step))
	(_
	 (syntax-violation __who__ "invalid binding" expr-stx))))
    (syntax-match expr-stx (while until)

      ;;This is an extended Vicare syntax.
      ;;
      ;;NOTE We want an implementation in which:  when BREAK and CONTINUE are not used,
      ;;the escape functions are never referenced, so the compiler can remove CALL/CC.
      ;;
      ;;NOTE Using CONTINUE in the body causes a jump to the test.
      ((_ ?body (while ?test))
       (let ((escape         (gensym "escape"))
	     (next-iteration (gensym "next-iteration")))
	 (bless
	  `(unwinding-call/cc
	       (lambda (,escape)
		 (let loop ()
		   (unwinding-call/cc
		       (lambda (,next-iteration)
			 ,(with-escape-fluids escape next-iteration (list ?body))))
		   (when ,?test
		     (loop))))))))

      ;;This is an extended Vicare syntax.
      ;;
      ;;NOTE We want an implementation in which:  when BREAK and CONTINUE are not used,
      ;;the escape functions are never referenced, so the compiler can remove CALL/CC.
      ;;
      ;;NOTE Using CONTINUE in the body causes a jump to the test.
      ((_ ?body (until ?test))
       (let ((escape         (gensym "escape"))
	     (next-iteration (gensym "next-iteration")))
	 (bless
	  `(unwinding-call/cc
	       (lambda (,escape)
		 (let loop ()
		   (unwinding-call/cc
		       (lambda (,next-iteration)
			 ,(with-escape-fluids escape next-iteration (list ?body))))
		   (until ,?test
		     (loop))))))))

      ;;This is the R6RS syntax.
      ;;
      ;;NOTE We want an implementation in which:  when BREAK and CONTINUE are not used,
      ;;the escape functions are never referenced, so the compiler can remove CALL/CC.
      ((_ (?binding* ...)
	  (?test ?expr* ...)
	  ?command* ...)
       (syntax-match (map %normalise-binding ?binding*) ()
	 (((?var* ?init* ?step*) ...)
	  (let ((escape         (gensym "escape"))
		(next-iteration (gensym "next-iteration")))
	    (bless
	     `(unwinding-call/cc
		  (lambda (,escape)
		    (letrec ((loop (lambda ,?var*
				     (if (unwinding-call/cc
					     (lambda (,next-iteration)
					       (if ,?test
						   #f
						 ,(with-escape-fluids escape next-iteration `(,@?command* #t)))))
					 (loop . ,?step*)
				       ,(if (null? ?expr*)
					    '(void)
					  `(begin . ,?expr*))))))
		      (loop . ,?init*)))))))
	 ))
      )))

;;; --------------------------------------------------------------------

(define (do*-macro expr-stx)
  ;;Transformer function used to expand Vicare DO* macros from the top-level built in
  ;;environment;  we also  support extended  Vicare syntax.   Expand the  contents of
  ;;EXPR-STX; return a syntax object that must be further expanded.
  ;;
  ;;This is meant to be similar to the Common Lisp syntax of the same name.
  ;;
  ;;NOTE We want  an implementation in which:  when BREAK and CONTINUE  are not used,
  ;;the escape functions are never referenced, so the compiler can remove CALL/CC.
  ;;
  (with-who 'do*
  (define (%make-init-binding binding-stx)
    (syntax-match binding-stx ()
      ((?var ?init)
       (receive (id tag)
	   (parse-tagged-identifier-syntax ?var)
	 binding-stx))
      ((?var ?init ?step)
       (receive (id tag)
	   (parse-tagged-identifier-syntax ?var)
	 (list ?var ?init)))
      (_
       (syntax-violation __who__ "invalid binding" expr-stx binding-stx))))
  (define (%make-step-update binding-stx knil)
    (syntax-match binding-stx ()
      ((?var ?init)
       knil)
      ((?var ?init ?step)
       (receive (id tag)
	   (parse-tagged-identifier-syntax ?var)
	 (cons `(set! ,id ,?step)
	       knil)))
      (_
       (syntax-violation __who__ "invalid binding" expr-stx binding-stx))))
  (syntax-match expr-stx ()
    ((_ (?binding* ...)
	(?test ?expr* ...)
	?command* ...)
     (let* ((escape         (gensym "escape"))
	    (next-iteration (gensym "next-iteration"))
	    (init-binding*  (map %make-init-binding ?binding*))
	    (step-update*   (fold-right %make-step-update '() ?binding*)))
       (bless
	`(unwinding-call/cc
	     (lambda (,escape)
	       (let* ,init-binding*
		 (letrec ((loop (lambda ()
				  (if (unwinding-call/cc
					  (lambda (,next-iteration)
					    (if ,?test
						#f
					      ,(with-escape-fluids escape next-iteration `(,@?command* #t)))))
				      (begin
					,@step-update*
					(loop))
				    ,(if (null? ?expr*)
					 '(void)
				       `(begin . ,?expr*))))))
		   (loop))))))))
    )))

;;; --------------------------------------------------------------------

(define (dolist-macro expr-stx)
  ;;Transformer function used to expand Vicare DOLIST macros from the top-level built
  ;;in environment; we  also support extended Vicare syntax.  Expand  the contents of
  ;;EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ (?var ?list-form)              ?body0 ?body* ...)
     (bless
      `(dolist (,?var ,?list-form (void))
	 ,?body0 . ,?body*)))
    ((_ (?var ?list-form ?result-form) ?body0 ?body* ...)
     (let ((ell  (gensym "ell"))
	   (loop (gensym "loop")))
       (bless
	`(let ,loop ((,ell ,?list-form))
	      (if (pair? ,ell)
		  (let ((,?var (car ,ell)))
		    ,?body0 ,@?body*
		    (,loop (cdr ,ell)))
		(let ((,?var '()))
		  ,?result-form))))))
    ))

;;; --------------------------------------------------------------------

(define (dotimes-macro expr-stx)
  ;;Transformer  function used  to expand  Vicare DOTIMES  macros from  the top-level
  ;;built  in  environment; we  also  support  extended  Vicare syntax.   Expand  the
  ;;contents of EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ (?var ?count-form)              ?body0 ?body* ...)
     (let ((max-var (gensym)))
       (bless
	`(let ((,max-var ,?count-form))
	   (do ((,?var 0 (add1 ,?var)))
	       ((>= ,?var ,max-var))
	     ,?body0 . ,?body*)))))
    ((_ (?var ?count-form ?result-form) ?body0 ?body* ...)
     (let ((max-var (gensym)))
       (bless
	`(let ((,max-var ,?count-form))
	   (do ((,?var 0 (add1 ,?var)))
	       ((>= ,?var ,max-var)
		,?result-form)
	     ,?body0 . ,?body*)))))
    ))

;;; --------------------------------------------------------------------

(define (while-macro expr-stx)
  ;;Transformer  function used  to expand  Vicare's WHILE  macros from  the top-level
  ;;built in  environment.  Expand the contents  of EXPR-STX; return a  syntax object
  ;;that must be further expanded.
  ;;
  ;;NOTE We want  an implementation in which:  when BREAK and CONTINUE  are not used,
  ;;the escape functions are never referenced, so the compiler can remove CALL/CC.
  ;;
  (syntax-match expr-stx ()
    ((_ ?test ?body* ...)
     (let ((escape         (gensym "escape"))
	   (next-iteration (gensym "next-iteration")))
       (bless
	`(unwinding-call/cc
	     (lambda (,escape)
	       (let loop ()
		 (when (unwinding-call/cc
			   (lambda (,next-iteration)
			     (if ,?test
				 ,(with-escape-fluids escape next-iteration `(,@?body* #t))
			       #f)))
		   (loop))))))))
    ))

(define (until-macro expr-stx)
  ;;Transformer  function used  to expand  Vicare's UNTIL  macros from  the top-level
  ;;built in  environment.  Expand the contents  of EXPR-STX; return a  syntax object
  ;;that must be further expanded.
  ;;
  ;;NOTE We want  an implementation in which:  when BREAK and CONTINUE  are not used,
  ;;the escape functions are never referenced, so the compiler can remove CALL/CC.
  ;;
  (syntax-match expr-stx ()
    ((_ ?test ?body* ...)
     (let ((escape         (gensym "escape"))
	   (next-iteration (gensym "next-iteration")))
       (bless
	`(unwinding-call/cc
	     (lambda (,escape)
	       (let loop ()
		 (when (unwinding-call/cc
			   (lambda (,next-iteration)
			     (if ,?test
				 #f
			       ,(with-escape-fluids escape next-iteration `(,@?body* #t)))))
		   (loop))))))))
    ))

(define (for-macro expr-stx)
  ;;Transformer function used to expand Vicare's  FOR macros from the top-level built
  ;;in environment.   Expand the contents  of EXPR-STX;  return a syntax  object that
  ;;must be further expanded.
  ;;
  ;;NOTE We want  an implementation in which:  when BREAK and CONTINUE  are not used,
  ;;the escape functions are never referenced, so the compiler can remove CALL/CC.
  ;;
  ;;NOTE The CONTINUE must skip the rest of the body and jump to the increment.
  ;;
  (syntax-match expr-stx ()
    ((_ (?init ?test ?incr) ?body* ...)
     (let ((escape         (gensym "escape"))
	   (next-iteration (gensym "next-iteration")))
       (bless
	`(unwinding-call/cc
	     (lambda (,escape)
	       ,?init
	       (let loop ()
		 (when (unwinding-call/cc
			   (lambda (,next-iteration)
			     (if ,?test
				 ,(with-escape-fluids escape next-iteration `(,@?body* #t))
			       #f)))
		   ,?incr
		   (loop))))))))
    ))


;;;; non-core macro: RETURNABLE

(define (returnable-macro expr-stx)
  ;;Transformer function used to expand Vicare's RETURNABLE macros from the top-level
  ;;built in  environment.  Expand the contents  of EXPR-STX; return a  syntax object
  ;;that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ ?body0 ?body* ...)
     (let ((escape (gensym "escape")))
       (bless
	`(unwinding-call/cc
	     (lambda (,escape)
	       (fluid-let-syntax ((return (syntax-rules ()
					    ((_ . ?args)
					     (,escape . ?args)))))
		 ,?body0 . ,?body*))))))
    ))


;;;; non-core macro: TRY

(module (try-macro)
  (define-constant __who__ 'try)

  (define (try-macro expr-stx)
    ;;Transformer  function  used  to  expand Vicare's  TRY  ...   CATCH
    ;;...  FINALLY  macros  from  the top-level  built  in  environment.
    ;;Expand the contents of EXPR-STX;  return a syntax object that must
    ;;be further expanded.
    ;;
    (syntax-match expr-stx (catch finally)
      ;;Full syntax.
      ((_ ?body (catch ?var ?catch-clause0 ?catch-clause* ...) (finally ?finally-body0 ?finally-body* ...))
       (begin
	 (validate-variable expr-stx ?var)
	 (let ((GUARD-CLAUSE* (parse-multiple-catch-clauses expr-stx ?var (cons ?catch-clause0 ?catch-clause*)))
	       (why           (gensym)))
	   (bless
	    `(with-unwind-protection
		 (lambda (,why)
		   ,?finally-body0 . ,?finally-body*)
	       (lambda ()
		 (guard (,?var . ,GUARD-CLAUSE*)
		   ,?body)))))))

      ;;Only catch, no finally.
      ((_ ?body (catch ?var ?catch-clause0 ?catch-clause* ...))
       (begin
	 (validate-variable expr-stx ?var)
	 (let ((GUARD-CLAUSE* (parse-multiple-catch-clauses expr-stx ?var (cons ?catch-clause0 ?catch-clause*))))
	   (bless
	    `(guard (,?var . ,GUARD-CLAUSE*) ,?body)))))

      ((_ ?body (finally ?finally-body0 ?finally-body* ...))
       (let ((why (gensym)))
	 (bless
	  `(with-unwind-protection
	       (lambda (,why)
		 ,?finally-body0 . ,?finally-body*)
	     (lambda ()
	       ,?body)))))
      ))

  (define (parse-multiple-catch-clauses expr-stx var-id clauses-stx)
    (syntax-match clauses-stx (else)
      ;;Match when  there is no  ELSE clause.  Remember that  GUARD will
      ;;reraise the exception when there is no ELSE clause.
      (()
       '())

      ;;This branch  with the ELSE  clause must come first!!!   The ELSE
      ;;clause is valid only if it is the last.
      (((else ?else-body0 ?else-body ...))
       clauses-stx)

      (((?pred ?tag-body0 ?tag-body* ...) . ?other-clauses)
       (cons (cons* (syntax-match ?pred ()
		      ((?tag)
		       (identifier? ?tag)
		       `(condition-is-a? ,var-id ,?tag))
		      (_
		       (parse-logic-predicate-syntax ?pred
						     (lambda (tag-id)
						       (syntax-match tag-id ()
							 (?tag
							  (identifier? ?tag)
							  `(condition-is-a? ,var-id ,?tag))
							 (else
							  (syntax-violation __who__
							    "expected identifier as condition type" tag-id)))))))
		    ?tag-body0 ?tag-body*)
	     (parse-multiple-catch-clauses expr-stx var-id ?other-clauses)))

      ((?clause . ?other-clauses)
       (syntax-violation __who__
	 "invalid catch clause in try syntax" expr-stx ?clause))))

  (define (validate-variable expr-stx var-id)
    (unless (identifier? var-id)
      (syntax-violation __who__
	"expected identifier as variable" expr-stx var-id)))

  #| end of module |# )


;;;; non-core macro: WITH-BLOCKED-EXCEPTIONS, WITH-CURRENT-DYNAMIC-ENVIRONMENT

(define (with-blocked-exceptions-macro expr-stx)
  ;;Transformer function used to  expand Vicare's WITH-BLOCKED-EXCEPTIONS macros from
  ;;the top-level  built in environment.  Expand  the contents of EXPR-STX;  return a
  ;;syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ ?exception-retvals-maker ?thunk)
     (bless
      `(call/cc
	   (lambda (reinstate-with-blocked-exceptions-continuation)
	     (with-exception-handler
		 (lambda (E)
		   (call-with-values
		       (lambda ()
			 (,?exception-retvals-maker E))
		     reinstate-with-blocked-exceptions-continuation))
	       ,?thunk)))))
    ((_ ?thunk)
     (bless
      `(call/cc
	   (lambda (reinstate-with-blocked-exceptions-continuation)
	     (with-exception-handler
		 reinstate-with-blocked-exceptions-continuation
	       ,?thunk)))))
    ))

(define (with-current-dynamic-environment-macro expr-stx)
  ;;Transformer  function used  to  expand Vicare's  WITH-CURRENT-DYNAMIC-ENVIRONMENT
  ;;macros from the top-level built in environment.  Expand the contents of EXPR-STX;
  ;;return a syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ ?exception-retvals-maker ?thunk)
     (bless
      `(call/cc
	   (lambda (return-thunk-with-packed-environment)
	     ((call/cc
		  (lambda (reinstate-target-environment-continuation)
		    (return-thunk-with-packed-environment
		     (lambda ()
		       (call/cc
			   (lambda (reinstate-thunk-call-continuation)
			     (reinstate-target-environment-continuation
			      (lambda ()
				(call-with-values
				    (lambda ()
				      (with-blocked-exceptions
					  ,?exception-retvals-maker
					,?thunk))
				  reinstate-thunk-call-continuation))))))))))))))
    ))


;;;; non-core macro: OR, AND

(define (or-macro expr-stx)
  ;;Transformer function  used to expand R6RS  OR macros from the  top-level built in
  ;;environment.  Expand the  contents of EXPR-STX; return a syntax  object that must
  ;;be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_) #f)

    ((_ ?expr ?expr* ...)
     (bless
      (let recur ((e  ?expr) (e* ?expr*))
	(if (null? e*)
	    e
	  `(let ((t ,e))
	     (if t
		 t
	       ,(recur (car e*) (cdr e*))))))))
    ))

(define (and-macro expr-stx)
  ;;Transformer function used  to expand R6RS AND macros from  the top-level built in
  ;;environment.  Expand the  contents of EXPR-STX; return a syntax  object that must
  ;;be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_) #t)

    ((_ ?expr ?expr* ...)
     (bless
      (let recur ((e ?expr) (e* ?expr*))
	(if (null? e*)
	    e
	  `(if ,e
	       ,(recur (car e*) (cdr e*))
	     #f)))))
    ))


;;;; non-core macro: COND

(define (cond-macro expr-stx)
  ;;Transformer function used to expand R6RS  COND macros from the top-level built in
  ;;environment.  Expand the  contents of EXPR-STX; return a syntax  object that must
  ;;be further expanded.
  ;;
  (with-who 'cond
    (syntax-match expr-stx ()
      ((_ ?cls ?cls* ...)
       (bless
	(let recur ((cls ?cls) (cls* ?cls*))
	  (if (null? cls*)
	      (syntax-match cls (else =>)
		((else ?expr ?expr* ...)
		 `(internal-body ,?expr . ,?expr*))

		((?test => ?proc)
		 `(let ((t ,?test))
		    (if t
			(,?proc t)
		      (void))))

		((?expr)
		 `(or ,?expr (void)))

		((?test ?expr* ...)
		 `(if ,?test
		      (internal-body . ,?expr*)
		    (void)))

		(_
		 (syntax-violation __who__ "invalid last clause" expr-stx cls)))

	    (syntax-match cls (else =>)
	      ((else ?expr ?expr* ...)
	       (syntax-violation __who__ "incorrect position of keyword ELSE" expr-stx cls))

	      ((?test => ?proc)
	       `(let ((t ,?test))
		  (if t
		      (,?proc t)
		    ,(recur (car cls*) (cdr cls*)))))

	      ((?expr)
	       `(or ,?expr
		    ,(recur (car cls*) (cdr cls*))))

	      ((?test ?expr* ...)
	       `(if ,?test
		    (internal-body . ,?expr*)
		  ,(recur (car cls*) (cdr cls*))))

	      (_
	       (syntax-violation __who__ "invalid last clause" expr-stx cls)))))))
      )))


;;;; non-core macro: QUASIQUOTE

(define (quasiquote-macro input-form.stx)
  ;;Transformer function  used to  expand R6RS QUASIQUOTE  macros from  the top-level
  ;;built in  environment.  Expand  the contents of  INPUT-FORM.STX; return  a syntax
  ;;object that must be further expanded.
  ;;
  ;;NOTE We  can test  QUASIQUOTE expansions  by evaluating  at the  REPL expressions
  ;;like:
  ;;
  ;;   (expansion-of '(quasiquote ?pattern))
  ;;
  (define (main input-form.stx)
    (syntax-match input-form.stx (unquote unquote-splicing)

      ;;According to  R6RS: a single-operand UNQUOTE  can appear outside of  list and
      ;;vector templates.  This happens when the input form is:
      ;;
      ;;   (quasiquote (unquote 1))	=> 1
      ;;
      ((_ (unquote ?expr))
       ?expr)

      ((_ (unquote ?expr0 ?expr* ...))
       (synner "invalid multi-operand UNQUOTE form outside list and vector templates"
	       (bless
		`(unquote ,?expr0 . ,?expr*))))

      ((_ (unquote-splicing ?expr* ...))
       (synner "invalid UNQUOTE-SPLICING form outside list and vector templates"
	       (bless
		`(unquote-splicing . ,?expr*))))

      ((_ (?car . ?cdr))
       (%quasi (cons ?car ?cdr) 0))

      ((_ #(?expr* ...))
       (%quasi (list->vector ?expr*) 0))

      ;;This happens when the input form is:
      ;;
      ;;   (quasiquote 1)	=> 1
      ;;
      ((_ ?expr)
       (bless
	`(quote ,?expr)))))

  (define (%quasi stx nesting-level)
    (syntax-match stx (unquote unquote-splicing quasiquote)

      ;;This happens when STX appears in improper tail position:
      ;;
      ;;   (quasiquote (1 . (unquote (+ 2 3)))) => (cons 1 5)
      ;;
      ((unquote ?expr)
       (if (zero? nesting-level)
	   ?expr
	 (%quasicons (make-top-level-syntax-object/quoted-quoting 'unquote)
		     (%quasi (list ?expr) (sub1 nesting-level)))))

      ;;This happens when the input form is:
      ;;
      ;;   (quasiquote (1 . (unquote)))
      ;;
      ((unquote)
       (synner "invalid UNQUOTE form in improper tail position" stx))

      (((unquote ?input-car-subexpr* ...) . ?input-cdr)
       ;;For  coherence  with what  R6RS  specifies  about UNQUOTE:  a  multi-operand
       ;;UNQUOTE must appear only inside a list or vector template.
       ;;
       ;;When the nesting level requires processing of unquoted expressions:
       ;;
       ;;* The expressions ?INPUT-CAR-SUBEXPR must be evaluated at run-time.
       ;;
       ;;* The input syntax object ?INPUT-CDR must be processed to produce the output
       ;;  syntax object ?OUTPUT-TAIL.
       ;;
       ;;* The returned syntax object must represent an expression that, at run-time,
       ;;  will construct the result as:
       ;;
       ;;     (cons* ?input-car-subexpr ... ?output-tail)
       ;;
       (let ((input-car-subexpr*.stx  ?input-car-subexpr*)
	     (output-tail.stx         (%quasi ?input-cdr nesting-level)))
	 (if (zero? nesting-level)
	     (%unquote-splice-cons* input-car-subexpr*.stx output-tail.stx)
	   (%quasicons (%quasicons (make-top-level-syntax-object/quoted-quoting 'unquote)
				   (%quasi input-car-subexpr*.stx (sub1 nesting-level)))
		       output-tail.stx))))

      (((unquote ?input-car-subexpr* ... . ?input-car-tail) . ?input-cdr)
       (synner "invalid improper list as UNQUOTE form"
	       (bless
		`(unquote ,@?input-car-subexpr* . ,?input-car-tail))))

      ;;This happens when the input form is:
      ;;
      ;;   (quasiquote (1 . (unquote-splicing)))
      ;;
      ((unquote-splicing)
       (synner "invalid UNQUOTE-SPLICING form in improper tail position" stx))

      ;;This happens when STX appears in improper tail position:
      ;;
      ;;   (quasiquote (1 . (unquote-splicing (list (+ 2 3))))) => (cons 1 5)
      ;;
      ((unquote-splicing ?expr)
       (if (zero? nesting-level)
	   ?expr
	 (%quasicons (make-top-level-syntax-object/quoted-quoting 'unquote-splicing)
		     (%quasi (list ?expr) (sub1 nesting-level)))))

      ((unquote-splicing ?input-car-subexpr0 ?input-car-subexpr* ...)
       (synner "invalid multi-operand UNQUOTE-SPLICING form in improper tail position" stx))

      (((unquote-splicing ?input-car-subexpr* ...) . ?input-cdr)
       ;;For  coherence   with  what   R6RS  specifies  about   UNQUOTE-SPLICING:  an
       ;;UNQUOTE-SPLICING must appear only inside a list or vector template.
       ;;
       ;;When the nesting level requires processing of unquoted expressions:
       ;;
       ;;* The  subexpressions ?INPUT-CAR-SUBEXPR must  be evaluated at  run-time and
       ;;  their results must be lists:
       ;;
       ;;     ?input-car-subexpr => (?output-car-item ...)
       ;;
       ;;* The input syntax object ?INPUT-CDR must be processed to produce the output
       ;;  syntax object ?OUTPUT-TAIL.
       ;;
       ;;* The returned syntax object must represent an expression that, at run-time,
       ;;  will construct the result as:
       ;;
       ;;     (append ?input-car-subexpr ... ?output-tail)
       ;;
       (let ((input-car-subexpr*.stx  ?input-car-subexpr*)
	     (output-tail.stx         (%quasi ?input-cdr nesting-level)))
	 (if (zero? nesting-level)
	     (%unquote-splice-append input-car-subexpr*.stx output-tail.stx)
	   (%quasicons (%quasicons (make-top-level-syntax-object/quoted-quoting 'unquote-splicing)
				   (%quasi input-car-subexpr*.stx (sub1 nesting-level)))
		       output-tail.stx))))

      (((unquote-splicing ?input-car-subexpr* ... . ?input-car-tail) . ?input-cdr)
       (synner "invalid improper list as UNQUOTE-SPLICING form"
	       (bless
		`(unquote-splicing ,@?input-car-subexpr* . ,?input-car-tail))))

      ((quasiquote ?nested-expr* ...)
       (%quasicons (make-top-level-syntax-object/quoted-quoting 'quasiquote)
		   (%quasi ?nested-expr* (add1 nesting-level))))

      ((?car . ?cdr)
       (%quasicons (%quasi ?car nesting-level)
		   (%quasi ?cdr nesting-level)))

      (#(?item* ...)
       (%quasivector (%vector-quasi ?item* nesting-level)))

      (?atom
       (bless
	`(quote ,?atom)))))

;;; --------------------------------------------------------------------

  (define (%quasicons output-car.stx output-cdr.stx)
    ;;Called to compose the output form resulting from processing:
    ;;
    ;;   (?car . ?cdr)
    ;;
    ;;return  a  syntax  object.   The  argument  OUTPUT-CAR.STX  is  the  result  of
    ;;processing  "(syntax ?car)".   The  argument OUTPUT-CDR.STX  is  the result  of
    ;;processing "(syntax ?cdr)".
    ;;
    (syntax-match output-cdr.stx (foldable-list quote)

      ;;When the result of  processing ?CDR is a quoted or iquoted  datum, we want to
      ;;return one among:
      ;;
      ;;   #'(cons (quote  ?car-input-datum) (quote  ?output-cdr-datum))
      ;;   #'(cons         ?car-input-datum  (quote  ?output-cdr-datum))
      ;;
      ;;and we know that we can simplify:
      ;;
      ;;   #'(cons (quote ?car-input-datum) (quote ()))
      ;;   ===> #'(list (quote ?car-input-datum))
      ;;
      ;;   #'(cons        ?car-input-datum  (quote ()))
      ;;   ===> #'(list ?car-input-datum)
      ;;
      ((quote ?cdr-datum)
       (syntax-match output-car.stx (quote)
	 ((quote ?car-datum)
	  (syntax-match ?cdr-datum ()
	    (()
	     (bless
	      `(foldable-list (quote ,?car-datum))))
	    (_
	     (bless
	      `(foldable-cons (quote ,?car-datum) (quote ,?cdr-datum))))))
	 (_
	  (syntax-match ?cdr-datum ()
	    (()
	     (bless
	      `(foldable-list ,output-car.stx)))
	    (_
	     (bless
	      `(foldable-cons ,output-car.stx (quote ,?cdr-datum))))))
	 ))

      ;;When  the result  of  processing  ?CDR is  a  syntax  object representing  an
      ;;expression that, at run-time, will build an immutable list: prepend the input
      ;;expression as first item of the list.
      ;;
      ((foldable-list ?cdr-expr* ...)
       (bless
	`(foldable-list ,output-car.stx . ,?cdr-expr*)))

      ;;When  the result  of processing  ?CDR is  a syntax  object representing  some
      ;;generic expression: return  a syntax object representing  an expression that,
      ;;at run-time, will build a pair.
      ;;
      (_
       (bless
	`(foldable-cons ,output-car.stx ,output-cdr.stx)))
      ))

  (define (%unquote-splice-cons* input-car-subexpr*.stx output-tail.stx)
    ;;Recursive function.  Called to build  the output form resulting from processing
    ;;the input form:
    ;;
    ;;   ((unquote ?input-car-subexpr ...) . ?input-cdr)
    ;;
    ;;return a syntax object.  At the first application:
    ;;
    ;;* The argument INPUT-CAR-SUBEXPR*.STX is the list of syntax objects:
    ;;
    ;;     ((syntax ?input-car-subexpr) ...)
    ;;
    ;;* The argument OUTPUT-TAIL.STX is the result of processing:
    ;;
    ;;     (syntax ?input-cdr)
    ;;
    ;;The returned  output form must  be a  syntax object representing  an expression
    ;;that, at run-time, constructs the result as:
    ;;
    ;;   (cons* ?input-car-subexpr0 ?input-car-subexpr ... ?output-tail)
    ;;
    ;;notice that the following expansion takes place:
    ;;
    ;;   ((unquote) . ?input-cdr) ==> ?output-tail
    ;;
    (if (null? input-car-subexpr*.stx)
	output-tail.stx
      (%quasicons (car input-car-subexpr*.stx)
		  (%unquote-splice-cons* (cdr input-car-subexpr*.stx) output-tail.stx))))

  (define (%unquote-splice-append input-car-subexpr*.stx output-tail.stx)
    ;;Called to build the result of processing the input form:
    ;;
    ;;   ((unquote-splicing ?input-car-subexpr ...) . ?input-cdr)
    ;;
    ;;return a syntax object.  At the first application:
    ;;
    ;;* The argument INPUT-CAR-SUBEXPR*.STX is the list of syntax objects:
    ;;
    ;;     ((syntax ?input-car-subexpr) ...)
    ;;
    ;;  where each expression ?INPUT-CAR-SUBEXPR is expected to return a list.
    ;;
    ;;* The argument OUTPUT-TAIL.STX is the result of processing:
    ;;
    ;;     (syntax ?input-cdr)
    ;;
    ;;The returned  output form must  be a  syntax object representing  an expression
    ;;that constructs the result as:
    ;;
    ;;   (append ?input-car-subexpr0 ?input-car-subexpr ... ?output-tail)
    ;;
    ;;notice that the following expansion takes place:
    ;;
    ;;   ((unquote-splicing) . ?input-cdr) ==> ?output-tail
    ;;
    (let ((ls (let recur ((stx* input-car-subexpr*.stx))
		(if (null? stx*)
		    (syntax-match output-tail.stx (quote)
		      ((quote ())
		       '())
		      (_
		       (list output-tail.stx)))
		  (syntax-match (car stx*) (quote)
		    ((quote ())
		     (recur (cdr stx*)))
		    (_
		     (cons (car stx*) (recur (cdr stx*)))))))))
      (cond ((null? ls)
	     (bless '(quote ())))
	    ((null? (cdr ls))
	     (car ls))
	    (else
	     (bless
	      `(foldable-append . ,ls))))))

;;; --------------------------------------------------------------------

  (define (%vector-quasi item*.stx nesting-level)
    ;;Recursive function.  Called to process an input syntax object with the format:
    ;;
    ;;   #(?item ...)
    ;;
    ;;At the first invocation, the argument ITEM*.STX is a syntax object representing
    ;;a proper list of items from the vector:
    ;;
    ;;   (syntax (?item ...))
    ;;
    ;;Return a syntax object representing an expression that, at run-time, will build
    ;;an list holding the vector items.
    ;;
    ;;NOTE  The difference  between  %QUASI  and %VECTOR-QUASI  is  that: the  former
    ;;accepts both  *proper* and *improper* lists  of items; the latter  accepts only
    ;;*proper* lists of items.
    ;;
    (syntax-match item*.stx ()
      ((?input-car . ?input-cdr)
       (let ((output-tail.stx (%vector-quasi ?input-cdr nesting-level)))
	 (syntax-match ?input-car (quasiquote unquote unquote-splicing)

	   ((unquote ?input-car-subexpr* ...)
	    ;;When the nesting level requires processing of unquoted expressions:
	    ;;
	    ;;* The expressions ?INPUT-CAR-SUBEXPR must be evaluated at run-time.
	    ;;
	    ;;* The input  syntax object ?INPUT-CDR must be processed  to produce the
	    ;;  output syntax object ?OUTPUT-TAIL.
	    ;;
	    ;;*  The returned  syntax object  must represent  an expression  that, at
	    ;;  run-time, will construct the result as:
	    ;;
	    ;;     (cons* ?input-car-subexpr ... ?output-tail)
	    ;;
	    ;;  notice that the following expansion takes place:
	    ;;
	    ;;     ((unquote) . ?input-cdr) ==> ?output-tail
	    ;;
	    (let ((input-car-subexpr*.stx ?input-car-subexpr*))
	      (if (zero? nesting-level)
		  (%unquote-splice-cons* input-car-subexpr*.stx output-tail.stx)
		(%quasicons (%quasicons (make-top-level-syntax-object/quoted-quoting 'unquote)
					(%quasi input-car-subexpr*.stx (sub1 nesting-level)))
			    output-tail.stx))))

	   ((unquote ?input-car-subexpr* ... . ?input-car-tail)
	    (synner "invalid improper list as UNQUOTE form"
		    (bless
		     `(unquote ,@?input-car-subexpr* . ,?input-car-tail))))

	   ((unquote-splicing ?input-car-subexpr* ...)
	    ;;When the nesting level requires processing of unquoted expressions:
	    ;;
	    ;;* The  subexpressions ?INPUT-CAR-SUBEXPR must be  evaluated at run-time
	    ;;  and their results must be lists:
	    ;;
	    ;;     ?input-car-subexpr => (?output-car-item ...)
	    ;;
	    ;;* The input  syntax object ?INPUT-CDR must be processed  to produce the
	    ;;  output syntax object ?OUTPUT-TAIL.
	    ;;
	    ;;*  The returned  syntax object  must represent  an expression  that, at
	    ;;  run-time, will construct the result as:
	    ;;
	    ;;     (append ?input-car-subexpr ... ?output-tail)
	    ;;
	    ;;  notice that the following expansion takes place:
	    ;;
	    ;;     ((unquote-splicing) . ?input-cdr) ==> ?output-tail
	    ;;
	    (let ((input-car-subexpr*.stx ?input-car-subexpr*))
	      (if (zero? nesting-level)
		  (%unquote-splice-append input-car-subexpr*.stx output-tail.stx)
		(%quasicons (%quasicons (make-top-level-syntax-object/quoted-quoting 'unquote-splicing)
					(%quasi input-car-subexpr*.stx (sub1 nesting-level)))
			    output-tail.stx))))

	   ((unquote-splicing ?input-car-subexpr* ... . ?input-car-tail)
	    (synner "invalid improper list as UNQUOTE-SPLICING form"
		    (bless
		     `(unquote-splicing ,@?input-car-subexpr* . ,?input-car-tail))))

	   ((quasiquote ?nested-expr* ...)
	    (%quasicons (%quasicons (make-top-level-syntax-object/quoted-quoting 'quasiquote)
				    (%quasi ?nested-expr* (add1 nesting-level)))
			output-tail.stx))

	   ((?nested-input-car . ?nested-input-cdr)
	    (%quasicons (%quasicons (%quasi ?nested-input-car nesting-level)
				    (%quasi ?nested-input-cdr nesting-level))
			output-tail.stx))

	   (#(?nested-input-item* ...)
	    (%quasicons (%quasivector (%vector-quasi ?nested-input-item* nesting-level))
			output-tail.stx))

	   (?input-atom
	    (%quasicons (bless
			 `(quote ,?input-atom))
			output-tail.stx)))))

      (()
       (bless '(quote ())))))

  (define (%quasivector output-list.stx)
    ;;Process to call the result of %QUASI-VECTOR.  The argument OUTPUT-LIST.STX is a
    ;;syntax object representing an expression that,  at run-time, will build an list
    ;;holding the vector items.
    ;;
    ;;Return  a syntax  object representing  an  expression that,  at run-time,  will
    ;;convert the list  to a vector.  In general applying  LIST->VECTOR always works,
    ;;but there are special cases where a more efficient processing is possible.
    ;;
    (syntax-match output-list.stx (foldable-list quote)
      ((foldable-list (quote ?datum*) ...)
       (bless
	`(quote #(,@?datum*))))
      (_
       (bless
	`(foldable-list->vector ,output-list.stx)))))

;;; --------------------------------------------------------------------

  (case-define synner
    ((message)
     (syntax-violation 'quasiquote message input-form.stx))
    ((message subform)
     (syntax-violation 'quasiquote message input-form.stx subform)))

  (main input-form.stx))


;;;; non-core macro: QUASISYNTAX

(module (quasisyntax-macro)
  ;;Transformer function used to expand R6RS QUASISYNTAX macros from the
  ;;top-level built  in environment.   Expand the contents  of EXPR-STX;
  ;;return a syntax object that must be further expanded.
  ;;
  ;;FIXME: not really correct (Abdulaziz Ghuloum).
  ;;
  (define (quasisyntax-macro expr-stx)
    (syntax-match expr-stx ()
      ((_ e)
       (receive (lhs* rhs* v)
	   (quasi e 0)
	 (bless
	  `(syntax-case (list ,@rhs*) ()
	     (,lhs*
	      (syntax ,v))))))
      ))

  (define-module-who quasisyntax)

  (define (quasi p nesting-level)
    (syntax-match p (unsyntax unsyntax-splicing quasisyntax)
      ((unsyntax p)
       (if (zero? nesting-level)
	   (let ((g (gensym)))
	     (values (list g) (list p) g))
	 (receive (lhs* rhs* p)
	     (quasi p (sub1 nesting-level))
	   (values lhs* rhs* (list 'unsyntax p)))))

      (unsyntax
       (zero? nesting-level)
       (syntax-violation __module_who__ "incorrect use of unsyntax" p))

      (((unsyntax p* ...) . q)
       (receive (lhs* rhs* q)
	   (quasi q nesting-level)
	 (if (zero? nesting-level)
	     (let ((g* (map (lambda (x) (gensym)) p*)))
	       (values (append g* lhs*)
		       (append p* rhs*)
		       (append g* q)))
	   (receive (lhs2* rhs2* p*)
	       (quasi p* (sub1 nesting-level))
	     (values (append lhs2* lhs*)
		     (append rhs2* rhs*)
		     `((unsyntax . ,p*) . ,q))))))

      (((unsyntax-splicing p* ...) . q)
       (receive (lhs* rhs* q)
	   (quasi q nesting-level)
	 (if (zero? nesting-level)
	     (let ((g* (map (lambda (x) (gensym)) p*)))
	       (values (append (map (lambda (g) `(,g ...)) g*)
			       lhs*)
		       (append p* rhs*)
		       (append (apply append
				      (map (lambda (g) `(,g ...)) g*))
			       q)))
	   (receive (lhs2* rhs2* p*)
	       (quasi p* (sub1 nesting-level))
	     (values (append lhs2* lhs*)
		     (append rhs2* rhs*)
		     `((unsyntax-splicing . ,p*) . ,q))))))

      (unsyntax-splicing
       (zero? nesting-level)
       (syntax-violation __module_who__ "incorrect use of unsyntax-splicing" p))

      ((quasisyntax p)
       (receive (lhs* rhs* p)
	   (quasi p (add1 nesting-level))
	 (values lhs* rhs* `(quasisyntax ,p))))

      ((p . q)
       (let-values
	   (((lhs*  rhs*  p) (quasi p nesting-level))
	    ((lhs2* rhs2* q) (quasi q nesting-level)))
	 (values (append lhs2* lhs*)
		 (append rhs2* rhs*)
		 (cons p q))))

      (#(x* ...)
       (receive (lhs* rhs* x*)
	   (quasi x* nesting-level)
	 (values lhs* rhs* (list->vector x*))))

      (_
       (values '() '() p))
      ))

  #| end of module |# )


;;;; non-core macro: DEFINE-VALUES, DEFINE-CONSTANT-VALUES

(define (define-values-macro expr-stx)
  ;;Transformer function  used to  expand Vicare's  DEFINE-VALUES macros
  ;;from the  top-level built  in environment.   Expand the  contents of
  ;;EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ ?formals ?form0 ?form* ...)
     (receive (standard-formals signature)
	 (parse-tagged-formals-syntax ?formals expr-stx)
       (syntax-match standard-formals ()
	 ((?id* ... ?id0)
	  (let ((TMP* (generate-temporaries ?id*)))
	    (receive (tag* tag0)
		(proper-list->head-and-last (formals-signature-tags signature))
	      (bless
	       `(begin
		  ,@(map (lambda (var tag)
			   `(define (brace ,var ,tag)))
		      ?id* tag*)
		  (define (brace ,?id0 ,tag0)
		    (call-with-values
			(lambda () ,?form0 . ,?form*)
		      (lambda (,@TMP* T0)
			,@(map (lambda (var TMP)
				 `(set! ,var ,TMP))
			    ?id* TMP*)
			T0))))))))

	 (?args
	  (identifier? ?args)
	  (bless
	   `(define (brace ,?args ,(formals-signature-tags signature))
	      (call-with-values
		  (lambda () ,?form0 . ,?form*)
		(lambda args args)))))

	 ((?id* ... . ?rest-id)
	  (let ((TMP* (generate-temporaries ?id*)))
	    (receive (tag* rest-tag)
		(improper-list->list-and-rest (formals-signature-tags signature))
	    (bless
	     `(begin
		,@(map (lambda (var tag)
			 `(define (brace ,var ,tag)))
		    ?id* tag*)
		(define (brace ,?rest-id ,rest-tag)
		  (call-with-values
		      (lambda () ,?form0 . ,?form*)
		    (lambda (,@TMP* . rest)
		      ,@(map (lambda (var TMP)
			       `(set! ,var ,TMP))
			  ?id* TMP*)
		      rest))))))))
	 )))
    ))

(define (define-constant-values-macro expr-stx)
  ;;Transformer function used  to expand Vicare's DEFINE-CONSTANT-VALUES
  ;;macros from the top-level built in environment.  Expand the contents
  ;;of EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ ?formals ?form0 ?form* ...)
     (receive (standard-formals signature)
	 (parse-tagged-formals-syntax ?formals expr-stx)
       (syntax-match standard-formals ()
	 ((?id* ... ?id0)
	  (let ((SHADOW* (generate-temporaries ?id*))
		(TMP*    (generate-temporaries ?id*)))
	    (receive (tag* tag0)
		(proper-list->head-and-last (formals-signature-tags signature))
	      (bless
	       `(begin
		  ,@(map (lambda (var tag)
			   `(define (brace ,var ,tag)))
		      SHADOW* tag*)
		  (define (brace SHADOW0 ,tag0)
		    (call-with-values
			(lambda () ,?form0 . ,?form*)
		      (lambda (,@TMP* T0)
			,@(map (lambda (var TMP)
				 `(set! ,var ,TMP))
			    SHADOW* TMP*)
			T0)))
		  ,@(map (lambda (var SHADOW)
			   `(define-syntax ,var
			      (identifier-syntax ,SHADOW)))
		      ?id* SHADOW*)
		  (define-syntax ,?id0
		    (identifier-syntax SHADOW0))
		  )))))

	 (?args
	  (identifier? ?args)
	  (let ((args-tag (formals-signature-tags signature)))
	    (bless
	     `(begin
		(define (brace shadow ,args-tag)
		  (call-with-values
		      (lambda () ,?form0 . ,?form*)
		    (lambda args args)))
		(define-syntax ,?args
		  (identifier-syntax shadow))
		))))

	 ((?id* ... . ?rest-id)
	  (let ((SHADOW* (generate-temporaries ?id*))
		(TMP*    (generate-temporaries ?id*)))
	    (receive (tag* rest-tag)
		(improper-list->list-and-rest (formals-signature-tags signature))
	    (bless
	     `(begin
		,@(map (lambda (var tag)
			 `(define (brace ,var ,tag)))
		    SHADOW* tag*)
		(define (brace rest-shadow ,rest-tag)
		  (call-with-values
		      (lambda () ,?form0 . ,?form*)
		    (lambda (,@TMP* . rest)
		      ,@(map (lambda (var TMP)
			       `(set! ,var ,TMP))
			  SHADOW* TMP*)
		      rest)))
		,@(map (lambda (var SHADOW)
			 `(define-syntax ,var
			    (identifier-syntax ,SHADOW)))
		    ?id* SHADOW*)
		(define-syntax ,?rest-id
		  (identifier-syntax rest-shadow))
		)))))
	 )))
    ))


;;;; non-core macro: RECEIVE, RECEIVE-AND-RETURN, BEGIN0, XOR

(define (receive-macro input-form.stx)
  ;;Transformer function  used to expand  Vicare's RECEIVE macros from  the top-level
  ;;built in  environment.  Expand  the contents of  INPUT-FORM.STX; return  a syntax
  ;;object that must be further expanded.
  ;;
  (syntax-match input-form.stx ()
    ((_ ?formals ?producer-expression ?body0 ?body* ...)
     (receive (standard-formals signature)
	 (parse-tagged-formals-syntax ?formals input-form.stx)
       (let ((single-return-value? (and (list? standard-formals)
					(= 1 (length standard-formals)))))
	 (if single-return-value?
	     (bless
	      `((lambda ,?formals ,?body0 ,@?body*) ,?producer-expression))
	   (bless
	    `(call-with-values
		 (lambda () ,?producer-expression)
	       (lambda ,?formals ,?body0 ,@?body*)))))))
    ))

(define (receive-and-return-macro input-form.stx)
  ;;Transformer function used  to expand Vicare's RECEIVE-AND-RETURN  macros from the
  ;;top-level built in environment.  Expand  the contents of INPUT-FORM.STX; return a
  ;;syntax object that must be further expanded.
  ;;
  (syntax-match input-form.stx ()
    ((_ ?formals ?producer-expression ?body0 ?body* ...)
     (receive (standard-formals signature)
	 (parse-tagged-formals-syntax ?formals input-form.stx)
       (receive (rv-form single-return-value?)
	   (cond ((list? standard-formals)
		  (if (= 1 (length standard-formals))
		      (values (car standard-formals) #t)
		    (values `(values . ,standard-formals) #f)))
		 ((pair? standard-formals)
		  (receive (rv* rv-rest)
		      (improper-list->list-and-rest standard-formals)
		    (values `(values ,@rv* ,rv-rest) #f)))
		 (else
		  ;;It's a standalone identifier.
		  (values standard-formals #f)))
	 (if single-return-value?
	     (bless
	      `((lambda ,?formals ,?body0 ,@?body* ,rv-form) ,?producer-expression))
	   (bless
	    `(call-with-values
		 (lambda () ,?producer-expression)
	       (lambda ,?formals ,?body0 ,@?body* ,rv-form)))))))
    ))

(define (begin0-macro input-form.stx)
  ;;Transformer function  used to  expand Vicare's BEGIN0  macros from  the top-level
  ;;built in  environment.  Expand  the contents of  INPUT-FORM.STX; return  a syntax
  ;;object that must be further expanded.
  ;;
  (syntax-match input-form.stx ()
    ((_ ?form0 ?form* ...)
     (bless
      `(call-with-values
	   (lambda () ,?form0)
	 (lambda args
	   ,@?form*
	   (apply values args)))))
    ))

(module (xor-macro)
  ;;Transformer function used to expand Vicare's  XOR macros from the top-level built
  ;;in environment.   Expand the contents  of INPUT-FORM.STX; return a  syntax object
  ;;that must be further expanded.
  ;;
  (define (xor-macro input-form.stx)
    (syntax-match input-form.stx ()
      ((_ ?expr* ...)
       (bless (%xor-aux #f ?expr*)))
      ))

  (define (%xor-aux bool/var expr*)
    (cond ((null? expr*)
	   bool/var)
	  ((null? (cdr expr*))
	   `(let ((x ,(car expr*)))
	      (if ,bool/var
		  (and (not x) ,bool/var)
		x)))
	  (else
	   `(let ((x ,(car expr*)))
	      (and (or (not ,bool/var)
		       (not x))
		   (let ((n (or ,bool/var x)))
		     ,(%xor-aux 'n (cdr expr*))))))))

  #| end of module: XOR-MACRO |# )


;;;; non-core macro: DEFINE-INLINE, DEFINE-CONSTANT

(define (define-constant-macro expr-stx)
  ;;Transformer function used to  expand Vicare's DEFINE-CONSTANT macros
  ;;from the  top-level built  in environment.   Expand the  contents of
  ;;EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx (brace)
    ((_ (brace ?name ?tag) ?expr)
     (and (identifier? ?name)
	  (tag-identifier? ?tag))
     (let ((ghost (gensym (syntax->datum ?name))))
       (bless
	`(begin
	   (define (brace ,ghost ?tag) ,?expr)
	   (define-syntax ,?name
	     (identifier-syntax ,ghost))))))
    ((_ ?name ?expr)
     (identifier? ?name)
     (let ((ghost (gensym (syntax->datum ?name))))
       (bless
	`(begin
	   (define ,ghost ,?expr)
	   (define-syntax ,?name
	     (identifier-syntax ,ghost))))))
    ))

(define (define-inline-constant-macro expr-stx)
  ;;Transformer function used  to expand Vicare's DEFINE-INLINE-CONSTANT
  ;;macros from the top-level built in environment.  Expand the contents
  ;;of EXPR-STX; return a syntax object that must be further expanded.
  ;;
  ;;We want to allow a generic expression to generate the constant value
  ;;at expand time.
  ;;
  (syntax-match expr-stx ()
    ((_ ?name ?expr)
     (bless
      `(define-syntax ,?name
	 (let ((const ,?expr))
	   (lambda (stx)
	     (if (identifier? stx)
		 ;;By  using DATUM->SYNTAX  we avoid  the  "raw symbol  in output  of
		 ;;macro" error whenever the CONST is a symbol or contains a symbol.
		 #`(quote #,(datum->syntax stx const))
	       (syntax-violation (quote ?name)
		 "invalid use of identifier syntax" stx (syntax ?name))))))))
    ))

(define (define-inline-macro expr-stx)
  ;;Transformer function  used to  expand Vicare's  DEFINE-INLINE macros
  ;;from the  top-level built  in environment.   Expand the  contents of
  ;;EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (define (%output name-id arg-stx* rest-stx body-stx)
    (let ((TMP* (generate-temporaries arg-stx*))
	  (REST (gensym)))
      (bless
       `(define-fluid-syntax ,name-id
	  (syntax-rules ()
	    ((_ ,@TMP* . REST)
	     (fluid-let-syntax
		 ((,name-id (lambda (stx)
			      (syntax-violation (quote ,name-id)
				"cannot recursively expand inline expression"
				stx))))
	       (let ,(append (map list arg-stx* TMP*)
			     (let ((rest.datum (syntax->datum rest-stx)))
			       (cond ((null? rest.datum)
				      '())
				     ((symbol? rest.datum)
				      ;;If the  rest argument is untagged,  we tag it
				      ;;by default with "<list>".
				      `(((brace ,rest-stx <list>) (list . REST))))
				     (else
				      `((,rest-stx (list . REST)))))))
		 . ,body-stx))))))))
  (syntax-match expr-stx (brace)
    ((_ (?name ?arg* ... . (brace ?rest ?rest-tag)) ?form0 ?form* ...)
     (and (identifier? ?name)
	  (tagged-lambda-proto-syntax? (append ?arg* (bless `(brace ,?rest ,?rest-tag)))))
     (%output ?name ?arg* (bless `(brace ,?rest ,?rest-tag)) (cons ?form0 ?form*)))
    ((_ (?name ?arg* ... . ?rest) ?form0 ?form* ...)
     (and (identifier? ?name)
	  (tagged-lambda-proto-syntax? (append ?arg* ?rest)))
     (%output ?name ?arg* ?rest (cons ?form0 ?form*)))
    ))


;;;; non-core macro: INCLUDE

(define (include-macro expr-stx)
  ;;Transformer function  used to expand  Vicare's INCLUDE macros from  the top-level
  ;;built in  environment.  Expand the contents  of EXPR-STX; return a  syntax object
  ;;that must be further expanded.
  ;;
  (with-who 'include
    (define (main expr-stx)
      (syntax-match expr-stx ()
	((?context ?filename)
	 (%include-file ?filename ?context #f %synner))
	((?context ?filename #t)
	 (%include-file ?filename ?context #t %synner))
	))

    (define (%include-file filename-stx context-id verbose? synner)
      (define filename.str
	(syntax->datum filename-stx))
      (unless (string? filename.str)
	(%synner "expected string as include file pathname" filename-stx))
      (receive (pathname contents)
	  ((current-include-loader) filename.str verbose? synner)
	;;We expect CONTENTS to be null or a list of annotated datums.
	(bless
	 `(stale-when (internal-body
			(import (only (vicare language-extensions posix)
				      file-modification-time))
			(or (not (file-exists? ,pathname))
			    (> (file-modification-time ,pathname)
			       ,(file-modification-time pathname))))
	    . ,(map (lambda (item)
		      (datum->syntax context-id item))
		 contents)))))

    (define (%synner message subform)
      (syntax-violation __who__ message expr-stx subform))

    (main expr-stx)))


;;;; non-core macro: DEFINE-INTEGRABLE

(define (define-integrable-macro expr-stx)
  ;;Transformer  function  used  to  expand  Vicare's  DEFINE-INTEGRABLE
  ;;macros from the top-level built in environment.  Expand the contents
  ;;of EXPR-STX; return a syntax object that must be further expanded.
  ;;
  ;;The original  syntax was  posted by "leppie"  on the  Ikarus mailing
  ;;list; subject "Macro Challenge of Last Year [Difficulty: *****]", 20
  ;;Oct 2009.
  ;;
  (syntax-match expr-stx (lambda)
    ((_ (?name . ?formals) ?form0 ?form* ...)
     (identifier? ?name)
     (bless
      `(define-integrable ,?name (lambda ,?formals ,?form0 ,@?form*))))

    ((_ ?name (lambda ?formals ?form0 ?form* ...))
     (identifier? ?name)
     (bless
      `(begin
	 (define-fluid-syntax ,?name
	   (lambda (x)
	     (syntax-case x ()
	       (_
		(identifier? x)
		#'xname)

	       ((_ arg ...)
		#'((fluid-let-syntax
		       ((,?name (identifier-syntax xname)))
		     (lambda ,?formals ,?form0 ,@?form*))
		   arg ...)))))
	 (define xname
	   (fluid-let-syntax ((,?name (identifier-syntax xname)))
	     (lambda ,?formals ,?form0 ,@?form*)))
	 )))
    ))


;;;; non-core macro: DEFINE-SYNTAX-PARAMETER, SYNTAX-PARAMETRISE

(define (define-syntax-parameter-macro expr-stx)
  ;;Transformer function used to expand Vicare's DEFINE-SYNTAX-PARAMETER
  ;;macros from the top-level built in environment.  Expand the contents
  ;;of EXPR-STX; return a syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ ?param-id ?param-expr)
     (identifier? ?param-id)
     (bless
      `(define-fluid-syntax ,?param-id
	 (make-expand-time-value ,?param-expr))))
    ))

(define (syntax-parametrise-macro expr-stx)
  ;;Transformer      function      used     to      expand      Vicare's
  ;;SYNTAX-PARAMETRISE-MACRO   macros  from   the  top-level   built  in
  ;;environment.   Expand  the contents  of  EXPR-STX;  return a  syntax
  ;;object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ ((?lhs* ?rhs*) ...) ?body0 ?body* ...)
     (for-all identifier? ?lhs*)
     (bless
      `(fluid-let-syntax ,(map (lambda (lhs rhs)
				 (list lhs `(make-expand-time-value ,rhs)))
			    ?lhs* ?rhs*)
	 ,?body0 . ,?body*)))
    ))


;;;; non-core macro: UNSAFE

(define (unsafe-macro input-form.stx)
  ;;Transformer function  used to  expand Vicare's UNSAFE  macros from  the top-level
  ;;built in  environment.  Expand  the contents of  INPUT-FORM.STX; return  a syntax
  ;;object that must be further expanded.
  ;;
  (with-who unsafe
    (syntax-match input-form.stx ()
      ((_ ?safe-id)
       (identifier? ?safe-id)
       (or (identifier-unsafe-variant ?safe-id)
	   (syntax-violation __who__
	     "identifier has no unsafe variant" input-form.stx ?safe-id)))
      )))


;;;; non-core macro: PRE-INCR!, PRE-DECR!, POST-INCR!, POST-DECR!

(define (pre-incr-macro input-form.stx)
  ;;Transformer function used to expand  Vicare's PRE-INCR! macros from the top-level
  ;;built in  environment.  Expand  the contents of  INPUT-FORM.STX; return  a syntax
  ;;object that must be further expanded.
  ;;
  (syntax-match input-form.stx ()
    ((_ ?id)
     (identifier? ?id)
     (bless
      `(begin
	 (set! ,?id (add1 ,?id))
	 ,?id)))
    ((_ ?id ?step)
     (identifier? ?id)
     (bless
      `(begin
	 (set! ,?id (+ ,?id ,?step))
	 ,?id)))
    ((_ ?expr)
     (bless
      `(add1 ,?expr)))
    ((_ ?expr ?step)
     (bless
      `(+ ,?expr ,?step)))
    (_
     (syntax-violation 'pre-incr! "invalid pre-increment operation" input-form.stx))
    ))

(define (pre-decr-macro input-form.stx)
  ;;Transformer function used to expand  Vicare's PRE-DECR! macros from the top-level
  ;;built in  environment.  Expand  the contents of  INPUT-FORM.STX; return  a syntax
  ;;object that must be further expanded.
  ;;
  (syntax-match input-form.stx ()
    ((_ ?id)
     (identifier? ?id)
     (bless
      `(begin
	 (set! ,?id (sub1 ,?id))
	 ,?id)))
    ((_ ?id ?step)
     (identifier? ?id)
     (bless
      `(begin
	 (set! ,?id (- ,?id ,?step))
	 ,?id)))
    ((_ ?expr)
     (bless
      `(sub1 ,?expr)))
    ((_ ?expr ?step)
     (bless
      `(- ,?expr ,?step)))
    (_
     (syntax-violation 'pre-decr! "invalid pre-decrement operation" input-form.stx))
    ))

;;; --------------------------------------------------------------------

(define (post-incr-macro input-form.stx)
  ;;Transformer function used to expand Vicare's POST-INCR! macros from the top-level
  ;;built in  environment.  Expand  the contents of  INPUT-FORM.STX; return  a syntax
  ;;object that must be further expanded.
  ;;
  (syntax-match input-form.stx ()
    ((_ ?id)
     (identifier? ?id)
     (bless
      `(receive-and-return (V)
	   ,?id
	 (set! ,?id (add1 ,?id)))))
    ((_ ?id ?step)
     (identifier? ?id)
     (bless
      `(receive-and-return (V)
	   ,?id
	 (set! ,?id (+ ,?id ,?step)))))
    ((_ ?expr)
     (bless
      `(add1 ,?expr)))
    ((_ ?expr ?step)
     (bless
      `(+ ,?expr ,?step)))
    (_
     (syntax-violation 'post-incr! "invalid post-increment operation" input-form.stx))
    ))

(define (post-decr-macro input-form.stx)
  ;;Transformer function used to expand Vicare's POST-DECR! macros from the top-level
  ;;built in  environment.  Expand  the contents of  INPUT-FORM.STX; return  a syntax
  ;;object that must be further expanded.
  ;;
  (syntax-match input-form.stx ()
    ((_ ?id)
     (identifier? ?id)
     (bless
      `(receive-and-return (V)
	   ,?id
	 (set! ,?id (sub1 ,?id)))))
    ((_ ?id ?step)
     (identifier? ?id)
     (bless
      `(receive-and-return (V)
	   ,?id
	 (set! ,?id (- ,?id ,?step)))))
    ((_ ?expr)
     (bless
      `(sub1 ,?expr)))
    ((_ ?expr ?step)
     (bless
      `(- ,?expr ,?step)))
    (_
     (syntax-violation 'post-decr! "invalid post-decrement operation" input-form.stx))
    ))


;;;; non-core macro: INFIX

(module (infix-macro)
  (include "psyntax.non-core-macro-transformers.infix-macro.scm" #t)
  #| end of module: INFIX-MACRO |# )


;;;; non-core macro: miscellanea

(define (time-macro expr-stx)
  ;;Transformer function  used to expand  Vicare's TIME macros  from the
  ;;top-level built  in environment.   Expand the contents  of EXPR-STX;
  ;;return a syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ ?expr)
     (let ((str (receive (port getter)
		    (open-string-output-port)
		  (write (syntax->datum ?expr) port)
		  (getter))))
       (bless
	`(time-it ,str (lambda () ,?expr)))))))

(define (delay-macro expr-stx)
  ;;Transformer  function used  to  expand R6RS  DELAY  macros from  the
  ;;top-level built  in environment.   Expand the contents  of EXPR-STX;
  ;;return a syntax object that must be further expanded.
  ;;
  (syntax-match expr-stx ()
    ((_ ?expr)
     (bless
      `(make-promise (lambda ()
		       ,?expr))))))

(define (assert-macro expr-stx)
  ;;Defined by R6RS.  An ASSERT  form is evaluated by evaluating EXPR.
  ;;If  EXPR returns a  true value,  that value  is returned  from the
  ;;ASSERT  expression.   If EXPR  returns  false,  an exception  with
  ;;condition  types  "&assertion"  and  "&message"  is  raised.   The
  ;;message  provided  in   the  condition  object  is  implementation
  ;;dependent.
  ;;
  ;;NOTE  Implementations should  exploit the  fact that  ASSERT  is a
  ;;syntax  to  provide as  much  information  as  possible about  the
  ;;location of the assertion failure.
  ;;
  (syntax-match expr-stx ()
    ((_ ?expr)
     (if (option.drop-assertions?)
	 ?expr
       (let ((pos (or (expression-position expr-stx)
		      (expression-position ?expr))))
	 (bless
	  (if (source-position-condition? pos)
	      `(or ,?expr
		   (assertion-error
		    ',?expr ,(source-position-port-id pos)
		    ,(source-position-byte pos) ,(source-position-character pos)
		    ,(source-position-line pos) ,(source-position-column    pos)))
	    `(or ,?expr
		 (assertion-error ',?expr "unknown source" #f #f #f #f)))))))
    ))

(define (file-options-macro expr-stx)
  ;;Transformer for  the FILE-OPTIONS macro.  File  options selection is
  ;;implemented   as   an   enumeration  type   whose   constructor   is
  ;;MAKE-FILE-OPTIONS from the boot environment.
  ;;
  (define (valid-option? opt-stx)
    (and (identifier? opt-stx)
	 (memq (identifier->symbol opt-stx) '(no-fail no-create no-truncate executable))))
  (syntax-match expr-stx ()
    ((_ ?opt* ...)
     (for-all valid-option? ?opt*)
     (bless
      `(make-file-options ',?opt*)))))

(define (expander-options-macro expr-stx)
  ;;Transformer  for   the  EXPANDER-OPTIONS   macro.   File  options   selection  is
  ;;implemented  as an  enumeration type  whose constructor  is MAKE-EXPANDER-OPTIONS
  ;;from the boot environment.
  ;;
  (define (valid-option? opt-stx)
    (and (identifier? opt-stx)
	 (case (identifier->symbol opt-stx)
	   ((strict-r6rs tagged-language)
	    #t)
	   (else #f))))
  (syntax-match expr-stx ()
    ((_ ?opt* ...)
     (for-all valid-option? ?opt*)
     (bless
      `(make-expander-options ',?opt*)))))

(define (compiler-options-macro expr-stx)
  ;;Transformer  for   the  COMPILER-OPTIONS   macro.   File  options   selection  is
  ;;implemented  as an  enumeration type  whose constructor  is MAKE-COMPILER-OPTIONS
  ;;from the boot environment.
  ;;
  (define (valid-option? opt-stx)
    (and (identifier? opt-stx)
	 (memq (identifier->symbol opt-stx) '(strict-r6rs))))
  (syntax-match expr-stx ()
    ((_ ?opt* ...)
     (for-all valid-option? ?opt*)
     (bless
      `(make-compiler-options ',?opt*)))))

(define (endianness-macro expr-stx)
  ;;Transformer of  ENDIANNESS.  Support  the symbols:  "big", "little",
  ;;"network", "native"; convert "network" to "big".
  ;;
  (syntax-match expr-stx ()
    ((_ ?name)
     (and (identifier? ?name)
	  (memq (identifier->symbol ?name) '(big little network native)))
     (case (identifier->symbol ?name)
       ((network)
	(bless '(quote big)))
       ((native)
	(bless '(native-endianness)))
       ((big little)
	(bless `(quote ,?name)))))))

(define (%allowed-symbol-macro expr-stx allowed-symbol-set)
  ;;Helper  function used  to  implement the  transformer of:  EOL-STYLE
  ;;ERROR-HANDLING-MODE, BUFFER-MODE,  ENDIANNESS.  All of  these macros
  ;;should expand to a quoted symbol among a list of allowed ones.
  ;;
  (syntax-match expr-stx ()
    ((_ ?name)
     (and (identifier? ?name)
	  (memq (identifier->symbol ?name) allowed-symbol-set))
     (bless
      `(quote ,?name)))))


;;;; done

#| end of library |# )

;;; end of file
;;Local Variables:
;;fill-column: 85
;;eval: (put 'build-library-letrec*		'scheme-indent-function 1)
;;eval: (put 'build-application			'scheme-indent-function 1)
;;eval: (put 'build-conditional			'scheme-indent-function 1)
;;eval: (put 'build-case-lambda			'scheme-indent-function 1)
;;eval: (put 'build-lambda			'scheme-indent-function 1)
;;eval: (put 'build-foreign-call		'scheme-indent-function 1)
;;eval: (put 'build-sequence			'scheme-indent-function 1)
;;eval: (put 'build-global-assignment		'scheme-indent-function 1)
;;eval: (put 'build-lexical-assignment		'scheme-indent-function 1)
;;eval: (put 'build-letrec*			'scheme-indent-function 1)
;;eval: (put 'build-data			'scheme-indent-function 1)
;;eval: (put 'push-lexical-contour		'scheme-indent-function 1)
;;eval: (put 'syntactic-binding-getprop		'scheme-indent-function 1)
;;eval: (put 'sys.syntax-case			'scheme-indent-function 2)
;;eval: (put 'with-who				'scheme-indent-function 1)
;;eval: (put '$fold-left/stx			'scheme-indent-function 1)
;;End:
