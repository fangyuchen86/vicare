;;; -*- coding: utf-8-unix -*-
;;;
;;;Part of: Vicare Scheme
;;;Contents: tests for the compiler internals
;;;Date: Tue Oct 21, 2014
;;;
;;;Abstract
;;;
;;;	Test the compiler pass "flatten codes".
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
(check-display "*** testing Vicare compiler pass: flatten codes\n")

(compiler.generate-descriptive-labels?   #t)
(compiler.generate-debug-calls #f)

#;(debug-print-enabled? #t)


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

(define (%color-by-chaitin core-language-form)
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
	 (D (compiler.pass-color-by-chaitin D))
	 (S (compiler.unparse-recordized-code/sexp D)))
    S))

(define (%flatten-codes core-language-form)
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
	 (D (compiler.pass-color-by-chaitin D))
	 (D (compiler.pass-flatten-codes D))
	 (S (gensyms->symbols D)))
    S))

;;; --------------------------------------------------------------------

(define-syntax doit
  (syntax-rules ()
    ((_ ?core-language-form ?expected-result)
     (check
	 (%flatten-codes (quasiquote ?core-language-form))
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


(parametrise ((check-test-name	'simple-addition))

  (check
      (%specify-representation '((primitive +) '1 '2))
    => '(codes
	 ()
	 (shortcut
	     (seq
	       (asmcall nop)
	       (asmcall int+/overflow (constant 8) (constant 16)))
	   (funcall (asmcall mref (constant (object +)) (constant 19))
	     (constant 8)
	     (constant 16)))))

  (check
      (%impose-eval-order '((primitive +) '1 '2))
    => '(codes
	 ()
	 (locals
	  (local-vars: tmp_0 tmp_1)
	  (shortcut
	      (seq
		(asmcall nop)
		(asm-instr move tmp_0 (constant 8))
		(asm-instr int+/overflow tmp_0 (constant 16))
		(asm-instr move %eax tmp_0)
		(asmcall return %eax %ebp %esp %esi))
	    (seq
	      (asm-instr move tmp_1 (disp (constant (object +)) (constant 19)))
	      (asm-instr move fvar.1 (constant 8))
	      (asm-instr move fvar.2 (constant 16))
	      (asm-instr move %edi tmp_1)
	      (asm-instr move %eax (constant -16))
	      (asmcall indirect-jump %eax %ebp %edi %esp %esi fvar.1 fvar.2))))))

  (check
      (%assign-frame-sizes '((primitive +) '1 '2))
    => '(codes
	 ()
	 (locals
	  (local-vars: #(tmp_0 tmp_1) tmp_0 tmp_1)
	  (shortcut
	      (seq
		(asmcall nop)
		(asm-instr move tmp_0 (constant 8))
		(asm-instr int+/overflow tmp_0 (constant 16))
		(asm-instr move %eax tmp_0)
		(asmcall return %eax %ebp %esp %esi))
	    (seq
	      (asm-instr move tmp_1 (disp (constant (object +)) (constant 19)))
	      (asm-instr move fvar.1 (constant 8))
	      (asm-instr move fvar.2 (constant 16))
	      (asm-instr move %edi tmp_1)
	      (asm-instr move %eax (constant -16))
	      (asmcall indirect-jump %eax %ebp %edi %esp %esi fvar.1 fvar.2))))))

  (check
      (%color-by-chaitin '((primitive +) '1 '2))
    => '(codes
	 ()
	 (shortcut
	     (seq
	       ;;This nop will be discarded by the next compiler pass.
	       (asmcall nop)
	       (asm-instr move %eax (constant 8))
	       (asm-instr int+/overflow %eax (constant 16))
	       ;;This move will be discarded by the next compiler pass.
	       (asm-instr move %eax %eax)
	       (asmcall return %eax %ebp %esp %esi))
	   (seq
	     (asm-instr move %eax (constant (object +)))
	     (asm-instr move %eax (disp %eax (constant 19)))
	     (asm-instr move fvar.1 (constant 8))
	     (asm-instr move fvar.2 (constant 16))
	     (asm-instr move %edi %eax)
	     (asm-instr move %eax (constant -16))
	     (asmcall indirect-jump %eax %ebp %edi %esp %esi fvar.1 fvar.2)))))

  (doit ((primitive +) '1 '2)
	((code-object-sexp
	  (number-of-free-vars: 0)
	  (annotation:		init-expression)
	  (label L_init_expression_label_0)
	  ;;Implementation of primitive operation "+": SHORTCUT's body.
	  (movl 8 %eax)
	  (addl 16 %eax)
	  (jo (label L_shortcut_interrupt_handler_0))
	  (ret)
	  (nop)
	  ;;Implementation of primitive operation "+": SHORTCUT's interrupt handler.
	  (label L_shortcut_interrupt_handler_0)
	  (movl (obj +) %eax)
	  (movl (disp %eax 19) %eax)
	  (movl 8 (disp -8 %esp))
	  (movl 16 (disp -16 %esp))
	  (movl %eax %edi)
	  (movl -16 %eax)
	  (jmp (disp -3 %edi)))))

  #t)


(parametrise ((check-test-name	'conditionals))

  ;;CONDITIONAL in T context.
  (doit (if ((primitive read))
	    ((primitive display) '1)
	  ((primitive display) '2))
	((code-object-sexp
	  (number-of-free-vars: 0)
	  (annotation: init-expression)
	  (label L_init_expression_label_0)

	  ;;This is the body of the core primitive $STACK-OVERFLOW-CHECK.
	  (cmpl (disp %esi 32) %esp)
	  (jb (label L_shortcut_interrupt_handler_0))
	  (label L_return_from_interrupt_0)

	  ;;Call the primitive READ.
	  (movl (obj read) %eax)     ;Load the loc gensym from the relocation vector.
	  (movl (disp %eax 19) %eax) ;Retrieve the value of the PROC field.
	  (movl %eax %edi)	     ;Load in CPR the entry point of READ.
	  (movl 0 %eax)		     ;Load in AAR the number of arguments.
	  (seq			     ;Perform the non-tail call.
	    (nop)
	    (jmp (label call_label))
	    (byte-vector #(0))
	    (int 8)
	    (code-object-self-machine-word-index)
	    (label-address SL_multiple_values_error_rp)
	    (pad 10
		 (label call_label)
		 (call (disp -3 %edi)))
	    (nop))
	  ;;The single return value is now in AAR.
	  (cmpl 47 %eax) ;Compare the return value with the boolean #f.
	  (je (label L_conditional_altern_0))

	  ;;This is the CONSEQ branch of the CONDITIONAL.
	  (movl (obj display) %eax)
	  (movl (disp %eax 19) %eax)
	  (movl 8 (disp -8 %esp)) ;Put the fixnum 1 on the stack as argument.
	  (movl %eax %edi)
	  (movl -8 %eax)
	  (jmp (disp -3 %edi))

	  ;;This is the ALTERN branch of the CONDITIONAL.
	  (label L_conditional_altern_0)
	  (movl (obj display) %eax)
	  (movl (disp %eax 19) %eax)
	  (movl 16 (disp -8 %esp)) ;Put the fixnum 2 on the stack as argument.
	  (movl %eax %edi)
	  (movl -8 %eax)
	  (jmp (disp -3 %edi))

	  ;;Begin the sequence of SHORTCUT's interrupt handler routines.
	  (nop)

	  ;;This    is    the   interrupt    handler    of    the   core    primitive
	  ;;$STACK-OVERFLOW-CHECK.
	  (label L_shortcut_interrupt_handler_0)
	  (movl (foreign-label "ik_stack_overflow") %edi)
	  (movl 0 %eax)
	  (movl (foreign-label "ik_foreign_call") %ebx)
	  (seq
	    (nop)
	    (jmp (label call_label))
	    (byte-vector #(0))
	    (int 8)
	    (code-object-self-machine-word-index)
	    (label-address SL_multiple_values_ignore_rp)
	    (pad 10 (label call_label)
		 (call %ebx))
	    (nop))
	  (jmp (label L_return_from_interrupt_0)))))

;;; --------------------------------------------------------------------

  ;;CONDITIONAL in E context.
  (doit (begin
	  (if ((primitive read))
	      ((primitive display) '1)
	    ((primitive display) '2))
	  ((primitive newline)))
	((code-object-sexp
	  (number-of-free-vars: 0)
	  (annotation: init-expression)
	  (label L_init_expression_label_0)

	  ;;This is the body of the core primitive $STACK-OVERFLOW-CHECK.
	  (cmpl (disp %esi 32) %esp)
	  (jb (label L_shortcut_interrupt_handler_0))
	  (label L_return_from_interrupt_0)

	  ;;Call the primitive READ.
	  (movl (obj read) %eax)     ;Load the loc gensym from the relocation vector.
	  (movl (disp %eax 19) %eax) ;Retrieve the value of the PROC field.
	  (movl %eax %edi)	     ;Load in CPR the Assembly entry point of READ.
	  (movl 0 %eax)		     ;Load the number of argument in AAR.
	  (seq			     ;Perform the non-tail call to READ.
	    (nop)
	    (jmp (label call_label))
	    (byte-vector #(0))
	    (int 8)
	    (code-object-self-machine-word-index)
	    (label-address SL_multiple_values_error_rp)
	    (pad 10
		 (label call_label)
		 (call (disp -3 %edi)))
	    (nop))
	  ;;Now the single return value of READ is in AAR.
	  (cmpl 47 %eax) ;Compare the return value to the boolean #f.
	  (je (label L_conditional_altern_0))

	  ;;This is the CONSEQ branch of the CONDITIONAL.
	  (movl 8 (disp -16 %esp))   ;Put the fixnum 1 on the stack as argument.
	  (movl (obj display) %eax)  ;Load the loc gensym from the relocation vector.
	  (movl (disp %eax 19) %eax) ;Retrieve the value of the PROC field.
	  (movl %eax %edi) ;Load in CPR the Assembly entry point of DISPLAY.
	  (movl -8 %eax)   ;Load the number of arguments in AAR.
	  (seq		   ;Perform the non-tail call to DISPLAY.
	    (nop)
	    (jmp (label call_label))
	    (byte-vector #(0))
	    (int 8)
	    (code-object-self-machine-word-index)
	    (label-address SL_multiple_values_ignore_rp)
	    (pad 10
		 (label call_label)
		 (call (disp -3 %edi)))
	    (nop))
	  ;;Now the single return value of READ is in AAR; it is discarded.
	  (jmp (label L_conditional_end_0)) ;Jump after the CONDITIONAL.

	  ;;This is the CONSEQ branch of the CONDITIONAL.
	  (label L_conditional_altern_0)
	  (movl 16 (disp -16 %esp))  ;Put the fixnum 2 on the stack as argument.
	  (movl (obj display) %eax)  ;Load the loc gensym from the relocation vector.
	  (movl (disp %eax 19) %eax) ;Retrieve the value of the PROC field.
	  (movl %eax %edi) ;Load in CPR the Assembly entry point of DISPLAY.
	  (movl -8 %eax)   ;Load the number of arguments in AAR.
	  (seq		   ;Perform the non-tail call to DISPLAY.
	    (nop)
	    (jmp (label call_label))
	    (byte-vector #(0))
	    (int 8)
	    (code-object-self-machine-word-index)
	    (label-address SL_multiple_values_ignore_rp)
	    (pad 10
		 (label call_label)
		 (call (disp -3 %edi)))
	    (nop))

	  (label L_conditional_end_0)

	  ;;Here we are past the conditional.
	  (movl (obj newline) %eax)  ;Load the loc gensym from the relocation vector.
	  (movl (disp %eax 19) %eax) ;Retrieve the value of the PROC field.
	  (movl %eax %edi)	     ;Load in CPR the entry point of NEWLINE.
	  (movl 0 %eax)		     ;Load in AAR the number of arguments.
	  (jmp (disp -3 %edi))	     ;Perform the tail call to NEWLINE.

	  ;;Begin the sequence of SHORTCUT's interrupt handler routines.
	  (nop)

	  ;;This    is    the   interrupt    handler    of    the   core    primitive
	  ;;$STACK-OVERFLOW-CHECK.
	  (label L_shortcut_interrupt_handler_0)
	  (movl (foreign-label "ik_stack_overflow") %edi)
	  (movl 0 %eax)
	  (movl (foreign-label "ik_foreign_call") %ebx)
	  (seq
	    (nop)
	    (jmp (label call_label))
	    (byte-vector #(0))
	    (int 8)
	    (code-object-self-machine-word-index)
	    (label-address SL_multiple_values_ignore_rp)
	    (pad 10
		 (label call_label)
		 (call %ebx))
	    (nop))
	  (jmp (label L_return_from_interrupt_0)))))

;;; --------------------------------------------------------------------

  ;;CONDITIONAL in P context, as test for CONDITIONAL in T context.
  (doit (if (if ((primitive read))
		((primitive read))
	      ((primitive read)))
	    ((primitive display) '1)
	  ((primitive display) '2))
	((code-object-sexp
	  (number-of-free-vars: 0)
	  (annotation: init-expression)
	  (label L_init_expression_label_0)

	  ;;This is the body of the core primitive $STACK-OVERFLOW-CHECK.
	  (cmpl (disp %esi 32) %esp)
	  (jb (label L_shortcut_interrupt_handler_0))
	  (label L_return_from_interrupt_0)

	  ;;This is  the TEST  expression of  the inner  CONDITIONAL.  Call  the READ
	  ;;primitive.
	  (movl (obj read) %eax)
	  (movl (disp %eax 19) %eax)
	  (movl %eax %edi)
	  (movl 0 %eax)
	  (seq
	    (nop)
	    (jmp (label call_label))
	    (byte-vector #(0))
	    (int 8)
	    (code-object-self-machine-word-index)
	    (label-address SL_multiple_values_error_rp)
	    (pad 10
		 (label call_label)
		 (call (disp -3 %edi)))
	    (nop))
	  ;;If the result is false: jump to the inner altern.
	  (cmpl 47 %eax)
	  (je (label L_inner_conditional_altern_0))

	  ;;This is  the CONSEQ expression of  the inner CONDITIONAL.  Call  the READ
	  ;;primitive.
	  (movl (obj read) %eax)
	  (movl (disp %eax 19) %eax)
	  (movl %eax %edi)
	  (movl 0 %eax)
	  (seq
	    (nop)
	    (jmp (label call_label))
	    (byte-vector #(0))
	    (int 8)
	    (code-object-self-machine-word-index)
	    (label-address SL_multiple_values_error_rp)
	    (pad 10
		 (label call_label)
		 (call (disp -3 %edi)))
	    (nop))
	  ;;If the result  is non-false: jump to the outer  CONSEQ; otherwise jump to
	  ;;the outer ALTERN.
	  (cmpl 47 %eax)
	  (jne (label L_outer_conditional_conseq_0))
	  (jmp (label L_conditional_altern_0))

	  ;;This is  the ALTERN expression of  the inner CONDITIONAL.  Call  the READ
	  ;;primitive.
	  (label L_inner_conditional_altern_0)
	  (movl (obj read) %eax)
	  (movl (disp %eax 19) %eax)
	  (movl %eax %edi)
	  (movl 0 %eax)
	  (seq
	    (nop)
	    (jmp (label call_label))
	    (byte-vector #(0))
	    (int 8)
	    (code-object-self-machine-word-index)
	    (label-address SL_multiple_values_error_rp)
	    (pad 10
		 (label call_label)
		 (call (disp -3 %edi)))
	    (nop))
	  ;;If the  result is  false: jump  to the  outer ALTERN.   If the  result is
	  ;;non-false: fall through to the outer CONSEQ, which is directly below.
	  (cmpl 47 %eax)
	  (je (label L_conditional_altern_0))

	  ;;This is the CONSEQ expression of the outer CONDITIONAL.
	  (label L_outer_conditional_conseq_0)
	  (movl (obj display) %eax)
	  (movl (disp %eax 19) %eax)
	  (movl 8 (disp -8 %esp))
	  (movl %eax %edi)
	  (movl -8 %eax)
	  (jmp (disp -3 %edi))

	  ;;This is the ALTERN expression of the outer CONDITIONAL.
	  (label L_conditional_altern_0)
	  (movl (obj display) %eax)
	  (movl (disp %eax 19) %eax)
	  (movl 16 (disp -8 %esp))
	  (movl %eax %edi)
	  (movl -8 %eax)
	  (jmp (disp -3 %edi))

	  ;;Begin the sequence of SHORTCUT's interrupt handler routines.
	  (nop)

	  ;;This    is    the   interrupt    handler    of    the   core    primitive
	  ;;$STACK-OVERFLOW-CHECK.
	  (label L_shortcut_interrupt_handler_0)
	  (movl (foreign-label "ik_stack_overflow") %edi)
	  (movl 0 %eax)
	  (movl (foreign-label "ik_foreign_call") %ebx)
	  (seq
	    (nop)
	    (jmp (label call_label))
	    (byte-vector #(0))
	    (int 8)
	    (code-object-self-machine-word-index)
	    (label-address SL_multiple_values_ignore_rp)
	    (pad 10
		 (label call_label)
		 (call %ebx))
	    (nop))
	  (jmp (label L_return_from_interrupt_0)))))

  #t)


(parametrise ((check-test-name	'shortcut-in-predicate-context))

  (doit (let ((x ((primitive read))))
	  (if ((primitive fl=?) x '1.0)
	      ((primitive newline))
	    ((primitive newline))))
	((code-object-sexp
	  (number-of-free-vars: 0)
	  (annotation: init-expression)
	  (label L_init_expression_label_0)

	  ;;This is the body of the core primitive $STACK-OVERFLOW-CHECK.
	  (cmpl (disp %esi 32) %esp)
	  (jb (label L_shortcut_interrupt_handler_1))
	  (label L_return_from_interrupt_0)

	  ;;Call the READ primitive.
	  (movl (obj read) %eax)
	  (movl (disp %eax 19) %eax)
	  (movl %eax %edi)
	  (movl 0 %eax)
	  (seq
	    (nop)
	    (jmp (label call_label))
	    (byte-vector #(0))
	    (int 8)
	    (code-object-self-machine-word-index)
	    (label-address SL_multiple_values_error_rp)
	    (pad 10 (label call_label)
		 (call (disp -3 %edi)))
	    (nop))
	  (movl %eax %ebx)

	  ;;This is the  body of the core  primitive operation FL=?.  It  is also the
	  ;;test expression of the CONDITIONAL.
	  (movl %ebx %edi)
	  (movl %edi %eax)
	  ;;Check that  the first operand  is a  fixnum.  If it  is not: jump  to the
	  ;;interrupt handler.
	  (andl 7 %eax)
	  (cmpl 5 %eax)
	  (jne (label L_shortcut_interrupt_handler_0))
	  (cmpl 23 (disp %edi -5))
	  (jne (label L_shortcut_interrupt_handler_0))
	  ;;Load the first operand in XMM0.
	  (movsd (disp 3 %ebx) xmm0)
	  ;;Load the second operand.
	  (movl (obj 1.0) %eax)
	  ;;Compare the operands.
	  (ucomisd (disp %eax 3) xmm0)
	  ;;If not equal: jump to the ALTERN.  Otherwise fall through to the CONSEQ.
	  (jp (label L_conditional_altern_0))
	  (jne (label L_conditional_altern_0))

	  (label L_shortcut_end_0)

	  ;;This is the CONSEQ.
	  (movl (obj newline) %eax)
	  (movl (disp %eax 19) %eax)
	  (movl %eax %edi)
	  (movl 0 %eax)
	  (jmp (disp -3 %edi))

	  ;;This is the ALTERN.
	  (label L_conditional_altern_0)
	  (movl (obj newline) %eax)
	  (movl (disp %eax 19) %eax)
	  (movl %eax %edi)
	  (movl 0 %eax)
	  (jmp (disp -3 %edi))

	  ;;Start the sequence of interrupt handler routines.
	  (nop)

	  ;;This is the handler of the core primitive $STACK-OVERFLOW-CHECK.
	  (label L_shortcut_interrupt_handler_1)
	  (movl (foreign-label "ik_stack_overflow") %edi)
	  (movl 0 %eax)
	  (movl (foreign-label "ik_foreign_call") %ebx)
	  (seq
	    (nop)
	    (jmp (label call_label))
	    (byte-vector #(0))
	    (int 8)
	    (code-object-self-machine-word-index)
	    (label-address SL_multiple_values_ignore_rp)
	    (pad 10
		 (label call_label)
		 (call %ebx))
	    (nop))
	  (jmp (label L_return_from_interrupt_0))

	  ;;This is the handler of the core primitive FL=?.
	  (label L_shortcut_interrupt_handler_0)
	  (movl %ebx (disp -16 %esp))	;Put the first operand on the stack.
	  (movl (obj 1.0) %eax)		;Load the second operand.
	  (movl %eax (disp -24 %esp))	;Put the second operand on the stack.
	  (movl (obj fl=?) %eax)	;Retrieve the loc gensym.
	  (movl (disp %eax 19) %eax)	;Retrieve the PROC field of the loc gensym.
	  (movl %eax %edi)		;Put the function entry point in the CPR.
	  (movl -16 %eax)		;Store in AAR the encoded number of arguments.
	  (seq				;Perform the tail call.
	    (nop)
	    (jmp (label call_label))
	    (byte-vector #(0))
	    (int 8)
	    (code-object-self-machine-word-index)
	    (label-address SL_multiple_values_error_rp)
	    (pad 10
		 (label call_label)
		 (call (disp -3 %edi)))
	    (nop))
	  ;;Compare the result with the boolean #f.
	  (cmpl 47 %eax)
	  ;;If the result is non-false: jump to the SHORTCUT's end.
	  (jne (label L_shortcut_end_0))
	  ;;If the retult is #f: jump to the CONDITIONAL altern.
	  (jmp (label L_conditional_altern_0)))))

  #t)


(parametrise ((check-test-name	'conditional-with-constant-branches))

  (doit (if ((primitive read))
	    (quote #t)
	  (quote #t))
	((code-object-sexp
	  (number-of-free-vars: 0)
	  (annotation: init-expression)
	  (label L_init_expression_label_0)

	  ;;This is the body of the core primitive $STACK-OVERFLOW-CHECK.
	  (cmpl (disp %esi 32) %esp)
	  (jb (label L_shortcut_interrupt_handler_0))
	  (label L_return_from_interrupt_0)

	  ;;Call the primitive READ.
	  (movl (obj read) %eax)
	  (movl (disp %eax 19) %eax)
	  (movl %eax %edi)
	  (movl 0 %eax)
	  (seq
	    (nop)
	    (jmp (label call_label))
	    (byte-vector #(0))
	    (int 8)
	    (code-object-self-machine-word-index)
	    (label-address SL_multiple_values_error_rp)
	    (pad 10 (label call_label)
		 (call (disp -3 %edi)))
	    (nop))
	  ;;The result is in AAR.  Jump to ALTERN if the result is #f; otherwise fall
	  ;;through to the CONSEQ.
	  (cmpl 47 %eax)
	  (je (label L_conditional_altern_0))

	  ;;This is the CONDITIONAL conseq.
	  (movl 63 %eax)
	  (ret)

	  ;;This is the CONDITIONAL altern.
	  (label L_conditional_altern_0)
	  (movl 63 %eax)
	  (ret)

	  ;;Start the sequence of interrupt handlers.
	  (nop)

	  (label L_shortcut_interrupt_handler_0)
	  (movl (foreign-label "ik_stack_overflow") %edi)
	  (movl 0 %eax)
	  (movl (foreign-label "ik_foreign_call") %ebx)
	  (seq
	    (nop)
	    (jmp (label call_label))
	    (byte-vector #(0))
	    (int 8)
	    (code-object-self-machine-word-index)
	    (label-address SL_multiple_values_ignore_rp)
	    (pad 10
		 (label call_label)
		 (call %ebx))
	    (nop))
	  (jmp (label L_return_from_interrupt_0)))))

;;; --------------------------------------------------------------------

  (doit (if (if ((primitive read))
		(quote #t)
	      (quote #t))
	    '1
	  '2)
	((code-object-sexp
	  (number-of-free-vars: 0)
	  (annotation: init-expression)
	  (label L_init_expression_label_0)

	  ;;This is the body of the core primitive $STACK-OVERFLOW-CHECK.
	  (cmpl (disp %esi 32) %esp)
	  (jb (label L_shortcut_interrupt_handler_0))
	  (label L_return_from_interrupt_0)

	  ;;Call the primitive READ.
	  (movl (obj read) %eax)
	  (movl (disp %eax 19) %eax)
	  (movl %eax %edi)
	  (movl 0 %eax)
	  (seq
	    (nop)
	    (jmp (label call_label))
	    (byte-vector #(0))
	    (int 8)
	    (code-object-self-machine-word-index)
	    (label-address SL_multiple_values_error_rp)
	    (pad 10
		 (label call_label)
		 (call (disp -3 %edi)))
	    (nop))
	  ;;The result is in  AAR.  Compare it to #f.
	  ;;
	  ;;NOTE Mh...  yes, this  code could  be better.  (Marco  Maggi; Sun  Nov 2,
	  ;;2014)
	  (cmpl 47 %eax)
	  (je (label L_conditional_altern_0))
	  (jmp (label L_conditional_end_0))

	  (label L_conditional_altern_0)
	  (label L_conditional_end_0)
	  (movl 8 %eax)
	  (ret)

	  ;;Start the sequence of interrupt handlers.
	  (nop)

	  ;;This    is    the   interrupt    handler    of    the   core    primitive
	  ;;$STACK-OVERFLOW-CHECK.
	  (label L_shortcut_interrupt_handler_0)
	  (movl (foreign-label "ik_stack_overflow") %edi)
	  (movl 0 %eax)
	  (movl (foreign-label "ik_foreign_call") %ebx)
	  (seq
	    (nop)
	    (jmp (label call_label))
	    (byte-vector #(0))
	    (int 8)
	    (code-object-self-machine-word-index)
	    (label-address SL_multiple_values_ignore_rp)
	    (pad 10
		 (label call_label)
		 (call %ebx))
	    (nop))
	  (jmp (label L_return_from_interrupt_0)))))

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
