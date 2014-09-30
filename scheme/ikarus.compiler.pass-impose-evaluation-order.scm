;;;Ikarus Scheme -- A compiler for R6RS Scheme.
;;;Copyright (C) 2006,2007,2008  Abdulaziz Ghuloum
;;;Modified by Marco Maggi <marco.maggi-ipsu@poste.it>
;;;
;;;This program is free software:  you can redistribute it and/or modify
;;;it under  the terms of  the GNU General  Public License version  3 as
;;;published by the Free Software Foundation.
;;;
;;;This program is  distributed in the hope that it  will be useful, but
;;;WITHOUT  ANY   WARRANTY;  without   even  the  implied   warranty  of
;;;MERCHANTABILITY or  FITNESS FOR  A PARTICULAR  PURPOSE.  See  the GNU
;;;General Public License for more details.
;;;
;;;You should  have received a  copy of  the GNU General  Public License
;;;along with this program.  If not, see <http://www.gnu.org/licenses/>.


(module (impose-calling-convention/evaluation-order)
  ;;This module does stuff:
  ;;
  ;;*  All the  BIND  struct instances  in  the input  expression  are processed  and
  ;;substituted with code that evaluates the  RHS expressions and stores their single
  ;;return value into appropriately allocated Scheme stack machine words.  Here it is
  ;;decided in which order the RHS expressions are computed.
  ;;
  ;;*  All the  FUNCALL  struct  instances in  the  input  expression representing  a
  ;;function call:
  ;;
  ;;   (funcall (asmcall mref
  ;;                    (constant (object ?loc))
  ;;                    (constant ?off-symbol-record-proc))
  ;;            (?rand ...))
  ;;
  ;;are converted to:
  ;;
  ;;   (bind ((tmp ?rand) ...)
  ;;     (funcall (asmcall mref
  ;;                      (constant (object ?loc))
  ;;                      (constant ?off-symbol-record-proc))
  ;;              (tmp ...)))
  ;;
  ;;so that the order of evaluation of the operands' expressions is decided.
  ;;
  ;;*  All the  ASMCALL  struct  instances in  the  input  expression representing  a
  ;;high-level Assembly instruction:
  ;;
  ;;   (asmcall ?instr (?rand ...))
  ;;
  ;;are converted to the equivalent of:
  ;;
  ;;   (bind ((tmp ?rand) ...)
  ;;     (asmcall ?instr (tmp ...)))
  ;;
  ;;so that the order of evaluation of the operands' expressions is decided.
  ;;
  ;;This module  accepts as  input a  struct instance of  type CODES,  whose internal
  ;;recordized code must be composed by struct instances of the following types:
  ;;
  ;;   bind		conditional		constant
  ;;   forcall		funcall			jmpcall
  ;;   known		asmcall			seq
  ;;   shortcut		var
  ;;
  ;;in addition CLOSURE-MAKER structs can appear in side CONSTANT structs.
  ;;
  (import INTEL-ASSEMBLY-CODE-GENERATION)


;;;;

(define-syntax __module_who__
  (identifier-syntax 'impose-calling-convention/evaluation-order))

(define (impose-calling-convention/evaluation-order x)
  (Program x))

;;; --------------------------------------------------------------------

(define locals
  (make-parameter #f))

(define-syntax-rule (%locals-cons ?A)
  (locals (cons ?A (locals))))

(define-syntax-rule (%locals-cons* ?A0 ?A ...)
  (locals (cons* ?A0 ?A ... (locals))))

;;; --------------------------------------------------------------------

(module (Program)

  (define (Program x)
    (struct-case x
      ((codes x.code* x.body)
       (make-codes (map Clambda x.code*) (Main x.body)))))

  (define (Clambda x)
    (struct-case x
      ((clambda x.label x.case* x.cp x.freevar* x.name)
       (make-clambda x.label (map ClambdaCase x.case*) x.cp x.freevar* x.name))))

  (module (ClambdaCase)

    (define (ClambdaCase cas)
      (struct-case cas
	((clambda-case cas.info cas.body)
	 (struct-case cas.info
	   ;;Remember that CAS.INFO.ARGS  is a proper list of VAR  structs with the
	   ;;format:
	   ;;
	   ;;   (?cpvar ?arg ...)
	   ;;
	   ;;where: ?CPVAR  represents a machine word  that must hold a  pointer to
	   ;;the closure object; each ?ARG represents a machine word that must hold
	   ;;a CLAMBDA clause's argument.
	   ((case-info cas.info.label cas.info.args cas.info.proper)
	    (receive (register-args register-names stack-args stack-locations)
		(%partition-formals PARAMETER-REGISTERS cas.info.args)
	      ;;The  arguments  listed  in  REGISTER-ARGS will  be  stored  in  the
	      ;;registers  listed  in  REGISTER-NAMES.   The  arguments  listed  in
	      ;;STACK-ARGS will be stored in  the Scheme stack machine words listed
	      ;;in STACK-LOCATIONS.
	      (parametrise ((locals register-args))
		($for-each/stx set-var-loc! stack-args stack-locations)
		(let ((body (let recur ((args register-args)
					(locs register-names))
			      (if (pair? args)
				  (make-seq (%move-dst<-src (car args) (car locs))
					    (recur          (cdr args) (cdr locs)))
				(Tail cas.body)))))
		  (make-clambda-case
		   (make-case-info cas.info.label (append register-names stack-locations) cas.info.proper)
		   (make-locals (locals) body))))))))))

    (define (%partition-formals available-registers formals)
      ;;Recursive function.  Associate the formals of a CLAMBDA clause to available
      ;;CPU registers.
      ;;
      ;;AVAILABLE-REGISTERS must  be a list  of symbols representing  available CPU
      ;;registers.
      ;;
      ;;FORMALS must be a list of CLAMBDA clause's formals.
      ;;
      ;;Return 4 values:
      ;;
      ;;1.  The  list of  lex gensyms representing  formal arguments  associated to
      ;;   available registers.
      ;;
      ;;2. The  list of  symbols representing register  names associated  to formal
      ;;   arguments.
      ;;
      ;;3. The list of lex gensyms representing formal arguments associated to FVAR
      ;;   structures.
      ;;
      ;;4. The list of FVAR structures associated to formals.
      ;;
      (cond ((null? available-registers)
	     ;;If  the number  of formals  is <=  of the  number of  registers: the
	     ;;left-over  registers  are  associated   to  FVAR  structures,  which
	     ;;represent Scheme stack machine words.
	     (let ((stack-locations (%one-fvar-for-each-left-over-formal 1 formals)))
	       (values '() '() formals stack-locations)))
	    ((null? formals)
	     ;;If there are more registers than formals: fine.
	     (values '() '() '() '()))
	    (else
	     ;;If there is a register for the next formal: associate them.
	     (receive (register-args register-names stack-args stack-locations)
		 (%partition-formals (cdr available-registers) (cdr formals))
	       (values (cons (car formals)             register-args)
		       (cons (car available-registers) register-names)
		       stack-args stack-locations)))))

    (define (%one-fvar-for-each-left-over-formal i leftover-formal)
      (if (pair? leftover-formal)
	  (cons (mkfvar i)
		(%one-fvar-for-each-left-over-formal (fxadd1 i) (cdr leftover-formal)))
	'()))

    #| end of module: ClambdaCase |# )

  (define (Main x)
    (parametrise ((locals '()))
      (let ((x (Tail x)))
	(make-locals (locals) x))))

  (module (Tail)

    (define (Tail x)
      (struct-case x

	((constant)
	 (VT x))

	((var)
	 (VT x))

	((asmcall op rands)
	 (case op
	   ((call-with-underflow-handler)
	    ;;This    primitive    is    used   by    the    primitive    operation
	    ;;$SEAL-FRAME-AND-CALL  to implement  the heart  of CALL/CC  (call with
	    ;;current  continuation) and  CALL/CF (call  with current  frame), file
	    ;;"ikarus.control.sls".   Let's super  simplify  and  comment the  code
	    ;;starting with  the call to  %PRIMITIVE-CALL/CF which is the  heart of
	    ;;both CALL/CC and CALL/CF.
	    ;;
	    ;;Remember that:
	    ;;
	    ;;* FPR stands for Frame Pointer Register;
	    ;;
	    ;;*  PCR stands  for Process  Control  Register and  it references  the
	    ;;structure PCB defined at the C language level;
	    ;;
	    ;;*  CPR stands  for Closure  Pointer Register  and it  must contain  a
	    ;;reference to the closure object being executed.
	    ;;
	    ;;* ARGC-REGISTER stands for Argument Count Register.
	    ;;
	    ;;When arriving here  the scenario of the Scheme stack  is the one left
	    ;;by $SEAL-FRAME-AND-CALL:
	    ;;
	    ;;         high memory
	    ;;   |                      |
	    ;;   |----------------------|
	    ;;   | ik_underflow_handler |
	    ;;   |----------------------|                           --
	    ;;     ... other frames ...                             .
	    ;;   |----------------------|                           .
	    ;;   |      local value     |                           . freezed
	    ;;   |----------------------|                           . frames
	    ;;   |      local value     |                           .
	    ;;   |----------------------|                           .
	    ;;   |     return address   | <- FPR = pcb->frame_base  .
	    ;;   |----------------------|                           --
	    ;;   |         func         | -> closure object
	    ;;   |----------------------|
	    ;;             ...
	    ;;   |----------------------|
	    ;;   |      free word       | <- pcb->stack_base
	    ;;   |----------------------|
	    ;;   |                      |
	    ;;          low memory
	    ;;
	    ;;ARGC-REGISTER contains the encoded  number of arguments, counting the
	    ;;single  argument FUNC  to %PRIMITIVE-CALL/CF.   The reference  to the
	    ;;just created  continuation object is  in some CPU register.   The raw
	    ;;memory pointer UNDERFLOW-HANDLER is in some CPU register.
	    ;;
	    ;;There are 3 operands in RANDS:
	    ;;
	    ;;*  A representation  of  the CPU  register  containing the  underflow
	    ;;handler:  a   raw  memory  address   equal  to  the   assembly  label
	    ;;"ik_underflow_handler".
	    ;;
	    ;;* A representation of the stack location containing FUNC.
	    ;;
	    ;;* A representation of the CPU  register containing a reference to the
	    ;;continuation   object   referencing   the   freezed   frames.    Such
	    ;;continuation object  is also the  "next process continuation"  in the
	    ;;PCB, that is: it is the value of the field "pcb->next_k".
	    ;;
	    (let ((t0			(make-unique-var 't))
		  (t1			(make-unique-var 't))
		  (t2			(make-unique-var 't))
		  (underflow-handler	(car rands))
		  (func		(cadr rands))
		  (kont-object	(caddr rands)))
	      (%locals-cons* t0 t1 t2)
	      (multiple-forms-sequence
	       ;;Copy the arguments in CPU registers.
	       (V t0 underflow-handler)
	       (V t1 kont-object)
	       (V t2 func)
	       ;;Move IK_UNDERFLOW_HANDLER in  its reserved slot the  on the Scheme
	       ;;stack.
	       (%move-dst<-src (mkfvar 1) t0)
	       ;;Move the the reference to continuation object in its reserved slog
	       ;;on the Scheme stack, as argument to THE-FUNC.
	       (%move-dst<-src (mkfvar 2) t1)
	       ;;When we arrive here the situation on the Scheme stack is:
	       ;;
	       ;;         high memory
	       ;;   |                      |
	       ;;   |----------------------|
	       ;;   | ik_underflow_handler |
	       ;;   |----------------------|                           --
	       ;;     ... other frames ...                             .
	       ;;   |----------------------|                           .
	       ;;   |      local value     |                           . freezed
	       ;;   |----------------------|                           . frames
	       ;;   |      local value     |                           .
	       ;;   |----------------------|                           .
	       ;;   |     return address   | <- FPR = pcb->frame_base  .
	       ;;   |----------------------|                           --
	       ;;   | ik_underflow_handler |
	       ;;   |----------------------|
	       ;;   |         kont         | -> continuation object
	       ;;   |----------------------|
	       ;;             ...
	       ;;   |----------------------|
	       ;;   |      free word       | <- pcb->stack_base
	       ;;   |----------------------|
	       ;;   |                      |
	       ;;          low memory
	       ;;
	       ;;Load the reference to closure object FUNC in the CPR.
	       (%move-dst<-src cpr t2)
	       ;;Load in  ARGC-REGISTER the  encoded number of  arguments, counting
	       ;;the continuation object.
	       (%move-dst<-src ARGC-REGISTER (make-constant (argc-convention 1)))
	       ;;Decrement the FPR so that it points to the underflow handler.
	       (make-asm-instr 'int- fpr (make-constant wordsize))
	       ;;When we arrive here the situation on the Scheme stack is:
	       ;;
	       ;;         high memory
	       ;;   |                      |
	       ;;   |----------------------|
	       ;;   | ik_underflow_handler |
	       ;;   |----------------------|                     --
	       ;;     ... other frames ...                       .
	       ;;   |----------------------|                     .
	       ;;   |      local value     |                     . freezed
	       ;;   |----------------------|                     . frames
	       ;;   |      local value     |                     .
	       ;;   |----------------------|                     .
	       ;;   |     return address   | <- pcb->frame_base  .
	       ;;   |----------------------|                     --
	       ;;   | ik_underflow_handler | <- FPR
	       ;;   |----------------------|
	       ;;   |         kont         | -> continuation object
	       ;;   |----------------------|
	       ;;             ...
	       ;;   |----------------------|
	       ;;   |      free word       | <- pcb->stack_base
	       ;;   |----------------------|
	       ;;   |                      |
	       ;;          low memory
	       ;;
	       ;;The following INDIRECT-JUMP compiles to a single "jmp" instruction
	       ;;that  jumps  to  the  machine  code entry  point  in  the  closure
	       ;;referenced by  the CPR, which is  FUNC.  By doing a  "jmp", rather
	       ;;than a  "call", we avoid  pushing a  return address on  the Scheme
	       ;;stack.
	       ;;
	       ;;Notice that the stack frame of FUNC starts with the argument KONT.
	       ;;The  IK_UNDERFLOW_HANDLER we  have  put on  the  stack does  *not*
	       ;;belong to any stack frame.
	       ;;
	       ;;If the closure FUNC returns  without calling a continuation escape
	       ;;function: it will return to  the underflow handler; such underflow
	       ;;handler must  pop the  continuation object from  "pcb->next_k" and
	       ;;process it as explained in the documentation.
	       ;;
	       (make-asmcall 'indirect-jump
		 (list ARGC-REGISTER cpr pcr esp apr (mkfvar 1) (mkfvar 2))))))
	   (else
	    (VT x))))

	((bind lhs* rhs* e)
	 (%do-bind lhs* rhs* (Tail e)))

	((seq e0 e1)
	 (make-seq (E e0) (Tail e1)))

	((conditional e0 e1 e2)
	 (make-conditional (P e0) (Tail e1) (Tail e2)))

	((funcall rator rands)
	 (%handle-tail-call #f rator rands))

	((jmpcall label rator rands)
	 (%handle-tail-call (make-code-loc label) rator rands))

	((forcall)
	 (VT x))

	((shortcut body handler)
	 (make-shortcut (Tail body) (Tail handler)))

	((known expr)
	 (Tail expr))

	(else
	 (error __module_who__ "invalid tail" x))))

    (define (VT x)
      ;;X is a struct of type: CONSTANT, VAR, ASMCALL, FORCALL.
      ;;
      (S x (lambda (x)
	     (make-seq (%move-dst<-src RETURN-VALUE-REGISTER x)
		       (make-asmcall 'return (list pcr esp apr RETURN-VALUE-REGISTER))))))

    #| end of module: Tail |# )

  #| end of module: Program |# )


;;;; helpers

(define (S* x* kont)
  (if (pair? x*)
      (S (car x*) (lambda (a)
		    (S* (cdr x*) (lambda (d)
				   (kont (cons a d))))))
    (kont '())))

(define (S x kont)
  (struct-case x
    ((bind lhs* rhs* body)
     (%do-bind lhs* rhs* (S body kont)))
    ((seq e0 e1)
     (make-seq (E e0) (S e1 kont)))
    ((known expr)
     (S expr kont))
    (else
     (cond ((or (constant? x)
		(symbol?   x))
	    (kont x))
	   ((var? x)
	    (cond ((var-loc x)
		   => kont)
		  (else
		   (kont x))))
	   ((or (funcall? x) (asmcall? x) (jmpcall? x)
		(forcall? x) (shortcut? x) (conditional? x))
	    (let ((t (make-unique-var 'tmp)))
	      (%do-bind (list t) (list x) (kont t))))
	   (else
	    (error __module_who__ "invalid S" x))))))

(define (assign* lhs* rhs* tail-body)
  ;;Given a list of left-hand  sides and right-hand sides for assembly
  ;;assignments,  build  and  return a  struct  instance  representing
  ;;recordized code for this pseudo-code:
  ;;
  ;;   (begin
  ;;     (move ?lhs ?rhs)
  ;;     ...
  ;;     . ?tail-body)
  ;;
  (if (pair? lhs*)
      (make-seq (%move-dst<-src (car lhs*) (car rhs*))
		(assign*        (cdr lhs*) (cdr rhs*) tail-body))
    tail-body))



(define (%do-bind lhs* rhs* body)
  (if (pair? lhs*)
      (begin
	(%locals-cons (car lhs*))
	(make-seq (V (car lhs*) (car rhs*))
		  (%do-bind (cdr lhs*) (cdr rhs*) body)))
    body))

(define-syntax-rule (%move-dst<-src ?lhs ?rhs)
  (make-asm-instr 'move ?lhs ?rhs))

(define (%do-bind-frmt* nf* v* ac)
  (if (pair? nf*)
      (make-seq (V (car nf*) (car v*))
		(%do-bind-frmt* (cdr nf*) (cdr v*) ac))
    ac))


(module (alloc-check alloc-check/no-hooks)

  (define (alloc-check size)
    (E (make-shortcut
	   (make-conditional (%test size)
	       (nop)
	     (interrupt))
	 (make-funcall
	  ;;From the  relocation vector of  this code object: retrieve  the location
	  ;;gensym associated to DO-OVERFLOW, then  retrieve the value of its "proc"
	  ;;slot.  The  "proc" slot of such  loc gensym contains a  reference to the
	  ;;closure object implementing DO-OVERFLOW.
	  (make-asmcall 'mref
	    (list (make-constant (make-object (primitive-public-function-name->location-gensym 'do-overflow)))
		  (make-constant off-symbol-record-proc)))
	  (list size)))))

  (define (alloc-check/no-hooks size)
    (E (make-shortcut
	   (make-conditional (%test size)
	       (nop)
	     (interrupt))
	 (make-forcall "ik_collect" (list size)))))

  (define (%test size)
    (if (struct-case size
	  ((constant i)
	   (<= i 4096))
	  (else
	   #f))
	(make-asmcall '<=
	  (list apr
		(make-asmcall 'mref
		  (list pcr (make-constant pcb-allocation-redline)))))
      (make-asmcall '>=
	(list (make-asmcall 'int-
		(list (make-asmcall 'mref
			(list pcr (make-constant pcb-allocation-redline)))
		      apr))
	      size))))

  #| end of module: ALLOC-CHECK, ALLOC-CHECK/NO-HOOKS |# )


(define (V d x)
  ;;Generate assembly instructions  to compute a value from struct  X and store the
  ;;result in destination D.
  ;;
  ;;We can think of D as an allocated  machine word on the stack which will receive
  ;;the result of a subexpression computation.
  ;;
  (struct-case x
    ((constant)
     (%move-dst<-src d x))

    ((var)
     (cond ((var-loc x)
	    => (lambda (loc)
		 (%move-dst<-src d loc)))
	   (else
	    (%move-dst<-src d x))))
    ((bind lhs* rhs* e)
     (%do-bind lhs* rhs* (V d e)))

    ((seq e0 e1)
     (make-seq (E e0) (V d e1)))

    ((conditional e0 e1 e2)
     (make-conditional (P e0) (V d e1) (V d e2)))

    ((asmcall op rands)
     (case op

       ((alloc)
	;;Allocate a Scheme object on  the heap.  First check if there
	;;is  enough room  on  the  heap segment:
	;;
	;;*  If  there  is:  just  increment  the  Allocation  Pointer
	;;  Register (APR) and return the old APR value.
	;;
	;;* If there  is not: run a garbage  collection (complete with
	;;   execution  of  post-GC  hooks) by  calling  the  function
	;;  DO-OVERFLOW, then increment the APR and return the old APR
	;;  after the GC.
	;;
	(S (car rands)
	   (lambda (size)
	     (make-seq (alloc-check size)
		       (S (cadr rands)
			  (lambda (tag)
			    (make-seq (make-seq (%move-dst<-src d apr)
						(make-asm-instr 'logor d tag))
				      (make-asm-instr 'int+ apr size))))))))

       ((alloc-no-hooks)
	;;This is like ALLOC, but, if there is the need, run a garbage
	;;collection without executing the post-GC hooks.
	;;
	;;This  simpler  GC  run  does not  touch  the  Scheme  stack,
	;;avoiding the  generation of corrupt continuation  objects by
	;;the  primitive operation  $SEAL-FRAME-AND-CALL (which  was a
	;;cause of issue #35).
	;;
	;;$SEAL-FRAME-AND-CALL should be the only operation making use
	;;of this heap allocation method.
	;;
	(S (car rands)
	   (lambda (size)
	     (make-seq (alloc-check/no-hooks size)
		       (S (cadr rands)
			  (lambda (tag)
			    (make-seq (make-seq (%move-dst<-src d apr)
						(make-asm-instr 'logor d tag))
				      (make-asm-instr 'int+ apr size))))))))

       ((mref)
	(S* rands (lambda (rands)
		    (%move-dst<-src d (make-disp (car rands) (cadr rands))))))

       ((mref32)
	(S* rands (lambda (rands)
		    (make-asm-instr 'load32 d (make-disp (car rands) (cadr rands))))))

       ((bref)
	(S* rands (lambda (rands)
		    (make-asm-instr 'load8 d (make-disp (car rands) (cadr rands))))))

       ((logand logxor logor int+ int- int*
		int-/overflow int+/overflow int*/overflow)
	(make-seq (V d (car rands))
		  (S (cadr rands) (lambda (s)
				    (make-asm-instr op d s)))))
       ((int-quotient)
	(S* rands (lambda (rands)
		    (multiple-forms-sequence
		     (%move-dst<-src eax (car rands))
		     (make-asm-instr 'cltd edx eax)
		     (make-asm-instr 'idiv eax (cadr rands))
		     (%move-dst<-src d eax)))))

       ((int-remainder)
	(S* rands (lambda (rands)
		    (multiple-forms-sequence
		     (%move-dst<-src eax (car rands))
		     (make-asm-instr 'cltd edx eax)
		     (make-asm-instr 'idiv edx (cadr rands))
		     (%move-dst<-src d edx)))))

       ((sll sra srl sll/overflow)
	(let ((a (car rands))
	      (b (cadr rands)))
	  (if (constant? b)
	      (make-seq (V d a)
			(make-asm-instr op d b))
	    (S b (lambda (b)
		   (multiple-forms-sequence
		    (V d a)
		    (%move-dst<-src ecx b)
		    (make-asm-instr op d ecx)))))))

       (else
	(error __module_who__ "invalid value op" op rands))))

    ((funcall rator rands)
     (handle-nontail-call rator rands d #f))

    ((jmpcall label rator rands)
     (handle-nontail-call rator rands d label))

    ((forcall op rands)
     (handle-nontail-call (make-constant (make-foreign-label op))
			  rands d op))

    ((shortcut body handler)
     (make-shortcut (V d body)
       (V d handler)))

    ((known expr)
     (V d expr))

    (else
     (if (symbol? x)
	 (%move-dst<-src d x)
       (error __module_who__ "invalid value" (unparse-recordized-code x))))))


(define (E x)
  (struct-case x
    ((seq e0 e1)
     (make-seq (E e0) (E e1)))

    ((conditional e0 e1 e2)
     (make-conditional (P e0) (E e1) (E e2)))

    ((bind lhs* rhs* e)
     (%do-bind lhs* rhs* (E e)))

    ((asmcall op rands)
     (case op
       ((mset bset mset32)
	(S* rands (lambda (s*)
		    (make-asm-instr op (make-disp (car s*) (cadr s*))
				    (caddr s*)))))
       ((fl:load fl:store fl:add! fl:sub! fl:mul! fl:div!
		 fl:from-int fl:shuffle bswap!
		 fl:store-single fl:load-single)
	(S* rands (lambda (s*)
		    (make-asm-instr op (car s*) (cadr s*)))))
       ((nop interrupt incr/zero? fl:double->single fl:single->double)
	x)
       (else
	(error __module_who__ "invalid instr" x))))

    ((funcall rator rands)
     (handle-nontail-call rator rands #f #f))

    ((jmpcall label rator rands)
     (handle-nontail-call rator rands #f label))

    ((forcall op rands)
     (handle-nontail-call (make-constant (make-foreign-label op))
			  rands #f op))
    ((shortcut body handler)
     (make-shortcut (E body) (E handler)))

    (else
     (error __module_who__ "invalid effect" x))))


(module (P)

  (define (P x)
    (struct-case x
      ((constant)
       x)

      ((seq e0 e1)
       (make-seq (E e0) (P e1)))

      ((conditional e0 e1 e2)
       (make-conditional (P e0) (P e1) (P e2)))

      ((bind lhs* rhs* e)
       (%do-bind lhs* rhs* (P e)))

      ((asmcall op rands)
       (let ((a (car rands)) (b (cadr rands)))
	 (if (and (constant? a)
		  (constant? b))
	     (let ((t (make-unique-var 'tmp)))
	       (P (make-bind (list t) (list a)
			     (make-asmcall op (list t b)))))
	   (Mem a (lambda (a)
		    (Mem b (lambda (b)
			     (make-asm-instr op a b))))))))

      ((shortcut body handler)
       (make-shortcut (P body) (P handler)))

      (else
       (error __module_who__ "invalid pred" x))))

  (define (Mem x kont)
    (struct-case x
      ((asmcall op arg*)
       (if (eq? op 'mref)
	   (S* arg* (lambda (arg*)
		      (kont (make-disp (car arg*) (cadr arg*)))))
	 (S x kont)))
      (else
       (S x kont))))

  #| end of module: P |# )


(module (%handle-tail-call)

  (define (%handle-tail-call target rator rands)
    ;;Handle FUNCALL and JMPCALL structures in tail position.
    ;;
    ;;If TARGET is true: the call is a JMPCALL and TARGET is a CODE-LOC.
    ;;
    ;;We build and return a struct instance to represent:
    ;;
    ;;1.  For the operator and the operands: a sequence of assignments to store the
    ;;values in registers or memory locations.
    ;;
    ;;2. Loading the number of  arguments in the appropriate register.
    ;;
    ;;3. The actual call.
    ;;
    (let* ((args (cons rator rands))
	   (locs (%formals-locations PARAMETER-REGISTERS args))
	   (rest (make-seq (%move-dst<-src ARGC-REGISTER
					   (make-constant (argc-convention (length rands))))
			   (if target
			       (make-asmcall 'direct-jump
				 (cons target (cons* ARGC-REGISTER pcr esp apr locs)))
			     (make-asmcall 'indirect-jump
			       (cons* ARGC-REGISTER pcr esp apr locs))))))
      (let recur ((args  (reverse args))
		  (locs  (reverse locs))
		  (targs '())
		  (tlocs '()))
	(cond ((null? args)
	       (assign* tlocs targs rest))
	      ((constant? (car args))
	       (recur (cdr args)
		      (cdr locs)
		      (cons (car args) targs)
		      (cons (car locs) tlocs)))
	      ((and (fvar? (car locs))
		    (var?  (car args))
		    (eq?   (car locs)
			   (var-loc (car args))))
	       (recur (cdr args)
		      (cdr locs)
		      targs
		      tlocs))
	      (else
	       (let ((t (make-unique-var 'tmp)))
		 (%locals-cons t)
		 (make-seq (V t (car args))
			   (recur (cdr args)
				  (cdr locs)
				  (cons t targs)
				  (cons (car locs) tlocs)))))))))

  (define (%formals-locations regs args)
    (cond ((null? args)
	   '())
	  ((null? regs)
	   (%one-fvar-for-each-arg 1 args))
	  (else
	   (cons (car regs) (%formals-locations (cdr regs) (cdr args))))))

  (define (%one-fvar-for-each-arg i args)
    (if (pair? args)
	(cons (mkfvar i)
	      (%one-fvar-for-each-arg (fxadd1 i) (cdr args)))
      '()))

  #| end of module: %HANDLE-TAIL-CALL |# )


(module (handle-nontail-call)

  (define (handle-nontail-call rator rands value-dest call-targ)
    (let-values (((reg-locs reg-args frm-args)
		  (%nontail-locations PARAMETER-REGISTERS (cons rator rands))))
      (let ((regt* (map (lambda (x)
			  (make-unique-var 'rt))
		     reg-args))
	    (frmt* (map (lambda (x)
			  (make-nfv 'unset-conflicts #f #f #f #f))
		     frm-args)))
	(let* ((call (make-ntcall call-targ value-dest
				  (cons* ARGC-REGISTER pcr esp apr
					 (append reg-locs frmt*))
				  #f #f))
	       (body (make-nframe
		      frmt* #f
		      (%do-bind-frmt*
		       frmt* frm-args
		       (%do-bind (cdr regt*) (cdr reg-args)
				 ;;evaluate cpt last
				 (%do-bind (list (car regt*)) (list (car reg-args))
					   (assign*
					    reg-locs regt*
					    (make-seq
					     (%move-dst<-src ARGC-REGISTER
							     (make-constant
							      (argc-convention (length rands))))
					     call))))))))
	  (if value-dest
	      (make-seq body (%move-dst<-src value-dest RETURN-VALUE-REGISTER))
	    body)))))

  (define (%nontail-locations regs args)
    (cond ((null? args)
	   (values '() '() '()))
	  ((null? regs)
	   (values '() '() args))
	  (else
	   (let-values (((r* rl* f*)
			 (%nontail-locations (cdr regs) (cdr args))))
	     (values (cons (car regs) r*)
		     (cons (car args) rl*)
		     f*)))))

  #| end of module: HANDLE-NONTAIL-CALL |# )


;;;; done

#| end of module: IMPOSE-CALLING-CONVENTION/EVALUATION-ORDER |# )

;;; end of file
;; Local Variables:
;; mode: vicare
;; eval: (put 'make-asmcall		'scheme-indent-function 1)
;; eval: (put 'assemble-sources		'scheme-indent-function 1)
;; eval: (put 'make-conditional		'scheme-indent-function 2)
;; eval: (put 'struct-case		'scheme-indent-function 1)
;; End:
