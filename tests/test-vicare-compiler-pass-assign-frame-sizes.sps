;;; -*- coding: utf-8-unix -*-
;;;
;;;Part of: Vicare Scheme
;;;Contents: tests for the compiler internals
;;;Date: Thu Oct  9, 2014
;;;
;;;Abstract
;;;
;;;	Test the compiler pass "assign frame sizes".
;;;
;;;Copyright (C) 2014, 2015 Marco Maggi <marco.maggi-ipsu@poste.it>
;;;
;;;This program is free software: you can  redistribute it and/or modify it under the
;;;terms  of  the GNU  General  Public  License as  published  by  the Free  Software
;;;Foundation,  either version  3  of the  License,  or (at  your  option) any  later
;;;version.
;;;
;;;This program is  distributed in the hope  that it will be useful,  but WITHOUT ANY
;;;WARRANTY; without  even the implied warranty  of MERCHANTABILITY or FITNESS  FOR A
;;;PARTICULAR PURPOSE.  See the GNU General Public License for more details.
;;;
;;;You should have received a copy of  the GNU General Public License along with this
;;;program.  If not, see <http://www.gnu.org/licenses/>.
;;;


#!vicare
(import (vicare)
  (vicare checks)
  (only (vicare expander)
	expand-form-to-core-language)
  (only (vicare libraries)
	expand-library->sexp)
  (prefix (vicare compiler)
	  compiler.))

(check-set-mode! 'report-failed)
(check-display "*** testing Vicare compiler pass: assign frame sizes\n")

(compiler.generate-descriptive-labels?   #t)
(compiler.generate-debug-calls #f)


;;;; helpers

(define (gensyms->symbols sexp)
  (cond ((pair? sexp)
	 (cons (gensyms->symbols (car sexp))
	       (gensyms->symbols (cdr sexp))))
	((vector? sexp)
	 (vector-map gensyms->symbols sexp))
	((gensym? sexp)
	 (string->symbol (symbol->string sexp)))
	(else sexp)))

;;; --------------------------------------------------------------------
;;; expansion helpers

(define-constant THE-ENVIRONMENT
  (environment '(vicare)
	       '(vicare unsafe operations)))

(define (%expand standard-language-form)
  (receive (code libs)
      (expand-form-to-core-language standard-language-form THE-ENVIRONMENT)
    code))

(define (%expand-library standard-language-form)
  (cdr (assq 'invoke-code (expand-library->sexp standard-language-form))))

(define (%make-annotated-form form)
  (let* ((form.str (receive (port extract)
		       (open-string-output-port)
		     (unwind-protect
			 (begin
			   (display form port)
			   (extract))
		       (close-port port))))
	 (port     (open-string-input-port form.str)))
    (unwind-protect
	(get-annotated-datum port)
      (close-port port))))

;;; --------------------------------------------------------------------

(define (%specify-representation core-language-form)
  (let* ((D (compiler.pass-recordize core-language-form))
	 (D (compiler.pass-optimize-direct-calls D))
	 (D (compiler.pass-optimize-letrec D))
	 ;;Source optimisation is skipped here to  make it easier to write meaningful
	 ;;code for debugging and inspection.
	 #;(D (compiler.pass-source-optimize D))
	 (D (compiler.pass-rewrite-references-and-assignments D))
	 (D (compiler.pass-core-type-inference D))
	 (D (compiler.pass-sanitize-bindings D))
	 (D (compiler.pass-optimize-for-direct-jumps D))
	 (D (compiler.pass-insert-global-assignments D))
	 (D (compiler.pass-introduce-vars D))
	 (D (compiler.pass-introduce-closure-makers D))
	 (D (compiler.pass-optimize-combinator-calls/lift-clambdas D))
	 (D (compiler.pass-introduce-primitive-operation-calls D))
	 (D (compiler.pass-rewrite-freevar-references D))
	 (D (compiler.pass-insert-engine-checks D))
	 (D (compiler.pass-insert-stack-overflow-check D))
	 (D (compiler.pass-specify-representation D))
	 (S (compiler.unparse-recordized-code/sexp D)))
    S))

(define (%impose-eval-order core-language-form)
  (let* ((D (compiler.pass-recordize core-language-form))
	 (D (compiler.pass-optimize-direct-calls D))
	 (D (compiler.pass-optimize-letrec D))
	 ;;Source optimisation is skipped here to  make it easier to write meaningful
	 ;;code for debugging and inspection.
	 #;(D (compiler.pass-source-optimize D))
	 (D (compiler.pass-rewrite-references-and-assignments D))
	 (D (compiler.pass-core-type-inference D))
	 (D (compiler.pass-sanitize-bindings D))
	 (D (compiler.pass-optimize-for-direct-jumps D))
	 (D (compiler.pass-insert-global-assignments D))
	 (D (compiler.pass-introduce-vars D))
	 (D (compiler.pass-introduce-closure-makers D))
	 (D (compiler.pass-optimize-combinator-calls/lift-clambdas D))
	 (D (compiler.pass-introduce-primitive-operation-calls D))
	 (D (compiler.pass-rewrite-freevar-references D))
	 (D (compiler.pass-insert-engine-checks D))
	 (D (compiler.pass-insert-stack-overflow-check D))
	 (D (compiler.pass-specify-representation D))
	 (D (compiler.pass-impose-calling-convention/evaluation-order D))
	 (S (compiler.unparse-recordized-code/sexp D)))
    S))

(define (%assign-frame-sizes core-language-form)
  (let* ((D (compiler.pass-recordize core-language-form))
	 (D (compiler.pass-optimize-direct-calls D))
	 (D (compiler.pass-optimize-letrec D))
	 ;;Source optimisation is skipped here to  make it easier to write meaningful
	 ;;code for debugging and inspection.
	 #;(D (compiler.pass-source-optimize D))
	 (D (compiler.pass-rewrite-references-and-assignments D))
	 (D (compiler.pass-core-type-inference D))
	 (D (compiler.pass-sanitize-bindings D))
	 (D (compiler.pass-optimize-for-direct-jumps D))
	 (D (compiler.pass-insert-global-assignments D))
	 (D (compiler.pass-introduce-vars D))
	 (D (compiler.pass-introduce-closure-makers D))
	 (D (compiler.pass-optimize-combinator-calls/lift-clambdas D))
	 (D (compiler.pass-introduce-primitive-operation-calls D))
	 (D (compiler.pass-rewrite-freevar-references D))
	 (D (compiler.pass-insert-engine-checks D))
	 (D (compiler.pass-insert-stack-overflow-check D))
	 (D (compiler.pass-specify-representation D))
	 (D (compiler.pass-impose-calling-convention/evaluation-order D))
	 (D (compiler.pass-assign-frame-sizes D))
	 (S (compiler.unparse-recordized-code/sexp D)))
    S))

;;; --------------------------------------------------------------------

(define-syntax doit
  (syntax-rules ()
    ((_ ?core-language-form ?expected-result)
     (check
	 (%assign-frame-sizes (quasiquote ?core-language-form))
       => (quasiquote ?expected-result)))
    ))

(define-syntax doit*
  (syntax-rules ()
    ((_ ?standard-language-form ?expected-result)
     ;;We want the ?STANDARD-LANGUAGE-FORM to appear  in the output of CHECK when a
     ;;test fails.
     (doit ,(%expand (quasiquote ?standard-language-form))
	   ?expected-result))
    ))

(define-syntax libdoit*
  (syntax-rules ()
    ((_ ?standard-language-form ?expected-result/basic)
     (doit ,(%expand-library (quasiquote ?standard-language-form)) ?expected-result/basic))
    ))


(parametrise ((check-test-name	'nested-non-tail-calls))

;;;We want to show  what happens when we perform a non-tail  call while preparing the
;;;stack operands for a non-tail call.

;;;To make things  simpler: we use "_"  as function name, without  defining a binding
;;;for "_";  whenever the  compiler finds  a standalone symbol,  it interprets  it as
;;;variable reference.

  (check
      (%specify-representation '(let ((f (lambda (x) (_ '1 x)))
				      (g (lambda (y) (_ '2 y))))
				  (begin
				    (f (g '3))
				    '4)))
    => '(codes
	 ((lambda (label: asmlabel:g:clambda) (cp_0 y_0)
	     (seq
	       ;;Core primitive operation $DO-EVENT.
	       (shortcut
		   (asmcall incr/zero? %esi (constant 72) (constant 8))
		 (funcall (asmcall mref (constant (object $do-event)) (constant 19))))
	       ;;Tail call to the fake function "_".
	       (funcall (asmcall mref (constant (object _)) (constant 27))
		 (constant 16) y_0)))
	  (lambda (label: asmlabel:f:clambda) (cp_1 x_0)
	     (seq
	       ;;Core primitive operation $DO-EVENT.
	       (shortcut
		   (asmcall incr/zero? %esi (constant 72) (constant 8))
		 (funcall (asmcall mref (constant (object $do-event)) (constant 19))))
	       ;;Tail call to the core primitive function "_".
	       (funcall (asmcall mref (constant (object _)) (constant 27))
		 (constant 8) x_0))))
	 (seq
	   ;;Core primitive operation $STACK-OVERFLOW-CHECK.
	   (shortcut
	       (conditional (asmcall u< %esp (asmcall mref %esi (constant 32)))
		   (asmcall interrupt)
		 (asmcall nop))
	     (foreign-call "ik_stack_overflow"))
	   ;;Core primitive operation $DO-EVENT.
	   (shortcut
	       (asmcall incr/zero? %esi (constant 72) (constant 8))
	     (funcall (asmcall mref (constant (object $do-event)) (constant 19))))
	   (jmpcall asmlabel:f:clambda:case-1
		    (bind ((tmp_0 (constant (closure-maker (code-loc asmlabel:f:clambda) no-freevars))))
		      tmp_0)
		    (jmpcall asmlabel:g:clambda:case-1
			     (bind ((tmp_1 (constant (closure-maker (code-loc asmlabel:g:clambda) no-freevars))))
			       tmp_1)
			     (constant 24)))
	   (constant 32))))

;;; --------------------------------------------------------------------

  (check
      (%impose-eval-order '(let ((f (lambda (x) (_ '1 x)))
				 (g (lambda (y) (_ '2 y))))
			     (begin
			       (f (g '3))
			       '4)))
    => '(codes
	 ((lambda (label: asmlabel:g:clambda) (%edi fvar.1)
	     (locals
	      (local-vars: tmp_0 tmp_1 tmp_2 cp_0)
	      (seq
		(asm-instr move cp_0 %edi)
		;;Core primitive operation $DO-EVENT.
		(shortcut (asmcall incr/zero? %esi (constant 72) (constant 8))
		  (non-tail-call-frame
		    (rand*: #f)
		    (live: #f)
		    (seq
		      (asm-instr move tmp_0 (disp (constant (object $do-event)) (constant 19)))
		      (asm-instr move %edi tmp_0)
		      (asm-instr move %eax (constant 0))
		      (non-tail-call
			(target: #f)
			(retval-var: #f)
			(all-rand*: %eax %ebp %edi %esp %esi)
			(mask: #f)
			(size: #f)))))
		;;Tail call to the fake function "_".
		(asm-instr move tmp_1 fvar.1)
		(asm-instr move tmp_2 (disp (constant (object _)) (constant 27)))
		(asm-instr move fvar.1 (constant 16))
		(asm-instr move fvar.2 tmp_1)
		(asm-instr move %edi tmp_2)
		(asm-instr move %eax (constant -16))
		(asmcall indirect-jump %eax %ebp %edi %esp %esi fvar.1 fvar.2))))
	  (lambda (label: asmlabel:f:clambda) (%edi fvar.1)
	     (locals
	      (local-vars: tmp_3 tmp_4 tmp_5 cp_1)
	      (seq
		(asm-instr move cp_1 %edi)
		;;Core primitive operation $DO-EVENT.
		(shortcut
		    (asmcall incr/zero? %esi (constant 72) (constant 8))
		  (non-tail-call-frame
		    (rand*: #f)
		    (live: #f)
		    (seq
		      (asm-instr move tmp_3 (disp (constant (object $do-event)) (constant 19)))
		      (asm-instr move %edi tmp_3)
		      (asm-instr move %eax (constant 0))
		      (non-tail-call
			(target: #f)
			(retval-var: #f)
			(all-rand*: %eax %ebp %edi %esp %esi)
			(mask: #f)
			(size: #f)))))
		;;Tail call to the fake function "_".
		(asm-instr move tmp_4 fvar.1)
		(asm-instr move tmp_5 (disp (constant (object _)) (constant 27)))
		(asm-instr move fvar.1 (constant 8))
		(asm-instr move fvar.2 tmp_4)
		(asm-instr move %edi tmp_5)
		(asm-instr move %eax (constant -16))
		(asmcall indirect-jump %eax %ebp %edi %esp %esi fvar.1 fvar.2)))))
	 (locals
	  (local-vars: tmp_6 tmp_7 tmp_8 tmp_9 tmp_10)
	  (seq
	    ;;Core primitive operation $STACK-OVERFLOW-CHECK.
	    (shortcut
		(conditional (asm-instr u< %esp (disp %esi (constant 32)))
		    (asmcall interrupt)
		  (asmcall nop))
	      (non-tail-call-frame
		(rand*: #f)
		(live: #f)
		(seq
		  (asm-instr move %edi (constant (foreign-label "ik_stack_overflow")))
		  (asm-instr move %eax (constant 0))
		  (non-tail-call
		    (target: "ik_stack_overflow")
		    (retval-var: #f)
		    (all-rand*: %eax %ebp %edi %esp %esi)
		    (mask: #f) (size: #f)))))
	    ;;Core primitive operation $DO-EVENT.
	    (shortcut
		(asmcall incr/zero? %esi (constant 72) (constant 8))
	      (non-tail-call-frame
		(rand*: #f)
		(live: #f)
		(seq
		  (asm-instr move tmp_6 (disp (constant (object $do-event)) (constant 19)))
		  (asm-instr move %edi tmp_6)
		  (asm-instr move %eax (constant 0))
		  (non-tail-call
		    (target: #f)
		    (retval-var: #f)
		    (all-rand*: %eax %ebp %edi %esp %esi)
		    (mask: #f)
		    (size: #f)))))
	    ;;Non-tail call frame to the function F.
	    (non-tail-call-frame
	      (rand*: nfv.1_0)
	      (live: #f)
	      (seq
		;;Non-tail call frame to the function G.
		(non-tail-call-frame
		  (rand*: nfv.1_1)
		  (live: #f)
		  (seq
		    (asm-instr move nfv.1_1 (constant 24))
		    (asm-instr move tmp_7 (constant (closure-maker (code-loc asmlabel:g:clambda) no-freevars)))
		    (asm-instr move tmp_8 tmp_7)
		    (asm-instr move %edi tmp_8)
		    (asm-instr move %eax (constant -8))
		    (non-tail-call
		      (target: asmlabel:g:clambda:case-1)
		      (retval-var: nfv.1_0)
		      (all-rand*: %eax %ebp %edi %esp %esi nfv.1_1)
		      (mask: #f)
		      (size: #f))))
		(asm-instr move nfv.1_0 %eax)
		(asm-instr move tmp_9 (constant (closure-maker (code-loc asmlabel:f:clambda) no-freevars)))
		(asm-instr move tmp_10 tmp_9)
		(asm-instr move %edi tmp_10)
		(asm-instr move %eax (constant -8))
		(non-tail-call
		  (target: asmlabel:f:clambda:case-1)
		  (retval-var: #f)
		  (all-rand*: %eax %ebp %edi %esp %esi nfv.1_0)
		  (mask: #f)
		  (size: #f))))
	    (asm-instr move %eax (constant 32))
	    (asmcall return %eax %ebp %esp %esi)))))

;;; --------------------------------------------------------------------

  (doit (let ((f (lambda (x) (_ '1 x)))
	      (g (lambda (y) (_ '2 y))))
	  (begin
	    (f (g '3))
	    '4))
	(codes
	 ((lambda (label: asmlabel:g:clambda) (%edi fvar.1)
	     (locals
	      (local-vars: #(tmp_0 tmp_1 tmp_2 cp_0)
			   tmp_0 tmp_1 tmp_2 cp_0)
	      (seq
		(asmcall nop)
		(shortcut
		    (asmcall incr/zero? %esi (constant 72) (constant 8))
		  (seq
		    (asm-instr move tmp_0 (disp (constant (object $do-event)) (constant 19)))
		    (asm-instr move %edi tmp_0)
		    (asm-instr move %eax (constant 0))
		    (non-tail-call
		      (target: #f)
		      (retval-var: #f)
		      (all-rand*: %eax %ebp %edi %esp %esi)
		      (mask: #(2))
		      (size: 2))))
		(asm-instr move tmp_1 fvar.1)
		(asm-instr move tmp_2 (disp (constant (object _)) (constant 27)))
		(asm-instr move fvar.1 (constant 16))
		(asm-instr move fvar.2 tmp_1)
		(asm-instr move %edi tmp_2)
		(asm-instr move %eax (constant -16))
		(asmcall indirect-jump %eax %ebp %edi %esp %esi fvar.1 fvar.2))))
	  (lambda (label: asmlabel:f:clambda) (%edi fvar.1)
	    (locals
	     (local-vars: #(tmp_3 tmp_4 tmp_5 cp_1)
			  tmp_3 tmp_4 tmp_5 cp_1)
	     (seq
	       (asmcall nop)
	       (shortcut
		   (asmcall incr/zero? %esi (constant 72) (constant 8))
		 (seq
		   (asm-instr move tmp_3 (disp (constant (object $do-event)) (constant 19)))
		   (asm-instr move %edi tmp_3)
		   (asm-instr move %eax (constant 0))
		   (non-tail-call
		     (target: #f)
		     (retval-var: #f)
		     (all-rand*: %eax %ebp %edi %esp %esi)
		     (mask: #(2))
		     (size: 2))))
	       (asm-instr move tmp_4 fvar.1)
	       (asm-instr move tmp_5 (disp (constant (object _)) (constant 27)))
	       (asm-instr move fvar.1 (constant 8))
	       (asm-instr move fvar.2 tmp_4)
	       (asm-instr move %edi tmp_5)
	       (asm-instr move %eax (constant -16))
	       (asmcall indirect-jump %eax %ebp %edi %esp %esi fvar.1 fvar.2)))))
	 (locals
	  (local-vars: #(tmp_6 tmp_7 tmp_8 tmp_9 tmp_10)
		       tmp_6 tmp_7 tmp_8 tmp_9 tmp_10)
	  (seq
	    (shortcut
		(conditional (asm-instr u< %esp (disp %esi (constant 32)))
		    (asmcall interrupt)
		  (asmcall nop))
	      (seq
		(asm-instr move %edi (constant (foreign-label "ik_stack_overflow")))
		(asm-instr move %eax (constant 0))
		(non-tail-call
		  (target: "ik_stack_overflow")
		  (retval-var: #f)
		  (all-rand*: %eax %ebp %edi %esp %esi)
		  (mask: #(0))
		  (size: 1))))
	    (shortcut
		(asmcall incr/zero? %esi (constant 72) (constant 8))
	      (seq
		(asm-instr move tmp_6 (disp (constant (object $do-event)) (constant 19)))
		(asm-instr move %edi tmp_6)
		(asm-instr move %eax (constant 0))
		(non-tail-call
		  (target: #f)
		  (retval-var: #f)
		  (all-rand*: %eax %ebp %edi %esp %esi)
		  (mask: #(0))
		  (size: 1))))
	    (asm-instr move fvar.2 (constant 24))
	    (asm-instr move tmp_7 (constant (closure-maker (code-loc asmlabel:g:clambda) no-freevars)))
	    (asm-instr move tmp_8 tmp_7)
	    (asm-instr move %edi tmp_8)
	    (asm-instr move %eax (constant -8))
	    (non-tail-call
	      (target: asmlabel:g:clambda:case-1)
	      (retval-var: fvar.2)
	      (all-rand*: %eax %ebp %edi %esp %esi fvar.2)
	      (mask: #(0))
	      (size: 1))
	    (asm-instr move fvar.2 %eax)
	    (asm-instr move tmp_9 (constant (closure-maker (code-loc asmlabel:f:clambda) no-freevars)))
	    (asm-instr move tmp_10 tmp_9)
	    (asm-instr move %edi tmp_10)
	    (asm-instr move %eax (constant -8))
	    (non-tail-call
	      (target: asmlabel:f:clambda:case-1)
	      (retval-var: #f)
	      (all-rand*: %eax %ebp %edi %esp %esi fvar.2)
	      (mask: #(0))
	      (size: 1))
	    (asm-instr move %eax (constant 32))
	    (asmcall return %eax %ebp %esp %esi)))))

  #t)


(parametrise ((check-test-name	'nested-non-tail-calls-2))

;;;We want to show  what happens when we perform a non-tail  call while preparing the
;;;stack operands for a non-tail call.

;;;To make things  simpler: we use "_"  as function name, without  defining a binding
;;;for "_";  whenever the  compiler finds  a standalone symbol,  it interprets  it as
;;;variable reference.

  (check
      (%specify-representation '(let ((f (lambda (a b) (_ a b)))
				      (g (lambda (y) (_ '1 y)))
				      (h (lambda (z) (_ '2 z))))
				  (begin
				    (f (g '3) (h '4))
				    '5)))
    => '(codes
	 ((lambda (label: asmlabel:h:clambda) (cp_0 z_0)
	     (seq
	       (shortcut
		   (asmcall incr/zero? %esi (constant 72) (constant 8))
		 (funcall (asmcall mref (constant (object $do-event)) (constant 19))))
	       (funcall (asmcall mref (constant (object _)) (constant 27))
		 (constant 16) z_0)))
	  (lambda (label: asmlabel:g:clambda) (cp_1 y_0)
	     (seq
	       (shortcut
		   (asmcall incr/zero? %esi (constant 72) (constant 8))
		 (funcall (asmcall mref (constant (object $do-event)) (constant 19))))
	       (funcall (asmcall mref (constant (object _)) (constant 27))
		 (constant 8) y_0)))
	  (lambda (label: asmlabel:f:clambda) (cp_2 a_0 b_0)
	     (seq
	       (shortcut
		   (asmcall incr/zero? %esi (constant 72) (constant 8))
		 (funcall (asmcall mref (constant (object $do-event)) (constant 19))))
	       (funcall (asmcall mref (constant (object _)) (constant 27))
		 a_0 b_0))))
	 (seq
	   (shortcut
	       (conditional (asmcall u< %esp (asmcall mref %esi (constant 32)))
		   (asmcall interrupt)
		 (asmcall nop))
	     (foreign-call "ik_stack_overflow"))
	   (shortcut
	       (asmcall incr/zero? %esi (constant 72) (constant 8))
	     (funcall (asmcall mref (constant (object $do-event)) (constant 19))))
	   (jmpcall asmlabel:f:clambda:case-2
		    (bind ((tmp_0 (constant (closure-maker (code-loc asmlabel:f:clambda) no-freevars))))
		      tmp_0)
		    (jmpcall asmlabel:g:clambda:case-1
			     (bind ((tmp_1 (constant (closure-maker (code-loc asmlabel:g:clambda) no-freevars))))
			       tmp_1)
			     (constant 24))
		    (jmpcall asmlabel:h:clambda:case-1
			     (bind ((tmp_2 (constant (closure-maker (code-loc asmlabel:h:clambda) no-freevars))))
			       tmp_2)
			     (constant 32)))
	   (constant 40))))

;;; --------------------------------------------------------------------

  (check
      (%impose-eval-order '(let ((f (lambda (a b) (_ a b)))
				 (g (lambda (y) (_ '1 y)))
				 (h (lambda (z) (_ '2 z))))
			     (begin
			       (f (g '3) (h '4))
			       '5)))
    => '(codes
	 ((lambda (label: asmlabel:h:clambda) (%edi fvar.1)
	     (locals
	      (local-vars: tmp_0 tmp_1 tmp_2 cp_0)
	      (seq
		(asm-instr move cp_0 %edi)
		(shortcut
		    (asmcall incr/zero? %esi (constant 72) (constant 8))
		  (non-tail-call-frame
		    (rand*: #f)
		    (live: #f)
		    (seq
		      (asm-instr move tmp_0 (disp (constant (object $do-event)) (constant 19)))
		      (asm-instr move %edi tmp_0)
		      (asm-instr move %eax (constant 0))
		      (non-tail-call
			(target: #f)
			(retval-var: #f)
			(all-rand*: %eax %ebp %edi %esp %esi)
			(mask: #f)
			(size: #f)))))
		(asm-instr move tmp_1 fvar.1)
		(asm-instr move tmp_2 (disp (constant (object _)) (constant 27)))
		(asm-instr move fvar.1 (constant 16))
		(asm-instr move fvar.2 tmp_1)
		(asm-instr move %edi tmp_2)
		(asm-instr move %eax (constant -16))
		(asmcall indirect-jump %eax %ebp %edi %esp %esi fvar.1 fvar.2))))
	  (lambda (label: asmlabel:g:clambda) (%edi fvar.1)
	     (locals
	      (local-vars: tmp_3 tmp_4 tmp_5 cp_1)
	      (seq
		(asm-instr move cp_1 %edi)
		(shortcut
		    (asmcall incr/zero? %esi (constant 72) (constant 8))
		  (non-tail-call-frame
		    (rand*: #f)
		    (live: #f)
		    (seq
		      (asm-instr move tmp_3 (disp (constant (object $do-event)) (constant 19)))
		      (asm-instr move %edi tmp_3)
		      (asm-instr move %eax (constant 0))
		      (non-tail-call
			(target: #f)
			(retval-var: #f)
			(all-rand*: %eax %ebp %edi %esp %esi)
			(mask: #f)
			(size: #f)))))
		(asm-instr move tmp_4 fvar.1)
		(asm-instr move tmp_5 (disp (constant (object _)) (constant 27)))
		(asm-instr move fvar.1 (constant 8))
		(asm-instr move fvar.2 tmp_4)
		(asm-instr move %edi tmp_5)
		(asm-instr move %eax (constant -16))
		(asmcall indirect-jump %eax %ebp %edi %esp %esi fvar.1 fvar.2))))
	  (lambda (label: asmlabel:f:clambda) (%edi fvar.1 fvar.2)
	     (locals
	      (local-vars: tmp_6 tmp_7 cp_2)
	      (seq
		(asm-instr move cp_2 %edi)
		(shortcut
		    (asmcall incr/zero? %esi (constant 72) (constant 8))
		  (non-tail-call-frame
		    (rand*: #f)
		    (live: #f)
		    (seq
		      (asm-instr move tmp_6 (disp (constant (object $do-event)) (constant 19)))
		      (asm-instr move %edi tmp_6)
		      (asm-instr move %eax (constant 0))
		      (non-tail-call
			(target: #f)
			(retval-var: #f)
			(all-rand*: %eax %ebp %edi %esp %esi)
			(mask: #f)
			(size: #f)))))
		(asm-instr move tmp_7 (disp (constant (object _)) (constant 27)))
		(asm-instr move %edi tmp_7)
		(asm-instr move %eax (constant -16))
		(asmcall indirect-jump %eax %ebp %edi %esp %esi fvar.1 fvar.2)))))
	 (locals
	  (local-vars: tmp_8 tmp_9 tmp_10 tmp_11 tmp_12 tmp_13 tmp_14)
	  (seq
	    (shortcut
		(conditional (asm-instr u< %esp (disp %esi (constant 32)))
		    (asmcall interrupt)
		  (asmcall nop))
	      (non-tail-call-frame
		(rand*: #f)
		(live: #f)
		(seq
		  (asm-instr move %edi (constant (foreign-label "ik_stack_overflow")))
		  (asm-instr move %eax (constant 0))
		  (non-tail-call
		    (target: "ik_stack_overflow")
		    (retval-var: #f)
		    (all-rand*: %eax %ebp %edi %esp %esi)
		    (mask: #f)
		    (size: #f)))))
	    (shortcut
		(asmcall incr/zero? %esi (constant 72) (constant 8))
	      (non-tail-call-frame
		(rand*: #f)
		(live: #f)
		(seq
		  (asm-instr move tmp_8 (disp (constant (object $do-event)) (constant 19)))
		  (asm-instr move %edi tmp_8)
		  (asm-instr move %eax (constant 0))
		  (non-tail-call
		    (target: #f)
		    (retval-var: #f)
		    (all-rand*: %eax %ebp %edi %esp %esi)
		    (mask: #f)
		    (size: #f)))))

	    (non-tail-call-frame
	      (rand*: nfv.1_0 nfv.2_0)
	      (live: #f)
	      (seq
		(non-tail-call-frame
		  (rand*: nfv.1_1)
		  (live: #f)
		  (seq
		    (asm-instr move nfv.1_1 (constant 24))
		    (asm-instr move tmp_9 (constant (closure-maker (code-loc asmlabel:g:clambda) no-freevars)))
		    (asm-instr move tmp_10 tmp_9)
		    (asm-instr move %edi tmp_10)
		    (asm-instr move %eax (constant -8))
		    (non-tail-call
		      (target: asmlabel:g:clambda:case-1)
		      (retval-var: nfv.1_0)
		      (all-rand*: %eax %ebp %edi %esp %esi nfv.1_1)
		      (mask: #f)
		      (size: #f))))
		(asm-instr move nfv.1_0 %eax)

		(non-tail-call-frame
		  (rand*: nfv.1_2)
		  (live: #f)
		  (seq
		    (asm-instr move nfv.1_2 (constant 32))
		    (asm-instr move tmp_11 (constant (closure-maker (code-loc asmlabel:h:clambda) no-freevars)))
		    (asm-instr move tmp_12 tmp_11)
		    (asm-instr move %edi tmp_12)
		    (asm-instr move %eax (constant -8))
		    (non-tail-call
		      (target: asmlabel:h:clambda:case-1)
		      (retval-var: nfv.2_0)
		      (all-rand*: %eax %ebp %edi %esp %esi nfv.1_2)
		      (mask: #f)
		      (size: #f))))
		(asm-instr move nfv.2_0 %eax)

		(asm-instr move tmp_13 (constant (closure-maker (code-loc asmlabel:f:clambda) no-freevars)))
		(asm-instr move tmp_14 tmp_13)
		(asm-instr move %edi tmp_14)
		(asm-instr move %eax (constant -16))
		(non-tail-call
		  (target: asmlabel:f:clambda:case-2)
		  (retval-var: #f)
		  (all-rand*: %eax %ebp %edi %esp %esi nfv.1_0 nfv.2_0)
		  (mask: #f)
		  (size: #f))))

	    (asm-instr move %eax (constant 40))
	    (asmcall return %eax %ebp %esp %esi)))))

;;; --------------------------------------------------------------------

  (doit (let ((f (lambda (a b) (_ a b)))
	      (g (lambda (y) (_ '1 y)))
	      (h (lambda (z) (_ '2 z))))
	  (begin
	    (f (g '3) (h '4))
	    '5))
	(codes
	 ((lambda (label: asmlabel:h:clambda) (%edi fvar.1)
	     (locals
	      (local-vars: #(tmp_0 tmp_1 tmp_2 cp_0)
			   tmp_0 tmp_1 tmp_2 cp_0)
	      (seq
		(asmcall nop)
		(shortcut
		    (asmcall incr/zero? %esi (constant 72) (constant 8))
		  (seq
		    (asm-instr move tmp_0 (disp (constant (object $do-event)) (constant 19)))
		    (asm-instr move %edi tmp_0)
		    (asm-instr move %eax (constant 0))
		    (non-tail-call
		      (target: #f)
		      (retval-var: #f)
		      (all-rand*: %eax %ebp %edi %esp %esi)
		      (mask: #(2))
		      (size: 2))))
		(asm-instr move tmp_1 fvar.1)
		(asm-instr move tmp_2 (disp (constant (object _)) (constant 27)))
		(asm-instr move fvar.1 (constant 16))
		(asm-instr move fvar.2 tmp_1)
		(asm-instr move %edi tmp_2)
		(asm-instr move %eax (constant -16))
		(asmcall indirect-jump %eax %ebp %edi %esp %esi fvar.1 fvar.2))))
	  (lambda (label: asmlabel:g:clambda) (%edi fvar.1)
	     (locals
	      (local-vars: #(tmp_3 tmp_4 tmp_5 cp_1)
			   tmp_3 tmp_4 tmp_5 cp_1)
	      (seq
		(asmcall nop)
		(shortcut
		    (asmcall incr/zero? %esi (constant 72) (constant 8))
		  (seq
		    (asm-instr move tmp_3 (disp (constant (object $do-event)) (constant 19)))
		    (asm-instr move %edi tmp_3)
		    (asm-instr move %eax (constant 0))
		    (non-tail-call
		      (target: #f)
		      (retval-var: #f)
		      (all-rand*: %eax %ebp %edi %esp %esi)
		      (mask: #(2))
		      (size: 2))))
		(asm-instr move tmp_4 fvar.1)
		(asm-instr move tmp_5 (disp (constant (object _)) (constant 27)))
		(asm-instr move fvar.1 (constant 8))
		(asm-instr move fvar.2 tmp_4)
		(asm-instr move %edi tmp_5)
		(asm-instr move %eax (constant -16))
		(asmcall indirect-jump %eax %ebp %edi %esp %esi fvar.1 fvar.2))))
	  (lambda (label: asmlabel:f:clambda) (%edi fvar.1 fvar.2)
	     (locals
	      (local-vars: #(tmp_6 tmp_7 cp_2)
			   tmp_6 tmp_7 cp_2)
	      (seq
		(asmcall nop)
		(shortcut
		    (asmcall incr/zero? %esi (constant 72) (constant 8))
		  (seq
		    (asm-instr move tmp_6 (disp (constant (object $do-event)) (constant 19)))
		    (asm-instr move %edi tmp_6)
		    (asm-instr move %eax (constant 0))
		    (non-tail-call
		      (target: #f)
		      (retval-var: #f)
		      (all-rand*: %eax %ebp %edi %esp %esi)
		      (mask: #(6))
		      (size: 3))))
		(asm-instr move tmp_7 (disp (constant (object _)) (constant 27)))
		(asm-instr move %edi tmp_7)
		(asm-instr move %eax (constant -16))
		(asmcall indirect-jump %eax %ebp %edi %esp %esi fvar.1 fvar.2)))))
	 (locals
	  (local-vars: #(tmp_8 tmp_9 tmp_10 tmp_11 tmp_12 tmp_13 tmp_14)
		       tmp_8 tmp_9 tmp_10 tmp_11 tmp_12 tmp_13 tmp_14)
	  (seq
	    (shortcut
		(conditional (asm-instr u< %esp (disp %esi (constant 32)))
		    (asmcall interrupt)
		  (asmcall nop))
	      (seq
		(asm-instr move %edi (constant (foreign-label "ik_stack_overflow")))
		(asm-instr move %eax (constant 0))
		(non-tail-call
		  (target: "ik_stack_overflow")
		  (retval-var: #f)
		  (all-rand*: %eax %ebp %edi %esp %esi)
		  (mask: #(0))
		  (size: 1))))
	    (shortcut
		(asmcall incr/zero? %esi (constant 72) (constant 8))
	      (seq
		(asm-instr move tmp_8 (disp (constant (object $do-event)) (constant 19)))
		(asm-instr move %edi tmp_8)
		(asm-instr move %eax (constant 0))
		(non-tail-call
		  (target: #f)
		  (retval-var: #f)
		  (all-rand*: %eax %ebp %edi %esp %esi)
		  (mask: #(0))
		  (size: 1))))

	    ;;For the non-tail call to G we prepare the Scheme stack layout:
	    ;;
	    ;;           high memory
	    ;;   |                          |
	    ;;   |--------------------------|
	    ;;   |     ik_stack_overflow    | <-- FPR
	    ;;   |--------------------------|
	    ;;   |       empty word         | <- fvar.1
	    ;;   |--------------------------|
	    ;;   | stack operand = fixnum 3 | <- fvar.2
	    ;;   |--------------------------|
	    ;;   |                          |
	    ;;           low memory
	    ;;
	    ;;where the FVAR.1 will be filled by the return address.
	    ;;
	    (asm-instr move fvar.2 (constant 24))
	    (asm-instr move tmp_9 (constant (closure-maker (code-loc asmlabel:g:clambda) no-freevars)))
	    (asm-instr move tmp_10 tmp_9)
	    (asm-instr move %edi tmp_10)
	    (asm-instr move %eax (constant -8))
	    (non-tail-call
	      (target: asmlabel:g:clambda:case-1)
	      (retval-var: fvar.2)
	      (all-rand*: %eax %ebp %edi %esp %esi fvar.2)
	      (mask: #(0))
	      (size: 1))
	    (asm-instr move fvar.2 %eax)

	    ;;For the non-tail call to H we prepare the Scheme stack layout:
	    ;;
	    ;;           high memory
	    ;;   |                          |
	    ;;   |--------------------------|
	    ;;   |     ik_stack_overflow    | <-- FPR
	    ;;   |--------------------------|
	    ;;   |       empty word         | <- fvar.1
	    ;;   |--------------------------|
	    ;;   |      G return value      | <- fvar.2
	    ;;   |--------------------------|
	    ;;   |       empty word         | <- fvar.3
	    ;;   |--------------------------|
	    ;;   | stack operand = fixnum 4 | <- fvar.4
	    ;;   |--------------------------|
	    ;;   |                          |
	    ;;           low memory
	    ;;
	    ;;where the FVAR.3 will be filled by the return address.
	    ;;
	    (asm-instr move fvar.4 (constant 32))
	    (asm-instr move tmp_11 (constant (closure-maker (code-loc asmlabel:h:clambda) no-freevars)))
	    (asm-instr move tmp_12 tmp_11)
	    (asm-instr move %edi tmp_12)
	    (asm-instr move %eax (constant -8))
	    (non-tail-call
	      (target: asmlabel:h:clambda:case-1)
	      (retval-var: fvar.3)
	      (all-rand*: %eax %ebp %edi %esp %esi fvar.4)
	      (mask: #(4))
	      (size: 3))
	    (asm-instr move fvar.3 %eax)

	    ;;For the non-tail call to F we prepare the Scheme stack layout:
	    ;;
	    ;;           high memory
	    ;;   |                          |
	    ;;   |--------------------------|
	    ;;   |     ik_stack_overflow    | <-- FPR
	    ;;   |--------------------------|
	    ;;   |       empty word         | <- fvar.1
	    ;;   |--------------------------|
	    ;;   |      G return value      | <- fvar.2
	    ;;   |--------------------------|
	    ;;   |      H return value      | <- fvar.3
	    ;;   |--------------------------|
	    ;;   |                          | <- fvar.4
	    ;;   |--------------------------|
	    ;;   |                          |
	    ;;           low memory
	    ;;
	    ;;where the FVAR.1 will be filled by the return address.
	    ;;
	    (asm-instr move tmp_13 (constant (closure-maker (code-loc asmlabel:f:clambda) no-freevars)))
	    (asm-instr move tmp_14 tmp_13)
	    (asm-instr move %edi tmp_14)
	    (asm-instr move %eax (constant -16))
	    (non-tail-call
	      (target: asmlabel:f:clambda:case-2)
	      (retval-var: #f)
	      (all-rand*: %eax %ebp %edi %esp %esi fvar.2 fvar.3)
	      (mask: #(0))
	      (size: 1))

	    (asm-instr move %eax (constant 40))
	    (asmcall return %eax %ebp %esp %esi)))))

  #t)


;;;; done

(check-report)

;;; end of file
;; Local Variables:
;; eval: (put 'bind			'scheme-indent-function 1)
;; eval: (put 'fix			'scheme-indent-function 1)
;; eval: (put 'recbind			'scheme-indent-function 1)
;; eval: (put 'rec*bind			'scheme-indent-function 1)
;; eval: (put 'seq			'scheme-indent-function 0)
;; eval: (put 'conditional		'scheme-indent-function 2)
;; eval: (put 'funcall			'scheme-indent-function 1)
;; eval: (put 'library-letrec*		'scheme-indent-function 1)
;; eval: (put 'shortcut			'scheme-indent-function 1)
;; eval: (put 'non-tail-call		'scheme-indent-function 0)
;; eval: (put 'non-tail-call-frame	'scheme-indent-function 0)
;; End:
