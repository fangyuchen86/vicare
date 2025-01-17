;;;Ikarus Scheme -- A compiler for R6RS Scheme.
;;;Copyright (C) 2006,2007,2008  Abdulaziz Ghuloum
;;;Modified by Marco Maggi <marco.maggi-ipsu@poste.it>
;;;
;;;This program is free software: you can  redistribute it and/or modify it under the
;;;terms  of the  GNU General  Public  License version  3  as published  by the  Free
;;;Software Foundation.
;;;
;;;This program is  distributed in the hope  that it will be useful,  but WITHOUT ANY
;;;WARRANTY; without  even the implied warranty  of MERCHANTABILITY or FITNESS  FOR A
;;;PARTICULAR PURPOSE.  See the GNU General Public License for more details.
;;;
;;;You should have received a copy of  the GNU General Public License along with this
;;;program.  If not, see <http://www.gnu.org/licenses/>.
;;;


#!vicare
(library (ikarus.compiler.pass-letrec-optimizer)
  (export
    pass-optimize-letrec
    current-letrec-pass
    check-for-illegal-letrec
    optimize-letrec/basic
    optimize-letrec/waddell
    optimize-letrec/scc)
  (import (rnrs)
    (ikarus.compiler.compat)
    (ikarus.compiler.config)
    (ikarus.compiler.helpers)
    (ikarus.compiler.typedefs)
    (ikarus.compiler.condition-types)
    (ikarus.compiler.unparse-recordised-code))


;;;; introduction
;;
;;For an  introduction to processing LETREC  and LETREC* syntaxes, and  to understand
;;the code below, we *must* read the following paper:
;;
;;   [WSD]  Oscar Waddell,  Dipanwita  Sarkar,  R. Kent  Dybvig.   "Fixing Letrec:  A
;;   Faithful Yet Efficient Implementation of Scheme's Recursive Binding Construct"
;;
;;then we  can move to  the following paper,  which describes the  SCC transformation
;;used by Vicare:
;;
;;   [GD]  Abdulaziz  Ghuloum,  R.    Kent  Dybvig.   ``Fixing  Letrec  (reloaded)''.
;;   Workshop on Scheme and Functional Programming '09
;;
;;and finally the documentation of the pass functions in Texinfo format.
;;
;;
;;Input and output of all the LETREC optimisation alternatives
;;============================================================
;;
;;The input of  all the alternative pass functions is  a struct instance representing
;;an expression  as recordized  code; the  input is a  tree-like nested  hierarchy of
;;structures with the following struct types:
;;
;;	assign		bind		clambda
;;	conditional	constant	forcall
;;	funcall				prelex
;;	primref		rec*bind	recbind
;;	seq
;;
;;in such  hierarchy: instances of the  struct type BIND represent  LET core language
;;forms; instances  of the  struct types  RECBIND and  REC*BIND represent  LETREC and
;;LETREC* core  language forms;  instances of  the struct  type PRELEX,  in reference
;;position, represent references to bindings defined by BIND, RECBIND or REC*BIND.
;;
;;The  output  of  all the  alternative  pass  functions  is  a new  struct  instance
;;representing  an  expression  as  recordized  code; the  hierarchy  of  the  output
;;expression is  the same as  that of the input  expression, except for  instances of
;;RECBIND and REC*BIND which are replaced by a composition of BIND, FIX and ASSIGN.
;;
;;
;;Notes for all the LETREC optimisation alternatives
;;==================================================
;;
;;NOTE We assume that the input expression  is correct.  All the PRELEX structures in
;;reference position are captured by a  binding defined by BIND, RECBIND or REC*BIND;
;;there are no references to free variables.
;;
;;NOTE We need to  remember that the LETREC-optimisation pass is  used to process the
;;result of fully expanding: libraries,  programs and standalone expressions given to
;;EVAL (either in stateless environments or stateful interactive environments).  This
;;means some  bindings are defined  in the input  expression, while others  have been
;;defined in  a previously processed  expression; assignments and references  to such
;;previously defined bindings have been  already processed and transformed into calls
;;to  the  primitive  functions:  they  are not  represented  by  ASSIGN  and  PRELEX
;;structures.
;;
;;NOTE Upon entering  this compiler pass, the PRELEX  structures representing defined
;;bindings already  have the  fields SOURCE-REFERENCED?,  SOURCE-ASSIGNED?  correctly
;;set; a previous pass has determined if a binding is assigned or not.
;;


(define check-for-illegal-letrec
  (make-parameter #t
    (lambda (obj)
      (and obj #t))))

(define current-letrec-pass
  (make-parameter 'scc
    (lambda (obj)
      (if (memq obj '(scc waddell basic))
	  obj
	(procedure-argument-violation 'current-letrec-pass
	  "invalid letrec optimization mode, expected a symbol among: scc, waddell, basic"
	  obj)))))

(define* (pass-optimize-letrec X)
  (when (check-for-illegal-letrec)
    (check-for-illegal-letrec-references X))
  (let ((Y (integrate-nested-binding-forms X)))
    (case (current-letrec-pass)
      ((scc)     (optimize-letrec/scc     Y))
      ((waddell) (optimize-letrec/waddell Y))
      ((basic)   (optimize-letrec/basic   Y))
      (else
       (assertion-violation __who__
	 "invalid letrec optimization mode" (current-letrec-pass))))))


;;;; helpers

(case-define %map-in-order-with-index
  ((func serial-idx ell1)
   (if (pair? ell1)
       (cons (func                          serial-idx          (car ell1))
	     (%map-in-order-with-index func (fxadd1 serial-idx) (cdr ell1)))
     '()))
  ((func serial-idx ell1 ell2)
   (if (pair? ell1)
       (cons (func                          serial-idx          (car ell1) (car ell2))
	     (%map-in-order-with-index func (fxadd1 serial-idx) (cdr ell1) (cdr ell2)))
     '())))

(define-syntax* (define-fold-right stx)
  ;;Define  a  new FOLD-RIGHT  function  with  a  fixed number  of  list
  ;;arguments and a fixed number of return values.  For example, we want
  ;;the definition:
  ;;
  ;;   (define-fold-right %fold-right/1-list/2-retvals
  ;;     (number-of-lists       1)
  ;;     (number-of-retvals     2))
  ;;
  ;;to expand into:
  ;;
  ;;   (define (%fold-right/1-list/2-retvals combine nil1 nil2 ell)
  ;;     (if (pair? ell)
  ;;         (receive (nil1^ nil2^)
  ;;             (%fold-right/1-list/2-retvals combine nil1 nil2 (cdr ell))
  ;;           (combine (car ell) nil1^ nil2^))
  ;;       (values nil1 nil2)))
  ;;
  ;;we blindly assume that the  list arguments are correct: proper lists
  ;;with equal length.
  ;;
  (define (%positive-fixnum? obj)
    (and (fixnum?     obj)
	 (fxpositive? obj)))
  (syntax-case stx (number-of-lists number-of-retvals)
    ((_ ?who
	(number-of-lists	?num-of-lists)
	(number-of-retvals	?num-of-retvals))
     (let ((num-of-lists   (syntax->datum #'?num-of-lists))
	   (num-of-retvals (syntax->datum #'?num-of-retvals)))
       (unless (identifier? #'?who)
	 (synner "expected identifier as function name" #'?who))
       (unless (%positive-fixnum? num-of-lists)
	 (synner "expected positive fixnum as number of list arguments" #'?num-of-lists))
       (unless (%positive-fixnum? num-of-retvals)
	 (synner "expected positive fixnum as number of return values"  #'?num-of-retvals))
       (with-syntax
	   (((ELL0 ELL ...) (generate-temporaries (make-list (syntax->datum #'?num-of-lists))))
	    ((NIL0 NIL ...) (generate-temporaries (make-list (syntax->datum #'?num-of-retvals)))))
	 #'(define (?who combine NIL0 NIL ... ELL0 ELL ...)
	     (if (pair? ELL0)
		 (receive (NIL0 NIL ...)
		     (?who combine NIL0 NIL ... (cdr ELL0) (cdr ELL) ...)
		   (combine (car ELL0) (car ELL) ... NIL0 NIL ...))
	       (values NIL0 NIL ...))))))
    ))

(define-auxiliary-syntaxes number-of-lists number-of-retvals)

(define-fold-right %fold-right/1-list/2-retvals
  (number-of-lists	1)
  (number-of-retvals	2))

(define-fold-right %fold-right/2-lists/2-retvals
  (number-of-lists	2)
  (number-of-retvals	2))

;;; --------------------------------------------------------------------

(module (%make-void-constants)
  ;;Build and  return a  list of  CONSTANT structs  representing #<void>  values, one
  ;;struct  for each  item in  LHS*.  They  are used,  for example,  to generate  the
  ;;undefined RHS expressions in the transformation from:
  ;;
  ;;   (letrec* ((?var ?init) ...)
  ;;     ?body0 ?body ...)
  ;;
  ;;to:
  ;;
  ;;   (let ((?var (void)) ...)
  ;;     (set! ?var ?init) ...
  ;;     ?body0 ?body ...)
  ;;
  (define (%make-void-constants lhs*)
    (map (lambda (x) THE-VOID) lhs*))

  (define-constant THE-VOID
    (make-constant (void)))

  #| end of module |# )

(define (build-assign* lhs* rhs* body)
  ;;Build a sequence of assignments followed by a body.
  ;;
  ;;LHS* must  be a list  of struct instances  of type PRELEX  representing left-hand
  ;;sides in LET-like bindings.
  ;;
  ;;RHS* must be a list of struct instances representing right-hand sides in LET-like
  ;;bindings, as recordized code.
  ;;
  ;;BODY must  be a  struct instance  representing the  body of  a LET-like  body, as
  ;;recordized code.
  ;;
  ;;Return a new struct instance representing the sequence:
  ;;
  ;;  (begin (set! ?lhs ?rhs) ... . ?body)
  ;;
  (fold-right (lambda (lhs rhs tail)
		(make-seq (%make-init-single-assign lhs rhs) tail))
    body lhs* rhs*))

(define (%make-init-single-assign lhs rhs)
  ;;Build and return an ASSIGN struct for the given LHS and RHS.
  ;;
  ;;LHS must be a PRELEX structure representing the left-hand side of the assignment.
  ;;RHS  must  be  a  struct  representing the  right-hand  side  expression  of  the
  ;;assignment.
  ;;
  ;;The LHS  is marked  as having  a single  initialisation assignment:  the returned
  ;;assignment is the only one of  an otherwise unassigned binding.  This function is
  ;;to be  used when the LHS  is never referenced before  the RHS is assigned  to the
  ;;storage location.
  ;;
  (unless ($prelex-source-assigned? lhs)
    ;;FIXME This is very fragile.  (Abdulaziz Ghuloum)
    ($set-prelex-source-assigned?! lhs (or ($prelex-global-location lhs) #t)))
  (make-assign lhs rhs))


(module (check-for-illegal-letrec-references)
  ;;This module is used to check for illegal references to bindings in the right-hand
  ;;sides of LETREC and LETREC* syntaxes.
  ;;
  (define-syntax __module_who__
    (identifier-syntax 'check-for-illegal-letrec-references))

  (define (check-for-illegal-letrec-references x)
    (cond ((C x (%make-empty-illegal-set))
	   => (lambda (illegal)
		(%error illegal x)))))

  ;;In this commented out version we use a  list to hold the set of PRELEX structures
  ;;that  is  illegal  to  reference  in right-hand  sides  of  LETREC,  LETREC*  and
  ;;LIBRARY-LETREC* syntaxes.
  ;;
  ;;Doing a  linear search is usually  fine for LETREC and  LETREC* syntaxes, because
  ;;the list  of bindings is  most likely  small.  But LIBRARY-LETREC*  syntaxes will
  ;;have "many" bindings, one for each defined function.
  ;;
  ;; (begin
  ;;   (define-inline (%make-empty-illegal-set)
  ;;     '())
  ;;   (define (%illegal-reference-to? x illegals)
  ;;     (cond ((memq x illegals)
  ;; 	     => car)
  ;; 	    (else #f)))
  ;;   (define-inline (%illegal-augment more illegals)
  ;;     (append more illegals)))
  ;;
  ;;In  this version  we use  a closure  on a  hashtable to  hold the  set of  PRELEX
  ;;structures that  is illegal to reference  in right-hand sides of  LETREC, LETREC*
  ;;and LIBRARY-LETREC* syntaxes.
  ;;
  (begin
    (define-syntax-rule (%make-empty-illegal-set)
      (lambda (x) #f))
    (define-syntax-rule (%illegal-reference-to? prel illegals)
      ;;Must return #f if PREL is legal, and PREL itself if PREL is illegal.
      ;;
      (illegals prel))
    (define (%illegal-augment prel* illegals)
      ;;PREL* must be a list of PRELEX structures to add to the illegals set.
      ;;
      (if (null? prel*)
	  illegals
	(let ((H (make-eq-hashtable)))
	  (for-each (lambda (prel)
		      ;;Yes, we want PREL as both key and value.
		      (hashtable-set! H prel prel))
	    prel*)
	  (lambda (prel)
	    (or (hashtable-ref H prel #f)
		(%illegal-reference-to? prel illegals)))))))

  (define (C x illegals)
    ;;Recursively visit the  recordized code X looking for a  struct instance of type
    ;;PRELEX which is EQ? to one in the set ILLEGALS.  When found return such struct,
    ;;else return #f.
    ;;
    (struct-case x
      ((constant)
       #f)

      ((typed-expr expr)
       (C expr illegals))

      ((prelex)
       (%illegal-reference-to? x illegals))

      ((assign lhs rhs)
       (or (%illegal-reference-to? lhs illegals)
	   (C rhs illegals)))

      ((primref)
       #f)

      ((bind lhs* rhs* body)
       (or (if (null? lhs*)
	       #f
	     (C*/error rhs* illegals))
	   (C body illegals)))

      ((recbind lhs* rhs* body)
       (or (if (null? lhs*)
	       #f
	     (C*/error rhs* (%illegal-augment lhs* illegals)))
	   (C body illegals)))

      ((rec*bind lhs* rhs* body)
       (or (if (null? lhs*)
	       #f
	     ;;Notice the difference between LETREC and  LETREC*: in the latter it is
	     ;;fine for a RHS to reference the LHS of a previous local binding.
	     (let loop ((lhs* lhs*)
			(rhs* rhs*))
	       (if (null? rhs*)
		   #f
		 (or (C/error (car rhs*) (%illegal-augment lhs* illegals))
		     (loop (cdr lhs*) (cdr rhs*))))))
	   (C body illegals)))

      ((conditional test conseq altern)
       (or (C test   illegals)
	   (C conseq illegals)
	   (C altern illegals)))

      ((seq e0 e1)
       (or (C e0 illegals)
	   (C e1 illegals)))

      ((clambda)
       (C-clambda x))

      ((funcall rator rand*)
       (or (C  rator illegals)
	   (C* rand* illegals)))

      ((forcall rator rand*)
       ;;Remember that RATOR is a string here.
       (C* rand* illegals))

      (else
       (error __module_who__ "invalid expression" (unparse-recordized-code x)))))

  (define (C/error x illegals)
    ;;Like C,  but in case  of error make  use of X as  enclosing form in  the raised
    ;;exception.
    ;;
    (cond ((C x illegals)
	   => (lambda (illegal)
		(%error illegal x)))
	  (else #f)))

  (define (C* x* illegals)
    ;;Apply C to every item in the list X*.
    ;;
    (find (lambda (x)
	    (C x illegals))
      x*))

  (define (C*/error x* illegals)
    ;;Like C*, but in  case of error make use of the culprit  item of X* as enclosing
    ;;form in the raised exception.
    ;;
    (let loop ((x* x*))
      (cond ((null? x*)
	     #f)
	    ((C (car x*) illegals)
	     => (lambda (illegal)
		  (%error illegal (car x*))))
	    (else
	     (loop (cdr x*))))))

;;; --------------------------------------------------------------------

  (module (C-clambda)
    ;;The purpose  of this module  is to  apply C to  every CASE-LAMBDA body  with an
    ;;empty set of illegals.
    ;;
    (define (C-clambda x)
      (struct-case x
	((clambda label.unused cls*)
	 (for-each C-clambda-case cls*)
	 #f)))

    (define (C-clambda-case x)
      (struct-case x
	((clambda-case info body)
	 (C/error body (%make-empty-illegal-set)))))

    #| end of module: C-lambda |# )

;;; --------------------------------------------------------------------

  (define (%error illegal-prelex enclosing-code)
    ;;R6RS requests that this error is of type "&assertion", but "&syntax" is not bad
    ;;either.
    ;;
    (syntax-violation __module_who__
      "illegal binding reference in right-hand side of LETREC, LETREC* or LIBRARY syntax"
      (unparse-recordized-code/pretty enclosing-code)
      (unparse-recordized-code/pretty illegal-prelex)))

  #| end of module: check-for-illegal-letrec-references |# )


(module (integrate-nested-binding-forms)
  ;;In this  compiler sub-pass we merge  nested LET-like forms before  optimising the
  ;;RECBIND  and  REC*BIND forms;  the  more  we stuff  bindings  in  the RECBIND  or
  ;;REC*BIND, the better.
  ;;
  ;;See below the functions "E-recbind" and  "E-rec*bind" for the list of implemented
  ;;transformations.
  ;;
  (define-syntax __module_who__
    (identifier-syntax 'integrate-nested-binding-forms))

  (define-syntax-rule (integrate-nested-binding-forms X)
    (E X))

  (define (E X)
    ;;Recursively  visit the  recordized code  X merging  nested LET-like  forms when
    ;;possible.
    ;;
    (struct-case X
      ((constant)
       X)

      ((typed-expr expr core-type)
       (make-typed-expr (E expr) core-type))

      ((prelex)
       X)

      ((assign lhs rhs)
       (make-assign lhs (E rhs)))

      ((primref)
       X)

      ((bind lhs* rhs* body)
       (if (null? lhs*)
	   (E body)
	 (make-bind lhs* (E* rhs*) (E body))))

      ((recbind lhs* rhs* body)
       (E-recbind lhs* rhs* body))

      ((rec*bind lhs* rhs* body)
       (E-rec*bind lhs* rhs* body))

      ((conditional test conseq altern)
       (make-conditional (E test)
	   (E conseq)
	 (E altern)))

      ((seq e0 e1)
       (make-seq (E e0) (E e1)))

      ((clambda)
       (E-clambda X))

      ((funcall rator rand*)
       (make-funcall (E rator) (E* rand*)))

      ((forcall rator rand*)
       ;;Remember that RATOR is a string here.
       (make-forcall rator (E* rand*)))

      (else
       (error __module_who__ "invalid expression" (unparse-recordized-code X)))))

  (define (E* X*)
    ;;Apply E to every item in the list X*.
    ;;
    (map E X*))

;;; --------------------------------------------------------------------

  (module (E-clambda)
    ;;The purpose of this module is to apply E to every CASE-LAMBDA body.
    ;;
    (define (E-clambda x)
      (struct-case x
	((clambda label cls* cp free name)
	 (make-clambda label (map E-clambda-case cls*) cp free name))))

    (define (E-clambda-case x)
      (struct-case x
	((clambda-case info body)
	 (make-clambda-case info (E body)))))

    #| end of module: E-lambda |# )

;;; --------------------------------------------------------------------

  (define (E-recbind lhs* rhs* body)
    (if (null? lhs*)
	(E body)
      (make-recbind lhs* (E* rhs*) (E body))))

;;; --------------------------------------------------------------------

  (module (E-rec*bind)

    (define (E-rec*bind lhs* rhs* body)
      (if (null? lhs*)
	  (E body)
	(receive (lhs*^ rhs*^)
	    (%fold-right/2-lists/2-retvals %E-rhs '() '() lhs* rhs*)
	  (receive (lhs*^^ rhs*^^ body^)
	      (%E-body lhs*^ rhs*^ body)
	    (make-rec*bind lhs*^^ rhs*^^ body^)))))

    (define (%E-rhs lhs rhs tail-lhs* tail-rhs*)
      (struct-case (E rhs)
	((bind nested-lhs* nested-rhs* nested-body)
	 ;;   (letrec* ((lhs0 rhs0)
	 ;;             (lhs1 (let ((lhs3 rhs3)
	 ;;                         (lhs4 rhs4))
	 ;;                     body2))
	 ;;             (lhs2 rhs2))
	 ;;     body1)
	 ;;   ===> (letrec* ((lhs0 rhs0)
	 ;;                  (tmp0 rhs3)
	 ;;                  (tmp1 rhs4)
	 ;;                  (lhs3 tmp0)
	 ;;                  (lhs4 tmp1)
	 ;;                  (lhs1 body2)
	 ;;                  (lhs2 rhs2))
	 ;;          body1)
	 (let ((tmp* (map make-prelex-for-tmp-binding nested-lhs*)))
	   (values (append tmp*        nested-lhs* (list lhs)         tail-lhs*)
		   (append nested-rhs* tmp*        (list nested-body) tail-rhs*))))

	((recbind nested-lhs* nested-rhs* nested-body)
	 ;;   (letrec* ((lhs0 rhs0)
	 ;;             (lhs1 (letrec ((lhs3 rhs3)
	 ;;                            (lhs4 rhs4))
	 ;;                     body2))
	 ;;             (lhs2 rhs2))
	 ;;     body1)
	 ;;   ===> (letrec* ((lhs0 rhs0)
	 ;;                  (tmp0 rhs3)
	 ;;                  (tmp1 rhs4)
	 ;;                  (lhs3 tmp0)
	 ;;                  (lhs4 tmp1)
	 ;;                  (lhs1 body2)
	 ;;                  (lhs2 rhs2))
	 ;;          body1)
	 (let ((tmp* (map make-prelex-for-tmp-binding nested-lhs*)))
	   (values (append tmp*        nested-lhs* (list lhs)         tail-lhs*)
		   (append nested-rhs* tmp*        (list nested-body) tail-rhs*))))

	((rec*bind nested-lhs* nested-rhs* nested-body)
	 ;;   (letrec* ((lhs0 rhs0)
	 ;;             (lhs1 (letrec* ((lhs3 rhs3)
	 ;;                             (lhs4 rhs4))
	 ;;                     body2))
	 ;;             (lhs2 rhs2))
	 ;;     body1)
	 ;;   ===> (letrec* ((lhs0 rhs0)
	 ;;                  (tmp0 rhs3)
	 ;;                  (tmp1 rhs4)
	 ;;                  (lhs3 tmp0)
	 ;;                  (lhs4 tmp1)
	 ;;                  (lhs1 body2)
	 ;;                  (lhs2 rhs2))
	 ;;          body1)
	 (let ((tmp* (map make-prelex-for-tmp-binding nested-lhs*)))
	   (values (append tmp*        nested-lhs* (list lhs)         tail-lhs*)
		   (append nested-rhs* tmp*        (list nested-body) tail-rhs*))))

	(else
	 (values (cons lhs tail-lhs*)
		 (cons rhs tail-rhs*)))))

    (define (%E-body lhs*^ rhs*^ body)
      (struct-case (E body)
	((bind nested-lhs* nested-rhs* nested-body)
	 ;;   (letrec* ((lhs0 rhs0)
	 ;;             (lhs1 rhs1)
	 ;;             (lhs2 rhs2))
	 ;;     (let ((lhs3 rhs3)
	 ;;           (lhs4 rhs4))
	 ;;       body))
	 ;;   ===> (letrec* ((lhs0 rhs0)
	 ;;                  (lhs1 rhs1)
	 ;;                  (lhs2 rhs2)
	 ;;                  (lhs3 rhs3)
	 ;;                  (lhs4 rhs4))
	 ;;          body)
	 (values (append lhs*^ nested-lhs*)
		 (append rhs*^ nested-rhs*)
		 nested-body))

	((recbind nested-lhs* nested-rhs* nested-body)
	 ;;   (letrec* ((lhs0 rhs0)
	 ;;             (lhs1 rhs1)
	 ;;             (lhs2 rhs2))
	 ;;     (letrec ((lhs3 rhs3)
	 ;;              (lhs4 rhs4))
	 ;;       body))
	 ;;   ===> (letrec* ((lhs0 rhs0)
	 ;;                  (lhs1 rhs1)
	 ;;                  (lhs2 rhs2)
	 ;;                  (lhs3 rhs3)
	 ;;                  (lhs4 rhs4))
	 ;;          body)
	 (values (append lhs*^ nested-lhs*)
		 (append rhs*^ nested-rhs*)
		 nested-body))

	((rec*bind nested-lhs* nested-rhs* nested-body)
	 ;;   (letrec* ((lhs0 rhs0)
	 ;;             (lhs1 rhs1)
	 ;;             (lhs2 rhs2))
	 ;;     (letrec* ((lhs3 rhs3)
	 ;;               (lhs4 rhs4))
	 ;;       body))
	 ;;   ===> (letrec* ((lhs0 rhs0)
	 ;;                  (lhs1 rhs1)
	 ;;                  (lhs2 rhs2)
	 ;;                  (lhs3 rhs3)
	 ;;                  (lhs4 rhs4))
	 ;;          body)
	 (values (append lhs*^ nested-lhs*)
		 (append rhs*^ nested-rhs*)
		 nested-body))

	(else
	 (values lhs*^ rhs*^ body))))

    #| end of module: E-REC*BIND |# )

  #| end of module: INTEGRATE-NESTED-BINDING-FORMS |# )


(module (optimize-letrec/basic)
  ;;Perform basic transformations to convert  the recordized representation of LETREC
  ;;and LETREC* forms into LET-like forms and assignments.
  ;;
  ;;The transformations performed by this module are equivalent to the following:
  ;;
  ;;   (letrec ((?var ?init) ...) . ?body)
  ;;   ==> (let ((?var (void)) ...)
  ;;         (let ((?tmp ?init) ...)
  ;;           (set! ?var ?tmp) ...
  ;;           . ?body))
  ;;
  ;;   (letrec* ((?var ?init) ...) . ?body)
  ;;   ==> (let ((?var (void)) ...)
  ;;         (set! ?var ?init) ...
  ;;         . ?body)
  ;;
  ;;   (library-letrec* ((?var ?loc ?init) ...) . ?body)
  ;;   ==> (let ((?var (void)) ...)
  ;;         (set! ?var ?init) ...
  ;;         . ?body)
  ;;
  ;;Notice that the transformation for LETREC is described also in the R5RS document.
  ;;
  (define-syntax __module_who__
    (identifier-syntax 'optimize-letrec/basic))

  ;;Make the code more readable.
  (define-syntax-rule (optimize-letrec/basic x)
    (E x))

  (define (E x)
    (struct-case x
      ((constant)
       x)

      ((typed-expr expr core-type)
       (make-typed-expr (E expr) core-type))

      ((prelex)
       (assert (prelex-source-referenced? x))
       x)

      ((assign lhs rhs)
       (assert (prelex-source-assigned? lhs))
       (make-assign lhs (E rhs)))

      ((primref)
       x)

      ((bind lhs* rhs* body)
       (if (null? lhs*)
	   (E body)
	 (make-bind lhs* (map E rhs*) (E body))))

      ((recbind lhs* rhs* body)
       (if (null? lhs*)
	   (E body)
	 (%do-recbind lhs* (map E rhs*) (E body))))

      ((rec*bind lhs* rhs* body)
       (if (null? lhs*)
	   (E body)
	 (%do-rec*bind lhs* (map E rhs*) (E body))))

      ((conditional test conseq altern)
       (make-conditional (E test) (E conseq) (E altern)))

      ((seq e0 e1)
       (make-seq (E e0) (E e1)))

      ((clambda)
       (E-clambda x))

      ((funcall rator rand*)
       (make-funcall (E rator) (map E rand*)))

      ((forcall rator rand*)
       (make-forcall rator (map E rand*)))

      (else
       (error __module_who__ "invalid expression" (unparse-recordized-code x)))))

  (define (E-clambda x)
    (struct-case x
      ((clambda label cls* cp free name)
       (make-clambda label (map E-clambda-case cls*) cp free name))))

  (define (E-clambda-case x)
    (struct-case x
      ((clambda-case info body)
       (make-clambda-case info (E body)))))

;;; --------------------------------------------------------------------

  (define (%do-rec*bind lhs* rhs* body)
    ;;A struct instance of type REC*BIND represents a form like:
    ;;
    ;;   (letrec* ((?var ?init) ...) ?body0 ?body ...)
    ;;
    ;;the transformation we do here is equivalent to constructing the following form:
    ;;
    ;;   (let ((?var (void)) ...)
    ;;     (set! ?var ?init) ...
    ;;     ?body0 ?body ...)
    ;;
    (make-bind lhs* (%make-void-constants lhs*)
      (build-assign* lhs* rhs* body)))

  (define (%do-recbind lhs* rhs* body)
    ;;A struct instance of type REC*BIND represents a form like:
    ;;
    ;;   (letrec ((?var ?init) ...) ?body0 ?body ...)
    ;;
    ;;the transformation we do here is equivalent to constructing the following form:
    ;;
    ;;   (let ((?var (void)) ...)
    ;;     (let ((?tmp ?init) ...)
    ;;       (set! ?var ?tmp) ...
    ;;       ?body0 ?body ...))
    ;;
    (let ((tmp* (map make-prelex-for-tmp-binding lhs*)))
      (make-bind lhs* (%make-void-constants lhs*)
	(make-bind tmp* rhs* (build-assign* lhs* tmp* body)))))

  #| end of module: optimize-letrec/basic |# )


(module (optimize-letrec/waddell)
  ;;Perform transformations  to convert the  recordized representation of  LETREC and
  ;;LETREC*  forms into  LET-like forms  and assignments.   This function  performs a
  ;;transformation similar (but not equal to) the one described in the [WSD] paper.
  ;;
  (define-syntax __module_who__
    (identifier-syntax 'optimize-letrec/waddell))

  (define (optimize-letrec/waddell x)
    (parametrise ((lhs-used-func  (%make-top-lhs-used-registrar-func))
		  (rhs-cplx-func  (%make-top-rhs-cplx-registrar-func)))
      (E x)))

  (module (E)

    (define (E x)
      ;;Recursively visit the recordized code X.
      ;;
      (struct-case x
	((constant)
	 x)

	((typed-expr expr core-type)
	 (make-typed-expr (E expr) core-type))

	((prelex)
	 ;;A reference to a lexical variable.
	 (register-lhs-usage! x)
	 x)

	((assign lhs rhs)
	 ;;X is  a binding assignment.  An  assignment is a reference  to the binding
	 ;;LHS and also it makes X a "complex" expression.
	 (register-lhs-usage! lhs)
	 (make-the-enclosing-rhs-complex!)
	 (make-assign lhs (E rhs)))

	((primref)
	 x)

	((bind lhs* rhs* body)
	 ;;X is a binding creation form like LET.  Do RHS* first, then BODY.
	 (if (null? lhs*)
	     (E body)
	   (let* ((rhs*^ (E* rhs*))
		  (body^ (parametrise ((lhs-used-func (%make-nonrec-lhs-used-registrar-func (lhs-used-func) lhs*)))
			   (E body))))
	     (make-bind lhs* rhs*^ body^))))

	((recbind lhs* rhs* body)
	 (if (null? lhs*)
	     (E body)
	   (%do-recbind lhs* rhs* body)))

	((rec*bind lhs* rhs* body)
	 (if (null? lhs*)
	     (E body)
	   (%do-rec*bind lhs* rhs* body)))

	((conditional test conseq altern)
	 (make-conditional (E test)
	     (E conseq)
	   (E altern)))

	((seq e0 e1)
	 (make-seq (E e0) (E e1)))

	((clambda)
	 (E-clambda x))

	((funcall)
	 (E-funcall x))

	((forcall rator rand*)
	 ;;This is a foreign function call.
	 (make-forcall rator (E* rand*)))

	(else
	 (error __module_who__ "invalid expression" (unparse-recordized-code x)))))

    (define (E* x*)
      (if (pair? x*)
	  (cons (E  (car x*))
		(E* (cdr x*)))
	'()))

    (module (E-clambda)
      ;;Process  a CLAMBDA  structure.  In  general  we just  process the  body of  a
      ;;CLAMBDA like all the  other forms, but we have to take  care of the following
      ;;cases.
      ;;
      ;;CLAMBDA arguments
      ;;-----------------
      ;;
      ;;The arguments of a CLAMBDA structure  are simple bindings, not different from
      ;;the ones defined by  a BIND structure.  So, upon entering  a CLAMBDA body, we
      ;;create  a  new  LHS-usage  registrar  function  that  avoids  inspecting  the
      ;;references to bindings defined by the arguments.
      ;;
      ;;Complexity of the enclosing expression
      ;;--------------------------------------
      ;;
      ;;We decide that nothing  that happens in the body of the  CLAMBDA can make the
      ;;enclosing RHS  expression complex; this  allows lambda RHS expressions  to be
      ;;classified as "fixable", even if they  reference or assign a binding in their
      ;;lexical contour.
      ;;
      ;;Noticing that "complex"  RHS expressions are evaluated  *after* "fixable" RHS
      ;;expressions, we can understand the following examples.
      ;;
      ;;* Here the  binding A is assigned, so  it is "complex"; but the  binding B is
      ;;  "fixable", it does not become itself complex.
      ;;
      ;;    (letrec ((a 1)
      ;;             (b (lambda () (set! a 1))))
      ;;      (b))
      ;;    ==> (bind ()
      ;;          (bind ((a_0 !#void))
      ;;            (fix ((b (lambda () (assign a_0 '1))))
      ;;              (bind ((a_1 '1))
      ;;                (seq
      ;;                  (assign a_0 a_1)
      ;;                  (funcall b))))))
      ;;
      (define (E-clambda x)
	(struct-case x
	  ((clambda label clause* cp free name)
	   (make-clambda label (map E-clambda-case clause*) cp free name))))

      (define (E-clambda-case clause)
	(struct-case clause
	  ((clambda-case info body)
	   (make-clambda-case info
			      (parametrise
				  ((lhs-used-func (%make-nonrec-lhs-used-registrar-func (lhs-used-func) (case-info-args info)))
				   (rhs-cplx-func (%make-top-rhs-cplx-registrar-func)))
				(E body))))))

      #| end of module: E-clambda |# )

    (module (E-funcall)

      (define (E-funcall x)
	(struct-case x
	  ((funcall rator rand*)
	   (let ((rator^ (E  rator))
		 (rand*^ (E* rand*)))
	     ;;This form is a function call.  In general:
	     ;;
	     ;;* We must assume it might reference assigned bindings or assign itself
	     ;;some bindings.
	     ;;
	     ;;* We  must assume that  it might  cause side effects  whose evaluation
	     ;;order must not be changed or it  might return a value which depends on
	     ;;a previously executed side effect.
	     ;;
	     ;;To avoid changing  the order (for LETREC* bindings): we  make all such
	     ;;RHS      expressions     "complex";      so      we     must      call
	     ;;MAKE-THE-ENCLOSING-RHS-COMPLEX!.  For example:
	     ;;
	     ;;   (letrec* ((a (lambda () c))
	     ;;             (b (a))
	     ;;             (c 1))
	     ;;     #f)
	     ;;
	     ;;the  call to  A in  the RHS  of B  must cause  B to  be classified  as
	     ;;"complex".  Notice that with LETREC these bindings are illegal.
	     ;;
	     ;;As  special case:  if we  recognise  the function  call as  a call  to
	     ;;primitive function  with *no*  side effects, we  can avoid  making the
	     ;;enclosing expression complex.
	     (struct-case rator^
	       ((primref primitive-function-public-name)
		(unless (memq primitive-function-public-name SIMPLE-PRIMITIVES)
		  (make-the-enclosing-rhs-complex!)))
	       (else
		(make-the-enclosing-rhs-complex!)))
	     (make-funcall rator^ rand*^)))))

      (define-constant SIMPLE-PRIMITIVES
	;;NOTE There are  many, many simple primitives.  Maybe, one  day, I will list
	;;them here.  However, notice that a primitive function is *not* simple if:
	;;
	;;* I performs side effects.
	;;
	;;*  It raises  an  exception  for whatever  reason,  including invalid  call
	;;arguments.
	;;
	;;(Marco Maggi; Mon Aug 11, 2014)
	;;
	'($fx+ $fx- $fx* $fxdiv))

      #| end of module: E-funcall |# )

    #| end of module: E |# )

;;; --------------------------------------------------------------------

  (module LHS-USAGE-FLAGS
    (%make-lhs-usage-flags
     %lhs-usage-flags-set!
     %lhs-usage-flags-ref)
    ;;This module handles values called USED-LHS-FLAGS  in the code.  Such values are
    ;;associative containers representing  a property of the LHS  of bindings defined
    ;;by  RECBIND  (LETREC) and  REC*BIND  (LETREC*).   Each container  maps  binding
    ;;indexes to flags representing left-hand side usage: the flag is true if the LHS
    ;;has  been referenced  or assigned  at least  once in  the right-hand  side init
    ;;expressions of the same lexical contour.
    ;;
    (define (%make-lhs-usage-flags lhs*)
      (make-vector (length lhs*) #f))

    (define-syntax-rule (%lhs-usage-flags-set! ?flags ?lhs-index)
      (vector-set! ?flags ?lhs-index #t))

    (define-syntax-rule (%lhs-usage-flags-ref ?flags ?lhs-index)
      (vector-ref ?flags ?lhs-index))

    #| end of module: LHS-USAGE-FLAGS |# )

;;; --------------------------------------------------------------------

  (module RHS-COMPLEXITY-FLAGS
    (%make-rhs-complexity-flags
     %rhs-complexity-flags-set!
     %rhs-complexity-flags-ref)
    ;;This module handles values called CPLX-RHS-FLAGS  in the code.  Such values are
    ;;associative containers representing  a property of the RHS  of bindings defined
    ;;by  RECBIND  (LETREC) and  REC*BIND  (LETREC*).   Each container  maps  binding
    ;;indexes to flags  representing right-hand side init  expression complexity: the
    ;;flag is true if the RHS expression is  "complex", that is: it may assign one of
    ;;the LHS in the same lexical contour (we  cannot be sure if it actually does it,
    ;;nor of which bindings are mutated), or it performs a complex function call.
    ;;
    (define (%make-rhs-complexity-flags rhs*)
      (make-vector (length rhs*) #f))

    (define-syntax-rule (%rhs-complexity-flags-set! ?flags ?rhs-index)
      (vector-set! ?flags ?rhs-index #t))

    (define-syntax-rule (%rhs-complexity-flags-ref ?flags ?rhs-index)
      (vector-ref ?flags ?rhs-index))

    #| end of module: RHS-COMPLEXITY-FLAGS |# )

;;; --------------------------------------------------------------------

  (define (%make-top-lhs-used-registrar-func)
    ;;Build  and  return a  top  variable-usage  registrar function.   Top  registrar
    ;;functions are generated only when starting to process a whole input expression,
    ;;not when entering a nested subexpression representing a binding form.
    ;;
    ;;Given the  way the  registrar functions  are implemented:  if this  function is
    ;;actually applied to a PRELEX structure,  it means such PRELEX represents a free
    ;;variable in the whole expression; this is an error.  If this error is found: it
    ;;means  that the  original  input  expression is  incorrect;  this should  never
    ;;happen.
    ;;
    (lambda (prel)
      (assertion-violation __module_who__ "found free variable reference" prel)))

  (module (%make-nonrec-lhs-used-registrar-func
	   %make-recbind-lhs-used-registrar-func)

    (define (%make-nonrec-lhs-used-registrar-func outer-lhs-usage-registrar! prel*)
      ;;Build and return a new nonrecursive-binding variable-usage registrar function
      ;;wrapping the  one given  as argument.  The  returned registrar  function will
      ;;avoid attempting to mark as "used" the PRELEX structures in the list PREL*.
      ;;
      ;;The  nonrecursive-binding  registrar  functions  are used  to  avoid  marking
      ;;binding  references  created  by non-RECBIND  (non-LETREC)  and  non-REC*BIND
      ;;(non-LETREC*) binding forms; so it must be used when entering: a BIND form; a
      ;;CLAMBDA subexpression body; a RECBIND or REC*BIND body.
      ;;
      ;;For efficiency reasons: a  nonrecursive-binding variable-usage function marks
      ;;a PRELEX  structure as  "used" only  once; we  do this  by avoiding  to apply
      ;;OUTER-LHS-USAGE-REGISTRAR!  to PREL when PREL is already in the TABLE.
      ;;
      ;;NOTE At the call site of the  registrar function: we do know for which PRELEX
      ;;struct we call it.
      ;;
      (define-constant TABLE (make-eq-hashtable))
      (for-each (lambda (prel)
		  (hashtable-set! TABLE prel #t))
	prel*)
      (lambda (prel)
	(with-unseen-prel (prel TABLE)
	  (outer-lhs-usage-registrar! prel))))

    (define (%make-recbind-lhs-used-registrar-func outer-lhs-usage-registrar! prel* used-lhs-flags)
      ;;Build and  return a  new recursive-binding variable-usage  registrar function
      ;;wrapping the one given as argument.
      ;;
      ;;For efficiency reasons: a  recursive-binding variable-usage registrar marks a
      ;;PRELEX  structure as  "used"  only once;  we  do this  by  avoiding to  apply
      ;;OUTER-LHS-USAGE-REGISTRAR!  to PREL when PREL is already in the TABLE.
      ;;
      ;;We need  a registrar  function for  each recursive-binding  lexical countour;
      ;;*not* one for each binding.
      ;;
      ;;NOTE At the call site of the  registrar function: we do know for which PRELEX
      ;;struct  we  call it;  for  this  reason we  can  compute  at the  moment  the
      ;;LHS-INDEX.
      ;;
      (define-constant TABLE (make-eq-hashtable))
      (lambda (prel)
	(with-unseen-prel (prel TABLE)
	  ;;EFFICIENCY NOTE  Searching the PRELEX struct  PREL in the list  of PRELEX
	  ;;structs  PREL* is  not  very  efficient.  The  list  can  be "long";  for
	  ;;example, PREL*  can be the  list of top  level function definitions  in a
	  ;;LIBRARY form.  Can we make it better with a cheap data structure?  (Marco
	  ;;Maggi; Tue Aug 12, 2014)
	  (cond ((%find-index prel prel*)
		 => (lambda (lhs-index)
		      (import LHS-USAGE-FLAGS)
		      (%lhs-usage-flags-set! used-lhs-flags lhs-index)
		      ;;If we are here the  PRELEX struct PREL represents a reference
		      ;;to LETREC or LETREC* binding.  If  we are processing a RHS of
		      ;;the same  lexical contour: we want  this RHS to be  marked as
		      ;;"complex".
		      ;;
		      ;;Example (invalid for LETREC*):
		      ;;
		      ;;  (letrec ((a 1)
		      ;;           (b a))
		      ;;    #f)
		      ;;
		      ;;must be transformed into:
		      ;;
		      ;;  (bind ((a_0 '1))
		      ;;    (bind ((b_0 a_0))
		      ;;      (fix ()
		      ;;        (bind ()
		      ;;          '#f))))
		      ;;
		      ;;in which  the binding for  B is "complex".
		      (make-the-enclosing-rhs-complex!)))
		(else
		 (outer-lhs-usage-registrar! prel))))))

    (define-syntax (with-unseen-prel stx)
      (syntax-case stx ()
	;;Evaluate ?BODY if ?PREL is *not* already in ?TABLE.
	((_ (?prel ?table) . ?body)
	 (and (identifier? #'?prel)
	      (identifier? #'?table))
	 #'(unless (hashtable-ref ?table ?prel #f)
	     (hashtable-set! ?table ?prel #t)
	     . ?body))))

    (case-define %find-index
      ;;Search ITEM  in the proper list  ELL; when found return  its index, otherwise
      ;;return false.
      ;;
      ((item ell)
       (%find-index item ell 0))
      ((item ell counter)
       (cond ((null? ell)
	      #f)
	     ((eq? item (car ell))
	      counter)
	     (else
	      (%find-index item (cdr ell) (fxadd1 counter))))))

    #| end of module |# )

  (define-constant lhs-used-func
    (make-parameter (%make-top-lhs-used-registrar-func)))

  (define-syntax-rule (register-lhs-usage! ?prel)
    ((lhs-used-func) ?prel))

;;; --------------------------------------------------------------------

  (define-syntax-rule (%make-top-rhs-cplx-registrar-func)
    ;;Return a top thunk to be used as expression complexity registrar.  The returned
    ;;thunk is  to be used  as outer thunk when  entering whole input  expressions or
    ;;CLAMBDA bodies.
    ;;
    void)

  (define (%make-recbind-rhs-cplx-registrar-func outer-rhs-cplx-registrar-func cplx-rhs-flags rhs-index)
    ;;Build and  return a new  thunk to be  used as expression  complexity registrar,
    ;;wrapping the  one given as  argument.  Called  to register that  the right-hand
    ;;side init expression with index RHS-INDEX in the container CPLX-RHS-FLAGS is to
    ;;be classified "complex"; also make the outer expression complex.
    ;;
    ;;We really need one of these thunks for each RHS in a recbind lexical contour.
    ;;
    ;;NOTE At the call site of the registrar function: we do *not* know for which RHS
    ;;expression struct we call  it; for this reason we need  to generate a registrar
    ;;function closed upon RHS-INDEX.
    ;;
    (lambda ()
      (import RHS-COMPLEXITY-FLAGS)
      (%rhs-complexity-flags-set! cplx-rhs-flags rhs-index)
      (outer-rhs-cplx-registrar-func)))

  (define-constant rhs-cplx-func
    (make-parameter (%make-top-lhs-used-registrar-func)))

  (define-syntax-rule (make-the-enclosing-rhs-complex!)
    ((rhs-cplx-func)))

;;; --------------------------------------------------------------------

  (module (%do-recbind %do-rec*bind)

    (define-syntax-rule (%do-recbind ?lhs* ?rhs* ?body)
      (%true-do-recbind ?lhs* ?rhs* ?body #t))

    (define-syntax-rule (%do-rec*bind ?lhs* ?rhs* ?body)
      (%true-do-recbind ?lhs* ?rhs* ?body #f))

    (define (%true-do-recbind lhs* rhs* body letrec?)
      ;;If  the core  language form  we are  processing is  a RECBIND  representing a
      ;;LETREC: the  argument LETREC?   is true.   If the core  language form  we are
      ;;processing is  a REC*BIND  representing a LETREC*:  the argument  LETREC?  is
      ;;false.
      ;;
      (import LHS-USAGE-FLAGS RHS-COMPLEXITY-FLAGS)
      (let* ((used-lhs-flags (%make-lhs-usage-flags      lhs*))
	     (cplx-rhs-flags (%make-rhs-complexity-flags rhs*))
	     (rhs*^          (parametrise
				 ((lhs-used-func (%make-recbind-lhs-used-registrar-func (lhs-used-func) lhs* used-lhs-flags)))
			       (E-rhs* rhs* cplx-rhs-flags)))
	     (body^          (parametrise
				 ((lhs-used-func (%make-nonrec-lhs-used-registrar-func  (lhs-used-func) lhs*)))
			       (E body))))
	(receive (simple.lhs* simple.rhs* fixable.lhs* fixable.rhs* complex.lhs* complex.rhs*)
	    (%partition-rhs* lhs* rhs*^ used-lhs-flags cplx-rhs-flags)
	  (%make-bind simple.lhs* simple.rhs*
	    (%make-bind complex.lhs* (%make-void-constants complex.lhs*)
	      (%make-fix fixable.lhs* fixable.rhs*
			 (if letrec?
			     ;;It is  a RECBIND  and LETREC:  no order  enforced when
			     ;;evaluating COMPLEX.RHS*.
			     (let ((tmp* (map make-prelex-for-tmp-binding complex.lhs*)))
			       (%make-bind tmp* complex.rhs*
				 (build-assign* complex.lhs* tmp* body^)))
			   ;;It  is  a  REC*BIND  and LETREC*:  order  enforced  when
			   ;;evaluating COMPLEX.RHS*.
			   (build-assign* complex.lhs* complex.rhs* body^))))))))

    (define (E-rhs* rhs* cplx-rhs-flags)
      ;;Process RHS* and return a list of  struct instances which is meant to replace
      ;;the  original RHS*.   This function  has the  purpose of  applying E  to each
      ;;struct  in RHS*;  in  so  doing it  will  fill  appropriately the  containers
      ;;USED-LHS-FLAGS and CPLX-RHS-FLAGS.
      ;;
      (%map-in-order-with-index
	  (lambda (binding-index rhs)
	    (parametrise
		((rhs-cplx-func (%make-recbind-rhs-cplx-registrar-func (rhs-cplx-func) cplx-rhs-flags binding-index)))
	      (E rhs)))
	0 rhs*))

    (case-define %partition-rhs*
      ((lhs* rhs* used-lhs-flags cplx-rhs-flags)
       (%partition-rhs* lhs* rhs* used-lhs-flags cplx-rhs-flags 0))
      ((lhs* rhs* used-lhs-flags cplx-rhs-flags binding-index)
       ;;Non-tail  recursive  function.  Make  use  of  the  data in  the  containers
       ;;USED-LHS-FLAGS and  CPLX-RHS-FLAGS to  partition the bindings  into: simple,
       ;;complex, fixable.  (RHS* is not visited here.)
       ;;
       ;;Return 6 values:
       ;;
       ;;SIMPLE.LHS*, SIMPLE.RHS*
       ;;   Simple  bindings.  SIMPLE.LHS is never  assigned in all the  RHS* and the
       ;;    associated SIMPLE.RHS  is a  simple expression:  it never  references an
       ;;   SIMPLE.LHS* and it does not call any function.
       ;;
       ;;COMPLEX.LHS*, COMPLEX.RHS*
       ;;   Complex bindings.  Lists of LHS and RHS for which either we know that the
       ;;   LHS has been assigned, or we know that the RHS may have assigned an LHS.
       ;;
       ;;FIXABLE.LHS*, FIXABLE.RHS*
       ;;    Fixable  bindings.   Lists  of LHS  and  RHS  representing  non-assigned
       ;;   bindings whose RHS is a CLAMBDA.
       ;;
       (import LHS-USAGE-FLAGS RHS-COMPLEXITY-FLAGS)
       (if (pair? lhs*)
	   (receive (simple.lhs* simple.rhs* fixable.lhs* fixable.rhs* complex.lhs* complex.rhs*)
	       (%partition-rhs* (cdr lhs*) (cdr rhs*) used-lhs-flags cplx-rhs-flags (fxadd1 binding-index))
	     (let ((lhs (car lhs*))
		   (rhs (car rhs*)))
	       (cond ((prelex-source-assigned? lhs)
		      ;;This binding is "complex".  It does  not matter if the RHS is
		      ;;a  CLAMBDA structure:  the  fact that  it  is assigned  takes
		      ;;precedence when deciding how to classify it.
		      (values simple.lhs* simple.rhs*
			      fixable.lhs* fixable.rhs*
			      (cons lhs complex.lhs*) (cons rhs complex.rhs*)))
		     ((clambda? rhs)
		      ;;This binding is "fixable".
		      (values simple.lhs* simple.rhs*
			      (cons lhs fixable.lhs*) (cons rhs fixable.rhs*)
			      complex.lhs* complex.rhs*))
		     ((or (%lhs-usage-flags-ref      used-lhs-flags binding-index)
			  (%rhs-complexity-flags-ref cplx-rhs-flags binding-index))
		      ;;This binding is "complex".
		      (values simple.lhs* simple.rhs*
			      fixable.lhs* fixable.rhs*
			      (cons lhs complex.lhs*) (cons rhs complex.rhs*)))
		     (else
		      ;;This binding is "simple".
		      (values (cons lhs simple.lhs*) (cons rhs simple.rhs*)
			      fixable.lhs* fixable.rhs*
			      complex.lhs* complex.rhs*))
		     )))
	 (values '() '() '() '() '() '()))))

    #| end of module: %DO-RECBIND %DO-REC*BIND |# )

;;; --------------------------------------------------------------------

  (define (%make-bind lhs* rhs* body)
    (if (null? lhs*)
	body
      (make-bind lhs* rhs* body)))

  (define (%make-fix lhs* rhs* body)
    (if (null? lhs*)
	body
      (make-fix lhs* rhs* body)))

  #| end of module: OPTIMIZE-LETREC/WADDELL |# )


(module (optimize-letrec/scc)
  ;;Perform transformations  to convert the  recordized representation of  LETREC and
  ;;LETREC*  forms into  LET-like forms  and assignments.   This function  performs a
  ;;transformation similar (but not equal to) the one described in the [GD] paper.
  ;;
  ;;NOTE  Internally this  compiler pass  makes use  of the  field OPERAND  of PRELEX
  ;;structures representing recursive bindings; however,  such fields are reset to #f
  ;;before this compiler pass returns to the caller.
  ;;
  (define-syntax __module_who__
    (identifier-syntax 'optimize-letrec/scc))

  (define (optimize-letrec/scc x)
    (receive-and-return (x)
	(E x (%make-top-<binding> #t))
      ;;(debug-print (unparse-recordized-code x))
      (void)))

;;; --------------------------------------------------------------------

  (define-struct <binding>
    ;;A structure of  this type is created  for every binding in  a recursive binding
    ;;form:
    ;;
    ;;   (letrec ((?lhs0 ?rhs0)    ; -> binding, serial index 0
    ;;            (?lhs1 ?rhs1)    ; -> binding, serial index 1
    ;;            (?lhs2 ?rhs2))   ; -> binding, serial index 2
    ;;     ?body)
    ;;
    ;;and such structure  is considered the "current <BINDING>" while  we process the
    ;;corresponding  RHS  expression.   In  general,  we  consider  every  expression
    ;;processed by  this compiler pass  as having a <BINDING>  structure representing
    ;;its properties.
    ;;
    (serial
		;When this struct  instance does not represent  a recursive binding's
		;RHS  expression:  set  to  false.  Otherwise:  a  zero-based  fixnum
		;representing the serial  index of the current RHS  expression in the
		;list of bindings.
     lhs
		;When this struct  instance does not represent  a recursive binding's
		;RHS  expression:  set  to  false.   Otherwise:  a  PRELEX  structure
		;representing the LHS of the binding.
     rhs
		;When this struct  instance does not represent  a recursive binding's
		;RHS expression:  set to false.  Otherwise:  a structure representing
		;the RHS expression of the binding.
     complex
		;Boolean.  When this  struct instance does not  represent a recursive
		;binding's  RHS expression:  set to  true.  Otherwise:  true if  this
		;binding is classified as "complex", otherwise false.
		;
		;A value for  this field is always produced, but  it is consumed only
		;when inserting  graph edges representing the  constraints of ordered
		;evaluation for  RHSs in  REC*BIND bindings; if  the binding  form is
		;RECBIND: the value of this field is not consumed.
		;
		;Specifically, a binding is "complex" if:
		;
		;* It  calls a  function or  a foreign  function, which,  in general,
		;might perform  a side effect  or return a  result that depends  on a
		;previously performed side effect.
		;
		;* Its RHS expression references a binding that is assigned somewhere
		;(no matter if the assignment happens  in the RHS itself or somewhere
		;else).
		;
		;* Its RHS expression assigns a binding.
		;
		;so a binding is *not* "complex" if:
		;
		;* It  does *not* reference any  binding, so the order  in which this
		;RHS  expression is  evaluated with  respect to  the others  does not
		;matter.
		;
		;* It  references only  UNassigned bindings, so  the only  thing that
		;matters  is that  this  RHS is  evaluated  after the  initialisation
		;expression of the referenced bindings.
		;
		;For example, in the following form A, B and C are all non-complex:
		;
		;   (rec*bind ((A 1)
		;              (B 2)
		;              (C A))
		;     ?body)
		;
		;the RHS of C  must be evaluated after the RHS of A,  but there is no
		;need to evaluate it before the RHS of B.
     prev
		;When this struct  instance does not represent  a recursive binding's
		;RHS expression: set  to true.  Otherwise: a struct  instance of type
		;<BINDING> representing the enclosing binding's properties.
		;
		;The  value of  this  field  references a  <BINDING>  in the  closest
		;uplevel recursive binding form; for example:
		;
		;   (recbind ((A (recbind ((B ?rhs))
		;                  ?body1)))
		;     ?body2)
		;
		;the <BINDING> of B has the <BINDING> of A in its PREV field; another
		;example:
		;
		;   (recbind ((A (bind ((B (recbind ((C ?rhs))
		;                            ?body1)))
		;                  ?body2)))
		;     ?body3)
		;
		;the <BINDING>  of C has  the <BINDING> of A  in its PREV  field, the
		;binding B does  not matter because it is defined  by a non-recursive
		;binding form.
		;
		;Two <BINDING>  structures defined at  the same lexical  contour will
		;have the same <BINDING> struct in their PREV field.
     successor*
		;When this struct  instance does not represent  a recursive binding's
		;RHS expression: set to null.  Otherwise: a list of <BINDING> structs
		;whose RHS expression must be  evaluated before the RHS expression of
		;this instance.  In the directed  graph of binding dependencies: this
		;list  represents  the  destination   of  edges  outgoing  from  this
		;instance.
		;
		;The value of  this field is produced while  classifying the bindings
		;from  a single  RECBIND  or  REC*BIND form  and  it  is consumed  in
		;Tarjan's algorithm.
     index
		;False or a non-negative fixnum.  This field is used only in Tarjan's
		;algorithm.  Upon entering the visit to this vertex: it is the serial
		;index of  this binding in  the depth-first visit.  Upon  exiting the
		;visit to this vertex: it is the minimum between serial index of this
		;binding and the serial indices of the successor vertexes.
     done
		;Boolean.    This  field   is  used   only  in   Tarjan's  algorithm.
		;Initialised  to false;  it  is  set to  true  when  this binding  is
		;included into a  cluster of SCCs, and so it  cannot be included into
		;another cluster.
     ))

  (define (%make-top-<binding> enclosing-binding)
    (let ((complex	#t)
	  (successor*   '()))
      (make-<binding> #f #f #f complex enclosing-binding successor* #f #f)))

  (define (<binding>-add-edge-from/to! binding.src binding.dst)
    ;;Insert a  graph edge from  BINDING.SRC to BINDING.DST,  if it does  not already
    ;;exists.
    ;;
    (let ((successor* ($<binding>-successor* binding.src)))
      (unless (memq binding.dst successor*)
	($set-<binding>-successor*! binding.src (cons binding.dst successor*)))))

;;; --------------------------------------------------------------------

  (module (E)

    (define (E x enclosing-binding)
      ;;X is the recordised code to  traverse.  ENCLOSING-BINDING is a struct of type
      ;;<BINDING>.
      ;;
      (struct-case x
	((constant)
	 x)

	((typed-expr expr core-type)
	 (make-typed-expr (E expr enclosing-binding) core-type))

	((prelex)
	 #;(assert (prelex-source-referenced? x))
	 (%mark-successor x enclosing-binding)
	 ;;If the enclosing binding references an assigned binding...
	 (when (prelex-source-assigned? x)
	   ;;... it is "complex".
	   (%mark-complex! enclosing-binding))
	 x)

	((assign lhs rhs)
	 #;(assert (prelex-source-assigned? lhs))
	 (%mark-successor lhs enclosing-binding)
	 ;;The enclosing binding assigns a binding, so it is "complex".
	 (%mark-complex! enclosing-binding)
	 (make-assign lhs (E rhs enclosing-binding)))

	((primref)
	 x)

	((bind lhs* rhs* body)
	 (if (null? lhs*)
	     (E body enclosing-binding)
	   (make-bind lhs* (E* rhs* enclosing-binding) (E body enclosing-binding))))

	((recbind lhs* rhs* body)
	 (if (null? lhs*)
	     (E body enclosing-binding)
	   (E-recbind lhs* rhs* body enclosing-binding)))

	((rec*bind lhs* rhs* body)
	 (if (null? lhs*)
	     (E body enclosing-binding)
	   (E-rec*bind lhs* rhs* body enclosing-binding)))

	((conditional test conseq altern)
	 (make-conditional (E test enclosing-binding) (E conseq enclosing-binding) (E altern enclosing-binding)))

	((seq e0 e1)
	 (make-seq (E e0 enclosing-binding) (E e1 enclosing-binding)))

	((clambda)
	 (E-clambda x enclosing-binding))

	((funcall rator rand*)
	 ;;This function call might: assign a binding, reference an assigned binding,
	 ;;perform  a side  effect,  return a  value which  depends  on a  previously
	 ;;performed side effect; so it is "complex".
	 (%mark-complex! enclosing-binding)
	 (make-funcall (E rator enclosing-binding) (E* rand* enclosing-binding)))

	((forcall rator rand*)
	 ;;This foreign function call might:  assign a binding, reference an assigned
	 ;;binding,  perform  a side  effect,  return  a  value  which depends  on  a
	 ;;previously performed side effect; so it is "complex".
	 (%mark-complex! enclosing-binding)
	 (make-forcall rator (E* rand* enclosing-binding)))

	(else
	 (error __module_who__ "invalid expression" (unparse-recordized-code x)))))

    (define (E* x* enclosing-binding)
      (map (lambda (x)
	     (E x enclosing-binding))
	x*))

    (define (E-clambda x enclosing-binding)
      ;;Apply E to each clause's body.
      ;;
      (struct-case x
	((clambda label clause* cp free name)
	 ;;FIXME Why do we introduce a <binding> in the hierarchy here?  Example:
	 ;;
	 ;;   (recbind ((A 1)
	 ;;             (B (lambda ()
	 ;;                  (recbind ((C ?rhs-C)
	 ;;                            (D ?rhs-D))
	 ;;                    A))))
	 ;;     ?body)
	 ;;
	 ;;the <binding> structs  of C and D  have a "top" <binding>  as PREV, rather
	 ;;than the <binding> of B.  So what?  (Marco Maggi; Wed Aug 20, 2014)
	 ;;
	 (let ((top-binding (%make-top-<binding> enclosing-binding)))
	   (make-clambda label (map (lambda (clause)
				      (struct-case clause
					((clambda-case info body)
					 (make-clambda-case info (E body top-binding)))))
				 clause*)
			 cp free name)))))

    (define (%mark-complex! bc)
      ;;BC must be  a struct instance of  type <BINDING>.  Mark as  complex BC itself
      ;;and, recursively, its enclosing binding in the field PREV.
      ;;
      (unless ($<binding>-complex bc)
	($set-<binding>-complex! bc #t)
	(%mark-complex! ($<binding>-prev bc))))

    (define (%mark-successor prel enclosing-binding)
      ;;PREL is a  struct instance of type PRELEX appearing  in reference position or
      ;;assignment position.
      ;;
      ;;ENCLOSING-BINDING must  be a struct  instance of type  <BINDING> representing
      ;;the properties of the enclosing recursive binding.
      ;;
      ;;If PREL is a PRELEX  structure representing a recursive binding: PREL.BINDING
      ;;is the <BINDING>  struct representing the properties of  the binding.  Search
      ;;the hierarchy of  nested "enclosing <BINDING>" structures  until an enclosing
      ;;binding is  found which is  at the same lexical  contour of the  one defining
      ;;PREL; add a  dependency edge from such enclosing binding  to the one defining
      ;;PREL.  Return unspecified values.
      ;;
      ;;For example, given:
      ;;
      ;;   (recbind ((A 1)
      ;;             (B A))
      ;;     ?body)
      ;;
      ;;when this  function is  called for  the PRELEX A  in reference  position: the
      ;;<BINDING> of  B is the "enclosing  <BINDING>" at the same  lexical contour of
      ;;the one defining A, so we add the graph edge:
      ;;
      ;;   B --> A
      ;;
      ;;Another example, given:
      ;;
      ;;   (recbind ((A 1)
      ;;             (B (recbind ((C 2)
      ;;                          (D A))
      ;;                  ?body)))
      ;;     ?body)
      ;;
      ;;when this  function is  called for  the PRELEX A  in reference  position: the
      ;;<BINDING> of  B is the "enclosing  <BINDING>" at the same  lexical contour of
      ;;the one defining A, so we add the graph edge:
      ;;
      ;;   B --> A
      ;;
      ;;Yet another example, given:
      ;;
      ;;   (recbind ((A (lambda () A)))
      ;;     ?body)
      ;;
      ;;when this  function is  called for  the PRELEX A  in reference  position: the
      ;;<binding> of  A is the "enclosing  <binding>" at the same  lexical contour of
      ;;the one defining A, so we add the graph edge:
      ;;
      ;;   A --> A
      ;;
      ;;NOTE How do we recognise two <BINDING> structures defined at the same lexical
      ;;contour?  They have the same <BINDING> struct in their PREV field.
      ;;
      (cond ((prelex-operand prel)
	     => (lambda (prel.binding)
		  (let ((lb (let-constants ((prel.binding.prev ($<binding>-prev prel.binding)))
			      ;;In   the  hierarchy   of  ENCLOSING-BINDING   find  a
			      ;;<BINDING> having the same PREV of PREL.BINDING.
			      (let loop ((EC enclosing-binding))
				(let ((EC.prev ($<binding>-prev EC)))
				  (if (eq? EC.prev prel.binding.prev)
				      ;;Fine:  EC  is  defined at  the  same  lexical
				      ;;contour of PREL.BINDING.
				      EC
				    (loop EC.prev)))))))
		    (<binding>-add-edge-from/to! lb prel.binding))))))

    #| end of module: E |# )

;;; --------------------------------------------------------------------

  (module (E-recbind E-rec*bind)

    (define (E-recbind lhs* rhs* body bc)
      (%do-recbind lhs* rhs* body bc #f))

    (define (E-rec*bind lhs* rhs* body bc)
      (%do-recbind lhs* rhs* body bc #t))

    (define (%do-recbind lhs* rhs* body enclosing-binding ordered?)
      ;;LHS*  is a  list  of PRELEX  structures representing  the  left-hand side  of
      ;;recursive  binding forms.   RHS* is  a  list of  structures representing  the
      ;;right-hand side expressions of recursive  binding forms.  BODY is a structure
      ;;representing the body of the recursive binding form.
      ;;
      ;;ENCLOSING-BINDING  is  an  instance  of  struct  <BINDING>  representing  the
      ;;properties of the enclosing expression.
      ;;
      ;;ORDERED? is true the RHS* expression must be evaluated in order.
      ;;
      (let ((binding* (%make-bindings lhs* rhs* enclosing-binding)))
	;;Process  each right-hand  side  expression using  the associated  <BINDING>
	;;struct as "enclosing binding properties descriptor".
	(for-each (lambda (b)
		    ($set-<binding>-rhs! b (E ($<binding>-rhs b) b)))
	  binding*)
	;;Reset to false  the field OPERAND in the LHS*  PRELEX structures that where
	;;used by %MAKE-BINDINGS and %MARK-SUCCESSOR.
	(for-each (lambda (x)
		    (set-prelex-operand! x #f))
	  lhs*)
	(let ((body^ (E body enclosing-binding)))
	  (when ordered?
	    (insert-order-edges! binding*))
	  (gen-letrecs (tarjan-algorithm binding*) ordered? body^))))

    (define (%make-bindings lhs* rhs* enclosing-binding)
      ;;Return a  list of <BINDING>  struct instances representing the  properties of
      ;;the bindings in the lists LHS* and RHS*.
      ;;
      ;;LHS*  is a  list  of PRELEX  structures representing  the  left-hand side  of
      ;;recursive  binding forms.   RHS* is  a  list of  structures representing  the
      ;;right-hand side expressions of recursive binding forms.
      ;;
      ;;ENCLOSING-BINDING  is an  instance  of <BINDING>  structure representing  the
      ;;properties of the enclosing expression.
      ;;
      ;;For every  PRELEX struct in  LHS*: store in  its OPERAND field  the <BINDING>
      ;;struct representing its properties.
      ;;
      (%map-in-order-with-index
	  (lambda (serial-idx lhs rhs)
	    (receive-and-return (binding)
		(let ((complex		#f)
		      (successor*	'())
		      (index		#f)
		      (done		#f))
		  (make-<binding> serial-idx lhs rhs complex enclosing-binding successor* index done))
	      (set-prelex-operand! lhs binding)))
	0 lhs* rhs*))

    (module (insert-order-edges!)
      ;;If the recursive binding  form is a REC*BIND: the order  of evaluation of the
      ;;RHS expressions must be preserved if it  depends on some side effect; in this
      ;;module we represent such constraints by inserting graph edges.
      ;;
      ;;In general,  we might just assign  an edge between each  successive bindings;
      ;;for example, given:
      ;;
      ;;   (rec*bind ((A ?rhs-A) (B ?rhs-B) (C ?rhs-C) (D ?rhs-D)) ?body)
      ;;
      ;;we may insert the edges:
      ;;
      ;;   A <-- B <-- C <-- D
      ;;
      ;;meaning that the RHS  of A must be evaluated before the RHS  of B, which must
      ;;be evaluated before the  RHS of C, which must be evaluated  before the RHS of
      ;;D; but this  would add unrequired constraints if some  of the RHS expressions
      ;;do not depend on any side effect and bindings; for example if ?RHS-B above is
      ;;non-complex, we can just add the edges:
      ;;
      ;;   A <-- C <-- D
      ;;
      ;;When  entering here  we have  already added  edges representing  the variable
      ;;reference dependencies  between bindings;  so, here, we  add an  edge between
      ;;successive bindings only between bindings having a "complex" dependency, that
      ;;is:  only  if both  the  source  and destination  bindings  of  the edge  are
      ;;classified as "complex".
      ;;
      (define (insert-order-edges! binding*)
	;;Add  edges  between  "complex"  <BINDING>  structures.   If  there  are  no
	;;"complex" bindings: do nothing.  Return unspecified values.
	;;
	(when (pair? binding*)
	  (let ((B (car binding*)))
	    (if (%complex-binding? B)
		(%mark B (cdr binding*))
	      (insert-order-edges! (cdr binding*))))))

      (define (%mark previous-B binding*)
	(when (pair? binding*)
	  (let ((B (car binding*)))
	    (if (%complex-binding? B)
		(begin
		  ;;Set "previous-B" as dependency for B, if it is not already.
		  #;(assert (%complex-binding? previous-B))
		  (<binding>-add-edge-from/to! B previous-B)
		  (%mark B (cdr binding*)))
	      ;;Skip B and inspect the next.
	      (%mark previous-B (cdr binding*))))))

      (define (%complex-binding? B)
	(or ($<binding>-complex B)
	    ($prelex-source-assigned? ($<binding>-lhs B))))

      #| end of module: INSERT-ORDER-EDGES! |# )

    #| end of module: DO-RECBIND |# )

;;; --------------------------------------------------------------------

  (module (gen-letrecs)

    (define (gen-letrecs scc* ordered? binding-form-body)
      ;;SCC* is a list  of sublists, each sublist being a  list of <BINDING> structs;
      ;;SCC* is a partition  of the bindings from a single  RECBIND or REC*BIND form,
      ;;in which each  sublist represents a cluster of  Strongly Connected Components
      ;;(SCCs).
      ;;
      ;;ORDERED? is true if the original binding form is REC*BIND, it is false if the
      ;;binding form is RECBIND.
      ;;
      (receive (outer-fixable* outer-body)
	  (%fold-right/1-list/2-retvals
	      (lambda (scc fixable* body)
		(gen-single-letrec scc fixable* body ordered?))
	    '() ;fixable*
	    binding-form-body
	    scc*)
	(mkfix outer-fixable* outer-body)))

    (define (mkfix binding* body)
      (if (null? binding*)
	  body
	(make-fix (map <binding>-lhs binding*)
	    (map <binding>-rhs binding*)
	  body)))

    (module (gen-single-letrec)

      (define (gen-single-letrec scc fixable* body ordered?)
	;;Generate binding forms for a single SCC.
	;;
	;;SCC is  a list  of <BINDING>  structures representing  a single  cluster of
	;;Strongly Connected Components.
	;;
	;;FIXABLE* is  null or  a list of  <BINDING> structures  representing fixable
	;;bindings, leftovers  from the  previously processed  SCC.  Notice  that the
	;;order of  <BINDINGS> in  the FIXABLE*  list does not  matter: they  are all
	;;lambda RHS and will end in the same FIX structure.
	;;
	;;BODY is a structure representing the body of the recursive binding form.
	;;
	;;ORDERED?  is true if the RHS  expressions of the binding form classified as
	;;"complex" must be evaluated in the given order.
	;;
	;;Return 2 values: null or a list of "fixable" bindings to be processed along
	;;with the outer  SCC; recordised code representing the  result of processing
	;;this SCC.
	;;
	;;NOTE The reason we collect "fixable" bindings is that we want forms like:
	;;
	;;   (fix ((?lhs0 ?rhs0))
	;;     (fix ((?lhs1 ?rhs1))
	;;       (fix ((?lhs2 ?rhs2))
	;;         ?body)))
	;;
	;;to be collapsed into:
	;;
	;;   (fix ((?lhs0 ?rhs0)
	;;         (?lhs1 ?rhs1)
	;;         (?lhs2 ?rhs2))
	;;     ?body)
	;;
	(if (null? (cdr scc))
	    ;;In this cluster there is a single binding.
	    (let ((B (car scc)))
	      (cond ((%fixable-binding? B)
		     ;;We will process this <BINDING> along with the outer SCC.
		     (values (cons B fixable*) body))
		    ((not (memq B ($<binding>-successor* B)))
		     ;;Return as second value:
		     ;;
		     ;;   (bind ((B.lhs B.rhs))
		     ;;     (fix ((?fixable.lhs ?fixable.rhs) ...)
		     ;;       ?body))
		     ;;
		     ;;where  the   "fixable"  bindings   are  the   ones  previously
		     ;;collected.
		     (values '() (make-bind (list ($<binding>-lhs B))
				     (list ($<binding>-rhs B))
				   (mkfix fixable* body))))
		    (else
		     ;;Return as second value:
		     ;;
		     ;;   (bind ((B.lhs '#!void))
		     ;;     (assign B.lhs B.rhs)
		     ;;     (fix ((?fixable.lhs ?fixable.rhs) ...)
		     ;;       ?body))
		     ;;
		     ;;where  the   "fixable"  bindings   are  the   ones  previously
		     ;;collected.
		     (values '() (make-bind (list ($<binding>-lhs B))
				     (%make-void-constants '(#f))
				   (mk-assign-seq scc (mkfix fixable* body)))))))
	  ;;In this cluster there are multiple bindings.
	  (receive (inner-fixable* complex*)
	      (partition %fixable-binding? scc)
	    (let ((fixable*^ (append inner-fixable* fixable*)))
	      (if (null? complex*)
		  ;;All the bindings in this SCC are "fixable".
		  (values fixable*^ body)
		;;Return as second value:
		;;
		;;   (bind ((?complex.lhs '#!void) ...)
		;;     (fix ((?fixable.lhs ?fixable.rhs) ...)
		;;       (assign ?complex.lhs ?complex.rhs) ...
		;;       ?body))
		;;
		(values '() (let ((complex*^ (if ordered? (%sort-bindings complex*) complex*)))
			      (mkbind (map <binding>-lhs complex*^)
				      (%make-void-constants complex*^)
				      (mkfix fixable*^
					     (mk-assign-seq complex*^ body))))))))))

      (define (%fixable-binding? x)
	(and (not (prelex-source-assigned? ($<binding>-lhs x)))
	     (clambda? ($<binding>-rhs x))))

      (define (mkbind lhs* rhs* body)
	(if (null? lhs*)
	    body
	  (make-bind lhs* rhs* body)))

      (define (mk-assign-seq binding* body)
	;;Build and return a struct representing recordised code equivalent to:
	;;
	;;   (begin
	;;     (set! ?lhs ?rhs)
	;;     ...
	;;     ?body)
	;;
	;;where the LHS and RHS are extracted from BINDING*.
	;;
	;;BINDING* must be a list of  <BINDING> structures.  BODY must be a structure
	;;representing recordised code.
	;;
	;;NOTE Each PRELEX  structure representing an LHS is marked  as having single
	;;initialisation assignment.
	;;
	(fold-right (lambda (binding tail)
		      (make-seq (%make-init-single-assign ($<binding>-lhs binding)
							  ($<binding>-rhs binding))
				tail))
	  body binding*))

      (define (%sort-bindings binding*)
	(list-sort (lambda (binding1 binding2)
		     (fx<? ($<binding>-serial binding1)
			   ($<binding>-serial binding2)))
		   binding*))

      #| end of module: gen-single-letrec |# )

    #| end of module: gen-letrecs |# )

;;; --------------------------------------------------------------------

  (module (tarjan-algorithm)
    ;;This  module performs  the actual  Tarjan's algorithm.   The input  data is  an
    ;;already built directed  graph description of the  dependencies between bindings
    ;;from a single  RECBIND or REC*BIND form.   The output data is a  list of items;
    ;;each item represents a cluster of Strongly Connected Components (SCCs).
    ;;
    ;;In the graph:  each <BINDING> struct is  a vertex (also called  node); of these
    ;;structs: in this module we use  only the fields SUCCESSOR*, INDEX, DONE.  Let's
    ;;call "successors" the vertexes at the end  of edges outgoing from a vertex; the
    ;;successors of a vertex are listed in the field SUCCESSOR*.
    ;;
    ;;We perform a depth-first visit of the  directed graph of bindings from a single
    ;;RECBIND or  REC*BIND struct, using a  recursive function.  During the  visit we
    ;;step from  the current vertex to  a successor one,  if it has not  already been
    ;;visited; a depth-first visit  is like entering a maze and  always turn right at
    ;;cross roads.
    ;;
    ;;The  directed graph  of bindings  has cycles,  but we  avoid infinite  loops by
    ;;setting to non-false  the DONE and INDEX  fields of a <BINDING>  struct when we
    ;;visit and process it.
    ;;
    ;;The purpose of the  visit is to partition the bindings  in clusters of Strongly
    ;;Connected Components; each  cluster can be processed later to  compose a set of
    ;;nested binding forms in recordised code.
    ;;
    ;;Here is the gist of the Tarjan algorithm.  While visiting the vertexes: we push
    ;;each  visited <BINDING>  on  a stack;  we  rank each  <BINDING>  struct with  a
    ;;zero-based serial index.   The following example shows a visit  with path A, B,
    ;;C, D on a graph with a cycle  and the associated stack of visited vertexes; the
    ;;serial index of each vertex is in square brackets:
    ;;
    ;;   A[0] --> B[1] --> C[2]     STK == A, B, C, D
    ;;              ^       |
    ;;              .       |
    ;;              .       |
    ;;            D[3] <----
    ;;
    ;;Let's say  we are  visiting D and  considering the successor  vertex B  as next
    ;;step: B has been already  visited, so we do not enter it; the  index of B is 1,
    ;;less than the index of D which is 3, so we mutate the index of D to be 1:
    ;;
    ;;   A[0] --> B[1] --> C[2]     STK == A, B, C, D
    ;;              ^        |
    ;;              .        |
    ;;              .        |
    ;;            D[1] <-----
    ;;
    ;;there are no more  successor vertexes from D so we step back  to C; notice that
    ;;we leave the stack  unchanged.  Upon stepping back to C:  we recognise that the
    ;;index of C is 2, less than the index of D which is 1; so we mutate the index of
    ;;C to be 1:
    ;;
    ;;   A[0] --> B[1] --> C[1]     STK == A, B, C, D
    ;;              ^        .
    ;;              .        .
    ;;              .        .
    ;;            D[1] <.....
    ;;
    ;;there are no more  successor vertexes from C so we step back  to B; notice that
    ;;we leave the stack  unchanged.  Upon stepping back to B:  we recognise that the
    ;;index of B is 1,  greater than or equal to the index of C  which is 1; we leave
    ;;the  index of  B unchanged.   Now  we recognise  that: after  visiting all  the
    ;;vertexes successors to B, the index of B is unchanged; we conclude that all the
    ;;nodes on  the stack  up to  and including B  are part  of a  Strongly Connected
    ;;Component:
    ;;
    ;;   STK == A, B, C, D
    ;;            |-------| SCC
    ;;
    ;;so we pop them from the stack and  form a cluster with them.  The vertexes in a
    ;;cluster are marked as "done" and will be skipped in further steps of the visit,
    ;;as if they are not there.
    ;;
    ;;Clusters  of SCCs  are  formed and  accumulated while  stepping  back from  the
    ;;depth-first visit, the accumulated clusters are in reverse order; so at the end
    ;;of  the recursion  we reverse  the  accumulated list.   This implementation  of
    ;;Tarjan's algorithm  guarantees that  the returned  list of  clusters is  in the
    ;;correct order for RHS evaluation in RECBIND or REC*BIND structs:
    ;;
    ;;* The  RHS of bindings in  the first cluster  from the list, must  be evaluated
    ;;before the RHS of bindings in the second cluster.
    ;;
    ;;* The RHS  of bindings in the  second cluster from the list,  must be evaluated
    ;;before the RHS of bindings in the third cluster.
    ;;
    ;;* And so on.
    ;;
    ;;So we can arrange the evaluation as if each cluster comes from a nested binding
    ;;form; if the returned list is:
    ;;
    ;;   ((?cluster-binding-1 ...)
    ;;    (?cluster-binding-2 ...)
    ;;    (?cluster-binding-3 ...))
    ;;
    ;;the equivalent nested binding forms are:
    ;;
    ;;   (recbind (?cluster-binding-3 ...)
    ;;     (recbind (?cluster-binding-2 ...)
    ;;       (recbind (?cluster-binding-1 ...)
    ;;         ?body)))
    ;;

    (define (tarjan-algorithm vertex*)
      ;;For every vertex  in the list VERTEX*: start a  depth-first visit and perform
      ;;Tarjan's algorithm  to group clusters  of SCCs.   Return a list  of sublists,
      ;;each sublist being a list of  <BINDING> structures; each sublist represents a
      ;;cluster of Strongly Connected Components (SCCs).
      ;;
      (reverse (fold-left (lambda (reverse-scc* vertex)
			    (if ($<binding>-done vertex)
				reverse-scc*
			      (%compute-sccs vertex reverse-scc*)))
		 '() ;starting value of REVERSE-SCC*
		 vertex*)))

    (define (%compute-sccs start-vertex accum-reverse-scc*)
      (define index 0)
      (define stack-of-traversed '())

      (define (visit-vertex vertex reverse-scc*)
	;;Recursive function.   This function  performs a depth-first  visit starting
	;;from VERTEX and  visiting its successor vertexes.  Return  the updated list
	;;of SCC clusters.
	;;
	;;REVERSE-SCC* must be the list of clusters accumulated so far.
	;;
	(define-constant vertex.index-upon-entering index)
	(define (%vertex-index-UNchanged-since-entering?)
	  (fx=? ($<binding>-index vertex)
	       vertex.index-upon-entering))
	(fxincr! index)
	($set-<binding>-index! vertex vertex.index-upon-entering)
	;;Push VERTEX on the stack.
	(set-cons! stack-of-traversed vertex)
	(let ((reverse-scc*^ (%inspect/visit-successor-vertexes vertex reverse-scc*)))
	  ;;Back  from  the depth-first  visit,  the  accumulated Strongly  Connected
	  ;;Components are now in REVERSE-SCC*^.
	  (if (%vertex-index-UNchanged-since-entering?)
	      (cons (%make-scc-cluster-from-visited-vertexes vertex stack-of-traversed)
		    reverse-scc*^)
	    reverse-scc*^)))

      (define (%inspect/visit-successor-vertexes vertex reverse-scc*)
	(define-syntax-rule (%update-vertex-index ?successor-vertex)
	  ($set-<binding>-index! vertex (fxmin ($<binding>-index vertex)
					       ($<binding>-index ?successor-vertex))))
	(fold-left
	    (lambda (reverse-scc* successor-vertex)
	      ;;Inspect SUCCESSOR-VISIT and decide if we must visit it or skip it.
	      (cond (($<binding>-done successor-vertex)
		     ;;SUCCESSOR-VERTEX has already been  visited and included into a
		     ;;cluster; skip it.
		     reverse-scc*)
		    (($<binding>-index successor-vertex)
		     ;;SUCCESSOR-VERTEX is  not already  into a  cluster, but  it has
		     ;;already been visited; so skip it.
		     (%update-vertex-index successor-vertex)
		     reverse-scc*)
		    (else
		     ;;SUCCESSOR-VERTEX has not been visited; visit it.
		     (begin0
		       (visit-vertex successor-vertex reverse-scc*)
		       (%update-vertex-index successor-vertex)))))
	  reverse-scc*
	  ($<binding>-successor* vertex)))

      (define (%make-scc-cluster-from-visited-vertexes limit-vertex stk)
	;;Recursive  function.  This  function is  closed upon  (and mutates  as side
	;;effect)  STACK-OF-TRAVERSED:  a  list  representing the  current  stack  of
	;;traversed  vertexes, containing  LIMIT-VERTEX and  possibly other  vertexes
	;;after it; upon entering the  recursion both STK and STACK-OF-TRAVERSED must
	;;reference the top  of the stack.  The scenario upon  entering the recursion
	;;is:
	;;
	;;   vertex0 -> vertex1 -> LIMIT-VERTEX -> vertex3 -> vertex4
	;;                                                       ^
	;;                                              STK == STACK-OF-TRAVERSED
	;;
	;;When this function is  called: all the vertexes from the top  of STK up to,
	;;and including, LIMIT-VERTEX must be popped and used to form an SCC cluster.
	;;The scenario upon leaving the recursion is:
	;;
	;;   vertex0 -> vertex1          (vertex4 vertex3 LIMIT-VERTEX) == cluster
	;;                 ^
	;;        STACK-OF-TRAVERSED
	;;
	;;The  list of  vertexes  representing the  SCC cluster  is  returned to  the
	;;caller.  In  addition, as  side effects:  mark as  "done" all  the vertexes
	;;popped from the stack and included in the cluster.
	;;
	(let ((vertex-on-stack (car stk)))
	  ($set-<binding>-done! vertex-on-stack #t)
	  (cons vertex-on-stack
		(if (eq? vertex-on-stack limit-vertex)
		    ;;We have found the limit...
		    (begin
		      ;;... trim the stack ...
		      (set! stack-of-traversed (cdr stk))
		      ;;... end the cluster.
		      '())
		  (%make-scc-cluster-from-visited-vertexes limit-vertex (cdr stk))))))

      (visit-vertex start-vertex accum-reverse-scc*))

    #| end of module: TARJAN-ALGORITHM |# )

  #| end of module: OPTIMIZE-LETREC/SCC |# )


;;;; done

#| end of library |# )

;;; end of file
;; Local Variables:
;; mode: vicare
;; eval: (put 'make-bind			'scheme-indent-function 2)
;; eval: (put 'make-fix				'scheme-indent-function 2)
;; eval: (put '%make-bind			'scheme-indent-function 2)
;; eval: (put '$make-fix			'scheme-indent-function 2)
;; eval: (put 'with-unseen-prel			'scheme-indent-function 1)
;; eval: (put '%map-in-order-with-index		'scheme-indent-function 1)
;; eval: (put '%fold-right/1-list/2-retvals	'scheme-indent-function 1)
;; eval: (put '%fold-right/2-lists/2-retvals	'scheme-indent-function 1)
;; End:
