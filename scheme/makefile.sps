;;;Vicare Scheme -- A compiler for R6RS Scheme.
;;;Copyright (C) 2006,2007,2008  Abdulaziz Ghuloum
;;;Modified by Marco Maggi <marco.maggi-ipsu@poste.it>
;;;
;;;Abstract
;;;
;;;	This file  is a proper Scheme  program, using some Vicare's  extension.  When
;;;	run in  the appropriate  operating system  environment: it  rebuilds Vicare's
;;;	boot file "vicare.boot".
;;;
;;;	  This program works  hand-in-hand with the expander,  especially the library
;;;	(psyntax.library-manager) in the file "psyntax.library-manager.sls".
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


;;;; adding a primitive operation to an existing system library
;;
;;Primitive operations are defined  by the macro DEFINE-PRIMITIVE-OPERATION; examples
;;are: $CAR, $CDR,  $FX+ and $VECTOR-LENGTH but also FIXNUM?  and STRING?.  Some core
;;primitives are implemented both as:
;;
;;* Proper  procedures.  There exists  a loc gensym  whose "value" slot  references a
;;  closure object,  which in  turn references  a code  object implementing  the core
;;  primitive as machine code.
;;
;;* Primitive operations.  There exist functions that the compiler calls to integrate
;;  assembly instructions implementing the core primitive.
;;
;;Let's consider FX+ as example.  When the core primitive is used as argument as in:
;;
;;   (map fx+ a* b*)
;;
;;the closure object implementation is used; when the core primitive is used as first
;;subform of an application form as in:
;;
;;   (fx+ 1 2)
;;
;;the primitive  operation is  used.  So  we can  understand why  some core-primitive
;;procedure implementation is written as:
;;
;;   (import (except (vicare) fx+)
;;      (prefix (only (vicare) fx+) sys:)
;;
;;   (define (fx+ x y)
;;    (sys:fx+ x y))
;;
;;this code creates a  closure object bound to FX+; in the body  of the procedure the
;;application of SYS:FX+  is recognised as primitive operation  and the corresponding
;;assembly code is integrated.
;;
;;Here we want to examine the process  of adding a primitive operation to an existing
;;system library;  we will not  discuss how to define  the operation using  the macro
;;DEFINE-PRIMITIVE-OPERATION.
;;
;;What is  a primitive  operation?  We can  think of  it as a  macro embedded  in the
;;compiler,  which, when  used,  expands  inline the  elementary  instructions to  be
;;converted  to  machine language.   The  elementary  instructions are  expressed  in
;;Vicare's high-level assembly  language.  When building a new boot  image we can use
;;in Vicare's  source code  only the  primitive operations compiled  in the  old boot
;;image.
;;
;;Let's say  we want to  generate a new boot  image having the  operation $SWIRL-PAIR
;;embedded in it and exported by the system library:
;;
;;   (vicare system $pairs)
;;
;;which already exists, and making use of the operation in Vicare's source code; this
;;is the scenario:
;;
;;1. The image BOOT-0 already exists.
;;
;;2. We  generate a  new temporary  image, BOOT-1,  having the  operation $SWIRL-PAIR
;;   embedded in it, but not using it anywhere.
;;
;;3.  We generate a further image, BOOT-2,  which offers $SWIRL-PAIR and also uses it
;;   in the source code.
;;
;;Let's go.
;;
;;First we  define the $SWIRL-PAIR operation  adding to the compiler  library (in the
;;appropriate place) a form like:
;;
;;  (define-primitive-operation $swirl-pair unsafe ---)
;;
;;this  form alone  is enough  to make  the compiler  aware of  the existence  of the
;;operation.    Then,  in   this   makefile,   we  add   an   entry   to  the   table
;;IDENTIFIER->LIBRARY-MAP as follows:
;;
;;   (define IDENTIFIER->LIBRARY-MAP
;;     '(($swirl-pair		$pairs)
;;       ---))
;;
;;the order in which the entries appear in this table is not important.
;;
;;With no  other changes  we use the  image BOOT-0  to build an  image which  will be
;;BOOT-1.  Now we can use $SWIRL-PAIR in  Vicare's source code, then we use BOOT-1 to
;;compile a further image which will be BOOT-2.
;;


;;;; adding a new system library
;;
;;By convention system libraries have names like:
;;
;;   (vicare system ?nickname)
;;
;;where ?NICKNAME  is prefixed with a  $ character; for good  style, system libraries
;;should export  only primitive operations, but  they are abused to  export also very
;;low level procedures.
;;
;;Let's say we want to add to a boot image the library:
;;
;;  (vicare system $spiffy)
;;
;;exporting the single primitive operation $SWIRL, this is the scenario:
;;
;;1. The image BOOT-0 already exists.
;;
;;2. We generate a  temporary new image, BOOT-1, having the new  system library in it
;;   but not in a correctly usable state.
;;
;;3.  We generate a further image, BOOT-2, having the new system library in a correct
;;   state.
;;
;;Let's go.
;;
;;First  we define  the  $SWIRL operation  adding  to the  compiler  library (in  the
;;appropriate place) a form like:
;;
;;  (define-primitive-operation $swirl unsafe ---)
;;
;;this  form alone  is enough  to make  the compiler  aware of  the existence  of the
;;operation.   Then, in  this makefile,  we add  an  entry at  the end  of the  table
;;LIBRARY-LEGEND as follows:
;;
;;   (define LIBRARY-LEGEND
;;     '(---
;;       ($spiffy  (ikarus system $spiffy)  #t	#f))
;;
;;marking the library as visible but not required.  Then we add an entry to the table
;;IDENTIFIER->LIBRARY-MAP as follows:
;;
;;   (define IDENTIFIER->LIBRARY-MAP
;;     '(($swirl $spiffy)
;;       ---))
;;
;;the order in which the entries appear in this table is not important.
;;
;;Now we  use the  image BOOT-0 to  build a  new boot image,  BOOT-1, having  the new
;;library in  it.  Then we  change the library entry  in the table  LIBRARY-LEGEND as
;;follows:
;;
;;       ($spiffy  (ikarus system $spiffy)  #t	#t)
;;
;;making it required to  build further boot images.  Then we use  the image BOOT-1 to
;;generate a further boot image which will be BOOT-2.
;;


;;;; prelude

#!vicare
;;NOTE  Libraries imported  here  are  interned in  the  internal library  collection
;;defined by the old  boot image.  Source libraries expanded later to  be part of the
;;boot image are interned in a separate library collection, BOOTSTRAP-COLLECTION.
(import (vicare)
  ;;This library is from the old boot image.
  (prefix (only (psyntax system $all)
		find-library-by-name
		current-library-collection)
	  bootstrap.)
  ;;The following libraries are read, expanded and compiled from the source tree.
  (prefix (ikarus.options) option.)
  (prefix (only (ikarus.compiler)
		current-primitive-locations
		compile-core-expr-to-port
		;; configuration options
		perform-core-type-inference?
		perform-unsafe-primrefs-introduction?
		strip-source-info
		current-letrec-pass
		generate-debug-calls
		check-compiler-pass-preconditions
		generate-descriptive-labels?)
	  compiler.)
  (prefix (only (ikarus.fasl.write)
		writing-boot-image?)
	  fasl-write.))

(module (BOOT-IMAGE-MAJOR-VERSION
	 BOOT-IMAGE-MINOR-VERSION
	 BOOT-IMAGE-YEAR-VERSION
	 BOOT-IMAGE-MONTH-VERSION
	 BOOT-IMAGE-DAY-VERSION)
  (include "ikarus.config.scm" #t))

;;; --------------------------------------------------------------------

(define-syntax if-building-rotation-boot-image?
  (lambda (stx)
    (define rotating?
      (equal? "yes" (getenv "BUILDING_ROTATION_BOOT_IMAGE")))
    (define (%log description)
      (fprintf (current-error-port)
	       "makefile.sps: ~a: conditional for ~a boot image\n"
	       description
	       (if rotating? "rotation" "normal")))
    (syntax-case stx ()
      ((_ ?description ?true-body)
       (begin
	 (%log (syntax->datum #'?description))
	 (if rotating? #'?true-body #'(module ()))))
      ((_ ?description ?true-body ?false-body)
       (begin
	 (%log (syntax->datum #'?description))
	 (if rotating? #'?true-body #'?false-body)))
      )))

;;FIXME To be fixed at the next boot image rotation.  (Marco Maggi; Sun May 10, 2015)
(if-building-rotation-boot-image? "importing EXPAND-LIBRARY"
    (import (vicare libraries))
  (import (only (vicare) expand-library)))


;;;; configuration inspection

;;Print some platform-specific  constants to make sure that we  are building with the
;;correct configuration.
;;
(begin
  (module (config.wordsize
	   config.fixnum-width
	   config.greatest-fixnum
	   config.least-fixnum)
    (define-syntax-rule (config.wordsize)
      wordsize)
    (define-syntax-rule (config.fixnum-width)
      (fixnum-width))
    (define-syntax-rule (config.greatest-fixnum)
      (greatest-fixnum))
    (define-syntax-rule (config.least-fixnum)
      (least-fixnum))
    (include "ikarus.wordsize.scm"))
  (fprintf (current-error-port) "wordsize:        ~a\n" (config.wordsize))
  (fprintf (current-error-port) "fixnum width:    ~a\n" (config.fixnum-width))
  (fprintf (current-error-port) "greatest fixnum: ~a\n" (config.greatest-fixnum))
  (fprintf (current-error-port) "least fixnum:    ~a\n" (config.least-fixnum)))


;;;; parameters configuration

(define-constant BOOT-FILE-NAME
  "vicare.boot")

(define-constant BOOT-IMAGE-FILES-SOURCE-DIR
  (or (getenv "VICARE_SRC_DIR") "."))

;;; --------------------------------------------------------------------

(option.verbose? #t)
(option.print-debug-messages? (equal? "yes" (getenv "DEBUG_MESSAGES")))

(fasl-write.writing-boot-image? #t)

;; (compiler.perform-core-type-inference? #f)
;; (compiler.perform-unsafe-primrefs-introduction? #f)
(pretty-width 160)
((pretty-format 'fix)
 ((pretty-format 'letrec)))
(compiler.strip-source-info #t)
(compiler.current-letrec-pass 'scc)

;;NOTE This turns off some debug mode features  that cannot be used in the boot image
;;because it would become too big.  (Marco Maggi; Wed Apr 2, 2014)
;;
(compiler.generate-debug-calls #f)

;;NOTE This  can be #t  while developing and  #f in distributed  tarballs.  Obviously
;;someone has  to remember to set  it to #f; but  it is not bad  if it is set  to #t,
;;because it only affects bulding the boot image.  (Marco Maggi; Wed Oct 29, 2014)
;;
(compiler.check-compiler-pass-preconditions #t)

;;NOTE  This is  for debugging  purposes: it  causes the  compiler to  generate human
;;readable labels.  Generating  descriptive labels is slower, so this  is usually set
;;to false.  (Marco Maggi; Sun Nov 16, 2014)
;;
(compiler.generate-descriptive-labels? #f)

;;(set-port-buffer-mode! (current-output-port) (buffer-mode none))


;;;; helpers

(define-syntax each-for
  (syntax-rules ()
    ((_ ?list ?lambda)
     (for-each ?lambda ?list))))

(define (make-collection)
  ;;Return a  closure to  handle lists  of elements  called "collections".   When the
  ;;closure  is invoked  with  no arguments:  it returns  the  collection.  When  the
  ;;closure is invoked  with an argument: it prepends the  argument to the collection
  ;;without checking for duplicates.
  ;;
  (let ((set '()))
    (case-lambda
     (()
      set)
     ((x)
      (set! set (cons x set))))))

(define debug-printf
  (if (option.verbose?)
      (lambda args
	(let ((port (console-error-port)))
	  (apply fprintf port args)
	  (flush-output-port port)))
    (case-lambda
     ((str)
      (let ((port (console-error-port)))
	(fprintf port str)
	(flush-output-port port)))
     ((str . args)
      (let ((port (console-error-port)))
	(fprintf port ".")
	(flush-output-port port))))))


(define-constant SCHEME-LIBRARY-FILES
  ;;Listed in the order in which they're loaded.
  ;;
  ;;Loading  of  the boot  file  may  segfault if  a  library  is loaded  before  its
  ;;dependencies are loaded first.
  ;;
  ;;The reason  is that the  base libraries are not  a hierarchy of  dependencies but
  ;;rather an eco system in which every part depends on the other.
  ;;
  ;;For example, the printer may call error if it finds an error (e.g. "not an output
  ;;port"), while  the error procedure may  call the printer to  display the message.
  ;;This works fine as  long as error does not itself cause an  error (which may lead
  ;;to the  infamous Error: Error: Error:  Error: Error: Error: Error:  Error: Error:
  ;;...).
  ;;
  '("ikarus.emergency.sls"
    "ikarus.options.sls"
    "ikarus.singular-objects.sls"
    "ikarus.handlers.sls"
    "ikarus.multiple-values.sls"
    "ikarus.control.sls"
    "ikarus.exceptions.sls"
    "ikarus.collect.sls"
    "ikarus.apply.sls"
    "ikarus.keywords.sls"
    "ikarus.predicates.sls"
    "ikarus.booleans.sls"
    "ikarus.immutable-pairs.sls"
    "ikarus.equal.sls"
    "ikarus.pairs.sls"
    "ikarus.lists.sls"
    "ikarus.fixnums.sls"
    "ikarus.chars.sls"
    "ikarus.structs.sls"
    "ikarus.vectors.sls"
    "ikarus.hash-tables.sls"
    "ikarus.records.procedural.sls"
    "ikarus.strings.sls"
    "ikarus.symbols.sls"
    "ikarus.unicode.sls"
    "ikarus.string-to-number.sls"
    "ikarus.bignums.sls"
    "ikarus.ratnums.sls"
    "ikarus.conditions.sls"
    "ikarus.string-bytevector-conversion.sls"
    "ikarus.numerics.flonums.sls"
    "ikarus.numerics.generic-arithmetic.sls"
    "ikarus.numerics.flonum-conversion.sls"
    "ikarus.numerics.rationalize.sls"
    "ikarus.numerics.div-and-mod.sls"
    "ikarus.numerics.flonums.div-and-mod.sls"
    "ikarus.numerics.bitwise.misc.sls"
    "ikarus.numerics.complex-numbers.sls"
    "ikarus.unwind-protection.sls"
    "ikarus.guardians.sls"
    "ikarus.symbol-table.sls"
    "ikarus.codecs.sls"
    "ikarus.bytevectors.sls"
    "ikarus.pointers.sls"
    "ikarus.posix.sls"
    "ikarus.io.sls"
    "ikarus.pretty-formats.sls"
    "ikarus.writer.sls"
    "ikarus.strings-table.sls"
    "ikarus.foreign-libraries.sls"
    "ikarus.reader.sls"
    "ikarus.code-objects.sls"
    "ikarus.foldable.sls"
;;;
    "ikarus.compiler.condition-types.sls"
    "ikarus.intel-assembler.sls"
    "ikarus.fasl.write.sls"
    "ikarus.fasl.read.sls"
    "ikarus.compiler.scheme-objects-ontology.sls"
;;;
    "ikarus.compiler.core-primitive-properties.base.sls"
    "ikarus.compiler.core-primitive-properties.configuration.sls"
    ;;
    "ikarus.compiler.core-primitive-properties.booleans.sls"
    "ikarus.compiler.core-primitive-properties.characters.sls"
    ;;
    "ikarus.compiler.core-primitive-properties.fixnums.sls"
    "ikarus.compiler.core-primitive-properties.bignums.sls"
    "ikarus.compiler.core-primitive-properties.ratnums.sls"
    "ikarus.compiler.core-primitive-properties.flonums.sls"
    "ikarus.compiler.core-primitive-properties.cflonums.sls"
    "ikarus.compiler.core-primitive-properties.compnums.sls"
    ;;
    "ikarus.compiler.core-primitive-properties.code-objects.sls"
    "ikarus.compiler.core-primitive-properties.strings.sls"
    "ikarus.compiler.core-primitive-properties.symbols.sls"
    "ikarus.compiler.core-primitive-properties.keywords.sls"
    "ikarus.compiler.core-primitive-properties.pointers.sls"
    "ikarus.compiler.core-primitive-properties.bytevectors.sls"
    ;;
    "ikarus.compiler.core-primitive-properties.pairs-and-lists.sls"
    "ikarus.compiler.core-primitive-properties.vectors.sls"
    "ikarus.compiler.core-primitive-properties.structs.sls"
    "ikarus.compiler.core-primitive-properties.records.sls"
    "ikarus.compiler.core-primitive-properties.hash-tables.sls"
    ;;
    "ikarus.compiler.core-primitive-properties.annotation-objects.sls"
    "ikarus.compiler.core-primitive-properties.enum-sets.sls"
    "ikarus.compiler.core-primitive-properties.condition-objects.sls"
    "ikarus.compiler.core-primitive-properties.transcoder-objects.sls"
    ;;
    "ikarus.compiler.core-primitive-properties.control.sls"
    "ikarus.compiler.core-primitive-properties.generic-primitives.sls"
    "ikarus.compiler.core-primitive-properties.input-output.sls"
    "ikarus.compiler.core-primitive-properties.environment-inquiry.sls"
    "ikarus.compiler.core-primitive-properties.numerics.sls"
    "ikarus.compiler.core-primitive-properties.times-and-dates.sls"
    "ikarus.compiler.core-primitive-properties.library-utils.sls"
    "ikarus.compiler.core-primitive-properties.expander.sls"
    "ikarus.compiler.core-primitive-properties.eval-and-environments.sls"
    "ikarus.compiler.core-primitive-properties.ffi.sls"
    "ikarus.compiler.core-primitive-properties.posix.sls"
    ;;
    "ikarus.compiler.core-primitive-properties.sls"
;;;
    "ikarus.compiler.compat.sls"
    "ikarus.compiler.config.sls"
    "ikarus.compiler.helpers.sls"
    "ikarus.compiler.system-value.sls"
    "ikarus.compiler.typedefs.sls"
    "ikarus.compiler.unparse-recordised-code.sls"
    "ikarus.compiler.core-primitive-operation-names.sls"
    "ikarus.compiler.pass-recordise.sls"
    "ikarus.compiler.pass-optimize-direct-calls.sls"
    "ikarus.compiler.pass-letrec-optimizer.sls"
    "ikarus.compiler.pass-source-optimizer.sls"
    "ikarus.compiler.pass-rewrite-references-and-assignments.sls"
    "ikarus.compiler.pass-core-type-inference.sls"
    "ikarus.compiler.pass-introduce-unsafe-primrefs.sls"
    "ikarus.compiler.pass-sanitize-bindings.sls"
    "ikarus.compiler.pass-optimize-for-direct-jumps.sls"
    "ikarus.compiler.pass-insert-global-assignments.sls"
    "ikarus.compiler.pass-introduce-vars.sls"
    "ikarus.compiler.pass-introduce-closure-makers.sls"
    "ikarus.compiler.pass-optimize-combinator-calls-lift-clambdas.sls"
    "ikarus.compiler.pass-introduce-primitive-operation-calls.sls"
    "ikarus.compiler.pass-rewrite-freevar-references.sls"
    "ikarus.compiler.pass-insert-engine-checks.sls"
    "ikarus.compiler.pass-insert-stack-overflow-check.sls"
    "ikarus.compiler.intel-assembly.sls"
    "ikarus.compiler.common-assembly-subroutines.sls"
    "ikarus.compiler.pass-specify-representation.sls"
    "ikarus.compiler.core-primitive-operations.sls"
    "ikarus.compiler.pass-impose-evaluation-order.sls"
    "ikarus.compiler.pass-assign-frame-sizes.sls"
    "ikarus.compiler.pass-color-by-chaitin.sls"
    "ikarus.compiler.pass-flatten-codes.sls"
    "ikarus.compiler.code-generation.sls"
    "ikarus.compiler.sls"
;;;
    "psyntax.compat.sls"
    "psyntax.config.sls"
    "psyntax.setup.sls"
    "psyntax.library-utils.sls"
    "psyntax.library-manager.sls"
    "psyntax.internal.sls"
    "psyntax.builders.sls"
    "psyntax.special-transformers.sls"
    "psyntax.lexical-environment.sls"
    "psyntax.syntax-match.sls"
    "psyntax.library-collectors.sls"
    "psyntax.import-spec-parser.sls"
    "psyntax.export-spec-parser.sls"
    "psyntax.syntactic-binding-properties.sls"
    "psyntax.syntax-utilities.sls"
    "psyntax.tag-and-tagged-identifiers.sls"
    "psyntax.core-primitives-properties.sls"
    "psyntax.non-core-macro-transformers.sls"
    "psyntax.chi-procedures.sls"
    "psyntax.expander.sls"
    "ikarus.apropos.sls"
    "ikarus.enumerations.sls"
    "ikarus.load.sls"
    "ikarus.load.dynamic-library-loading.sls"
    "ikarus.pretty-print.sls"
    "ikarus.readline.sls"
    "ikarus.cafe.sls"
    "ikarus.timer.sls"
    "ikarus.time-and-date.sls"
    "ikarus.sort.sls"
    "ikarus.promises.sls"
    "ikarus.compensations.sls"
    "ikarus.command-line.sls"
;;; "ikarus.trace.sls"
    "ikarus.debugger.sls"
    "ikarus.syntax-utilities.sls"
    "ikarus.environment-inquiry.sls"
    "ikarus.object-utilities.sls"
    "ikarus.coroutines.sls"
    "ikarus.run-time-configuration.sls"
    "ikarus.main.sls"
    ))


;;;; system macros

(define-constant VICARE-SYSTEM-FLUIDS
  `((__who__					($fluid . ,(gensym "fluid-label.__who__")))
    (return					($fluid . ,(gensym "fluid-label.return")))
    (continue					($fluid . ,(gensym "fluid-label.continue")))
    (break					($fluid . ,(gensym "fluid-label.break")))
    (with					($fluid . ,(gensym "fluid-label.with")))
    (brace					($fluid . ,(gensym "fluid-label.brace")))
    (<>						($fluid . ,(gensym "fluid-label.<>")))))

;;At present there are no fluid syntaxes  with default binding defined by Vicare.  To
;;define one for an imaginary fluid SPIFY, we should to this here:
;;
;;  (define-constant label-of-spiffy
;;    (gensym "fluid-label.spiffy"))
;;
;;  (define-constant VICARE-SYSTEM-FLUIDS
;;    `(...
;;      (spiffy			($fluid . ,label-of-spiffy))
;;      ...))
;;
;;  (define-constant VICARE-SYSTEM-FLUIDS-DEFAULTS
;;    `((,label-of-spiffy	(macro . default-for-spiffy))))
;;
;;then we must add an integrated non-core expander macro named DEFAULT-FOR-SPIFFY.
;;
(define-constant VICARE-SYSTEM-FLUIDS-DEFAULTS '())

(define-constant VICARE-SYSTEM-MACROS
  '((internal-define				(define))
    (define-syntax				(define-syntax))
    (define-alias				(define-alias))
    (define-fluid-syntax			(define-fluid-syntax))
    (module					(module))
    (library					(library))
    (begin					(begin))
    (import					(import))
    (export					(export))
    (set!					(set!))
    (let-syntax					(let-syntax))
    (letrec-syntax				(letrec-syntax))
    (stale-when					(stale-when))
    (begin-for-syntax				(begin-for-syntax))
    (eval-for-expand				(begin-for-syntax))
    (foreign-call				(core-macro . foreign-call))
    (quote					(core-macro . quote))
    (syntax-case				(core-macro . syntax-case))
    (syntax					(core-macro . syntax))
    (let					(core-macro . let))
    (letrec					(core-macro . letrec))
    (letrec*					(core-macro . letrec*))
    (if						(core-macro . if))
    (lambda						(core-macro . lambda))
    (case-lambda				(core-macro . case-lambda))
    (internal-lambda				(core-macro . internal-lambda))
    (internal-case-lambda			(core-macro . internal-case-lambda))
    (internal-body				(core-macro . internal-body))
    (fluid-let-syntax				(core-macro . fluid-let-syntax))
    (struct-type-descriptor			(core-macro . struct-type-descriptor))
    (struct-type-and-struct?			(core-macro . struct-type-and-struct?))
    (struct-type-field-ref			(core-macro . struct-type-field-ref))
    (struct-type-field-set!			(core-macro . struct-type-field-set!))
    ($struct-type-field-ref			(core-macro . $struct-type-field-ref))
    ($struct-type-field-set!			(core-macro . $struct-type-field-set!))
    (record-type-descriptor			(core-macro . record-type-descriptor))
    (record-constructor-descriptor		(core-macro . record-constructor-descriptor))
    (record-type-field-set!			(core-macro . record-type-field-set!))
    (record-type-field-ref			(core-macro . record-type-field-ref))
    ($record-type-field-set!			(core-macro . $record-type-field-set!))
    ($record-type-field-ref			(core-macro . $record-type-field-ref))
    (type-descriptor				(core-macro . type-descriptor))
    (is-a?					(core-macro . is-a?))
    (condition-is-a?				(core-macro . condition-is-a?))
    (slot-ref					(core-macro . slot-ref))
    (slot-set!					(core-macro . slot-set!))
    (tag-predicate				(core-macro . tag-predicate))
    (tag-procedure-argument-validator		(core-macro . tag-procedure-argument-validator))
    (tag-return-value-validator			(core-macro . tag-return-value-validator))
    (tag-assert					(core-macro . tag-assert))
    (tag-assert-and-return			(core-macro . tag-assert-and-return))
    (tag-accessor				(core-macro . tag-accessor))
    (tag-mutator				(core-macro . tag-mutator))
    (tag-getter					(core-macro . tag-getter))
    (tag-setter					(core-macro . tag-setter))
    (tag-dispatch				(core-macro . tag-dispatch))
    (tag-cast					(core-macro . tag-cast))
    (tag-unsafe-cast				(core-macro . tag-unsafe-cast))
    (type-of					(core-macro . type-of))
    (expansion-of				(core-macro . expansion-of))
    (expansion-of*				(core-macro . expansion-of*))
    (visit-code-of				(core-macro . visit-code-of))
    (optimisation-of				(core-macro . optimisation-of))
    (further-optimisation-of			(core-macro . further-optimisation-of))
    (optimisation-of*				(core-macro . optimisation-of*))
    (further-optimisation-of*			(core-macro . further-optimisation-of*))
    (assembly-of				(core-macro . assembly-of))
    (splice-first-expand			(core-macro . splice-first-expand))
    (predicate-procedure-argument-validation	(core-macro . predicate-procedure-argument-validation))
    (predicate-return-value-validation		(core-macro . predicate-return-value-validation))
    (__file__					(macro! . __file__))
    (__line__					(macro! . __line__))
    (let-values					(macro . let-values))
    (let*-values				(macro . let*-values))
    (values->list				(macro . values->list))
    (define-struct				(macro . define-struct))
    (case					(macro . case))
    (case-identifiers				(macro . case-identifiers))
    (syntax-rules				(macro . syntax-rules))
    (quasiquote					(macro . quasiquote))
    (quasisyntax				(macro . quasisyntax))
    (with-syntax				(macro . with-syntax))
    (identifier-syntax				(macro . identifier-syntax))
    (parameterize				(macro . parameterize))
    (parameterise				(macro . parameterize))
    (parametrise				(macro . parameterize))
    (define-syntax-parameter			(macro . define-syntax-parameter))
    (syntax-parametrise				(macro . syntax-parametrise))
    (syntax-parameterise			(macro . syntax-parametrise))
    (syntax-parameterize			(macro . syntax-parametrise))
    (when					(macro . when))
    (unless					(macro . unless))
    (let*					(macro . let*))
    (cond					(macro . cond))
    (do						(macro . do))
    (do*					(macro . do*))
    (dolist					(macro . dolist))
    (dotimes					(macro . dotimes))
    (and					(macro . and))
    (or						(macro . or))
    (time					(macro . time))
    (delay					(macro . delay))
    (endianness					(macro . endianness))
    (assert					(macro . assert))
    (...					(macro . ...))
    (=>						(macro . =>))
    (else					(macro . else))
    (_						(macro . _))
    (unquote					(macro . unquote))
    (unquote-splicing				(macro . unquote-splicing))
    (unsyntax					(macro . unsyntax))
    (unsyntax-splicing				(macro . unsyntax-splicing))
    (let*-syntax				(macro . let*-syntax))
    (let-constants				(macro . let-constants))
    (let*-constants				(macro . let*-constants))
    (letrec-constants				(macro . letrec-constants))
    (letrec*-constants				(macro . letrec*-constants))
    (trace-lambda				(macro . trace-lambda))
    (trace-let					(macro . trace-let))
    (trace-define				(macro . trace-define))
    (trace-define-syntax			(macro . trace-define-syntax))
    (trace-let-syntax				(macro . trace-let-syntax))
    (trace-letrec-syntax			(macro . trace-letrec-syntax))
    (guard					(macro . guard))
    (eol-style					(macro . eol-style))
    (buffer-mode				(macro . buffer-mode))
    (file-options				(macro . file-options))
    (error-handling-mode			(macro . error-handling-mode))
    (expander-options				(macro . expander-options))
    (compiler-options				(macro . compiler-options))
    (fields					(macro . fields))
    (mutable					(macro . mutable))
    (immutable					(macro . immutable))
    (parent					(macro . parent))
    (protocol					(macro . protocol))
    (sealed					(macro . sealed))
    (opaque					(macro . opaque ))
    (nongenerative				(macro . nongenerative))
    (parent-rtd					(macro . parent-rtd))
    (define-record-type				(macro . define-record-type))
    (record-type-and-record?			(macro . record-type-and-record?))
    (define-enumeration				(macro . define-enumeration))
    (define-condition-type			(macro . define-condition-type))
;;;
    (define					(macro . exported-define))
    (define-auxiliary-syntaxes			(macro . define-auxiliary-syntaxes))
    (define-syntax*				(macro . define-syntax*))
    (case-define				(macro . case-define))
    (define*					(macro . define*))
    (case-define*				(macro . case-define*))
    (lambda*					(macro . lambda*))
    (case-lambda*				(macro . case-lambda*))
    (define-integrable				(macro . define-integrable))
    (define-inline				(macro . define-inline))
    (define-constant				(macro . define-constant))
    (define-inline-constant			(macro . define-inline-constant))
    (define-values				(macro . define-values))
    (define-constant-values			(macro . define-constant-values))
    (define-syntax-rule				(macro . define-syntax-rule))
    (receive					(macro . receive))
    (receive-and-return				(macro . receive-and-return))
    (begin0					(macro . begin0))
    (xor					(macro . xor))

    (unsafe					(macro . unsafe))

    (stdin					(macro . stdin))
    (stdout					(macro . stdout))
    (stderr					(macro . stderr))

    (unwind-protect				(macro . unwind-protect))
    (with-unwind-protection			(macro . with-unwind-protection))
    (with-unwind-handler			(macro . with-unwind-protection))

    (with-blocked-exceptions			(macro . with-blocked-exceptions))
    (with-current-dynamic-environment		(macro . with-current-dynamic-environment))

    (with-implicits				(macro . with-implicits))
    (include					(macro . include))
    (set-cons!					(macro . set-cons!))
;;;
    (while					(macro . while))
    (until					(macro . until))
    (for					(macro . for))
    (returnable					(macro . returnable))
;;;
    (concurrently				(macro . concurrently))
    (monitor					(macro . monitor))
;;;
    (infix					(macro . infix))
    (++						(macro . pre-incr))
    (--						(macro . pre-decr))
    (pre-incr!					(macro . pre-incr))
    (pre-decr!					(macro . pre-decr))
    (post-incr!					(macro . post-incr))
    (post-decr!					(macro . post-decr))
;;;
    (try					(macro . try))
    (catch					(macro . catch))
    (finally					(macro . finally))
;;;
    (with-compensations				(macro . with-compensations))
    (with-compensations/on-error		(macro . with-compensations/on-error))
    (with-compensation-handler			(macro . with-compensation-handler))
    (compensate					(macro . compensate))
    (push-compensation				(macro . push-compensation))
;;;
    (define-type-spec				(macro . define-type-spec))
    (define-callable-spec			(macro . define-callable-spec))
;;;
    (&condition					($core-rtd . (&condition-rtd
							      &condition-rcd)))
    (&message					($core-rtd . (&message-rtd
							      &message-rcd)))
    (&warning					($core-rtd . (&warning-rtd
							      &warning-rcd)))
    (&serious					($core-rtd . (&serious-rtd
							      &serious-rcd)))
    (&error					($core-rtd . (&error-rtd
							      &error-rcd)))
    (&violation					($core-rtd . (&violation-rtd
							      &violation-rcd)))
    (&assertion					($core-rtd . (&assertion-rtd
							      &assertion-rcd)))
    (&irritants					($core-rtd . (&irritants-rtd
							      &irritants-rcd)))
    (&who					($core-rtd . (&who-rtd
							      &who-rcd)))
    (&non-continuable				($core-rtd . (&non-continuable-rtd
							      &non-continuable-rcd)))
    (&implementation-restriction		($core-rtd . (&implementation-restriction-rtd
							      &implementation-restriction-rcd)))
    (&lexical					($core-rtd . (&lexical-rtd
							      &lexical-rcd)))
    (&syntax					($core-rtd . (&syntax-rtd
							      &syntax-rcd)))
    (&undefined					($core-rtd . (&undefined-rtd
							      &undefined-rcd)))
    (&i/o					($core-rtd . (&i/o-rtd
							      &i/o-rcd)))
    (&i/o-read					($core-rtd . (&i/o-read-rtd
							      &i/o-read-rcd)))
    (&i/o-write					($core-rtd . (&i/o-write-rtd
							      &i/o-write-rcd)))
    (&i/o-invalid-position			($core-rtd . (&i/o-invalid-position-rtd
							      &i/o-invalid-position-rcd)))
    (&i/o-filename				($core-rtd . (&i/o-filename-rtd
							      &i/o-filename-rcd)))
    (&i/o-file-protection			($core-rtd . (&i/o-file-protection-rtd
							      &i/o-file-protection-rcd)))
    (&i/o-file-is-read-only			($core-rtd . (&i/o-file-is-read-only-rtd
							      &i/o-file-is-read-only-rcd)))
    (&i/o-file-already-exists			($core-rtd . (&i/o-file-already-exists-rtd
							      &i/o-file-already-exists-rcd)))
    (&i/o-file-does-not-exist			($core-rtd . (&i/o-file-does-not-exist-rtd
							      &i/o-file-does-not-exist-rcd)))
    (&i/o-port					($core-rtd . (&i/o-port-rtd
							      &i/o-port-rcd)))
    (&i/o-decoding				($core-rtd . (&i/o-decoding-rtd
							      &i/o-decoding-rcd)))
    (&i/o-encoding				($core-rtd . (&i/o-encoding-rtd
							      &i/o-encoding-rcd)))
    (&i/o-eagain				($core-rtd . (&i/o-eagain-rtd
							      &i/o-eagain-rcd)))
    (&errno					($core-rtd . (&errno-rtd
							      &errno-rcd)))
    (&out-of-memory-error			($core-rtd . (&out-of-memory-error-rtd
							      &out-of-memory-error-rcd)))
    (&h_errno					($core-rtd . (&h_errno-rtd
							      &h_errno-rcd)))
    (&no-infinities				($core-rtd . (&no-infinities-rtd
							      &no-infinities-rcd)))
    (&no-nans					($core-rtd . (&no-nans-rtd
							      &no-nans-rcd)))
    (&interrupted				($core-rtd . (&interrupted-rtd
							      &interrupted-rcd)))
    (&source-position				($core-rtd . (&source-position-rtd
							      &source-position-rcd)))
    (&failed-expression-condition		($core-rtd . (&failed-expression-condition-rtd
							      &failed-expression-condition-rcd)))
    (&procedure-precondition-violation		($core-rtd . (&procedure-precondition-violation-rtd
							      &procedure-precondition-violation-rcd)))
    (&procedure-postcondition-violation		($core-rtd . (&procedure-postcondition-violation-rtd
							      &procedure-postcondition-violation-rcd)))
    (&procedure-argument-violation		($core-rtd . (&procedure-argument-violation-rtd
							      &procedure-argument-violation-rcd)))
    (&procedure-signature-argument-violation	($core-rtd . (&procedure-signature-argument-violation-rtd
							      &procedure-signature-argument-violation-rcd)))
    (&procedure-signature-return-value-violation ($core-rtd . (&procedure-signature-return-value-violation-rtd
							       &procedure-signature-return-value-violation-rcd)))
    (&procedure-arguments-consistency-violation	($core-rtd . (&procedure-arguments-consistency-violation-rtd
							      &procedure-arguments-consistency-violation-rcd)))
    (&expression-return-value-violation		($core-rtd . (&expression-return-value-violation-rtd
							      &expression-return-value-violation-rcd)))
    (&non-reinstatable				($core-rtd . (&non-reinstatable-rtd
							      &non-reinstatable-rcd)))
;;;
    (&string-encoding					($core-rtd . (&string-encoding-rtd
								      &string-encoding-rcd)))
    (&string-decoding					($core-rtd . (&string-decoding-rtd
								      &string-decoding-rcd)))
    (&utf8-string-encoding				($core-rtd . (&utf8-string-encoding-rtd
								      &utf8-string-encoding-rcd)))
    (&utf16-string-encoding				($core-rtd . (&utf16-string-encoding-rtd
								      &utf16-string-encoding-rcd)))
    (&utf32-string-encoding				($core-rtd . (&utf32-string-encoding-rtd
								      &utf32-string-encoding-rcd)))
    (&utf8-string-decoding				($core-rtd . (&utf8-string-decoding-rtd
								      &utf8-string-decoding-rcd)))
    (&utf16-string-decoding				($core-rtd . (&utf16-string-decoding-rtd
								      &utf16-string-decoding-rcd)))
    (&utf32-string-decoding				($core-rtd . (&utf32-string-decoding-rtd
								      &utf32-string-decoding-rcd)))
    (&utf8-string-decoding-invalid-octet		($core-rtd . (&utf8-string-decoding-invalid-octet-rtd
								      &utf8-string-decoding-invalid-octet-rcd)))
    (&utf8-string-decoding-invalid-2-tuple		($core-rtd . (&utf8-string-decoding-invalid-2-tuple-rtd
								      &utf8-string-decoding-invalid-2-tuple-rcd)))
    (&utf8-string-decoding-invalid-3-tuple		($core-rtd . (&utf8-string-decoding-invalid-3-tuple-rtd
								      &utf8-string-decoding-invalid-3-tuple-rcd)))
    (&utf8-string-decoding-invalid-4-tuple		($core-rtd . (&utf8-string-decoding-invalid-4-tuple-rtd
								      &utf8-string-decoding-invalid-4-tuple-rcd)))
    (&utf8-string-decoding-incomplete-2-tuple		($core-rtd . (&utf8-string-decoding-incomplete-2-tuple-rtd
								      &utf8-string-decoding-incomplete-2-tuple-rcd)))
    (&utf8-string-decoding-incomplete-3-tuple		($core-rtd . (&utf8-string-decoding-incomplete-3-tuple-rtd
								      &utf8-string-decoding-incomplete-3-tuple-rcd)))
    (&utf8-string-decoding-incomplete-4-tuple		($core-rtd . (&utf8-string-decoding-incomplete-4-tuple-rtd
								      &utf8-string-decoding-incomplete-4-tuple-rcd)))
    (&utf16-string-decoding-invalid-first-word		($core-rtd . (&utf16-string-decoding-invalid-first-word-rtd
								      &utf16-string-decoding-invalid-first-word-rcd)))
    (&utf16-string-decoding-invalid-second-word		($core-rtd . (&utf16-string-decoding-invalid-second-word-rtd
								      &utf16-string-decoding-invalid-second-word-rcd)))
    (&utf16-string-decoding-missing-second-word		($core-rtd . (&utf16-string-decoding-missing-second-word-rtd
								      &utf16-string-decoding-missing-second-word-rcd)))
    (&utf16-string-decoding-standalone-octet		($core-rtd . (&utf16-string-decoding-standalone-octet-rtd
								      &utf16-string-decoding-standalone-octet-rcd)))
    (&utf32-string-decoding-invalid-word		($core-rtd . (&utf32-string-decoding-invalid-word-rtd
								      &utf32-string-decoding-invalid-word-rcd)))
    (&utf32-string-decoding-orphan-octets		($core-rtd . (&utf32-string-decoding-orphan-octets-rtd
								      &utf32-string-decoding-orphan-octets-rcd)))
;;;
    (<top>					(macro . <top>))
    (<void>					(macro . <void>))
    (<boolean>					(macro . <boolean>))
    (<char>					(macro . <char>))
    (<symbol>					(macro . <symbol>))
    (<keyword>					(macro . <keyword>))
    (<pointer>					(macro . <pointer>))
    (<transcoder>				(macro . <transcoder>))
    (<procedure>				(macro . <procedure>))
    (<predicate>				(macro . <predicate>))

    (<fixnum>					(macro . <fixnum>))
    (<flonum>					(macro . <ratnum>))
    (<ratnum>					(macro . <ratnum>))
    (<bignum>					(macro . <bignum>))
    (<compnum>					(macro . <compnum>))
    (<cflonum>					(macro . <cflonum>))
    (<rational-valued>				(macro . <rational-valued>))
    (<rational>					(macro . <rational>))
    (<integer-valued>				(macro . <integer-valued>))
    (<integer>					(macro . <integer>))
    (<exact-integer>				(macro . <exact-integer>))
    (<real-valued>				(macro . <real-valued>))
    (<real>					(macro . <real>))
    (<complex>					(macro . <complex>))
    (<number>					(macro . <number>))

    (<string>					(macro . <string>))
    (<vector>					(macro . <vector>))
    (<pair>					(macro . <pair>))
    (<list>					(macro . <list>))
    (<bytevector>				(macro . <bytevector>))
    (<hashtable>				(macro . <hashtable>))
    (<record>					(macro . <record>))
    (<record-type-descriptor>			(macro . <record-type-descriptor>))
    (<struct>					(macro . <struct>))
    (<struct-type-descriptor>			(macro . <struct-type-descriptor>))
    (<condition>				(macro . <condition>))

    (<port>					(macro . <port>))
    (<input-port>				(macro . <input-port>))
    (<output-port>				(macro . <output-port>))
    (<input/output-port>			(macro . <input/output-port>))
    (<textual-port>				(macro . <textual-port>))
    (<binary-port>				(macro . <binary-port>))
    (<textual-input-port>			(macro . <textual-input-port>))
    (<textual-output-port>			(macro . <textual-output-port>))
    (<textual-input/output-port>		(macro . <textual-input/output-port>))
    (<binary-input-port>			(macro . <binary-input-port>))
    (<binary-output-port>			(macro . <binary-output-port>))
    (<binary-input/output-port>			(macro . <binary-input/output-port>))

    ))


(define-constant LIBRARY-LEGEND
  ;;The library legend lists all the libraries  that will be implemented by the newly
  ;;built boot image.  If a library is  listed here: after building and loading a new
  ;;boot image, it is possible to IMPORT such library.
  ;;
  ;;The legend maps full library specifications  to nicknames: for example "v" is the
  ;;nickname of  "(vicare)".  Additionally  tag each  library with  a VISIBLE?  and a
  ;;REQUIRED?  boolean.
  ;;
  ;;The  libraries  marked  as  VISIBLE?   are listed  by  default  by  the  function
  ;;INTERNED-LIBRARIES.
  ;;
  ;;The libraries  marked as REQUIRED?   are required to build  a new boot  image, so
  ;;they must be already  implemented by the old boot image;  for each library marked
  ;;as REQUIRED?: a record of type LIBRARY, referencing the library from the old boot
  ;;image, is created and included in the starting set of BOOTSTRAP-COLLECTION.
  ;;
  ;;See BOOTSTRAP-COLLECTION for details on how to add a library to this list.
  ;;
  ;; abbr.              name			                visible? required?
  `((v			(vicare)				#t	#t)
    (r			(rnrs)					#t	#t)
    (r5			(rnrs r5rs)				#t	#t)
    (ct			(rnrs control)				#t	#t)
    (ev			(rnrs eval)				#t	#t)
    (mp			(rnrs mutable-pairs)			#t	#t)
    (ms			(rnrs mutable-strings)			#t	#t)
    (pr			(rnrs programs)				#t	#t)
    (sc			(rnrs syntax-case)			#t	#t)
    (fi			(rnrs files)				#t	#t)
    (sr			(rnrs sorting)				#t	#t)
    (ba			(rnrs base)				#t	#t)
    (ls			(rnrs lists)				#t	#t)
    (is			(rnrs io simple)			#t	#t)
    (bv			(rnrs bytevectors)			#t	#t)
    (uc			(rnrs unicode)				#t	#t)
    (ex			(rnrs exceptions)			#t	#t)
    (bw			(rnrs arithmetic bitwise)		#t	#t)
    (fx			(rnrs arithmetic fixnums)		#t	#t)
    (fl			(rnrs arithmetic flonums)		#t	#t)
    (ht			(rnrs hashtables)			#t	#t)
    (ip			(rnrs io ports)				#t	#t)
    (en			(rnrs enums)				#t	#t)
    (co			(rnrs conditions)			#t	#t)
    (ri			(rnrs records inspection)		#t	#t)
    (rp			(rnrs records procedural)		#t	#t)
    (rs			(rnrs records syntactic)		#t	#t)
;;;
    ($pairs		(vicare system $pairs)			#f	#t)
    ($lists		(vicare system $lists)			#f	#t)
    ($chars		(vicare system $chars)			#f	#t)
    ($strings		(vicare system $strings)		#f	#t)
    ($vectors		(vicare system $vectors)		#f	#t)
    ($flonums		(vicare system $flonums)		#f	#t)
    ($bignums		(vicare system $bignums)		#f	#t)
    ($bytes		(vicare system $bytevectors)		#f	#t)
    ($transc		(vicare system $transcoders)		#f	#t)
    ($fx		(vicare system $fx)			#f	#t)
    ($rat		(vicare system $ratnums)		#f	#t)
    ($comp		(vicare system $compnums)		#f	#t)
    ;;FIXME To be made  required at the next boot image  rotation.  (Marco Maggi; Sat
    ;;Mar 28, 2015)
    ($bools		(vicare system $booleans)		#f	#f)
    ($symbols		(vicare system $symbols)		#f	#t)
    ($keywords		(vicare system $keywords)		#f	#t)
    ($structs		(vicare system $structs)		#f	#t)
    ($pointers		(vicare system $pointers)		#f	#t)
    ($codes		(vicare system $codes)			#f	#t)
    ($tcbuckets		(vicare system $tcbuckets)		#f	#t)
    ($arg-list		(vicare system $arg-list)		#f	#t)
    ($stack		(vicare system $stack)			#f	#t)
    ($interrupts	(vicare system $interrupts)		#f	#t)
    ($io		(vicare system $io)			#f	#t)
    ($for		(vicare system $foreign)		#f	#t)
    ($numerics		(vicare system $numerics)		#f	#t)
    ($hashtables	(vicare system $hashtables)		#f	#t)
;;;
    ($all		(psyntax system $all)			#f	#t)
;;;
    ;; These   libraries  are   used   by  the   R6RS   functions  NULL-ENVIRONMENT   and
    ;; SCHEME-REPORT-ENVIRONMENT.
    (ne			(psyntax null-environment-5)		#f	#f)
    (se			(psyntax scheme-report-environment-5)	#f	#f)
;;;
    ($runtime		(vicare system $runtime)		#t	#f)
    ($compiler		(vicare compiler)			#t	#f)
    ($libraries		(vicare libraries)			#t	#t)
    ($programs		(vicare programs)			#t	#f)
    ($language		(vicare language-extensions)		#t	#f)
    ($posix		(vicare language-extensions posix)	#t	#t)
;;;
    ;;FIXME At  the next boot  image rotation  these libraries must  become required.
    ;;(Marco Maggi; Mon Apr 14, 2014)
    ,@(if-building-rotation-boot-image? "expander built-in libraries requirements"
	  '(($type-specs	(vicare expander object-type-specs)	#t	#t)
	    ($expander-tags	(vicare expander tags)			#t	#t)
	    ($expander		(vicare expander)			#t	#t))
	'(($type-specs		(vicare expander object-type-specs)	#t	#f)
	  ($expander-tags	(vicare expander tags)			#t	#f)
	  ($expander		(vicare expander)			#t	#f)))))


(define-constant IDENTIFIER->LIBRARY-MAP
  ;;Map  all  the identifiers  of  exported  bindings  (and  more) to  the  libraries
  ;;exporting them, using  the nicknames defined by LIBRARY-LEGEND each  entry in the
  ;;list has the format:
  ;;
  ;;   (?binding . ?library*)
  ;;
  ;;where:  ?BINDING is  a  symbol representing  the binding  name;  ?library* is  a,
  ;;possibly  empty, proper  list representing  a  list of  library nicknames.   Each
  ;;binding is  exported by  the given  libraries and also  by the  library "(psyntax
  ;;system  $all)"; when  ?LIBRARY* is  null:  the binding  is exported  only by  the
  ;;library "(psyntax system $all)".
  ;;
  ;;Notice that  the map includes LIBRARY,  IMPORT and EXPORT which  are both special
  ;;forms and bindings.
  ;;
  '((import					v $language)
    (export					v $language)
    (foreign-call				v $language)
    (splice-first-expand			v $language)
    (type-descriptor				v $language)
    (is-a?					v $language)
    (condition-is-a?				v $language)
    (slot-ref					v $language)
    (slot-set!					v $language)
    (struct-type-descriptor			v $language)
    (struct-type-and-struct?			v $language)
    (struct-type-field-ref			v $language)
    (struct-type-field-set!			v $language)
    ($struct-type-field-ref			v $language)
    ($struct-type-field-set!			v $language)
    (parameterize				v $language)
    (parameterise				v $language)
    (parametrise				v $language)
    (define-struct				v $language)
    (stale-when					v $language)
    (time					v $language)
    (let*-syntax				v $language)
    (let-constants				v $language)
    (let*-constants				v $language)
    (letrec-constants				v $language)
    (letrec*-constants				v $language)
    (internal-body				v $language)
    (type-of					v $language)
    (expansion-of				v $language)
    (expansion-of*				v $language)
    (visit-code-of				v $language)
    (optimisation-of				v $language)
    (further-optimisation-of			v $language)
    (optimisation-of*				v $language)
    (further-optimisation-of*			v $language)
    (assembly-of				v $language)
    (enable-tagged-language			v $language)
    (disable-tagged-language			v $language)
    (expander-options				v $language)
    (compiler-options				v $language)
    (trace-lambda				v $language)
    (trace-let					v $language)
    (trace-define				v $language)
    (trace-define-syntax			v $language)
    (trace-let-syntax				v $language)
    (trace-letrec-syntax			v $language)
    (integer->machine-word			v $language)
    (machine-word->integer			v $language)
    (make-list					v $language)
    (last-pair					v $language)
    (bwp-object					v $language)
    (bwp-object?				v $language)
    (weak-cons					v $language)
    (weak-pair?					v $language)
    (uuid					v $language)
    (andmap					v $language)
    (ormap					v $language)
    (fx<					v $language)
    (fx<=					v $language)
    (fx>					v $language)
    (fx>=					v $language)
    (fx=					v $language)
    (fx!=					v $language)
    (fxadd1					v $language)
    (fxsub1					v $language)
    (fxquotient					v $language)
    (fxremainder				v $language)
    (fxmodulo					v $language)
    (fxsign					v $language)
    (fxsll					v $language)
    (fxsra					v $language)
    (sra					v $language)
    (sll					v $language)
    (fxlogand					v $language)
    (fxlogxor					v $language)
    (fxlogor					v $language)
    (fxlognot					v $language)
    (fixnum->string				v $language)
    (fixnum->char				v $language)
    (char->fixnum				v $language)
    (string->flonum				v $language)
    (flonum->string				v $language)
    (always-true				v $language)
    (always-false				v $language)
    (add1					v $language)
    (sub1					v $language)
    (bignum?					v $language)
    (ratnum?					v $language)
    (compnum?					v $language)
    (cflonum?					v $language)
    (flonum-parts				v $language)
    (flonum-bytes				v $language)
    (quotient+remainder				v $language)
    (random					v $language)
    (gensym?					v $language)
    (getprop					v $language)
    (putprop					v $language)
    (remprop					v $language)
    (property-list				v $language)
    (gensym->unique-string			v $language)
    (make-guardian				v $language)
    (port-mode					v $language)
    (set-port-mode!				v $language)
    (with-input-from-string			v $language)
    (get-output-string				v $language)
    (with-output-to-string			v $language)
    (console-input-port				v $language)
    (console-error-port				v $language)
    (console-output-port			v $language)
    (stdin					v $language)
    (stdout					v $language)
    (stderr					v $language)
    (reset-input-port!				v $language)
    (reset-output-port!				v $language)
    (printf					v $language)
    (fprintf					v $language)
    (format					v $language)
    (print-gensym				v $language)
    (print-graph				v $language)
    (print-unicode				v $language)
    (printer-integer-radix			v $language)
    (unicode-printable-char?			v $language)
    (gensym-count				v $language)
    (gensym-prefix				v $language)
    (make-parameter				v $language)
    (interrupt-handler				v $language)
    (engine-handler				v $language)
    (assembler-property-key			$codes)
    (new-cafe					v $language)
    (waiter-prompt-string			v $language)
    (cafe-input-port				v $language)
    (readline-enabled?				v $language)
    (readline					v $language)
    (make-readline-input-port			v $language)
;;;
    (environment?				v $language)
    (environment-symbols			v $language)
    (environment-libraries			v $language)
    (environment-labels				v $language)
    (environment-binding			v $language)
;;;
    (time-and-gather				v $language)
    (stats?					v $language)
    (stats-user-secs				v $language)
    (stats-user-usecs				v $language)
    (stats-sys-secs				v $language)
    (stats-sys-usecs				v $language)
    (stats-real-secs				v $language)
    (stats-real-usecs				v $language)
    (stats-collection-id			v $language)
    (stats-gc-user-secs				v $language)
    (stats-gc-user-usecs			v $language)
    (stats-gc-sys-secs				v $language)
    (stats-gc-sys-usecs				v $language)
    (stats-gc-real-secs				v $language)
    (stats-gc-real-usecs			v $language)
    (stats-bytes-minor				v $language)
    (stats-bytes-major				v $language)
    (time-it					v $language)
    (verbose-timer				v $language)
;;;
    (current-time				v $language)
    (time-from-now				v $language)
    (time?					v $language)
    (time-second				v $language)
    (time-nanosecond				v $language)
    (time-gmt-offset				v $language)
    (date-string				v $language)
    (make-time					v $language)
    (time-addition				v $language)
    (time-difference				v $language)
    (time=?					v $language)
    (time<?					v $language)
    (time<=?					v $language)
    (time>?					v $language)
    (time>=?					v $language)
;;;
    (command-line-arguments			v $language)
    (set-rtd-printer!				v $language)
    (set-rtd-destructor!			v $language)
    (struct?					v $language)
    (make-struct-type				v $language)
    (struct-type-descriptor?			v $language)
    (struct-type-name				v $language)
    (struct-type-symbol				v $language)
    (struct-type-field-names			v $language)
    (struct-type-destructor			v $language)
    (default-struct-printer			v $language)
    (default-struct-printer-details		v $language)
    (struct-constructor				v $language)
    (struct-predicate				v $language)
    (struct-field-accessor			v $language)
    (struct-field-mutator			v $language)
    (struct-length				v $language)
    (struct-ref					v $language)
    (struct-set!				v $language)
    (struct-printer				v $language)
    (struct-destructor				v $language)
    (struct-name				v $language)
    (struct-rtd					v $language)
    (struct=?					v $language)
    (struct-reset				v $language)
    (struct-guardian-logger			v $language)
    (struct-guardian-log			v $language)
    (code?					v $language)
    (immediate?					v $language)
    (pointer-value				v $language)
;;;
    (apropos					v $language)

;;; ------------------------------------------------------------
;;; symbols stuff

;;NOTE These bindings  are also needed to  compile the boot image.  Let's  not make a
;;mess with them and just export them from  the library (vicare), so that they can be
;;loaded by "ikarus.compiler".  See the comments in that file for details.

    (symbol-bound?				v $language)
    (top-level-value				v)
    (top-level-bound?				v)
    (set-top-level-value!			v)
    (reset-symbol-proc!				v)

;;; --------------------------------------------------------------------
;;; foldable primitives

    (foldable-cons)
    (foldable-list)
    (foldable-vector)
    (foldable-string)
    (foldable-list->vector)
    (foldable-append)

;;; --------------------------------------------------------------------

    ($boolean=					$bools)
    ($boolean!=					$bools)
    ($boolean<					$bools)
    ($boolean>					$bools)
    ($boolean<=					$bools)
    ($boolean>=					$bools)
    ($boolean-min				$bools)
    ($boolean-max				$bools)
;;;
    ($car					$pairs)
    ($cdr					$pairs)
    ($set-car!					$pairs)
    ($set-cdr!					$pairs)
    ;;
    ($length					$lists)
    ($memq					$lists)
    ($memv					$lists)
;;;
    ($char?					$chars)
    ($char=					$chars)
    ($char!=					$chars)
    ($char<					$chars)
    ($char>					$chars)
    ($char<=					$chars)
    ($char>=					$chars)
    ($chmax					$chars)
    ($chmin					$chars)
    ($char->fixnum				$chars)
    ($fixnum->char				$chars)
;;;
    ($make-string				$strings)
    ($string					$strings)
    ($string-ref				$strings)
    ($string-set!				$strings)
    ($string-length				$strings)
    ($string-empty?				$strings)
    ($string=					$strings)
    ($string!=					$strings)
    ($string<					$strings)
    ($string>					$strings)
    ($string<=					$strings)
    ($string>=					$strings)
    ($string-max				$strings)
    ($string-min				$strings)
    ($string-total-length			$strings)
    ($substring					$strings)
    ($string-copy				$strings)
    ($string-copy!				$strings)
    ($string-concatenate			$strings)
    ($string-reverse-and-concatenate		$strings)
    ($string-copy!/count			$strings)
    ($string-self-copy-forwards!/count		$strings)
    ($string-self-copy-backwards!/count		$strings)
    ($string-fill!				$strings)
    ($interned-strings				$strings)
    ($string->ascii				$strings)
    ($ascii->string				$strings)
    ($string->octets				$strings)
    ($octets->string				$strings)
    ($string->latin1				$strings)
    ($latin1->string				$strings)
    ($octets-encoded-string?			$strings)
    ($ascii-encoded-string?			$strings)
    ($latin1-encoded-string?			$strings)
    ($string-base64->bytevector			$strings)
    ($bytevector->string-base64			$strings)
    ($uri-encoded-string?			$strings)
    ($percent-encoded-string?			$strings)
    ;;
    ($make-bytevector				$bytes)
    ($bytevector-length				$bytes)
    ($bytevector-empty?				$bytes)
    ($bytevector-s8-ref				$bytes)
    ($bytevector-u8-ref				$bytes)
    ($bytevector-set!				$bytes)
    ($bytevector-u8-set!			$bytes)
    ($bytevector-s8-set!			$bytes)

    ($bytevector-u16l-ref			$bytes)
    ($bytevector-u16l-set!			$bytes)
    ($bytevector-u16b-ref			$bytes)
    ($bytevector-u16b-set!			$bytes)
    ($bytevector-u16n-ref			$bytes)
    ($bytevector-u16n-set!			$bytes)
    ($bytevector-s16l-ref			$bytes)
    ($bytevector-s16l-set!			$bytes)
    ($bytevector-s16b-ref			$bytes)
    ($bytevector-s16b-set!			$bytes)
    ($bytevector-s16n-ref			$bytes)
    ($bytevector-s16n-set!			$bytes)
    ($bytevector-u16-ref			$bytes)
    ($bytevector-u16-set!			$bytes)
    ($bytevector-s16-ref			$bytes)
    ($bytevector-s16-set!			$bytes)

    ($bytevector-u32b-ref			$bytes)
    ($bytevector-u32b-set!			$bytes)
    ($bytevector-u32l-ref			$bytes)
    ($bytevector-u32l-set!			$bytes)
    ($bytevector-s32b-ref			$bytes)
    ($bytevector-s32b-set!			$bytes)
    ($bytevector-s32l-ref			$bytes)
    ($bytevector-s32l-set!			$bytes)
    ($bytevector-u32n-ref			$bytes)
    ($bytevector-u32n-set!			$bytes)
    ($bytevector-s32n-ref			$bytes)
    ($bytevector-s32n-set!			$bytes)
    ($bytevector-u32-ref			$bytes)
    ($bytevector-u32-set!			$bytes)
    ($bytevector-s32-ref			$bytes)
    ($bytevector-s32-set!			$bytes)

    ($bytevector-u64b-ref			$bytes)
    ($bytevector-u64b-set!			$bytes)
    ($bytevector-u64l-ref			$bytes)
    ($bytevector-u64l-set!			$bytes)
    ($bytevector-s64b-ref			$bytes)
    ($bytevector-s64b-set!			$bytes)
    ($bytevector-s64l-ref			$bytes)
    ($bytevector-s64l-set!			$bytes)
    ($bytevector-u64n-ref			$bytes)
    ($bytevector-u64n-set!			$bytes)
    ($bytevector-s64n-ref			$bytes)
    ($bytevector-s64n-set!			$bytes)
    ($bytevector-u64-ref			$bytes)
    ($bytevector-u64-set!			$bytes)
    ($bytevector-s64-ref			$bytes)
    ($bytevector-s64-set!			$bytes)

    ($bytevector-ieee-double-native-ref		$bytes)
    ($bytevector-ieee-double-native-set!	$bytes)
    ($bytevector-ieee-double-nonnative-ref	$bytes)
    ($bytevector-ieee-double-nonnative-set!	$bytes)

    ($bytevector-ieee-double-big-ref		$bytes)
    ($bytevector-ieee-double-big-set!		$bytes)
    ($bytevector-ieee-double-little-ref		$bytes)
    ($bytevector-ieee-double-little-set!	$bytes)
    ($bytevector-ieee-double-ref		$bytes)
    ($bytevector-ieee-double-set!		$bytes)

    ($bytevector-ieee-single-native-ref		$bytes)
    ($bytevector-ieee-single-native-set!	$bytes)
    ($bytevector-ieee-single-nonnative-ref	$bytes)
    ($bytevector-ieee-single-nonnative-set!	$bytes)

    ($bytevector-ieee-single-big-ref		$bytes)
    ($bytevector-ieee-single-big-set!		$bytes)
    ($bytevector-ieee-single-little-ref		$bytes)
    ($bytevector-ieee-single-little-set!	$bytes)
    ($bytevector-ieee-single-ref		$bytes)
    ($bytevector-ieee-single-set!		$bytes)

    ($subbytevector-u8				$bytes)
    ($subbytevector-u8/count			$bytes)
    ($subbytevector-s8				$bytes)
    ($subbytevector-s8/count			$bytes)

    ($bytevector=				$bytes)
    ($bytevector!=				$bytes)
    ($bytevector-u8<				$bytes)
    ($bytevector-u8>				$bytes)
    ($bytevector-u8<=				$bytes)
    ($bytevector-u8>=				$bytes)
    ($bytevector-u8-min				$bytes)
    ($bytevector-u8-max				$bytes)
    ($bytevector-s8<				$bytes)
    ($bytevector-s8>				$bytes)
    ($bytevector-s8<=				$bytes)
    ($bytevector-s8>=				$bytes)
    ($bytevector-s8-min				$bytes)
    ($bytevector-s8-max				$bytes)
    ($bytevector-total-length			$bytes)
    ($bytevector-concatenate			$bytes)
    ($bytevector-reverse-and-concatenate	$bytes)
    ($bytevector-copy				$bytes)
    ($bytevector-copy!				$bytes)
    ($bytevector-copy!/count			$bytes)
    ($bytevector-self-copy-forwards!/count	$bytes)
    ($bytevector-self-copy-backwards!/count	$bytes)
    ($bytevector-fill!				$bytes)
    ($uri-encode				$bytes)
    ($uri-decode				$bytes)
    ($uri-encoded-bytevector?			$bytes)
    ($uri-normalise-encoding			$bytes)
    ($octets-encoded-bytevector?		$bytes)
    ($ascii-encoded-bytevector?			$bytes)
    ($latin1-encoded-bytevector?		$bytes)
    ($percent-encode				$bytes)
    ($percent-decode				$bytes)
    ($percent-encoded-bytevector?		$bytes)
    ($percent-normalise-encoding		$bytes)
    ($bytevector->base64			$bytes)
    ($base64->bytevector			$bytes)
;;;
    ($flonum-u8-ref				$flonums)
    ($make-flonum				$flonums)
    ($flonum-set!				$flonums)
    ($flonum-rational?				$flonums)
    ($flonum-integer?				$flonums)
    ($fl+					$flonums)
    ($fl-					$flonums)
    ($fl*					$flonums)
    ($fl/					$flonums)
    ($fl=					$flonums)
    ($fl!=					$flonums)
    ($fl<					$flonums)
    ($fl<=					$flonums)
    ($fl>					$flonums)
    ($fl>=					$flonums)
    ($fldiv					$flonums)
    ($flmod					$flonums)
    ($fldiv0					$flonums)
    ($flmod0					$flonums)
    ($fldiv-and-mod				$flonums)
    ($fldiv0-and-mod0				$flonums)
    ($fixnum->flonum				$flonums)
    ($flonum-sbe				$flonums)
    ($flonum->exact				$flonums)
    ($flzero?					$flonums)
    ($flzero?/positive				$flonums)
    ($flzero?/negative				$flonums)
    ($flpositive?				$flonums)
    ($flnegative?				$flonums)
    ($flnonpositive?				$flonums)
    ($flnonnegative?				$flonums)
    ($fleven?					$flonums)
    ($flnan?					$flonums)
    ($flfinite?					$flonums)
    ($flinfinite?				$flonums)
    ($flodd?					$flonums)
    ($flround					$flonums)
    ($flfloor					$flonums)
    ($flceiling					$flonums)
    ($fltruncate				$flonums)
    ($flnumerator				$flonums)
    ($fldenominator				$flonums)
    ($flabs					$flonums)
    ($flsin					$flonums)
    ($flcos					$flonums)
    ($fltan					$flonums)
    ($flasin					$flonums)
    ($flacos					$flonums)
    ($flatan					$flonums)
    ($flsinh					$flonums)
    ($flcosh					$flonums)
    ($fltanh					$flonums)
    ($flasinh					$flonums)
    ($flacosh					$flonums)
    ($flatanh					$flonums)
    ($flatan2					$flonums)
    ($flexp					$flonums)
    ($fllog					$flonums)
    ($fllog2					$flonums)
    ($flexpm1					$flonums)
    ($fllog1p					$flonums)
    ($flexpt					$flonums)
    ($flsqrt					$flonums)
    ($flcbrt					$flonums)
    ($flsquare					$flonums)
    ($flcube					$flonums)
    ($flhypot					$flonums)
    ($flmax					$flonums)
    ($flmin					$flonums)
;;;
    ($make-bignum				$bignums)
    ($bignum-positive?				$bignums)
    ($bignum-negative?				$bignums)
    ($bignum-non-positive?			$bignums)
    ($bignum-non-negative?			$bignums)
    ($bignum-size				$bignums)
    ($bignum-byte-ref				$bignums)
    ($bignum-byte-set!				$bignums)
    ($bignum-even?				$bignums)
    ($bignum-odd?				$bignums)
    ($bignum->flonum				$bignums)
;;;
    ($make-ratnum				$rat)
    ($ratnum-n					$rat)
    ($ratnum-num				$rat)
    ($ratnum-d					$rat)
    ($ratnum-den				$rat)
    ($ratnum->flonum				$rat)
    ($ratnum-positive?				$rat)
    ($ratnum-negative?				$rat)
    ($ratnum-non-positive?			$rat)
    ($ratnum-non-negative?			$rat)
;;;
    ($make-rectangular				$comp)

    ($make-compnum				$comp)
    ($compnum-real				$comp)
    ($compnum-imag				$comp)

    ($make-cflonum				$comp)
    ($cflonum-real				$comp)
    ($cflonum-imag				$comp)

    ($complex-conjugate-compnum			$numerics)
    ($complex-conjugate-cflonum			$numerics)

    ($angle-fixnum				$numerics)
    ($angle-bignum				$numerics)
    ($angle-ratnum				$numerics)
    ($angle-flonum				$numerics)
    ($angle-compnum				$numerics)
    ($angle-cflonum				$numerics)

    ($magnitude-fixnum				$numerics)
    ($magnitude-bignum				$numerics)
    ($magnitude-ratnum				$numerics)
    ($magnitude-flonum				$numerics)
    ($magnitude-compnum				$numerics)
    ($magnitude-cflonum				$numerics)
;;;
    ($make-vector				$vectors)
    ($make-clean-vector				$vectors)
    ($vector-length				$vectors)
    ($vector-empty?				$vectors)
    ($vector-ref				$vectors)
    ($vector-set!				$vectors)
    ($vector-map1				$vectors)
    ($vector-for-each1				$vectors)
    ($vector-for-all1				$vectors)
    ($vector-exists1				$vectors)
;;;
    ($fxzero?					$fx)
    ($fxpositive?				$fx)
    ($fxnegative?				$fx)
    ($fxnonpositive?				$fx)
    ($fxnonnegative?				$fx)
    ($fxeven?					$fx)
    ($fxodd?					$fx)
    ($fxadd1					$fx)
    ($fxsub1					$fx)
    ($fx>=					$fx)
    ($fx<=					$fx)
    ($fx>					$fx)
    ($fx<					$fx)
    ($fx=					$fx)
    ($fxmin					$fx)
    ($fxmax					$fx)
    ($fxsll					$fx)
    ($fxsra					$fx)
    ($fxquotient				$fx)
    ($fxmodulo					$fx)
    ($fxremainder				$fx)
    ($fxsign					$fx)
    ($int-quotient				$fx)
    ($int-remainder				$fx)
    ($fxlogxor					$fx)
    ($fxlogor					$fx)
    ($fxlognot					$fx)
    ($fxlogand					$fx)
    ($fx+					$fx)
    ($fx*					$fx)
    ($fx-					$fx)
    ($fxinthash					$fx)
    ($fxdiv					$fx)
    ($fxdiv0					$fx)
    ($fxmod					$fx)
    ($fxmod0					$fx)
    ($fxdiv-and-mod				$fx)
    ($fxdiv0-and-mod0				$fx)
    ($fxabs					$fx)
    ($fxcopy-bit				$fx)
    ($fxcopy-bit-field				$fx)
    ($fxrotate-bit-field			$fx)
    ($fxbit-field				$fx)
    ($fixnum->string				$fx)
;;;
    ($make-symbol				$symbols)
    ($string->symbol				$symbols)
    ($symbol=					$symbols)
    ($symbol!=					$symbols)
    ($symbol<					$symbols)
    ($symbol<=					$symbols)
    ($symbol>					$symbols)
    ($symbol>=					$symbols)
    ($symbol-max				$symbols)
    ($symbol-min				$symbols)
    ($symbol->string				$symbols)
    ($symbol-unique-string			$symbols)
    ($symbol-value				$symbols)
    ($symbol-proc				$symbols)
    ($symbol-string				$symbols)
    ($symbol-plist				$symbols)
    ($set-symbol-value!				$symbols)
    ($set-symbol-proc!				$symbols)
    ($set-symbol-string!			$symbols)
    ($set-symbol-unique-string!			$symbols)
    ($set-symbol-plist!				$symbols)
    ($unintern-gensym				$symbols)
    ($init-symbol-value!)
    ($unbound-object?				$symbols)
    ($symbol-table-size				$symbols)
    ($log-symbol-table-status			$symbols)
    ($getprop					$symbols)
    ($putprop					$symbols)
    ($remprop					$symbols)
    ($property-list				$symbols)
;;;
    ($symbol->keyword				$keywords)
    ($keyword->symbol				$keywords)
    ($keyword->string				$keywords)
    ($keyword-hash				$keywords)
    ($keyword=?					$keywords)
;;;
    (base-rtd					$structs)
    ($struct-set!				$structs)
    ($struct-ref				$structs)
    ($struct-rtd				$structs)
    ($struct					$structs)
    ($make-struct				$structs)
    ($make-clean-struct				$structs)
    ($struct?					$structs)
    ($struct/rtd?				$structs)
    ($struct-guardian				$structs)
    ($record-guardian				$structs)

    ($std-std					$structs)
    ($std-name					$structs)
    ($std-length				$structs)
    ($std-fields				$structs)
    ($std-printer				$structs)
    ($std-symbol				$structs)
    ($std-destructor				$structs)

    ($set-std-std!				$structs)
    ($set-std-name!				$structs)
    ($set-std-length!				$structs)
    ($set-std-fields!				$structs)
    ($set-std-printer!				$structs)
    ($set-std-symbol!				$structs)
    ($set-std-destructor!			$structs)

;;; --------------------------------------------------------------------
;;; (ikarus system $pointers)
    ($pointer=					$pointers)
    ($pointer!=					$pointers)
    ($pointer<					$pointers)
    ($pointer>					$pointers)
    ($pointer<=					$pointers)
    ($pointer>=					$pointers)
    ($pointer-min				$pointers)
    ($pointer-max				$pointers)
;;;
    ($closure-code				$codes)
    ($code->closure				$codes)
    ($code-reloc-vector				$codes)
    ($code-freevars				$codes)
    ($code-size					$codes)
    ($code-annotation				$codes)
    ($code-ref					$codes)
    ($code-set!					$codes)
    ($set-code-annotation!			$codes)
    (code-reloc-vector->sexp			$codes)
    (procedure-annotation			v $language)
    ($make-annotated-procedure			$codes)
    ($annotated-procedure-annotation		$codes)
    ($cpref					$codes)
    ($make-tcbucket				$tcbuckets)
    ($tcbucket-key				$tcbuckets)
    ($tcbucket-val				$tcbuckets)
    ($tcbucket-next				$tcbuckets)
    ($set-tcbucket-val!				$tcbuckets)
    ($set-tcbucket-next!			$tcbuckets)
    ($set-tcbucket-tconc!			$tcbuckets)
    ($arg-list					$arg-list)
    ($collect-key				$arg-list)
    ($$apply					$stack)
    ($fp-at-base				$stack)
    ($primitive-call/cc				$stack)
    ($frame->continuation			$stack)
    ($current-frame				$stack)
    ($seal-frame-and-call			$stack)
    ($make-call-with-values-procedure		$stack)
    ($make-values-procedure			$stack)
    ($interrupted?				$interrupts)
    ($unset-interrupted!			$interrupts)
    ($swap-engine-counter!			$interrupts)
;;;
    (interrupted-condition?			v $language)
    (make-interrupted-condition			v $language)
    (source-position-condition?			v $language)
    (make-source-position-condition		v $language)
    (source-position-port-id			v $language)
    (source-position-byte			v $language)
    (source-position-character			v $language)
    (source-position-line			v $language)
    (source-position-column			v $language)

    ($apply-nonprocedure-error-handler)
    ($incorrect-args-error-handler)
    ($multiple-values-error)
    ($debug)
    ($do-event)
    (do-overflow)
    (do-vararg-overflow)
    (collect					v $language)
    (automatic-collect				v $language)
    (collect-key				v $language)
    (post-gc-hooks				v $language)
    (automatic-garbage-collection		v $language)
    (register-to-avoid-collecting		v $language)
    (forget-to-avoid-collecting			v $language)
    (replace-to-avoid-collecting		v $language)
    (retrieve-to-avoid-collecting		v $language)
    (collection-avoidance-list			v $language)
    (purge-collection-avoidance-list		v $language)
    (do-stack-overflow)
    (make-promise)
    (make-traced-procedure			v $language)
    (make-traced-macro				v $language)
    (error@fx+)
    (error@fxarithmetic-shift-left)
    (error@fxarithmetic-shift-right)
    (error@fx*)
    (error@fx-)
    (error@add1)
    (error@sub1)
    (error@fxadd1)
    (error@fxsub1)
    (fasl-write					v $language)
    (fasl-read					v $language)
    (lambda						v r ba se ne)
    (lambda*					v $language)
    (case-lambda*				v $language)
    (case-define				v $language)
    (case-define*				v $language)
    (and					v r ba se ne)
    (begin					v r ba se ne)
    (case					v r ba se ne)
    (case-identifiers				v $language)
    (cond					v r ba se ne)
    (define					v r ba se ne)
    (internal-define)
    (internal-lambda)
    (internal-case-lambda)
    (define-syntax				v r ba se ne)
    (define-syntax*				v $language)
    (define*					v $language)
    (define-fluid-syntax			v $language)
    (define-alias				v $language)
    (identifier-syntax				v r ba)
    (if						v r ba se ne)
    (let					v r ba se ne)
    (let*					v r ba se ne)
    (let*-values				v r ba)
    (let-syntax					v r ba se ne)
    (let-values					v r ba)
    (fluid-let-syntax				v $language)
    (define-syntax-parameter			v $language)
    (syntax-parametrise				v $language)
    (syntax-parameterize			v $language)
    (syntax-parameterise			v $language)
    (syntax-parameter-value			v $language)
    (letrec					v r ba se ne)
    (letrec*					v r ba)
    (letrec-syntax				v r ba se ne)
    (or						v r ba se ne)
    (quasiquote					v r ba se ne)
    (quote					v r ba se ne)
    (set!					v r ba se ne)
    (syntax-rules				v r ba se ne)
    (unquote					v r ba se ne)
    (unquote-splicing				v r ba se ne)
    (<						v r ba se)
    (<=						v r ba se)
    (=						v r ba se)
    (!=						v $language)
    (>						v r ba se)
    (>=						v r ba se)
    (+						v r ba se)
    (-						v r ba se)
    (*						v r ba se)
    (/						v r ba se)
    (abs					v r ba se)
    (sign					v $language)
    (asin					v r ba se)
    (acos					v r ba se)
    (atan					v r ba se)
    (sinh					v $language)
    (cosh					v $language)
    (tanh					v $language)
    (asinh					v $language)
    (acosh					v $language)
    (atanh					v $language)
    (angle					v r ba se)
    (bignum->bytevector				v $language)
    (bytevector->bignum				v $language)
    (append					v r ba se)
    (apply					v r ba se)
    (assert					v r ba)
    (assertion-error) ;empty?!?
    (assertion-violation			v r ba)
    (boolean=?					v r ba)
    (boolean!=?					v $language)
    (boolean<?					v $language)
    (boolean>?					v $language)
    (boolean<=?					v $language)
    (boolean>=?					v $language)
    (boolean-min				v $language)
    (boolean-max				v $language)
    (list-of-booleans?				v $language)
    (boolean?					v r ba se)
    (car					v r ba se)
    (cdr					v r ba se)
    (caar					v r ba se)
    (cadr					v r ba se)
    (cdar					v r ba se)
    (cddr					v r ba se)
    (caaar					v r ba se)
    (caadr					v r ba se)
    (cadar					v r ba se)
    (caddr					v r ba se)
    (cdaar					v r ba se)
    (cdadr					v r ba se)
    (cddar					v r ba se)
    (cdddr					v r ba se)
    (caaaar					v r ba se)
    (caaadr					v r ba se)
    (caadar					v r ba se)
    (caaddr					v r ba se)
    (cadaar					v r ba se)
    (cadadr					v r ba se)
    (caddar					v r ba se)
    (cadddr					v r ba se)
    (cdaaar					v r ba se)
    (cdaadr					v r ba se)
    (cdadar					v r ba se)
    (cdaddr					v r ba se)
    (cddaar					v r ba se)
    (cddadr					v r ba se)
    (cdddar					v r ba se)
    (cddddr					v r ba se)
    (call-with-current-continuation		v r ba se)
    (call/cc					v r ba)
    ;;FIXME To be removed at the next boot image rotation.  (Marco Maggi; Thu Mar 26,
    ;;2015)
    (call/cf)
    (call-with-values				v r ba se)
    (ceiling					v r ba se)
;;
    (char->integer				v r ba se)
    (char<=?					v r ba se)
    (char<?					v r ba se)
    (char=?					v r ba se)
    (char!=?					v $language)
    (char>=?					v r ba se)
    (char>?					v r ba se)
    (char?					v r ba se)
    (chmin					v $language)
    (chmax					v $language)
    (list-of-chars?				v $language)
    (char-in-ascii-range?			v $language)
    (fixnum-in-character-range?			v $language)
;;
    (complex?					v r ba se)
    (cons					v r ba se)
    (cos					v r ba se)
    (denominator				v r ba se)
    (div					v r ba)
    (mod					v r ba)
    (div-and-mod				v r ba)
    (div0					v r ba)
    (mod0					v r ba)
    (div0-and-mod0				v r ba)
    (dynamic-wind				v r ba se)
    (eq?					v r ba se)
    (neq?					v $language)
    (equal?					v r ba se)
    (eqv?					v r ba se)
    (error					v r ba)
    (warning					v $language)
    (die					v $language)
    (even?					v r ba se)
    (exact					v r ba)
    (exact-integer-sqrt				v r ba)
    (exact?					v r ba se)
    (exp					v r ba se)
    (expt					v r ba se)
    (factorial					v $language)
    (finite?					v r ba)
    (floor					v r ba se)
    (for-each					v r ba se)
    (for-each-in-order				v $language)
    (gcd					v r ba se)
    (imag-part					v r ba se)
    (inexact					v r ba)
    (inexact?					v r ba se)
    (infinite?					v r ba)
    (integer->char				v r ba se)
    (integer-valued?				v r ba)
    (integer?					v r ba se)
    (exact-integer?				v $language)
    (zero-exact-integer?			v $language)
    (negative-exact-integer?			v $language)
    (positive-exact-integer?			v $language)
    (non-negative-exact-integer?		v $language)
    (non-positive-exact-integer?		v $language)
    (lcm					v r ba se)
    (length					v r ba se)
    (list					v r ba se)
    (list->string				v r ba se)
    (list->vector				v r ba se)
    (list-ref					v r ba se)
    (list-tail					v r ba se)
    (list?					v r ba se)
    (log					v r ba se)
    (magnitude					v r ba se)
    (make-polar					v r ba se)
    (make-rectangular				v r ba se)
    (complex-conjugate				v $language)
    (make-string				v r ba se)
    (make-vector				v r ba se)
    (map					v r ba se)
    (max					v r ba se)
    (min					v r ba se)
    (nan?					v r ba)
    (negative?					v r ba se)
    (non-negative?				v $language)
    (not					v r ba se)
    (null?					v r ba se)
    (number->string				v r ba se)
    (number?					v r ba se)
    (numerator					v r ba se)
    (odd?					v r ba se)
    (pair?					v r ba se)
    (positive?					v r ba se)
    (non-positive?				v $language)
    (procedure?					v r ba se)
    (rational-valued?				v r ba)
    (rational?					v r ba se)
    (rationalize				v r ba se)
    (real-part					v r ba se)
    (real-valued?				v r ba)
    (real?					v r ba se)
    (reverse					v r ba se)
    (round					v r ba se)
    (sin					v r ba se)
    (sqrt					v r ba se)
    (cbrt					v $language)
    (square					v $language)
    (cube					v $language)
    (string					v r ba se)
    (string->list				v r ba se)
    (string->number				v r ba se)
    (string->symbol				v r ba se)
    (string-or-symbol->string			v $language)
    (string-or-symbol->symbol			v $language)
    (string-append				v r ba se)
    (string-concatenate				v $language)
    (string-reverse-and-concatenate		v $language)
    (string-copy				v r ba se)
    (string-for-each				v r ba)
    (string-length				v r ba se)
    (string-empty?				v $language)
    (string-ref					v r ba se)
    (string<=?					v r ba se)
    (string<?					v r ba se)
    (string=?					v r ba se)
    (string!=?					v $language)
    (string>=?					v r ba se)
    (string>?					v r ba se)
    (string-min					v $language)
    (string-max					v $language)
    (string?					v r ba se)
    (list-of-strings?				v $language)
    (substring					v r ba se)
    (string->latin1				v $language)
    (latin1->string				v $language)
    (latin1-encoded-bytevector?			v $language)
    (ascii-encoded-string?			v $language)
    (latin1-encoded-string?			v $language)
    (string->ascii				v $language)
    (string->octets				v $language)
    (octets-encoded-bytevector?			v $language)
    (octets-encoded-string?			v $language)
    (octets->string				v $language)
    (ascii->string				v $language)
    (ascii-encoded-bytevector?			v $language)
    (bytevector->hex				v $language)
    (hex->bytevector				v $language)
    (string-hex->bytevector			v $language)
    (bytevector->string-hex			v $language)
    (bytevector->base64				v $language)
    (base64->bytevector				v $language)
    (string-base64->bytevector			v $language)
    (bytevector->string-base64			v $language)
    (string->uri-encoding			v $language)
    (uri-encoding->string			v $language)
    (string->percent-encoding			v $language)
    (percent-encoding->string			v $language)
    (uri-encode					v $language)
    (uri-decode					v $language)
    (normalise-uri-encoding			v $language)
    (uri-encoded-bytevector?			v $language)
    (uri-encoded-string?			v $language)
    (percent-encoded-bytevector?		v $language)
    (percent-encoded-string?			v $language)
    (percent-encode				v $language)
    (percent-decode				v $language)
    (normalise-percent-encoding			v $language)
    (symbol->string				v r ba se)
    (symbol=?					v r ba)
    (symbol!=?					v $language)
    (symbol<?					v $language)
    (symbol<=?					v $language)
    (symbol>?					v $language)
    (symbol>=?					v $language)
    (symbol-max					v $language)
    (symbol-min					v $language)
    (symbol?					v r ba se)
    (list-of-symbols?				v $language)
    (tan					v r ba se)
    (truncate					v r ba se)
    (values					v r ba se)
    (values->list				v $language)
    (vector					v r ba se)
    (vector->list				v r ba se)
    (vector-fill!				v r ba se)
    (vector-for-each				v r ba)
    (vector-length				v r ba se)
    (vector-empty?				v $language)
    (non-empty-vector?				v $language)
    (vectors-of-same-length?			v $language)
    (list-of-vectors-of-same-length?		v $language)
    (vector-map					v r ba)
    (vector-for-all				v $language)
    (vector-exists				v $language)
    (vector-find				v $language)
    (vector-fold-left				v $language)
    (vector-fold-right				v $language)
    (vector-ref					v r ba se)
    (vector-set!				v r ba se)
    (subvector					v $language)
    (vector-append				v $language)
    (vector-copy				v $language)
    (vector-copy!				v $language)
    (vector-resize				v $language)
    (vector?					v r ba se)
    (list-of-vectors?				v $language)
    (zero?					v r ba se)
    (...					v r ba sc se ne)
    (=>						v r ba ex se ne)
    (_						v r ba sc se ne)
    (else					v r ba ex se ne)
    (bitwise-arithmetic-shift			v r bw)
    (bitwise-arithmetic-shift-left		v r bw)
    (bitwise-arithmetic-shift-right		v r bw)
    (bitwise-not				v r bw)
    (bitwise-and				v r bw)
    (bitwise-ior				v r bw)
    (bitwise-xor				v r bw)
    (bitwise-bit-count				v r bw)
    (bitwise-bit-field				v r bw)
    (bitwise-bit-set?				v r bw)
    (bitwise-copy-bit				v r bw)
    (bitwise-copy-bit-field			v r bw)
    (bitwise-first-bit-set			v r bw)
    (bitwise-if					v r bw)
    (bitwise-length				v r bw)
    (bitwise-reverse-bit-field			v r bw)
    (bitwise-rotate-bit-field			v r bw)
    (fixnum?					v r fx)
    (list-of-fixnums?				v $language)
    (fixnum-width				v r fx)
    (least-fixnum				v r fx)
    (greatest-fixnum				v r fx)
    (fx*					v r fx)
    (fx*/carry					v r fx)
    (fx+					v r fx)
    (fx+/carry					v r fx)
    (fx-					v r fx)
    (fx-/carry					v r fx)
    (fx<=?					v r fx)
    (fx<?					v r fx)
    (fx=?					v r fx)
    (fx!=?					v r fx)
    (fx>=?					v r fx)
    (fx>?					v r fx)
    (fxand					v r fx)
    (fxarithmetic-shift				v r fx)
    (fxarithmetic-shift-left			v r fx)
    (fxarithmetic-shift-right			v r fx)
    (fxbit-count				v r fx)
    (fxbit-field				v r fx)
    (fxbit-set?					v r fx)
    (fxcopy-bit					v r fx)
    (fxcopy-bit-field				v r fx)
    (fxdiv					v r fx)
    (fxdiv-and-mod				v r fx)
    (fxdiv0					v r fx)
    (fxdiv0-and-mod0				v r fx)
    (fxabs					v $language)
    (fxeven?					v r fx)
    (fxfirst-bit-set				v r fx)
    (fxif					v r fx)
    (fxior					v r fx)
    (fxlength					v r fx)
    (fxmax					v r fx)
    (fxmin					v r fx)
    (fxmod					v r fx)
    (fxmod0					v r fx)
    (fxnot					v r fx)
    (fxodd?					v r fx)
    (fxreverse-bit-field			v r fx)
    (fxrotate-bit-field				v r fx)
    (fxxor					v r fx)
    (fxzero?					v r fx)
    (fxpositive?				v r fx)
    (fxnegative?				v r fx)
    (fxnonpositive?				v $language)
    (fxnonnegative?				v $language)
    (non-zero-fixnum?				v $language)
    (positive-fixnum?				v $language)
    (negative-fixnum?				v $language)
    (non-negative-fixnum?			v $language)
    (non-positive-fixnum?			v $language)
    (fixnum->flonum				v r fl)
;;;
    (bignum-positive?				v $language)
    (bignum-negative?				v $language)
    (bignum-non-negative?			v $language)
    (bignum-non-positive?			v $language)
    (bignum-odd?				v $language)
    (bignum-even?				v $language)
    (least-positive-bignum			v $language)
    (greatest-negative-bignum			v $language)
;;;
    (fl*					v r fl)
    (fl+					v r fl)
    (fl-					v r fl)
    (fl/					v r fl)
    (fl<=?					v r fl)
    (fl<?					v r fl)
    (fl=?					v r fl)
    (fl!=?					v $language)
    (fl>=?					v r fl)
    (fl>?					v r fl)
    (flabs					v r fl)
    (flceiling					v r fl)
    (fldenominator				v r fl)
    (fldiv					v r fl)
    (fldiv-and-mod				v r fl)
    (fldiv0					v r fl)
    (fldiv0-and-mod0				v r fl)
    (fleven?					v r fl)
    (flexp					v r fl)
    (flexpm1					v $language)
    (flexpt					v r fl)
    (flfinite?					v r fl)
    (flfloor					v r fl)
    (flinfinite?				v r fl)
    (flinteger?					v r fl)
    (fllog					v r fl)
    (fllog1p					v $language)
    (flhypot					v $language)
    (flmax					v r fl)
    (flmin					v r fl)
    (flmod					v r fl)
    (flmod0					v r fl)
    (flnan?					v r fl)
    (flnegative?				v r fl)
    (flnumerator				v r fl)
    (flodd?					v r fl)
    (flonum?					v r fl)
    (list-of-flonums?				v $language)
    (flpositive?				v r fl)
    (flnonpositive?				v $language)
    (flnonnegative?				v $language)
    (positive-flonum?				v $language)
    (negative-flonum?				v $language)
    (non-negative-flonum?			v $language)
    (non-positive-flonum?			v $language)
    (flround					v r fl)
    (flsin					v r fl)
    (flcos					v r fl)
    (fltan					v r fl)
    (flacos					v r fl)
    (flasin					v r fl)
    (flatan					v r fl)
    (flsinh					v $language)
    (flcosh					v $language)
    (fltanh					v $language)
    (flacosh					v $language)
    (flasinh					v $language)
    (flatanh					v $language)
    (flsqrt					v r fl)
    (flcbrt					v $language)
    (flsquare					v $language)
    (flcube					v $language)
    (fltruncate					v r fl)
    (flzero?					v r fl)
    (flzero?/positive				v $language)
    (flzero?/negative				v $language)
    (real->flonum				v r fl)
    (bytevector->flonum				v $language)
    (flonum->bytevector				v $language)
    (make-no-infinities-violation		v r fl)
    (make-no-nans-violation			v r fl)
    (&no-infinities				v r fl)
    (no-infinities-violation?			v r fl)
    (&no-nans					v r fl)
    (no-nans-violation?				v r fl)
    (bytevector->sint-list			v r bv)
    (bytevector->u8-list			v r bv)
    (bytevector->s8-list			v $language)
    (bytevector->u16l-list			v $language)
    (bytevector->u16b-list			v $language)
    (bytevector->u16n-list			v $language)
    (bytevector->s16l-list			v $language)
    (bytevector->s16b-list			v $language)
    (bytevector->s16n-list			v $language)
    (bytevector->u32l-list			v $language)
    (bytevector->u32b-list			v $language)
    (bytevector->u32n-list			v $language)
    (bytevector->s32l-list			v $language)
    (bytevector->s32b-list			v $language)
    (bytevector->s32n-list			v $language)
    (bytevector->u64l-list			v $language)
    (bytevector->u64b-list			v $language)
    (bytevector->u64n-list			v $language)
    (bytevector->s64l-list			v $language)
    (bytevector->s64b-list			v $language)
    (bytevector->s64n-list			v $language)
    (bytevector->uint-list			v r bv)
    (bytevector->f4l-list			v $language)
    (bytevector->f4b-list			v $language)
    (bytevector->f4n-list			v $language)
    (bytevector->f8l-list			v $language)
    (bytevector->f8b-list			v $language)
    (bytevector->f8n-list			v $language)
    (bytevector->c4l-list			v $language)
    (bytevector->c4b-list			v $language)
    (bytevector->c4n-list			v $language)
    (bytevector->c8l-list			v $language)
    (bytevector->c8b-list			v $language)
    (bytevector->c8n-list			v $language)
    (bytevector-copy				v r bv)
    (string-copy!				v $language)
    (bytevector-copy!				v r bv)
    (bytevector-fill!				v r bv)
    (bytevector-ieee-double-native-ref		v r bv)
    (bytevector-ieee-double-native-set!		v r bv)
    (bytevector-ieee-double-ref			v r bv)
    (bytevector-ieee-double-set!		v r bv)
    (bytevector-ieee-single-native-ref		v r bv)
    (bytevector-ieee-single-native-set!		v r bv)
    (bytevector-ieee-single-ref			v r bv)
    (bytevector-ieee-single-set!		v r bv)
    (bytevector-length				v r bv)
    (bytevector-length?				v $language)
    (bytevector-index?				v $language)
    (bytevector-word-size?			v $language)
    (bytevector-word-count?			v $language)
    (bytevector-index-for-word?			v $language)
    (bytevector-index-for-word8?		v $language)
    (bytevector-index-for-word16?		v $language)
    (bytevector-index-for-word32?		v $language)
    (bytevector-index-for-word64?		v $language)
    (bytevector-index-for-single-flonum?	v $language)
    (bytevector-index-for-double-flonum?	v $language)
    (bytevector-start-index-and-count-for-word?		v $language)
    (bytevector-start-index-and-count-for-word8?	v $language)
    (bytevector-start-index-and-count-for-word16?	v $language)
    (bytevector-start-index-and-count-for-word32?	v $language)
    (bytevector-start-index-and-count-for-word64?	v $language)
    (list-of-bytevectors?			v $language)
    (bytevector-empty?				v $language)
    (bytevector-s16-native-ref			v r bv)
    (bytevector-s16-native-set!			v r bv)
    (bytevector-s16-ref				v r bv)
    (bytevector-s16-set!			v r bv)
    (bytevector-s32-native-ref			v r bv)
    (bytevector-s32-native-set!			v r bv)
    (bytevector-s32-ref				v r bv)
    (bytevector-s32-set!			v r bv)
    (bytevector-s64-native-ref			v r bv)
    (bytevector-s64-native-set!			v r bv)
    (bytevector-s64-ref				v r bv)
    (bytevector-s64-set!			v r bv)
    (bytevector-s8-ref				v r bv)
    (bytevector-s8-set!				v r bv)
    (bytevector-sint-ref			v r bv)
    (bytevector-sint-set!			v r bv)
    (bytevector-u16-native-ref			v r bv)
    (bytevector-u16-native-set!			v r bv)
    (bytevector-u16-ref				v r bv)
    (bytevector-u16-set!			v r bv)
    (bytevector-u32-native-ref			v r bv)
    (bytevector-u32-native-set!			v r bv)
    (bytevector-u32-ref				v r bv)
    (bytevector-u32-set!			v r bv)
    (bytevector-u64-native-ref			v r bv)
    (bytevector-u64-native-set!			v r bv)
    (bytevector-u64-ref				v r bv)
    (bytevector-u64-set!			v r bv)
    (bytevector-u8-ref				v r bv)
    (bytevector-u8-set!				v r bv)
    (bytevector-uint-ref			v r bv)
    (bytevector-uint-set!			v r bv)
    (f4l-list->bytevector			v $language)
    (f4b-list->bytevector			v $language)
    (f4n-list->bytevector			v $language)
    (f8l-list->bytevector			v $language)
    (f8b-list->bytevector			v $language)
    (f8n-list->bytevector			v $language)
    (c4l-list->bytevector			v $language)
    (c4b-list->bytevector			v $language)
    (c4n-list->bytevector			v $language)
    (c8l-list->bytevector			v $language)
    (c8b-list->bytevector			v $language)
    (c8n-list->bytevector			v $language)
    (bytevector=?				v r bv)
    (bytevector!=?				v $language)
    (bytevector-u8<?				v $language)
    (bytevector-u8>?				v $language)
    (bytevector-u8<=?				v $language)
    (bytevector-u8>=?				v $language)
    (bytevector-u8-min				v $language)
    (bytevector-u8-max				v $language)
    (bytevector-s8<?				v $language)
    (bytevector-s8>?				v $language)
    (bytevector-s8<=?				v $language)
    (bytevector-s8>=?				v $language)
    (bytevector-s8-min				v $language)
    (bytevector-s8-max				v $language)
    (bytevector?				v r bv)
    (subbytevector-u8				v $language)
    (subbytevector-u8/count			v $language)
    (subbytevector-s8				v $language)
    (subbytevector-s8/count			v $language)
    (bytevector-append				v $language)
    (bytevector-concatenate			v $language)
    (bytevector-reverse-and-concatenate		v $language)
    (endianness					v r bv)
    (native-endianness				v r bv)
    (sint-list->bytevector			v r bv)
    (string->utf8-length			v $language)
    (string->utf8				v r bv)
    (string->utf16-length			v $language)
    (string->utf16				v r bv)
    (string->utf16le				v $language)
    (string->utf16be				v $language)
    (string->utf16n				v $language)
    (string->utf32-length			v $language)
    (string->utf32				v r bv)
    (u8-list->bytevector			v r bv)
    (s8-list->bytevector			v $language)
    (u16l-list->bytevector			v $language)
    (u16b-list->bytevector			v $language)
    (u16n-list->bytevector			v $language)
    (s16l-list->bytevector			v $language)
    (s16b-list->bytevector			v $language)
    (s16n-list->bytevector			v $language)
    (u32l-list->bytevector			v $language)
    (u32b-list->bytevector			v $language)
    (u32n-list->bytevector			v $language)
    (s32l-list->bytevector			v $language)
    (s32b-list->bytevector			v $language)
    (s32n-list->bytevector			v $language)
    (u64l-list->bytevector			v $language)
    (u64b-list->bytevector			v $language)
    (u64n-list->bytevector			v $language)
    (s64l-list->bytevector			v $language)
    (s64b-list->bytevector			v $language)
    (s64n-list->bytevector			v $language)
    (uint-list->bytevector			v r bv)
    (utf8->string				v r bv)
    (utf8->string-length			v $language)
    (utf16->string				v r bv)
    (utf16->string-length			v $language)
    (utf16le->string				v $language)
    (utf16n->string				v $language)
    (utf16be->string				v $language)
    (utf32->string				v r bv)
    (utf32->string-length			v $language)
    (print-condition				v $language)
    (condition?					v r co)
    (simple-condition?				v $language)
    (list-of-conditions?			v $language)
    (list-of-simple-conditions?			v $language)
    (compound-condition?			v $language)
    (condition-and-rtd?				v $language)
    (&assertion					v r co)
    (assertion-violation?			v r co)
    (&condition					v r co)
    (condition					v r co)
    (condition-accessor				v r co)
    (condition-irritants			v r co)
    (condition-message				v r co)
    (condition-predicate			v r co)
    (condition-who				v r co)
    (define-condition-type			v r co)
    (&error					v r co)
    (error?					v r co)
    (&implementation-restriction		v r co)
    (implementation-restriction-violation?	v r co)
    (&irritants					v r co)
    (irritants-condition?			v r co)
    (&lexical					v r co)
    (lexical-violation?				v r co)
    (make-assertion-violation			v r co)
    (make-error					v r co)
    (make-implementation-restriction-violation	v r co)
    (make-irritants-condition			v r co)
    (make-lexical-violation			v r co)
    (make-message-condition			v r co)
    (make-non-continuable-violation		v r co)
    (make-serious-condition			v r co)
    (make-syntax-violation			v r co)
    (make-undefined-violation			v r co)
    (make-violation				v r co)
    (make-warning				v r co)
    (make-who-condition				v r co)
    (&message					v r co)
    (message-condition?				v r co)
    (&non-continuable				v r co)
    (non-continuable-violation?			v r co)
    (&serious					v r co)
    (serious-condition?				v r co)
    (simple-conditions				v r co)
    (&syntax					v r co)
    (syntax-violation-form			v r co)
    (syntax-violation-subform			v r co)
    (syntax-violation?				v r co)
    (&undefined					v r co)
    (undefined-violation?			v r co)
    (&violation					v r co)
    (violation?					v r co)
    (&warning					v r co)
    (warning?					v r co)
    (&who					v r co)
    (who-condition?				v r co)
    (case-lambda				v r ct)
    (do						v r ct se ne)
    (do*					v $language)
    (dolist					v $language)
    (dotimes					v $language)
    (unless					v r ct)
    (when					v r ct)
    (define-enumeration				v r en)
    (enum-set->list				v r en)
    (enum-set-complement			v r en)
    (enum-set-constructor			v r en)
    (enum-set-difference			v r en)
    (enum-set-indexer				v r en)
    (enum-set-intersection			v r en)
    (enum-set-member?				v r en)
    (enum-set-projection			v r en)
    (enum-set-subset?				v r en)
    (enum-set-union				v r en)
    (enum-set-universe				v r en)
    (enum-set=?					v r en)
    (make-enumeration				v r en)
    (enum-set?					v $language)
    (environment				v ev)
    (eval					v ev se)
    (raise					v r ex)
    (raise-continuable				v r ex)
    (raise-non-continuable-standard-condition	v $language)
    (with-exception-handler			v r ex)
    (guard					v r ex)
    (binary-port?				v r ip)
    (buffer-mode				v r ip)
    (buffer-mode?				v r ip)
    (bytevector->string				v r ip)
    (call-with-bytevector-output-port		v r ip)
    (call-with-port				v r ip)
    (call-with-string-output-port		v r ip)
    (assoc					v r ls se)
    (assp					v r ls)
    (assq					v r ls se)
    (assv					v r ls se)
    (cons*					v r ls)
    (filter					v r ls)
    (find					v r ls)
    (fold-left					v r ls)
    (fold-right					v r ls)
    (for-all					v r ls)
    (exists					v r ls)
    (member					v r ls se)
    (memp					v r ls)
    (memq					v r ls se)
    (memv					v r ls se)
    (partition					v r ls)
    (remq					v r ls)
    (remp					v r ls)
    (remv					v r ls)
    (remove					v r ls)
    (make-queue-procs				v $language)
    (set-car!					v mp se)
    (set-cdr!					v mp se)
    (string-set!				v ms se)
    (string-fill!				v ms se)
    (command-line				v r pr)
    (exit					v r pr)
    (exit-hooks					v $language)
    (delay					v r5 se ne)
    (exact->inexact				v r5 se)
    (force					v r5 se)
    (inexact->exact				v r5 se)
    (modulo					v r5 se)
    (remainder					v r5 se)
    (null-environment				v r5 se)
    (promise?					v $language)
    (quotient					v r5 se)
    (scheme-report-environment			v r5 se)
    (interaction-environment			v $language)
    (new-interaction-environment		v $language)
    (close-port					v r ip)
    (eol-style					v r ip)
    (error-handling-mode			v r ip)
    (file-options				v r ip)
    (compiler-options				v $language)
    (expander-options				v $language)
    (flush-output-port				v r ip)
    (get-bytevector-all				v r ip)
    (get-bytevector-n				v r ip)
    (get-bytevector-n!				v r ip)
    (get-bytevector-some			v r ip)
    (get-char					v r ip)
    (get-datum					v r ip)
    (get-line					v r ip)
    (read-line					v $language)
    (get-string-all				v r ip)
    (get-string-n				v r ip)
    (get-string-n!				v r ip)
    (get-string-some				v $language)
    (get-u8					v r ip)
    (&i/o					v r ip is fi)
    (&i/o-decoding				v r ip)
    (i/o-decoding-error?			v r ip)
    (&i/o-encoding				v r ip)
    (i/o-encoding-error-char			v r ip)
    (i/o-encoding-error?			v r ip)
    (i/o-error-filename				v r ip is fi)
    (i/o-error-port				v r ip is fi)
    (i/o-error-position				v r ip is fi)
    (i/o-error?					v r ip is fi)
    (&i/o-file-already-exists			v r ip is fi)
    (i/o-file-already-exists-error?		v r ip is fi)
    (&i/o-file-does-not-exist			v r ip is fi)
    (i/o-file-does-not-exist-error?		v r ip is fi)
    (&i/o-file-is-read-only			v r ip is fi)
    (i/o-file-is-read-only-error?		v r ip is fi)
    (&i/o-file-protection			v r ip is fi)
    (i/o-file-protection-error?			v r ip is fi)
    (&i/o-filename				v r ip is fi)
    (i/o-filename-error?			v r ip is fi)
    (&i/o-invalid-position			v r ip is fi)
    (i/o-invalid-position-error?		v r ip is fi)
    (&i/o-port					v r ip is fi)
    (i/o-port-error?				v r ip is fi)
    (&i/o-read					v r ip is fi)
    (i/o-read-error?				v r ip is fi)
    (&i/o-write					v r ip is fi)
    (i/o-write-error?				v r ip is fi)
    (&i/o-eagain				v $language)
    (&i/o-eagain-rtd)
    (&i/o-eagain-rcd)
    (i/o-eagain-error?				v $language)
    (&errno					v $language)
    (&errno-rtd)
    (&errno-rcd)
    (errno-condition?				v $language)
    (&h_errno					v $language)
    (&h_errno-rtd)
    (&h_errno-rcd)
    (h_errno-condition?				v $language)
;;;
    (&failed-expression-condition		v $language)
    (&failed-expression-condition-rtd)
    (&failed-expression-condition-rcd)
    (make-failed-expression-condition		v $language)
    (failed-expression-condition?		v $language)
    (condition-failed-expression		v $language)
;;;
    (&procedure-precondition-violation		v $language)
    (&procedure-precondition-violation-rtd)
    (&procedure-precondition-violation-rcd)
    (procedure-precondition-violation?		v $language)
    (make-procedure-precondition-violation	v $language)
;;;
    (&procedure-postcondition-violation		v $language)
    (&procedure-postcondition-violation-rtd)
    (&procedure-postcondition-violation-rcd)
    (make-procedure-postcondition-violation	v $language)
    (procedure-postcondition-violation?		v $language)
;;;
    (&procedure-argument-violation				v $language)
    (&procedure-argument-violation-rtd)
    (&procedure-argument-violation-rcd)
    (procedure-argument-violation?				v $language)
    (make-procedure-argument-violation				v $language)
    (procedure-argument-violation				v $language)
;;;
    (&procedure-signature-argument-violation				v $language)
    (&procedure-signature-argument-violation-rtd)
    (&procedure-signature-argument-violation-rcd)
    (procedure-signature-argument-violation?				v $language)
    (make-procedure-signature-argument-violation			v $language)
    (procedure-signature-argument-violation.one-based-argument-index	v $language)
    (procedure-signature-argument-violation.failed-expression		v $language)
    (procedure-signature-argument-violation.offending-value		v $language)
    (procedure-signature-argument-violation				v $language)
;;;
    (&procedure-signature-return-value-violation				v $language)
    (&procedure-signature-return-value-violation-rtd)
    (&procedure-signature-return-value-violation-rcd)
    (make-procedure-signature-return-value-violation				v $language)
    (procedure-signature-return-value-violation?				v $language)
    (procedure-signature-return-value-violation.one-based-return-value-index	v $language)
    (procedure-signature-return-value-violation.failed-expression		v $language)
    (procedure-signature-return-value-violation.offending-value			v $language)
    (procedure-signature-return-value-violation					v $language)
;;;
    (&procedure-arguments-consistency-violation		v $language)
    (&procedure-arguments-consistency-violation-rtd)
    (&procedure-arguments-consistency-violation-rcd)
    (make-procedure-arguments-consistency-violation	v $language)
    (procedure-arguments-consistency-violation?		v $language)
    (procedure-arguments-consistency-violation		v $language)
    (procedure-arguments-consistency-violation/failed-expression	v $language)
;;;
    (&expression-return-value-violation					v $language)
    (&expression-return-value-violation-rtd)
    (&expression-return-value-violation-rcd)
    (expression-return-value-violation?					v $language)
    (make-expression-return-value-violation				v $language)
    (expression-return-value-violation					v $language)
;;;
    (&non-reinstatable				v $language)
    (&non-reinstatable-rtd)
    (&non-reinstatable-rcd)
    (make-non-reinstatable-violation		v $language)
    (non-reinstatable-violation?		v $language)
    (non-reinstatable-violation			v $language)
;;;
    (lookahead-char				v r ip)
    (lookahead-u8				v r ip)
    (lookahead-two-u8				v $language)
    (make-bytevector				v r bv)
    (make-custom-binary-input-port		v r ip)
    (make-custom-binary-output-port		v r ip)
    (make-custom-textual-input-port		v r ip)
    (make-custom-textual-output-port		v r ip)
    (make-custom-binary-input/output-port	v r ip)
    (make-custom-textual-input/output-port	v r ip)
    (make-binary-file-descriptor-input-port	v $language)
    (make-binary-file-descriptor-input-port*	v $language)
    (make-binary-file-descriptor-output-port	v $language)
    (make-binary-file-descriptor-output-port*	v $language)
    (make-binary-file-descriptor-input/output-port	v $language)
    (make-binary-file-descriptor-input/output-port*	v $language)
    (make-binary-socket-input-port		v $language)
    (make-binary-socket-input-port*		v $language)
    (make-binary-socket-output-port		v $language)
    (make-binary-socket-output-port*		v $language)
    (make-binary-socket-input/output-port	v $language)
    (make-binary-socket-input/output-port*	v $language)
    (make-textual-file-descriptor-input-port	v $language)
    (make-textual-file-descriptor-input-port*	v $language)
    (make-textual-file-descriptor-output-port	v $language)
    (make-textual-file-descriptor-output-port*	v $language)
    (make-textual-file-descriptor-input/output-port	v $language)
    (make-textual-file-descriptor-input/output-port*	v $language)
    (make-textual-socket-input-port		v $language)
    (make-textual-socket-input-port*		v $language)
    (make-textual-socket-output-port		v $language)
    (make-textual-socket-output-port*		v $language)
    (make-textual-socket-input/output-port	v $language)
    (make-textual-socket-input/output-port*	v $language)
    (make-i/o-decoding-error			v r ip)
    (make-i/o-encoding-error			v r ip)
    (make-i/o-error				v r ip is fi)
    (make-i/o-file-already-exists-error		v r ip is fi)
    (make-i/o-file-does-not-exist-error		v r ip is fi)
    (make-i/o-file-is-read-only-error		v r ip is fi)
    (make-i/o-file-protection-error		v r ip is fi)
    (make-i/o-filename-error			v r ip is fi)
    (make-i/o-invalid-position-error		v r ip is fi)
    (make-i/o-port-error			v r ip is fi)
    (make-i/o-read-error			v r ip is fi)
    (make-i/o-write-error			v r ip is fi)
    (make-i/o-eagain				v $language)
    (make-errno-condition			v $language)
    (condition-errno				v $language)
    (make-h_errno-condition			v $language)
    (condition-h_errno				v $language)
    (latin-1-codec				v r ip)
    (make-transcoder				v r ip)
    (native-eol-style				v r ip)
    (native-transcoder				v r ip)
    (transcoder?				v $language)
    (open-bytevector-input-port			v r ip)
    (open-bytevector-output-port		v r ip)
    (open-file-input-port			v r ip)
    (open-file-input/output-port		v r ip)
    (open-file-output-port			v r ip)
    (open-string-input-port			v r ip)
    (open-string-output-port			v r ip)
    (bytevector-port-buffer-size		v $language)
    (string-port-buffer-size			v $language)
    (input-file-buffer-size			v $language)
    (output-file-buffer-size			v $language)
    (input/output-file-buffer-size		v $language)
    (input/output-socket-buffer-size		v $language)
    (output-port-buffer-mode			v r ip)
    (set-port-buffer-mode!			v $language)
    (port-eof?					v r ip)
    (port-has-port-position?			v r ip)
    (port-has-set-port-position!?		v r ip)
    (port-position				v r ip)
    (get-char-and-track-textual-position	v $language)
    (port-textual-position			v $language)
    (port-transcoder				v r ip)
    (port?					v r ip)
    (put-bytevector				v r ip)
    (put-char					v r ip)
    (put-datum					v r ip)
    (put-string					v r ip)
    (put-u8					v r ip)
    (set-port-position!				v r ip)
    (standard-error-port			v r ip)
    (standard-input-port			v r ip)
    (standard-output-port			v r ip)
    (string->bytevector				v r ip)
    (textual-port?				v r ip)
    (transcoded-port				v r ip)
    (transcoder-codec				v r ip)
    (transcoder-eol-style			v r ip)
    (transcoder-error-handling-mode		v r ip)
    (utf-8-codec				v r ip)
    (utf-16-codec				v r ip)
    (utf-16le-codec				v $language)
    (utf-16be-codec				v $language)
    (utf-16n-codec				v $language)
    (utf-bom-codec				v $language)
    (would-block-object				v $language)
    (would-block-object?			v $language)
    (input-port?				v r is ip se)
    (output-port?				v r is ip se)
    (input/output-port?				v)
    (binary-input-port?				v $language)
    (textual-input-port?			v $language)
    (binary-output-port?			v $language)
    (textual-output-port?			v $language)
    (binary-input/output-port?			v $language)
    (textual-input/output-port?			v $language)
    (current-input-port				v r ip is se)
    (current-output-port			v r ip is se)
    (current-error-port				v r ip is)
    (eof-object					v r ip is)
    (eof-object?				v r ip is se)
    (close-input-port				v r is se)
    (close-output-port				v r is se)
    (display					v r is se)
    (newline					v r is se)
    (open-input-file				v r is se)
    (open-output-file				v r is se)
    (peek-char					v r is se)
    (read					v r is se)
    (read-char					v r is se)
    (with-input-from-file			v r is se)
    (with-output-to-file			v r is se)
    (with-output-to-port			v $language)
    (write					v r is se)
    (write-char					v r is se)
    (call-with-input-file			v r is se)
    (call-with-output-file			v r is se)
    (hashtable-clear!				v r ht)
    (hashtable-contains?			v r ht)
    (hashtable-copy				v r ht)
    (hashtable-delete!				v r ht)
    (hashtable-entries				v r ht)
    (hashtable-keys				v r ht)
    (hashtable-mutable?				v r ht)
    (mutable-hashtable?				v $language)
    (hashtable-ref				v r ht)
    (hashtable-set!				v r ht)
    (hashtable-size				v r ht)
    (hashtable-update!				v r ht)
    (hashtable?					v r ht)
    (make-eq-hashtable				v r ht)
    (make-eqv-hashtable				v r ht)
    (hashtable-hash-function			v r ht)
    (make-hashtable				v r ht)
    (hashtable-equivalence-function		v r ht)
    (hashtable-map-keys				v $language)
    (hashtable-map-entries			v $language)
    (hashtable-for-each-key			v $language)
    (hashtable-for-each-entry			v $language)
    (hashtable-for-all-keys			v $language)
    (hashtable-for-all-entries			v $language)
    (hashtable-exists-key			v $language)
    (hashtable-exists-entry			v $language)
    (hashtable-find-key				v $language)
    (hashtable-find-entry			v $language)
    (hashtable-fold-keys			v $language)
    (hashtable-fold-entries			v $language)
    (hashtable->alist				v $language)
    (alist->hashtable!				v $language)
    (equal-hash					v r ht)
    (string-hash				v r ht)
    (string-ci-hash				v r ht)
    (symbol-hash				v r ht)
    (bytevector-hash				v $language)
    (fixnum-hash				v $language)
    (exact-integer-hash				v $language)
    (flonum-hash				v $language)
    (number-hash				v $language)
    (char-hash					v $language)
    (char-ci-hash				v $language)
    (boolean-hash				v $language)
    (void-hash					v $language)
    (eof-object-hash				v $language)
    (would-block-hash				v $language)
    (struct-hash				v $language)
    (record-hash				v $language)
    (object-hash				v $language)
    (list-sort					v r sr)
    (vector-sort				v r sr)
    (vector-sort!				v r sr)
    (file-exists?				v r fi)
    (directory-exists?				v $language)
    (delete-file				v r fi)
    (define-record-type				v r rs)
    (record-type-descriptor			v r rs)
    (record-type-field-set!			v $language)
    (record-type-field-ref			v $language)
    ($record-type-field-set!			v $language)
    ($record-type-field-ref			v $language)
    (fields					v r rs)
    (immutable					v r rs)
    (mutable					v r rs)
    (opaque					v r rs)
    (parent					v r rs)
    (parent-rtd					v r rs)
    (protocol					v r rs)
    (record-constructor-descriptor		v r rs)
    (sealed					v r rs)
    (nongenerative				v r rs)
    (record-field-mutable?			v r ri)
    (record-rtd					v r ri)
    (record-type-field-names			v r ri)
    (record-type-generative?			v r ri)
    (record-type-name				v r ri)
    (record-type-opaque?			v r ri)
    (record-type-parent				v r ri)
    (record-type-sealed?			v r ri)
    (record-type-uid				v r ri)
    (record?					v r ri)
    (record-object?				v $language)
    (make-record-constructor-descriptor		v r rp)
    (make-record-type-descriptor		v r rp)
    (record-constructor				v r rp)
    (record-predicate				v r rp)
    (record-type-descriptor?			v r rp)
    (record-constructor-descriptor?		v $language)
    (record-type-and-record?			v $language)
    (record-destructor-set!			v $language)
    (record-destructor				v $language)
    (record-guardian-logger			v $language)
    (record-guardian-log			v $language)
    (record=?					v $language)
    (record-reset				v $language)
    (record-and-rtd?				v $language)
    (record-accessor				v r rp)
    (record-mutator				v r rp)
    (unsafe-record-accessor			v $language)
    (unsafe-record-mutator			v $language)
    (syntax-violation				v r sc)
    (bound-identifier=?				v r sc)
    (datum->syntax				v r sc)
    (syntax					v r sc)
    (syntax->datum				v r sc)
    (syntax-case				v r sc)
    (unsyntax					v r sc)
    (unsyntax-splicing				v r sc)
    (quasisyntax				v r sc)
    (with-syntax				v r sc)
    (free-identifier=?				v r sc)
    (generate-temporaries			v r sc)
    (identifier?				v r sc)
    (identifier-bound?				v $language)
    (make-variable-transformer			v r sc)
    (variable-transformer?			v $language)
    (variable-transformer-procedure		v $language)
    (make-synonym-transformer			v $language)
    (synonym-transformer?			v $language)
    (synonym-transformer-identifier		v $language)
    (make-expand-time-value			v $language)
    (expand-time-value?				v $language)
    (expand-time-value-object			v $language)
    (retrieve-expand-time-value			v $language)
    (syntactic-binding-putprop			v $language)
    (syntactic-binding-getprop			v $language)
    (syntactic-binding-remprop			v $language)
    (syntactic-binding-property-list		v $language)
    (char-alphabetic?				v r uc se)
    (char-ci<=?					v r uc se)
    (char-ci<?					v r uc se)
    (char-ci=?					v r uc se)
    (char-ci!=?					v $language)
    (char-ci>=?					v r uc se)
    (char-ci>?					v r uc se)
    (char-downcase				v r uc se)
    (char-foldcase				v r uc)
    (char-titlecase				v r uc)
    (char-upcase				v r uc se)
    (char-general-category			v r uc)
    (char-lower-case?				v r uc se)
    (char-numeric?				v r uc se)
    (char-title-case?				v r uc)
    (char-upper-case?				v r uc se)
    (char-whitespace?				v r uc se)
    (string-ci<=?				v r uc se)
    (string-ci<?				v r uc se)
    (string-ci=?				v r uc se)
    (string-ci>=?				v r uc se)
    (string-ci>?				v r uc se)
    (string-downcase				v r uc)
    (string-foldcase				v r uc)
    (string-normalize-nfc			v r uc)
    (string-normalize-nfd			v r uc)
    (string-normalize-nfkc			v r uc)
    (string-normalize-nfkd			v r uc)
    (string-titlecase				v r uc)
    (string-upcase				v r uc)
    (load					v $language)
    (void					v $language)
    (void-object?				v $language)
    (gensym					v $language)
    (symbol-value				v $language)
    (set-symbol-value!				v $language)
    (unbound-object				v $language)
    (unbound-object?				v $language)
    (pretty-print				v $language)
    (pretty-print*				v $language)
    (debug-print				v $language)
    (debug-print-enabled?			v $language)
    (debug-print*				v $language)
    (pretty-format				v $language)
    (pretty-width				v $language)
    (module					v $language)
    (library					v $language)
    ($transcoder->data				$transc)
    ($data->transcoder				$transc)
    (make-file-options				v $language)
    (make-expander-options			v $language)
    (make-compiler-options			v $language)

;;; --------------------------------------------------------------------
;;; string encoding and decoding condition types

    (&string-encoding					v $language)
    (&string-encoding-rtd)
    (&string-encoding-rcd)
    (make-string-encoding-error				v $language)
    (string-encoding-error?				v $language)

    (&string-decoding					v $language)
    (&string-decoding-rtd)
    (&string-decoding-rcd)
    (make-string-decoding-error				v $language)
    (string-decoding-error?				v $language)

    (&utf8-string-encoding				v $language)
    (&utf8-string-encoding-rtd)
    (&utf8-string-encoding-rcd)
    (make-utf8-string-encoding-error			v $language)
    (utf8-string-encoding-error?			v $language)

    (&utf16-string-encoding				v $language)
    (&utf16-string-encoding-rtd)
    (&utf16-string-encoding-rcd)
    (make-utf16-string-encoding-error			v $language)
    (utf16-string-encoding-error?			v $language)

    (&utf32-string-encoding				v $language)
    (&utf32-string-encoding-rtd)
    (&utf32-string-encoding-rcd)
    (make-utf32-string-encoding-error			v $language)
    (utf32-string-encoding-error?			v $language)

    (&utf8-string-decoding				v $language)
    (&utf8-string-decoding-rtd)
    (&utf8-string-decoding-rcd)
    (make-utf8-string-decoding-error			v $language)
    (utf8-string-decoding-error?			v $language)

    (&utf16-string-decoding				v $language)
    (&utf16-string-decoding-rtd)
    (&utf16-string-decoding-rcd)
    (make-utf16-string-decoding-error			v $language)
    (utf16-string-decoding-error?			v $language)

    (&utf32-string-decoding				v $language)
    (&utf32-string-decoding-rtd)
    (&utf32-string-decoding-rcd)
    (make-utf32-string-decoding-error			v $language)
    (utf32-string-decoding-error?			v $language)

;;;

    (&utf8-string-decoding-invalid-octet		v $language)
    (&utf8-string-decoding-invalid-octet-rtd)
    (&utf8-string-decoding-invalid-octet-rcd)
    (make-utf8-string-decoding-invalid-octet		v $language)
    (utf8-string-decoding-invalid-octet?		v $language)
    (utf8-string-decoding-invalid-octet.bytevector	v $language)
    (utf8-string-decoding-invalid-octet.index		v $language)
    (utf8-string-decoding-invalid-octet.octets		v $language)

    (&utf8-string-decoding-invalid-2-tuple		v $language)
    (&utf8-string-decoding-invalid-2-tuple-rtd)
    (&utf8-string-decoding-invalid-2-tuple-rcd)
    (make-utf8-string-decoding-invalid-2-tuple		v $language)
    (utf8-string-decoding-invalid-2-tuple?		v $language)
    (utf8-string-decoding-invalid-2-tuple.bytevector	v $language)
    (utf8-string-decoding-invalid-2-tuple.index		v $language)
    (utf8-string-decoding-invalid-2-tuple.octets	v $language)

    (&utf8-string-decoding-invalid-3-tuple		v $language)
    (&utf8-string-decoding-invalid-3-tuple-rtd)
    (&utf8-string-decoding-invalid-3-tuple-rcd)
    (make-utf8-string-decoding-invalid-3-tuple		v $language)
    (utf8-string-decoding-invalid-3-tuple?		v $language)
    (utf8-string-decoding-invalid-3-tuple.bytevector	v $language)
    (utf8-string-decoding-invalid-3-tuple.index		v $language)
    (utf8-string-decoding-invalid-3-tuple.octets	v $language)

    (&utf8-string-decoding-invalid-4-tuple		v $language)
    (&utf8-string-decoding-invalid-4-tuple-rtd)
    (&utf8-string-decoding-invalid-4-tuple-rcd)
    (make-utf8-string-decoding-invalid-4-tuple		v $language)
    (utf8-string-decoding-invalid-4-tuple?		v $language)
    (utf8-string-decoding-invalid-4-tuple.bytevector	v $language)
    (utf8-string-decoding-invalid-4-tuple.index		v $language)
    (utf8-string-decoding-invalid-4-tuple.octets	v $language)

    (&utf8-string-decoding-incomplete-2-tuple		v $language)
    (&utf8-string-decoding-incomplete-2-tuple-rtd)
    (&utf8-string-decoding-incomplete-2-tuple-rcd)
    (make-utf8-string-decoding-incomplete-2-tuple	v $language)
    (utf8-string-decoding-incomplete-2-tuple?		v $language)
    (utf8-string-decoding-incomplete-2-tuple.bytevector	v $language)
    (utf8-string-decoding-incomplete-2-tuple.index	v $language)
    (utf8-string-decoding-incomplete-2-tuple.octets	v $language)

    (&utf8-string-decoding-incomplete-3-tuple		v $language)
    (&utf8-string-decoding-incomplete-3-tuple-rtd)
    (&utf8-string-decoding-incomplete-3-tuple-rcd)
    (make-utf8-string-decoding-incomplete-3-tuple	v $language)
    (utf8-string-decoding-incomplete-3-tuple?		v $language)
    (utf8-string-decoding-incomplete-3-tuple.bytevector	v $language)
    (utf8-string-decoding-incomplete-3-tuple.index	v $language)
    (utf8-string-decoding-incomplete-3-tuple.octets	v $language)

    (&utf8-string-decoding-incomplete-4-tuple		v $language)
    (&utf8-string-decoding-incomplete-4-tuple-rtd)
    (&utf8-string-decoding-incomplete-4-tuple-rcd)
    (make-utf8-string-decoding-incomplete-4-tuple	v $language)
    (utf8-string-decoding-incomplete-4-tuple?		v $language)
    (utf8-string-decoding-incomplete-4-tuple.bytevector	v $language)
    (utf8-string-decoding-incomplete-4-tuple.index	v $language)
    (utf8-string-decoding-incomplete-4-tuple.octets	v $language)

;;;

    (&utf16-string-decoding-invalid-first-word			v $language)
    (&utf16-string-decoding-invalid-first-word-rtd)
    (&utf16-string-decoding-invalid-first-word-rcd)
    (make-utf16-string-decoding-invalid-first-word		v $language)
    (utf16-string-decoding-invalid-first-word?			v $language)
    (utf16-string-decoding-invalid-first-word.bytevector	v $language)
    (utf16-string-decoding-invalid-first-word.index		v $language)
    (utf16-string-decoding-invalid-first-word.word		v $language)

    (&utf16-string-decoding-invalid-second-word			v $language)
    (&utf16-string-decoding-invalid-second-word-rtd)
    (&utf16-string-decoding-invalid-second-word-rcd)
    (make-utf16-string-decoding-invalid-second-word		v $language)
    (utf16-string-decoding-invalid-second-word?			v $language)
    (utf16-string-decoding-invalid-second-word.bytevector	v $language)
    (utf16-string-decoding-invalid-second-word.index		v $language)
    (utf16-string-decoding-invalid-second-word.first-word	v $language)
    (utf16-string-decoding-invalid-second-word.second-word	v $language)

    (&utf16-string-decoding-missing-second-word			v $language)
    (&utf16-string-decoding-missing-second-word-rtd)
    (&utf16-string-decoding-missing-second-word-rcd)
    (make-utf16-string-decoding-missing-second-word		v $language)
    (utf16-string-decoding-missing-second-word?			v $language)
    (utf16-string-decoding-missing-second-word.bytevector	v $language)
    (utf16-string-decoding-missing-second-word.index		v $language)
    (utf16-string-decoding-missing-second-word.word		v $language)

    (&utf16-string-decoding-standalone-octet			v $language)
    (&utf16-string-decoding-standalone-octet-rtd)
    (&utf16-string-decoding-standalone-octet-rcd)
    (make-utf16-string-decoding-standalone-octet		v $language)
    (utf16-string-decoding-standalone-octet?			v $language)
    (utf16-string-decoding-standalone-octet.bytevector		v $language)
    (utf16-string-decoding-standalone-octet.index		v $language)
    (utf16-string-decoding-standalone-octet.octet		v $language)

;;;

    (&utf32-string-decoding-invalid-word			v $language)
    (&utf32-string-decoding-invalid-word-rtd)
    (&utf32-string-decoding-invalid-word-rcd)
    (make-utf32-string-decoding-invalid-word			v $language)
    (utf32-string-decoding-invalid-word?			v $language)
    (utf32-string-decoding-invalid-word.bytevector		v $language)
    (utf32-string-decoding-invalid-word.index			v $language)
    (utf32-string-decoding-invalid-word.word			v $language)

    (&utf32-string-decoding-orphan-octets			v $language)
    (&utf32-string-decoding-orphan-octets-rtd)
    (&utf32-string-decoding-orphan-octets-rcd)
    (make-utf32-string-decoding-orphan-octets			v $language)
    (utf32-string-decoding-orphan-octets?			v $language)
    (utf32-string-decoding-orphan-octets.bytevector		v $language)
    (utf32-string-decoding-orphan-octets.index			v $language)
    (utf32-string-decoding-orphan-octets.octets			v $language)

;;; --------------------------------------------------------------------
;;; special list functions

    (map1					v $language)
    (for-each1					v $language)
    (for-all1					v $language)
    (exists1					v $language)

;;; --------------------------------------------------------------------
;;;
    (define-auxiliary-syntaxes			v $language)
    (define-integrable				v $language)
    (define-inline				v $language)
    (define-constant				v $language)
    (define-inline-constant			v $language)
    (define-values				v $language)
    (define-constant-values			v $language)
    (define-syntax-rule				v $language)
    (receive					v $language)
    (receive-and-return				v $language)
    (begin0					v $language)
    (xor					v $language)
    (with-implicits				v $language)
    (set-cons!					v $language)
;;;
    (unwind-protect				v $language)
    (with-unwind-protection			v $language)
    (with-unwind-handler			v $language)
    (run-unwind-protection-cleanup-upon-exit?)
    (unwinding-call/cc				v $language)
;;;
    (with-blocked-exceptions			v $language)
    (with-current-dynamic-environment		v $language)
;;;
    (set-predicate-assertion-procedure-argument-validation!	v $language)
    (predicate-assertion-procedure-argument-validation		v $language)
    (set-predicate-assertion-return-value-validation!		v $language)
    (predicate-assertion-return-value-validation		v $language)
    (predicate-procedure-argument-validation	v $language)
    (predicate-return-value-validation		v $language)
;;;
    (unsafe					v $language)
    (set-identifier-unsafe-variant!		v $language)
    (identifier-unsafe-variant			v $language)
;;;
    (eval-for-expand				v $language)
    (begin-for-syntax				v $language)
;;;
    (__who__					v $language)
    (__file__					v $language)
    (__line__					v $language)
    (<>						v $language)
    (brace					v $language)
    (return					v $language)
    (continue					v $language)
    (break					v $language)
    (while					v $language)
    (until					v $language)
    (for					v $language)
    (returnable					v $language)
    (try					v $language)
    (catch					v $language)
    (finally					v $language)
    (infix					v $language)
    (++						v $language)
    (--						v $language)
    (pre-incr!					v $language)
    (pre-decr!					v $language)
    (post-incr!					v $language)
    (post-decr!					v $language)
;;;
    (with-compensations				v $language)
    (with-compensations/on-error		v $language)
    (with-compensation-handler			v $language)
    (compensate					v $language)
    (with					v $language)
    (push-compensation				v $language)
    (run-compensations				v $language)
    (compensations)
    (run-compensations-store)
    (push-compensation-thunk			v $language)
;;;
    (port-id					v $language)
    (port-uid					v $language)
    (port-hash					v $language)
    (port-fd					v $language)
    (port-set-non-blocking-mode!		v $language)
    (port-unset-non-blocking-mode!		v $language)
    (port-in-non-blocking-mode?			v $language)
    (port-putprop				v $language)
    (port-getprop				v $language)
    (port-remprop				v $language)
    (port-property-list				v $language)
    (string->filename-func			v $language)
    (filename->string-func			v $language)
    (string->pathname-func			v $language)
    (pathname->string-func			v $language)
    (port-dump-status				v $language)
    (port-closed?				v $language)
;;; (ikarus system $io)
    ($make-port					$io)
    ($port-tag					$io)
    ($port-id					$io)
    ($port-cookie				$io)
    ($port-transcoder				$io)
    ($port-index				$io)
    ($port-size					$io)
    ($port-buffer				$io)
    ($port-get-position				$io)
    ($port-set-position!			$io)
    ($port-close				$io)
    ($port-read!				$io)
    ($port-write!				$io)
    ($set-port-index!				$io)
    ($set-port-size!				$io)
    ($port-attrs				$io)
    ($set-port-attrs!				$io)
;;;
    (get-annotated-datum			v $language)
    (annotation?				v $language)
    (annotation-expression			v $language)
    (annotation-source				v $language)
    (annotation-stripped			v $language)
    (annotation-textual-position		v $language)
;;;
    (&condition-rtd)
    (&condition-rcd)
    (&message-rtd)
    (&message-rcd)
    (&warning-rtd)
    (&warning-rcd)
    (&serious-rtd)
    (&serious-rcd)
    (&error-rtd)
    (&error-rcd)
    (&violation-rtd)
    (&violation-rcd)
    (&assertion-rtd)
    (&assertion-rcd)
    (&irritants-rtd)
    (&irritants-rcd)
    (&who-rtd)
    (&who-rcd)
    (&non-continuable-rtd)
    (&non-continuable-rcd)
    (&implementation-restriction-rtd)
    (&implementation-restriction-rcd)
    (&lexical-rtd)
    (&lexical-rcd)
    (&syntax-rtd)
    (&syntax-rcd)
    (&undefined-rtd)
    (&undefined-rcd)
    (&i/o-rtd)
    (&i/o-rcd)
    (&i/o-read-rtd)
    (&i/o-read-rcd)
    (&i/o-write-rtd)
    (&i/o-write-rcd)
    (&i/o-invalid-position-rtd)
    (&i/o-invalid-position-rcd)
    (&i/o-filename-rtd)
    (&i/o-filename-rcd)
    (&i/o-file-protection-rtd)
    (&i/o-file-protection-rcd)
    (&i/o-file-is-read-only-rtd)
    (&i/o-file-is-read-only-rcd)
    (&i/o-file-already-exists-rtd)
    (&i/o-file-already-exists-rcd)
    (&i/o-file-does-not-exist-rtd)
    (&i/o-file-does-not-exist-rcd)
    (&i/o-port-rtd)
    (&i/o-port-rcd)
    (&i/o-decoding-rtd)
    (&i/o-decoding-rcd)
    (&i/o-encoding-rtd)
    (&i/o-encoding-rcd)
    (&no-infinities-rtd)
    (&no-infinities-rcd)
    (&no-nans-rtd)
    (&no-nans-rcd)
    (&interrupted-rtd)
    (&interrupted-rcd)
    (&source-position-rtd)
    (&source-position-rcd)

;;; --------------------------------------------------------------------
;;; keywords

    (symbol->keyword				v $language)
    (keyword->symbol				v $language)
    (keyword->string				v $language)
    (keyword?					v $language)
    (keyword=?					v $language)
    (keyword-hash				v $language)

;;; --------------------------------------------------------------------
;;; configuration options

    (vicare-built-with-ffi-enabled		v $language)
    (vicare-built-with-iconv-enabled		v $language)
    (vicare-built-with-posix-enabled		v $language)
    (vicare-built-with-glibc-enabled		v $language)
    (vicare-built-with-linux-enabled		v $language)
    (vicare-built-with-srfi-enabled		v $language)

    (vicare-built-with-arguments-validation-enabled	v $language)
    (vicare-built-with-descriptive-labels-generation	v $language)

;;; --------------------------------------------------------------------
;;; coroutines

    (coroutine					v $language)
    (yield					v $language)
    (finish-coroutines				v $language)
    (current-coroutine-uid			v $language)
    (coroutine-uid?				v $language)
    (suspend-coroutine				v $language)
    (resume-coroutine				v $language)
    (suspended-coroutine?			v $language)
    (reset-coroutines!				v $language)
    (dump-coroutines				v $language)
    (concurrently				v $language)
    (monitor					v $language)
    ;;This is for internal use.
    (do-monitor)

;;; --------------------------------------------------------------------
;;; immutable pairs

    (ipair					v $language)
    (icar					v $language)
    (icdr					v $language)
    (ipair?					v $language)

;;; --------------------------------------------------------------------
;;; POSIX functions

    (strerror					v $language $posix)
    (errno->string				$posix)
    (getenv					v $language $posix)
    (environ					v $language $posix)
    (mkdir					$posix)
    (mkdir/parents				$posix)
    (real-pathname				$posix)
    (file-pathname?				$posix)
    (file-string-pathname?			$posix)
    (file-bytevector-pathname?			$posix)
    (file-absolute-pathname?			$posix)
    (file-relative-pathname?			$posix)
    (file-string-absolute-pathname?		$posix)
    (file-string-relative-pathname?		$posix)
    (file-bytevector-absolute-pathname?		$posix)
    (file-bytevector-relative-pathname?		$posix)
    (file-colon-search-path?			$posix)
    (file-string-colon-search-path?		$posix)
    (file-bytevector-colon-search-path?		$posix)
    (list-of-pathnames?				$posix)
    (list-of-string-pathnames?			$posix)
    (list-of-bytevector-pathnames?		$posix)
    (file-modification-time			$posix)
    (split-pathname-root-and-tail		$posix)
    (search-file-in-environment-path		$posix)
    (search-file-in-list-path			$posix)
    (split-pathname				$posix)
    (split-pathname-bytevector			$posix)
    (split-pathname-string			$posix)
    (split-search-path				$posix)
    (split-search-path-bytevector		$posix)
    (split-search-path-string			$posix)
    (vicare-argv0				v $language $posix)
    (vicare-argv0-string			v $language $posix)

;;; --------------------------------------------------------------------
;;; environment inquiry

    (uname					v $language)
    (utsname?					v $language)
    (utsname-sysname				v $language)
    (utsname-nodename				v $language)
    (utsname-release				v $language)
    (utsname-version				v $language)
    (utsname-machine				v $language)

    (implementation-name			v $language)
    (implementation-version			v $language)
    (cpu-architecture				v $language)
    (machine-name				v $language)
    (os-name					v $language)
    (os-version					v $language)

    (host-info					v $language)

;;; --------------------------------------------------------------------
;;; include files

    (include					v $language)
    (current-include-loader			v $language)
    (default-include-loader			v $language)
    (default-include-file-locator		v $language)
    (default-include-file-loader		v $language)
    (current-include-file-locator		v $language)
    (current-include-file-loader		v $language)

;;; --------------------------------------------------------------------
;;; (ikarus system $foreign)
    (errno					v $language $for)
    (pointer?					v $language $for)
    (maybe-pointer?				v $language $for)
    (false-or-pointer?				v $language $for)
    (list-of-pointers?				v $language $for)
    (null-pointer				v $language $for)
    (pointer->integer				v $language $for)
    (integer->pointer				v $language $for)
    (pointer-clone				v $language $for)
    (pointer-null?				v $language $for)
    (pointer-non-null?				v $language $for)
    (pointer-diff				v $language $for)
    (pointer-add				v $language $for)
    (pointer-and-offset?			v $language $for)
    (pointer=?					v $language $for)
    (pointer!=?					v $language $for)
    (pointer<?					v $language $for)
    (pointer>?					v $language $for)
    (pointer<=?					v $language $for)
    (pointer>=?					v $language $for)
    (set-pointer-null!				v $language $for)
;;;
    (make-memory-block				v $language $for)
    (make-memory-block/guarded			v $language $for)
    (null-memory-block				v $language $for)
    (memory-block?				v $language $for)
    (memory-block?/non-null			v $language $for)
    (memory-block?/not-null			v $language $for)
    (memory-block-pointer			v $language $for)
    (memory-block-size				v $language $for)
    (memory-block-reset				v $language $for)
;;;
    (&out-of-memory-error			v $language $for)
    (&out-of-memory-error-rtd)
    (&out-of-memory-error-rcd)
    (make-out-of-memory-error			v $language $for)
    (out-of-memory-error?			v $language $for)
    (out-of-memory-error.old-pointer		v $language $for)
    (out-of-memory-error.number-of-bytes	v $language $for)
    (out-of-memory-error.clean?			v $language $for)
    (malloc					v $language $for)
    (realloc					v $language $for)
    (calloc					v $language $for)
    (guarded-malloc				v $language $for)
    (guarded-realloc				v $language $for)
    (guarded-calloc				v $language $for)
    (malloc*					v $language $for)
    (realloc*					v $language $for)
    (calloc*					v $language $for)
    (guarded-malloc*				v $language $for)
    (guarded-realloc*				v $language $for)
    (guarded-calloc*				v $language $for)
    (free					v $language $for)
    (memcpy					v $language $for)
    (memcmp					v $language $for)
    (memmove					v $language $for)
    (memset					v $language $for)
    (memory-copy				v $language $for)
    (memory->bytevector				v $language $for)
    (bytevector->memory				v $language $for)
    (bytevector->guarded-memory			v $language $for)
    (bytevector->memory*			v $language $for)
    (bytevector->guarded-memory*		v $language $for)
;;;
    (with-local-storage				v $language $for)
;;;
    (bytevector->cstring			v $language $for)
    (bytevector->guarded-cstring		v $language $for)
    (cstring->bytevector			v $language $for)
    (cstring16->bytevector			v $language $for)
    (cstring16n->string				v $language $for)
    (cstring16le->string			v $language $for)
    (cstring16be->string			v $language $for)
    (string->cstring				v $language $for)
    (string->guarded-cstring			v $language $for)
    (bytevector->cstring*			v $language $for)
    (bytevector->guarded-cstring*		v $language $for)
    (cstring->bytevector*			v $language $for)
    (string->cstring*				v $language $for)
    (string->guarded-cstring*			v $language $for)
    (cstring->string				v $language $for)
    (strlen					v $language $for)
    (strcmp					v $language $for)
    (strncmp					v $language $for)
    (strdup					v $language $for)
    (strndup					v $language $for)
    (guarded-strdup				v $language $for)
    (guarded-strndup				v $language $for)
    (strdup*					v $language $for)
    (strndup*					v $language $for)
    (guarded-strdup*				v $language $for)
    (guarded-strndup*				v $language $for)

    (argv->bytevectors				v $language $for)
    (argv-length				v $language $for)
    (argv->strings				v $language $for)
    (bytevectors->argv				v $language $for)
    (bytevectors->argv*				v $language $for)
    (bytevectors->guarded-argv			v $language $for)
    (bytevectors->guarded-argv*			v $language $for)
    (strings->argv				v $language $for)
    (strings->argv*				v $language $for)
    (strings->guarded-argv			v $language $for)
    (strings->guarded-argv*			v $language $for)

;;;
    (pointer-ref-c-uint8			v $language $for)
    (pointer-ref-c-sint8			v $language $for)
    (pointer-ref-c-uint16			v $language $for)
    (pointer-ref-c-sint16			v $language $for)
    (pointer-ref-c-uint32			v $language $for)
    (pointer-ref-c-sint32			v $language $for)
    (pointer-ref-c-uint64			v $language $for)
    (pointer-ref-c-sint64			v $language $for)
;;;
    (pointer-ref-c-signed-char			v $language $for)
    (pointer-ref-c-signed-short			v $language $for)
    (pointer-ref-c-signed-int			v $language $for)
    (pointer-ref-c-signed-long			v $language $for)
    (pointer-ref-c-signed-long-long		v $language $for)
    (pointer-ref-c-unsigned-char		v $language $for)
    (pointer-ref-c-unsigned-short		v $language $for)
    (pointer-ref-c-unsigned-int			v $language $for)
    (pointer-ref-c-unsigned-long		v $language $for)
    (pointer-ref-c-unsigned-long-long		v $language $for)
;;;
    (pointer-ref-c-float			v $language $for)
    (pointer-ref-c-double			v $language $for)
    (pointer-ref-c-double-complex		v $language $for)
    (pointer-ref-c-pointer			v $language $for)
;;;
    (pointer-ref-c-size_t			v $language $for)
    (pointer-ref-c-ssize_t			v $language $for)
    (pointer-ref-c-off_t			v $language $for)
    (pointer-ref-c-ptrdiff_t			v $language $for)
;;;
    (pointer-set-c-uint8!			v $language $for)
    (pointer-set-c-sint8!			v $language $for)
    (pointer-set-c-uint16!			v $language $for)
    (pointer-set-c-sint16!			v $language $for)
    (pointer-set-c-uint32!			v $language $for)
    (pointer-set-c-sint32!			v $language $for)
    (pointer-set-c-uint64!			v $language $for)
    (pointer-set-c-sint64!			v $language $for)
;;;
    (pointer-set-c-signed-char!			v $language $for)
    (pointer-set-c-signed-short!		v $language $for)
    (pointer-set-c-signed-int!			v $language $for)
    (pointer-set-c-signed-long!			v $language $for)
    (pointer-set-c-signed-long-long!		v $language $for)
    (pointer-set-c-unsigned-char!		v $language $for)
    (pointer-set-c-unsigned-short!		v $language $for)
    (pointer-set-c-unsigned-int!		v $language $for)
    (pointer-set-c-unsigned-long!		v $language $for)
    (pointer-set-c-unsigned-long-long!		v $language $for)
;;;
    (pointer-set-c-float!			v $language $for)
    (pointer-set-c-double!			v $language $for)
    (pointer-set-c-double-complex!		v $language $for)
    (pointer-set-c-pointer!			v $language $for)
;;;
    (pointer-set-c-size_t!			v $language $for)
    (pointer-set-c-ssize_t!			v $language $for)
    (pointer-set-c-off_t!			v $language $for)
    (pointer-set-c-ptrdiff_t!			v $language $for)
;;;
    (array-ref-c-uint8				v $language $for)
    (array-ref-c-sint8				v $language $for)
    (array-ref-c-uint16				v $language $for)
    (array-ref-c-sint16				v $language $for)
    (array-ref-c-uint32				v $language $for)
    (array-ref-c-sint32				v $language $for)
    (array-ref-c-uint64				v $language $for)
    (array-ref-c-sint64				v $language $for)
;;;
    (array-ref-c-signed-char			v $language $for)
    (array-ref-c-unsigned-char			v $language $for)
    (array-ref-c-signed-short			v $language $for)
    (array-ref-c-unsigned-short			v $language $for)
    (array-ref-c-signed-int			v $language $for)
    (array-ref-c-unsigned-int			v $language $for)
    (array-ref-c-signed-long			v $language $for)
    (array-ref-c-unsigned-long			v $language $for)
    (array-ref-c-signed-long-long		v $language $for)
    (array-ref-c-unsigned-long-long		v $language $for)
;;;
    (array-ref-c-float				v $language $for)
    (array-ref-c-double				v $language $for)
    (array-ref-c-double-complex			v $language $for)
    (array-ref-c-pointer			v $language $for)
;;;
    (array-ref-c-size_t				v $language $for)
    (array-ref-c-ssize_t			v $language $for)
    (array-ref-c-off_t				v $language $for)
    (array-ref-c-ptrdiff_t			v $language $for)
;;;
    (array-set-c-uint8!				v $language $for)
    (array-set-c-sint8!				v $language $for)
    (array-set-c-uint16!			v $language $for)
    (array-set-c-sint16!			v $language $for)
    (array-set-c-uint32!			v $language $for)
    (array-set-c-sint32!			v $language $for)
    (array-set-c-uint64!			v $language $for)
    (array-set-c-sint64!			v $language $for)
;;;
    (array-set-c-signed-char!			v $language $for)
    (array-set-c-unsigned-char!			v $language $for)
    (array-set-c-signed-short!			v $language $for)
    (array-set-c-unsigned-short!		v $language $for)
    (array-set-c-signed-int!			v $language $for)
    (array-set-c-unsigned-int!			v $language $for)
    (array-set-c-signed-long!			v $language $for)
    (array-set-c-unsigned-long!			v $language $for)
    (array-set-c-signed-long-long!		v $language $for)
    (array-set-c-unsigned-long-long!		v $language $for)
;;;
    (array-set-c-float!				v $language $for)
    (array-set-c-double!			v $language $for)
    (array-set-c-double-complex!		v $language $for)
    (array-set-c-pointer!			v $language $for)
;;;
    (array-set-c-size_t!			v $language $for)
    (array-set-c-ssize_t!			v $language $for)
    (array-set-c-off_t!				v $language $for)
    (array-set-c-ptrdiff_t!			v $language $for)
;;;
    (dlopen					$for)
    (dlerror					$for)
    (dlclose					$for)
    (dlsym					$for)
;;;
    (make-c-callout-maker			$for)
    (make-c-callout-maker/with-errno		$for)
    (make-c-callback-maker			$for)
    (free-c-callback				$for)

;;; --------------------------------------------------------------------

    (syntax-dispatch)
    (ellipsis-map)
    (debug-call)

    ;;FIXME  To be  removed at  the  next boot  image rotation.   (Marco
    ;;Maggi; Sat Apr 12, 2014)
    (syntax-error)

;;; --------------------------------------------------------------------
;;; syntax utilities

    (identifier->string				v $language)
    (string->identifier				v $language)
    (identifier-prefix				v $language)
    (identifier-suffix				v $language)
    (identifier-append				v $language)
    (identifier-format				v $language)
    (duplicate-identifiers?			v $language)
    (delete-duplicate-identifiers		v $language)
    (identifier-memq				v $language)

    (identifier-record-constructor		v $language)
    (identifier-record-predicate		v $language)
    (identifier-record-field-accessor		v $language)
    (identifier-record-field-mutator		v $language)

    (identifier-struct-constructor		v $language)
    (identifier-struct-predicate		v $language)
    (identifier-struct-field-accessor		v $language)
    (identifier-struct-field-mutator		v $language)

    (syntax-car					v $language)
    (syntax-cdr					v $language)
    (syntax->list				v $language)
    (identifiers->list				v $language)
    (all-identifiers?				v $language)

    (syntax->vector				v $language)
    (parse-logic-predicate-syntax		v $language)
    (syntax-unwrap				v $language)
    (syntax=?					v $language)
    (identifier=symbol?				v $language)
;;; (quoted-syntax-object?			v $language)

    (syntax-clauses-unwrap			v $language)
    (syntax-clauses-filter			v $language)
    (syntax-clauses-remove			v $language)
    (syntax-clauses-partition			v $language)
    (syntax-clauses-collapse			v $language)
    (syntax-clauses-verify-at-least-once	v $language)
    (syntax-clauses-verify-at-most-once		v $language)
    (syntax-clauses-verify-exactly-once		v $language)
    (syntax-clauses-verify-mutually-inclusive	v $language)
    (syntax-clauses-verify-mutually-exclusive	v $language)

    ;; clause specification structs
    (make-syntax-clause-spec			v $language)
    (syntax-clause-spec?			v $language)
    (syntax-clause-spec-keyword			v $language)
    (syntax-clause-spec-min-number-of-occurrences v $language)
    (syntax-clause-spec-max-number-of-occurrences v $language)
    (syntax-clause-spec-min-number-of-arguments	v $language)
    (syntax-clause-spec-max-number-of-arguments	v $language)
    (syntax-clause-spec-mutually-inclusive	v $language)
    (syntax-clause-spec-mutually-exclusive	v $language)
    (syntax-clause-spec-custom-data		v $language)
    (syntax-clauses-single-spec			v $language)
    (syntax-clauses-fold-specs			v $language)
    (syntax-clauses-validate-specs		v $language)

;;; --------------------------------------------------------------------
;;; library names

    (library-name?					$libraries)
    (library-version-numbers?				$libraries)
    (library-version-number?				$libraries)
    (library-name-decompose				$libraries)
    (library-name->identifiers				$libraries)
    (library-name->version				$libraries)
    (library-name-identifiers=?				$libraries)
    (library-name=?					$libraries)
    (library-name<?					$libraries)
    (library-name<=?					$libraries)
    (library-version=?					$libraries)
    (library-version<?					$libraries)
    (library-version<=?					$libraries)

;;; --------------------------------------------------------------------
;;; library references and conformity

    (library-reference?					$libraries)
    (library-version-reference?				$libraries)
    (library-sub-version-reference?			$libraries)
    (library-sub-version?				$libraries)
    (library-reference-decompose			$libraries)
    (library-reference->identifiers			$libraries)
    (library-reference->version-reference		$libraries)
    (library-reference-identifiers=?			$libraries)
    (conforming-sub-version-and-sub-version-reference?	$libraries)
    (conforming-version-and-version-reference?		$libraries)
    (conforming-library-name-and-library-reference?	$libraries)

;;; --------------------------------------------------------------------
;;; library infrastructure

    (current-library-expander				$libraries)
    (expand-library					$libraries)
    (expand-library->sexp				$libraries)

    (library?						$libraries)
    (library-uid					$libraries)
    (library-name					$libraries)
    (library-imp-lib*					$libraries)
    (library-vis-lib*					$libraries)
    (library-inv-lib*					$libraries)
    (library-export-subst				$libraries)
    (library-global-env					$libraries)
    (library-visit-state				$libraries)
    (library-invoke-state				$libraries)
    (library-visit-code					$libraries)
    (library-invoke-code				$libraries)
    (library-guard-code					$libraries)
    (library-guard-lib*					$libraries)
    (library-visible?					$libraries)
    (library-source-file-name				$libraries)
    (library-option*					$libraries)
    (library-loaded-from-source-file?			$libraries)
    (library-loaded-from-binary-file?			$libraries)
    (library-descriptor					$libraries)
    (library-descriptor?				$libraries)
    (library-descriptor-uid				$libraries)
    (library-descriptor-name				$libraries)

    (find-library-by-name				$libraries)
    (find-library-by-reference				$libraries)
    (find-library-by-descriptor				$libraries)
    (find-library-in-collection-by-predicate		$libraries)
    (find-library-in-collection-by-name			$libraries)
    (find-library-in-collection-by-reference		$libraries)
    (find-library-in-collection-by-descriptor		$libraries)

    (interned-libraries					$libraries)
    (unintern-library					$libraries)
    (visit-library					$libraries)
    (invoke-library					$libraries)

    (current-library-loader				$libraries)
    (default-library-loader				$libraries)
    (current-source-library-loader			$libraries)
    (current-binary-library-loader			$libraries)

    (library-source-search-path				$libraries)
    (library-binary-search-path				$libraries)
    (compiled-libraries-build-directory			$libraries)

    (library-extensions					$libraries)
    (library-name->filename-stem			$libraries)
    (library-reference->filename-stem			$libraries)
    (directory+library-stem->library-binary-pathname	$libraries)
    (directory+library-stem->library-source-pathname	$libraries)
    (library-name->library-binary-pathname-in-build-directory			$libraries)
    (library-reference->library-binary-pathname-in-build-directory		$libraries)
    (library-source-pathname->library-stem-pathname				$libraries)
    (library-source-pathname->library-binary-tail-pathname			$libraries)

    (current-library-locator				$libraries)
    (run-time-library-locator				$libraries)
    (compile-time-library-locator			$libraries)
    (source-library-locator				$libraries)

    (current-library-source-search-path-scanner		$libraries)
    (current-library-binary-search-path-scanner		$libraries)
    (default-library-source-search-path-scanner		$libraries)
    (default-library-binary-search-path-scanner		$libraries)

    (library-dynamic-load-and-intern			$libraries)
    (library-dynamic-retrieve				$libraries)

;;; --------------------------------------------------------------------
;;; programs

    (program-source-pathname->program-binary-pathname	$programs)
    (expand-top-level-program				$programs)
    (expand-top-level-program->sexp			$programs)

;;; --------------------------------------------------------------------
;;; expander stuff

    ;;This goes in "(psyntax system $all)" and it is used in this makefile.
    (current-library-collection)

    (initialise-expander				$expander)
    (generate-descriptive-gensyms?			$expander)
    (generate-descriptive-marks?			$expander)

    (syntax-object?					$expander)
    (stx?						$expander)
    (stx-expr						$expander)
    (stx-mark*						$expander)
    (stx-rib*						$expander)
    (stx-annotated-expr*				$expander)

    (expand-form-to-core-language			$expander)
    (current-inferior-lexenv				$expander)

    (syntactic-identifier->label			$expander)
    (label->syntactic-binding-descriptor		$expander)
    (label->syntactic-binding-descriptor/no-indirection	$expander)

    (system-label-gensym				$expander)
    (system-label					$expander)
    (system-id-gensym					$expander)
    (system-id						$expander)

    ;;These are only for internal use by the psyntax.
    (make-syntactic-binding-descriptor/struct-type-name)
    (make-syntactic-binding-descriptor/record-type-name)

;;; --------------------------------------------------------------------
;;; compiler stuff

    (initialise-compiler				$compiler)
    (strict-r6rs					$compiler)
    (current-letrec-pass				$compiler)
    (check-for-illegal-letrec				$compiler)
    (optimize-level					$compiler)
    (make-compile-time-error				$compiler)
    (compile-time-error?				$compiler)
    (make-compile-time-arity-error			$compiler)
    (compile-time-arity-error?				$compiler)
    (make-compile-time-core-type-error			$compiler)
    (compile-time-core-type-error?			$compiler)
    (make-compile-time-operand-core-type-error		$compiler)
    (compile-time-operand-core-type-error?		$compiler)
    (make-compile-time-retval-core-type-error		$compiler)
    (compile-time-retval-core-type-error?		$compiler)
    (source-optimizer-passes-count			$compiler)
    (perform-core-type-inference?			$compiler)
    (perform-unsafe-primrefs-introduction?		$compiler)
    (cp0-size-limit					$compiler)
    (cp0-effort-limit					$compiler)
    (strip-source-info					$compiler)
    (generate-debug-calls				$compiler)
    (enabled-function-application-integration?		$compiler)
    (generate-descriptive-labels?			$compiler)

    (system-value-gensym				$compiler)
    (system-value					$compiler)

    (assembler-output					$compiler)
    (optimizer-output					$compiler)

    (compile-core-expr->code				$compiler)
    (pass-recordize					$compiler)
    (pass-optimize-direct-calls				$compiler)
    (pass-optimize-letrec				$compiler)
    (pass-source-optimize				$compiler)
    (pass-rewrite-references-and-assignments		$compiler)
    (pass-core-type-inference				$compiler)
    (pass-introduce-unsafe-primrefs			$compiler)
    (pass-introduce-vars				$compiler)
    (pass-sanitize-bindings				$compiler)
    (pass-optimize-for-direct-jumps			$compiler)
    (pass-insert-global-assignments			$compiler)
    (pass-introduce-closure-makers			$compiler)
    (pass-optimize-combinator-calls/lift-clambdas	$compiler)
    (pass-introduce-primitive-operation-calls		$compiler)
    (pass-rewrite-freevar-references			$compiler)
    (pass-insert-engine-checks				$compiler)
    (pass-insert-stack-overflow-check			$compiler)
    (pass-code-generation				$compiler)
    (assemble-sources					$compiler)

    (pass-specify-representation			$compiler)
    (pass-impose-calling-convention/evaluation-order	$compiler)
    (pass-assign-frame-sizes				$compiler)
    (pass-color-by-chaitin				$compiler)
    (pass-flatten-codes					$compiler)

    (unparse-recordized-code				$compiler)
    (unparse-recordized-code/pretty			$compiler)
    (unparse-recordized-code/sexp			$compiler)

;;; --------------------------------------------------------------------
;;; run-time configuration

    (scheme-heap-nursery-size				$runtime)
    (scheme-stack-size					$runtime)

;;; --------------------------------------------------------------------

    ($compnum->cflonum				$numerics)

    ($neg-number				$numerics)
    ($neg-fixnum				$numerics)
    ($neg-bignum				$numerics)
    ($neg-flonum				$numerics)
    ($neg-ratnum				$numerics)
    ($neg-compnum				$numerics)
    ($neg-cflonum				$numerics)

    ($inv-number				$numerics)
    ($inv-fixnum				$numerics)
    ($inv-bignum				$numerics)
    ($inv-flonum				$numerics)
    ($inv-ratnum				$numerics)
    ($inv-compnum				$numerics)
    ($inv-cflonum				$numerics)

    ($add1-integer				$numerics)
    ($add1-fixnum				$numerics)
    ($add1-bignum				$numerics)

    ($sub1-integer				$numerics)
    ($sub1-fixnum				$numerics)
    ($sub1-bignum				$numerics)

    ($add-number-number				$numerics)
    ($add-fixnum-number				$numerics)
    ($add-bignum-number				$numerics)
    ($add-flonum-number				$numerics)
    ($add-ratnum-number				$numerics)
    ($add-compnum-number			$numerics)
    ($add-cflonum-number			$numerics)
    ($add-number-fixnum				$numerics)
    ($add-number-bignum				$numerics)
    ($add-number-flonum				$numerics)
    ($add-number-ratnum				$numerics)
    ($add-number-compnum			$numerics)
    ($add-number-cflonum			$numerics)
    ($add-fixnum-fixnum				$numerics)
    ($add-fixnum-bignum				$numerics)
    ($add-fixnum-flonum				$numerics)
    ($add-fixnum-ratnum				$numerics)
    ($add-fixnum-compnum			$numerics)
    ($add-fixnum-cflonum			$numerics)
    ($add-bignum-fixnum				$numerics)
    ($add-bignum-bignum				$numerics)
    ($add-bignum-flonum				$numerics)
    ($add-bignum-ratnum				$numerics)
    ($add-bignum-compnum			$numerics)
    ($add-bignum-cflonum			$numerics)
    ($add-flonum-fixnum				$numerics)
    ($add-flonum-bignum				$numerics)
    ($add-flonum-flonum				$numerics)
    ($add-flonum-ratnum				$numerics)
    ($add-flonum-compnum			$numerics)
    ($add-flonum-cflonum			$numerics)
    ($add-ratnum-fixnum				$numerics)
    ($add-ratnum-bignum				$numerics)
    ($add-ratnum-flonum				$numerics)
    ($add-ratnum-ratnum				$numerics)
    ($add-ratnum-compnum			$numerics)
    ($add-ratnum-cflonum			$numerics)
    ($add-compnum-fixnum			$numerics)
    ($add-compnum-bignum			$numerics)
    ($add-compnum-ratnum			$numerics)
    ($add-compnum-compnum			$numerics)
    ($add-compnum-flonum			$numerics)
    ($add-compnum-cflonum			$numerics)
    ($add-cflonum-fixnum			$numerics)
    ($add-cflonum-bignum			$numerics)
    ($add-cflonum-ratnum			$numerics)
    ($add-cflonum-flonum			$numerics)
    ($add-cflonum-compnum			$numerics)
    ($add-cflonum-cflonum			$numerics)

    ($sub-number-number				$numerics)
    ($sub-fixnum-number				$numerics)
    ($sub-bignum-number				$numerics)
    ($sub-flonum-number				$numerics)
    ($sub-ratnum-number				$numerics)
    ($sub-compnum-number			$numerics)
    ($sub-cflonum-number			$numerics)
    ($sub-number-fixnum				$numerics)
    ($sub-number-bignum				$numerics)
    ($sub-number-flonum				$numerics)
    ($sub-number-ratnum				$numerics)
    ($sub-number-compnum			$numerics)
    ($sub-number-cflonum			$numerics)
    ($sub-fixnum-fixnum				$numerics)
    ($sub-fixnum-bignum				$numerics)
    ($sub-fixnum-flonum				$numerics)
    ($sub-fixnum-ratnum				$numerics)
    ($sub-fixnum-compnum			$numerics)
    ($sub-fixnum-cflonum			$numerics)
    ($sub-bignum-fixnum				$numerics)
    ($sub-bignum-bignum				$numerics)
    ($sub-bignum-flonum				$numerics)
    ($sub-bignum-ratnum				$numerics)
    ($sub-bignum-compnum			$numerics)
    ($sub-bignum-cflonum			$numerics)
    ($sub-flonum-fixnum				$numerics)
    ($sub-flonum-bignum				$numerics)
    ($sub-flonum-ratnum				$numerics)
    ($sub-flonum-flonum				$numerics)
    ($sub-flonum-compnum			$numerics)
    ($sub-flonum-cflonum			$numerics)
    ($sub-ratnum-fixnum				$numerics)
    ($sub-ratnum-bignum				$numerics)
    ($sub-ratnum-flonum				$numerics)
    ($sub-ratnum-ratnum				$numerics)
    ($sub-ratnum-compnum			$numerics)
    ($sub-ratnum-cflonum			$numerics)
    ($sub-compnum-fixnum			$numerics)
    ($sub-compnum-bignum			$numerics)
    ($sub-compnum-ratnum			$numerics)
    ($sub-compnum-compnum			$numerics)
    ($sub-compnum-flonum			$numerics)
    ($sub-compnum-cflonum			$numerics)
    ($sub-cflonum-fixnum			$numerics)
    ($sub-cflonum-bignum			$numerics)
    ($sub-cflonum-ratnum			$numerics)
    ($sub-cflonum-flonum			$numerics)
    ($sub-cflonum-compnum			$numerics)
    ($sub-cflonum-cflonum			$numerics)

    ($mul-number-number				$numerics)
    ($mul-fixnum-number				$numerics)
    ($mul-bignum-number				$numerics)
    ($mul-flonum-number				$numerics)
    ($mul-ratnum-number				$numerics)
    ($mul-compnum-number			$numerics)
    ($mul-cflonum-number			$numerics)
    ($mul-number-fixnum				$numerics)
    ($mul-number-bignum				$numerics)
    ($mul-number-flonum				$numerics)
    ($mul-number-ratnum				$numerics)
    ($mul-number-compnum			$numerics)
    ($mul-number-cflonum			$numerics)
    ($mul-fixnum-fixnum				$numerics)
    ($mul-fixnum-bignum				$numerics)
    ($mul-fixnum-flonum				$numerics)
    ($mul-fixnum-ratnum				$numerics)
    ($mul-fixnum-compnum			$numerics)
    ($mul-fixnum-cflonum			$numerics)
    ($mul-bignum-fixnum				$numerics)
    ($mul-bignum-bignum				$numerics)
    ($mul-bignum-flonum				$numerics)
    ($mul-bignum-ratnum				$numerics)
    ($mul-bignum-compnum			$numerics)
    ($mul-bignum-cflonum			$numerics)
    ($mul-flonum-flonum				$numerics)
    ($mul-flonum-cflonum			$numerics)
    ($mul-flonum-fixnum				$numerics)
    ($mul-flonum-bignum				$numerics)
    ($mul-flonum-ratnum				$numerics)
    ($mul-flonum-compnum			$numerics)
    ($mul-ratnum-fixnum				$numerics)
    ($mul-ratnum-bignum				$numerics)
    ($mul-ratnum-flonum				$numerics)
    ($mul-ratnum-ratnum				$numerics)
    ($mul-ratnum-compnum			$numerics)
    ($mul-ratnum-cflonum			$numerics)
    ($mul-compnum-fixnum			$numerics)
    ($mul-compnum-bignum			$numerics)
    ($mul-compnum-ratnum			$numerics)
    ($mul-compnum-flonum			$numerics)
    ($mul-compnum-compnum			$numerics)
    ($mul-compnum-cflonum			$numerics)
    ($mul-cflonum-fixnum			$numerics)
    ($mul-cflonum-bignum			$numerics)
    ($mul-cflonum-ratnum			$numerics)
    ($mul-cflonum-flonum			$numerics)
    ($mul-cflonum-compnum			$numerics)
    ($mul-cflonum-cflonum			$numerics)

    ($div-number-number				$numerics)
    ($div-flonum-number				$numerics)
    ($div-fixnum-number				$numerics)
    ($div-bignum-number				$numerics)
    ($div-ratnum-number				$numerics)
    ($div-compnum-number			$numerics)
    ($div-cflonum-number			$numerics)
    ($div-number-flonum				$numerics)
    ($div-number-fixnum				$numerics)
    ($div-number-bignum				$numerics)
    ($div-number-ratnum				$numerics)
    ($div-number-compnum			$numerics)
    ($div-number-cflonum			$numerics)
    ($div-fixnum-flonum				$numerics)
    ($div-fixnum-fixnum				$numerics)
    ($div-fixnum-bignum				$numerics)
    ($div-fixnum-ratnum				$numerics)
    ($div-fixnum-compnum			$numerics)
    ($div-fixnum-cflonum			$numerics)
    ($div-bignum-fixnum				$numerics)
    ($div-bignum-bignum				$numerics)
    ($div-bignum-flonum				$numerics)
    ($div-bignum-ratnum				$numerics)
    ($div-bignum-compnum			$numerics)
    ($div-bignum-cflonum			$numerics)
    ($div-ratnum-fixnum				$numerics)
    ($div-ratnum-bignum				$numerics)
    ($div-ratnum-ratnum				$numerics)
    ($div-ratnum-flonum				$numerics)
    ($div-ratnum-compnum			$numerics)
    ($div-ratnum-cflonum			$numerics)
    ($div-flonum-flonum				$numerics)
    ($div-flonum-cflonum			$numerics)
    ($div-flonum-fixnum				$numerics)
    ($div-flonum-bignum				$numerics)
    ($div-flonum-ratnum				$numerics)
    ($div-flonum-compnum			$numerics)
    ($div-compnum-fixnum			$numerics)
    ($div-compnum-bignum			$numerics)
    ($div-compnum-ratnum			$numerics)
    ($div-compnum-flonum			$numerics)
    ($div-compnum-compnum			$numerics)
    ($div-compnum-cflonum			$numerics)
    ($div-cflonum-fixnum			$numerics)
    ($div-cflonum-bignum			$numerics)
    ($div-cflonum-ratnum			$numerics)
    ($div-cflonum-flonum			$numerics)
    ($div-cflonum-compnum			$numerics)
    ($div-cflonum-cflonum			$numerics)

    ($square-fixnum				$numerics)
    ($square-bignum				$numerics)
    ($square-ratnum				$numerics)
    ($square-compnum				$numerics)
    ($square-cflonum				$numerics)

    ($cube-fixnum				$numerics)
    ($cube-bignum				$numerics)
    ($cube-ratnum				$numerics)
    ($cube-compnum				$numerics)
    ($cube-cflonum				$numerics)

    ($gcd-number				$numerics)
    ($gcd-number-number				$numerics)
    ($gcd-fixnum-number				$numerics)
    ($gcd-bignum-number				$numerics)
    ($gcd-flonum-number				$numerics)
    ($gcd-number-fixnum				$numerics)
    ($gcd-number-bignum				$numerics)
    ($gcd-number-flonum				$numerics)
    ($gcd-fixnum-fixnum				$numerics)
    ($gcd-fixnum-bignum				$numerics)
    ($gcd-fixnum-flonum				$numerics)
    ($gcd-bignum-fixnum				$numerics)
    ($gcd-bignum-bignum				$numerics)
    ($gcd-bignum-flonum				$numerics)
    ($gcd-flonum-fixnum				$numerics)
    ($gcd-flonum-bignum				$numerics)
    ($gcd-flonum-flonum				$numerics)

    ($lcm-number				$numerics)
    ($lcm-number-number				$numerics)
    ($lcm-fixnum-number				$numerics)
    ($lcm-bignum-number				$numerics)
    ($lcm-flonum-number				$numerics)
    ($lcm-number-fixnum				$numerics)
    ($lcm-number-bignum				$numerics)
    ($lcm-number-flonum				$numerics)
    ($lcm-fixnum-fixnum				$numerics)
    ($lcm-fixnum-bignum				$numerics)
    ($lcm-fixnum-flonum				$numerics)
    ($lcm-bignum-fixnum				$numerics)
    ($lcm-bignum-bignum				$numerics)
    ($lcm-bignum-flonum				$numerics)
    ($lcm-flonum-fixnum				$numerics)
    ($lcm-flonum-bignum				$numerics)
    ($lcm-flonum-flonum				$numerics)

    ($quotient+remainder-fixnum-number		$numerics)
    ($quotient+remainder-number-fixnum		$numerics)
    ($quotient+remainder-bignum-number		$numerics)
    ($quotient+remainder-number-bignum		$numerics)
    ($quotient+remainder-flonum-number		$numerics)
    ($quotient+remainder-number-flonum		$numerics)
    ($quotient+remainder-fixnum-fixnum		$numerics)
    ($quotient+remainder-bignum-fixnum		$numerics)
    ($quotient+remainder-fixnum-bignum		$numerics)
    ($quotient+remainder-bignum-bignum		$numerics)
    ($quotient+remainder-fixnum-flonum		$numerics)
    ($quotient+remainder-bignum-flonum		$numerics)
    ($quotient+remainder-flonum-fixnum		$numerics)
    ($quotient+remainder-flonum-bignum		$numerics)
    ($quotient+remainder-flonum-flonum		$numerics)

    ($quotient-fixnum-number			$numerics)
    ($quotient-number-fixnum			$numerics)
    ($quotient-bignum-number			$numerics)
    ($quotient-number-bignum			$numerics)
    ($quotient-flonum-number			$numerics)
    ($quotient-number-flonum			$numerics)
    ($quotient-fixnum-fixnum			$numerics)
    ($quotient-fixnum-bignum			$numerics)
    ($quotient-fixnum-flonum			$numerics)
    ($quotient-bignum-fixnum			$numerics)
    ($quotient-bignum-bignum			$numerics)
    ($quotient-bignum-flonum			$numerics)
    ($quotient-flonum-fixnum			$numerics)
    ($quotient-flonum-bignum			$numerics)
    ($quotient-flonum-flonum			$numerics)

    ($remainder-fixnum-number			$numerics)
    ($remainder-number-fixnum			$numerics)
    ($remainder-bignum-number			$numerics)
    ($remainder-number-bignum			$numerics)
    ($remainder-flonum-number			$numerics)
    ($remainder-number-flonum			$numerics)
    ($remainder-fixnum-fixnum			$numerics)
    ($remainder-fixnum-bignum			$numerics)
    ($remainder-fixnum-flonum			$numerics)
    ($remainder-bignum-fixnum			$numerics)
    ($remainder-bignum-bignum			$numerics)
    ($remainder-bignum-flonum			$numerics)
    ($remainder-flonum-fixnum			$numerics)
    ($remainder-flonum-bignum			$numerics)
    ($remainder-flonum-flonum			$numerics)

    ($modulo-fixnum-number			$numerics)
    ($modulo-bignum-number			$numerics)
    ($modulo-flonum-number			$numerics)
    ($modulo-number-fixnum			$numerics)
    ($modulo-number-bignum			$numerics)
    ($modulo-number-flonum			$numerics)
    ($modulo-fixnum-fixnum			$numerics)
    ($modulo-fixnum-bignum			$numerics)
    ($modulo-fixnum-flonum			$numerics)
    ($modulo-bignum-fixnum			$numerics)
    ($modulo-bignum-bignum			$numerics)
    ($modulo-bignum-flonum			$numerics)
    ($modulo-flonum-fixnum			$numerics)
    ($modulo-flonum-bignum			$numerics)
    ($modulo-flonum-flonum			$numerics)

    ($max-fixnum-number				$numerics)
    ($max-bignum-number				$numerics)
    ($max-flonum-number				$numerics)
    ($max-ratnum-number				$numerics)
    ($max-number-fixnum				$numerics)
    ($max-number-bignum				$numerics)
    ($max-number-flonum				$numerics)
    ($max-number-ratnum				$numerics)
    ($max-fixnum-fixnum				$numerics)
    ($max-fixnum-bignum				$numerics)
    ($max-fixnum-flonum				$numerics)
    ($max-fixnum-ratnum				$numerics)
    ($max-bignum-fixnum				$numerics)
    ($max-bignum-bignum				$numerics)
    ($max-bignum-flonum				$numerics)
    ($max-bignum-ratnum				$numerics)
    ($max-flonum-flonum				$numerics)
    ($max-flonum-fixnum				$numerics)
    ($max-flonum-bignum				$numerics)
    ($max-flonum-ratnum				$numerics)
    ($max-ratnum-fixnum				$numerics)
    ($max-ratnum-bignum				$numerics)
    ($max-ratnum-ratnum				$numerics)
    ($max-ratnum-flonum				$numerics)

    ($min-fixnum-number				$numerics)
    ($min-bignum-number				$numerics)
    ($min-flonum-number				$numerics)
    ($min-ratnum-number				$numerics)
    ($min-number-fixnum				$numerics)
    ($min-number-bignum				$numerics)
    ($min-number-flonum				$numerics)
    ($min-number-ratnum				$numerics)
    ($min-fixnum-fixnum				$numerics)
    ($min-fixnum-bignum				$numerics)
    ($min-fixnum-flonum				$numerics)
    ($min-fixnum-ratnum				$numerics)
    ($min-bignum-fixnum				$numerics)
    ($min-bignum-bignum				$numerics)
    ($min-bignum-flonum				$numerics)
    ($min-bignum-ratnum				$numerics)
    ($min-flonum-flonum				$numerics)
    ($min-flonum-fixnum				$numerics)
    ($min-flonum-bignum				$numerics)
    ($min-flonum-ratnum				$numerics)
    ($min-ratnum-fixnum				$numerics)
    ($min-ratnum-bignum				$numerics)
    ($min-ratnum-ratnum				$numerics)
    ($min-ratnum-flonum				$numerics)

    ($abs-fixnum				$numerics)
    ($abs-bignum				$numerics)
    ($abs-flonum				$numerics)
    ($abs-ratnum				$numerics)

    ($sign-fixnum				$numerics)
    ($sign-bignum				$numerics)
    ($sign-flonum				$numerics)
    ($sign-ratnum				$numerics)

    ($numerator-fixnum				$numerics)
    ($numerator-bignum				$numerics)
    ($numerator-flonum				$numerics)
    ($numerator-ratnum				$numerics)

    ($denominator-fixnum			$numerics)
    ($denominator-bignum			$numerics)
    ($denominator-flonum			$numerics)
    ($denominator-ratnum			$numerics)

    ($exact-fixnum				$numerics)
    ($exact-bignum				$numerics)
    ($exact-flonum				$numerics)
    ($exact-ratnum				$numerics)
    ($exact-compnum				$numerics)
    ($exact-cflonum				$numerics)

    ($inexact-fixnum				$numerics)
    ($inexact-bignum				$numerics)
    ($inexact-flonum				$numerics)
    ($inexact-ratnum				$numerics)
    ($inexact-compnum				$numerics)
    ($inexact-cflonum				$numerics)

    ($expt-number-fixnum			$numerics)

    ($expt-number-zero-fixnum			$numerics)
    ($expt-fixnum-zero-fixnum			$numerics)
    ($expt-flonum-zero-fixnum			$numerics)
    ($expt-compnum-zero-fixnum			$numerics)
    ($expt-cflonum-zero-fixnum			$numerics)

    ($expt-number-negative-fixnum		$numerics)
    ($expt-fixnum-negative-fixnum		$numerics)
    ($expt-bignum-negative-fixnum		$numerics)
    ($expt-ratnum-negative-fixnum		$numerics)
    ($expt-flonum-negative-fixnum		$numerics)
    ($expt-compnum-negative-fixnum		$numerics)
    ($expt-cflonum-negative-fixnum		$numerics)

    ($expt-number-positive-fixnum		$numerics)
    ($expt-fixnum-positive-fixnum		$numerics)
    ($expt-bignum-positive-fixnum		$numerics)
    ($expt-flonum-positive-fixnum		$numerics)
    ($expt-ratnum-positive-fixnum		$numerics)
    ($expt-compnum-positive-fixnum		$numerics)
    ($expt-cflonum-positive-fixnum		$numerics)

    ($expt-fixnum-fixnum			$numerics)
    ($expt-bignum-fixnum			$numerics)
    ($expt-ratnum-fixnum			$numerics)
    ($expt-flonum-fixnum			$numerics)
    ($expt-compnum-fixnum			$numerics)
    ($expt-cflonum-fixnum			$numerics)

    ($expt-number-bignum			$numerics)
    ($expt-fixnum-bignum			$numerics)
    ($expt-bignum-bignum			$numerics)
    ($expt-ratnum-bignum			$numerics)
    ($expt-flonum-bignum			$numerics)
    ($expt-compnum-bignum			$numerics)
    ($expt-cflonum-bignum			$numerics)

    ($expt-number-flonum			$numerics)
    ($expt-number-ratnum			$numerics)
    ($expt-number-compnum			$numerics)
    ($expt-number-cflonum			$numerics)

    ($expt-fixnum-flonum			$numerics)
    ($expt-bignum-flonum			$numerics)
    ($expt-ratnum-flonum			$numerics)
    ($expt-flonum-flonum			$numerics)
    ($expt-compnum-flonum			$numerics)
    ($expt-cflonum-flonum			$numerics)

    ($expt-fixnum-ratnum			$numerics)
    ($expt-bignum-ratnum			$numerics)
    ($expt-ratnum-ratnum			$numerics)
    ($expt-flonum-ratnum			$numerics)
    ($expt-compnum-ratnum			$numerics)
    ($expt-cflonum-ratnum			$numerics)

    ($expt-fixnum-cflonum			$numerics)
    ($expt-bignum-cflonum			$numerics)
    ($expt-ratnum-cflonum			$numerics)
    ($expt-flonum-cflonum			$numerics)
    ($expt-compnum-cflonum			$numerics)
    ($expt-cflonum-cflonum			$numerics)

    ($expt-fixnum-compnum			$numerics)
    ($expt-bignum-compnum			$numerics)
    ($expt-ratnum-compnum			$numerics)
    ($expt-flonum-compnum			$numerics)
    ($expt-compnum-compnum			$numerics)
    ($expt-cflonum-compnum			$numerics)
;;;
    ($sqrt-fixnum				$numerics)
    ($sqrt-flonum				$numerics)
    ($sqrt-bignum				$numerics)
    ($sqrt-ratnum				$numerics)
    ($sqrt-compnum				$numerics)
    ($sqrt-cflonum				$numerics)

    ($exact-integer-sqrt-fixnum			$numerics)
    ($exact-integer-sqrt-bignum			$numerics)

    ($cbrt-fixnum				$numerics)
    ($cbrt-flonum				$numerics)
    ($cbrt-bignum				$numerics)
    ($cbrt-ratnum				$numerics)
    ($cbrt-compnum				$numerics)
    ($cbrt-cflonum				$numerics)

    ($log-fixnum				$numerics)
    ($log-flonum				$numerics)
    ($log-bignum				$numerics)
    ($log-ratnum				$numerics)
    ($log-compnum				$numerics)
    ($log-cflonum				$numerics)

    ($exp-fixnum				$numerics)
    ($exp-bignum				$numerics)
    ($exp-ratnum				$numerics)
    ($exp-flonum				$numerics)
    ($exp-compnum				$numerics)
    ($exp-cflonum				$numerics)

    ($sin-fixnum				$numerics)
    ($sin-bignum				$numerics)
    ($sin-ratnum				$numerics)
    ($sin-flonum				$numerics)
    ($sin-cflonum				$numerics)
    ($sin-compnum				$numerics)

    ($cos-fixnum				$numerics)
    ($cos-bignum				$numerics)
    ($cos-ratnum				$numerics)
    ($cos-flonum				$numerics)
    ($cos-cflonum				$numerics)
    ($cos-compnum				$numerics)

    ($tan-fixnum				$numerics)
    ($tan-bignum				$numerics)
    ($tan-ratnum				$numerics)
    ($tan-flonum				$numerics)
    ($tan-compnum				$numerics)
    ($tan-cflonum				$numerics)

    ($asin-fixnum				$numerics)
    ($asin-bignum				$numerics)
    ($asin-ratnum				$numerics)
    ($asin-flonum				$numerics)
    ($asin-cflonum				$numerics)
    ($asin-compnum				$numerics)

    ($acos-fixnum				$numerics)
    ($acos-bignum				$numerics)
    ($acos-ratnum				$numerics)
    ($acos-flonum				$numerics)
    ($acos-cflonum				$numerics)
    ($acos-compnum				$numerics)

    ($atan2-real-real				$numerics)

    ($atan-fixnum				$numerics)
    ($atan-ratnum				$numerics)
    ($atan-bignum				$numerics)
    ($atan-flonum				$numerics)
    ($atan-cflonum				$numerics)
    ($atan-compnum				$numerics)

    ($sinh-fixnum				$numerics)
    ($sinh-bignum				$numerics)
    ($sinh-ratnum				$numerics)
    ($sinh-flonum				$numerics)
    ($sinh-compnum				$numerics)
    ($sinh-cflonum				$numerics)

    ($cosh-fixnum				$numerics)
    ($cosh-bignum				$numerics)
    ($cosh-ratnum				$numerics)
    ($cosh-flonum				$numerics)
    ($cosh-compnum				$numerics)
    ($cosh-cflonum				$numerics)

    ($tanh-fixnum				$numerics)
    ($tanh-bignum				$numerics)
    ($tanh-ratnum				$numerics)
    ($tanh-flonum				$numerics)
    ($tanh-compnum				$numerics)
    ($tanh-cflonum				$numerics)

    ($asinh-fixnum				$numerics)
    ($asinh-bignum				$numerics)
    ($asinh-ratnum				$numerics)
    ($asinh-flonum				$numerics)
    ($asinh-cflonum				$numerics)
    ($asinh-compnum				$numerics)

    ($acosh-fixnum				$numerics)
    ($acosh-bignum				$numerics)
    ($acosh-ratnum				$numerics)
    ($acosh-flonum				$numerics)
    ($acosh-cflonum				$numerics)
    ($acosh-compnum				$numerics)

    ($atanh-fixnum				$numerics)
    ($atanh-bignum				$numerics)
    ($atanh-ratnum				$numerics)
    ($atanh-flonum				$numerics)
    ($atanh-cflonum				$numerics)
    ($atanh-compnum				$numerics)

    ($bitwise-not-fixnum			$numerics)
    ($bitwise-not-bignum			$numerics)

    ($bitwise-and-fixnum-number			$numerics)
    ($bitwise-and-bignum-number			$numerics)
    ($bitwise-and-fixnum-fixnum			$numerics)
    ($bitwise-and-fixnum-bignum			$numerics)
    ($bitwise-and-bignum-fixnum			$numerics)
    ($bitwise-and-bignum-bignum			$numerics)

    ($bitwise-ior-fixnum-number			$numerics)
    ($bitwise-ior-bignum-number			$numerics)
    ($bitwise-ior-fixnum-fixnum			$numerics)
    ($bitwise-ior-fixnum-bignum			$numerics)
    ($bitwise-ior-bignum-fixnum			$numerics)
    ($bitwise-ior-bignum-bignum			$numerics)

    ($bitwise-xor-fixnum-number			$numerics)
    ($bitwise-xor-bignum-number			$numerics)
    ($bitwise-xor-fixnum-fixnum			$numerics)
    ($bitwise-xor-fixnum-bignum			$numerics)
    ($bitwise-xor-bignum-fixnum			$numerics)
    ($bitwise-xor-bignum-bignum			$numerics)

    ($floor-fixnum				$numerics)
    ($floor-bignum				$numerics)
    ($floor-ratnum				$numerics)
    ($floor-flonum				$numerics)

    ($ceiling-fixnum				$numerics)
    ($ceiling-bignum				$numerics)
    ($ceiling-ratnum				$numerics)
    ($ceiling-flonum				$numerics)

    ($truncate-fixnum				$numerics)
    ($truncate-bignum				$numerics)
    ($truncate-ratnum				$numerics)
    ($truncate-flonum				$numerics)

    ($round-fixnum				$numerics)
    ($round-bignum				$numerics)
    ($round-ratnum				$numerics)
    ($round-flonum				$numerics)

;;; --------------------------------------------------------------------
;;; (vicare system $hashtables)

    ($string-hash				$hashtables)
    ($string-ci-hash				$hashtables)
    ($symbol-hash				$hashtables)
    ($bytevector-hash				$hashtables)

;;; --------------------------------------------------------------------
;;; expander tags

    (tag-predicate				$expander-tags)
    (tag-procedure-argument-validator		$expander-tags)
    (tag-return-value-validator			$expander-tags)
    (tag-assert					$expander-tags)
    (tag-assert-and-return			$expander-tags)
    (tag-accessor				$expander-tags)
    (tag-mutator				$expander-tags)
    (tag-getter					$expander-tags)
    (tag-setter					$expander-tags)
    (tag-dispatch				$expander-tags)
    (tag-cast					$expander-tags)
    (tag-unsafe-cast)

    (<top>					$expander-tags)
    (<void>					$expander-tags)
    (<boolean>					$expander-tags)
    (<char>					$expander-tags)
    (<symbol>					$expander-tags)
    (<keyword>					$expander-tags)
    (<pointer>					$expander-tags)
    (<transcoder>				$expander-tags)
    (<procedure>				$expander-tags)
    (<predicate>				$expander-tags)

    (<fixnum>					$expander-tags)
    (<flonum>					$expander-tags)
    (<ratnum>					$expander-tags)
    (<bignum>					$expander-tags)
    (<compnum>					$expander-tags)
    (<cflonum>					$expander-tags)
    (<exact-integer>				$expander-tags)
    (<integer-valued>				$expander-tags)
    (<integer>					$expander-tags)
    (<rational-valued>				$expander-tags)
    (<rational>					$expander-tags)
    (<real-valued>				$expander-tags)
    (<real>					$expander-tags)
    (<complex>					$expander-tags)
    (<number>					$expander-tags)

    (<string>					$expander-tags)
    (<vector>					$expander-tags)
    (<pair>					$expander-tags)
    (<list>					$expander-tags)
    (<bytevector>				$expander-tags)
    (<hashtable>				$expander-tags)
    (<record>					$expander-tags)
    (<record-type-descriptor>			$expander-tags)
    (<struct>					$expander-tags)
    (<struct-type-descriptor>			$expander-tags)
    (<condition>				$expander-tags)

    (<port>					$expander-tags)
    (<input-port>				$expander-tags)
    (<output-port>				$expander-tags)
    (<input/output-port>			$expander-tags)
    (<textual-port>				$expander-tags)
    (<binary-port>				$expander-tags)
    (<textual-input-port>			$expander-tags)
    (<textual-output-port>			$expander-tags)
    (<textual-input/output-port>		$expander-tags)
    (<binary-input-port>			$expander-tags)
    (<binary-output-port>			$expander-tags)
    (<binary-input/output-port>			$expander-tags)

;;; --------------------------------------------------------------------

    (print-identifier-info			v $language)

    (tagged-identifier-syntax?			$type-specs)
    (list-of-tagged-bindings?			$type-specs)
    (tagged-lambda-proto-syntax?		$type-specs)
    (tagged-formals-syntax?			$type-specs)
    (standard-formals-syntax?			$type-specs)
    (formals-signature-syntax?			$type-specs)
    (retvals-signature-syntax?			$type-specs)
    (parse-tagged-identifier-syntax		$type-specs)
    (parse-list-of-tagged-bindings		$type-specs)
    (parse-tagged-lambda-proto-syntax		$type-specs)
    (parse-tagged-formals-syntax		$type-specs)

    (make-clambda-compound			$type-specs)
    (clambda-compound?				$type-specs)
    (clambda-compound-common-retvals-signature	$type-specs)
    (clambda-compound-lambda-signatures		$type-specs)

    (make-lambda-signature			$type-specs)
    (lambda-signature?				$type-specs)
    (lambda-signature-formals			$type-specs)
    (lambda-signature-retvals			$type-specs)
    (lambda-signature-formals-tags		$type-specs)
    (lambda-signature-retvals-tags		$type-specs)
    (lambda-signature=?				$type-specs)

    (make-formals-signature			$type-specs)
    (formals-signature?				$type-specs)
    (formals-signature-tags			$type-specs)
    (formals-signature=?			$type-specs)

    (make-retvals-signature			$type-specs)
    (make-retvals-signature-single-value	$type-specs)
    (retvals-signature?				$type-specs)
    (retvals-signature-tags			$type-specs)
    (retvals-signature=?			$type-specs)
    (retvals-signature-common-ancestor		$type-specs)

    (tag-identifier?				$type-specs)
    (all-tag-identifiers?			$type-specs)
    (tag-super-and-sub?				$type-specs)
    (tag-identifier-ancestry			$type-specs)
    (tag-common-ancestor			$type-specs)
    (formals-signature-super-and-sub-syntax?	$type-specs)

    (set-tag-identifier-callable-signature!	$type-specs)
    (tag-identifier-callable-signature		$type-specs)
    (fabricate-procedure-tag-identifier		$type-specs)

    (set-identifier-object-type-spec!		$type-specs)
    (identifier-object-type-spec		$type-specs)
    (set-label-object-type-spec!		$type-specs)
    (label-object-type-spec			$type-specs)
    (make-object-type-spec			$type-specs)
    (object-type-spec?				$type-specs)
    (object-type-spec-uids			$type-specs)
    (object-type-spec-type-id			$type-specs)
    (object-type-spec-parent-spec		$type-specs)
    (object-type-spec-pred-stx			$type-specs)
    (object-type-spec-constructor-maker		$type-specs)
    (object-type-spec-accessor-maker		$type-specs)
    (object-type-spec-mutator-maker		$type-specs)
    (object-type-spec-getter-maker		$type-specs)
    (object-type-spec-setter-maker		$type-specs)
    (object-type-spec-dispatcher		$type-specs)
    (object-type-spec-ancestry			$type-specs)

    (tagged-identifier?				$type-specs)
    (set-identifier-tag!			$type-specs)
    (override-identifier-tag!			$type-specs)
    (identifier-tag				$type-specs)
    (set-label-tag!				$type-specs)
    (override-label-tag!			$type-specs)
    (label-tag					$type-specs)

    (expand-time-type-signature-violation?			$type-specs)
    (expand-time-retvals-signature-violation?			$type-specs)
    (expand-time-retvals-signature-violation-expected-signature	$type-specs)
    (expand-time-retvals-signature-violation-returned-signature	$type-specs)

    (top-tag-id					$type-specs)
    (void-tag-id				$type-specs)
    (procedure-tag-id				$type-specs)
    (list-tag-id				$type-specs)
    (boolean-tag-id				$type-specs)
    (struct-tag-id				$type-specs)
    (record-tag-id				$type-specs)

;;;; built-in object types utilities

    ;;These are exported only by "(psyntax system $all)".
    (procedure-argument-validation-with-predicate)
    (return-value-validation-with-predicate)
    (signature-rest-argument-validation-with-predicate)
    (any->symbol)
    (any->string)

    ))


;;;; bootstrap library collection

(define bootstrap-collection
  ;;A  collection of  LIBRARY structures  accessed  through a  closure.  The  LIBRARY
  ;;structure type is defined in the psyntax modules.
  ;;
  ;;This function works somewhat like a parameter  function; it is a closure with the
  ;;same interface  of the  ones returned  by MAKE-PARAMETER, but  it has  an initial
  ;;value and it checks for duplicates to avoid them.
  ;;
  ;;If the  function is called  with no arguments:  it returns the  whole collection,
  ;;which  is a  list of  LIBRARY structures.   If the  function is  called with  one
  ;;argument:  such argument  must be  a LIBRARY  structure and  it is  added to  the
  ;;collection if not already there.
  ;;
  ;;The initial  value is  a list  of old  boot image's  LIBRARY structures  built by
  ;;adding all the libraries in LIBRARY-LEGEND which are marked as REQUIRED?.  Notice
  ;;that  such structures  are built  by FIND-LIBRARY-BY-NAME,  which means  that the
  ;;libraries marked  as REQUIRED?  must  be already interned  in the old  boot image
  ;;running this program.
  ;;
  ;;To add  a REQUIRED? library  to a boot  image: first we have  to add an  entry to
  ;;LIBRARY-LEGEND marked  as non-REQUIRED?  and  build a temporary boot  image, then
  ;;mark the entry as REQUIRED? and using the temporary boot image build another boot
  ;;image which will have the new library as REQUIRED?.
  ;;
  (let ((list-of-library-records
	 (begin
	   (fprintf (current-error-port) "initialising bootstrap library collection:")
	   (let next-library-entry ((entries LIBRARY-LEGEND))
	     (define entry.required?	cadddr)
	     (define entry.library-name	cadr)
	     (cond ((null? entries)
		    '())
		   ((entry.required? (car entries))
		    (fprintf (current-error-port)
			     " ~a" (entry.library-name (car entries)))
		    (cons (bootstrap.find-library-by-name (entry.library-name (car entries)))
			  (next-library-entry (cdr entries))))
		   (else
		    (next-library-entry (cdr entries))))))))
    (fprintf (current-error-port) "\n")
    (case-lambda
     (()
      list-of-library-records)
     ((x)
      (unless (memq x list-of-library-records)
	(set! list-of-library-records (cons x list-of-library-records)))))))


(module (expand-all)
  ;;For  the  meaning  of  "location  gensym",  "label  gensym"  and  the  format  of
  ;;INVOKE-CODE, EXPORT-SUBST and GLOBAL-ENV see the expander documentation.
  ;;
  (define (expand-all files)
    ;;Expand all the libraries in FILES, which must be a list of strings representing
    ;;file pathnames  under the directory referenced  by BOOT-IMAGE-FILES-SOURCE-DIR.
    ;;Return 3 values:
    ;;
    ;;1. The list of library specifications.
    ;;
    ;;2. A list representing all the invoke codes from all the libraries.
    ;;
    ;;3. The EXPORT-PRIMLOCS: an alist whose keys are the exported primitive's symbol
    ;;   names and whose values are the exported primitive's location gensyms.
    ;;
    ;;Whenever the boot  image is loaded: the libraries' invoke  code is evaluated in
    ;;the same order the files appear in FILES;  the last code to be executed must be
    ;;the one of the library (ikarus main), so the file "ikarus.main.sls" must be the
    ;;last one.  In addition:
    ;;
    ;;* In this  module the procedure MAKE-INIT-CODE creates a  library; such library
    ;;  is inserted as first one.
    ;;
    ;;* In  this module  the procedure BUILD-SYSTEM-LIBRARY  creates a  library; such
    ;;  library is inserted as penultimate one, before (ikarus main).
    ;;
    ;;Every time  we expand a  component library with BOOT-LIBRARY-EXPAND,  we expect
    ;;the following return values:
    ;;
    ;;NAME -
    ;;   A list of symbols representing the library name.
    ;;
    ;;INVOKE-CODE -
    ;;   A  core language  symbolic expression  representing the  body of  a library;
    ;;   usually this symbolic expression is a LIBRARY-LETREC* form.
    ;;
    ;;EXPORT-SUBST -
    ;;   An export  subst selecting the lexical  bindings to be exported  by the boot
    ;;   image between the ones in defined in GLOBAL-ENV.
    ;;
    ;;GLOBAL-ENV -
    ;;    An export  env  representing the  global lexical  bindings  defined by  the
    ;;   library body.
    ;;
    ;;Notice that, from  the results of library expansion, we  discard all the macros
    ;;and all the library descriptors representing the library dependencies.
    ;;
    (receive (name* invoke-code* export-subst global-env)
	(make-init-code)
      (debug-printf "\nSource libraries expansion\n")
      (for-each (lambda (file)
		  (debug-printf "expanding: ~a\n" file)
		  ;;For  each library  in the  file apply  the closure  for its  side
		  ;;effects.
		  (load (string-append BOOT-IMAGE-FILES-SOURCE-DIR "/" file)
			(lambda (library-sexp)
			  (receive (name code subst env)
			      (boot-library-expand library-sexp)
			    ;; (when (equal? name '(ikarus flonum-conversion))
			    ;;   (debug-print 'invoke-code  code)
			    ;;   (debug-print 'export-subst subst)
			    ;;   (debug-print 'global-env   env))
			    (set! name*        (cons name name*))
			    (set! invoke-code* (cons code invoke-code*))
			    (set! export-subst (append subst export-subst))
			    (set! global-env   (append env   global-env))))))
	files)
      (receive (export-subst global-env export-primlocs)
	  (make-system-data (prune-subst export-subst global-env) global-env)
	(receive (primlocs-lib-name primlocs-lib-code)
	    (build-system-library export-subst global-env export-primlocs)
	  (values (reverse (cons* (car name*)        primlocs-lib-name (cdr name*)))
		  (reverse (cons* (car invoke-code*) primlocs-lib-code (cdr invoke-code*)))
		  export-primlocs)))))

  (define (make-init-code)
    ;;Return  4 values  representing  a fake  library (ikarus.init),  as  if we  have
    ;;processed a  file "ikarus.init.sls"  as first  library to  include in  the boot
    ;;image.  The returned values are:
    ;;
    ;;NAME* -
    ;;   A list holding a single item; the item is the library name.
    ;;
    ;;INVOKE-CODE* -
    ;;   A list holding a single item; the  item is a symbolic expression in the core
    ;;   language representing the invoke code of the library (ikarus.init).
    ;;
    ;;EXPORT-SUBST -
    ;;   A subst selecting  the bindings to be exported from  the ones in GLOBAL-ENV.
    ;;   For (ikarus.init) there is only one: $INIT-SYMBOL-VALUE!.
    ;;
    ;;GLOBAL-ENV -
    ;;    Represents  the   global  bindings  defined  by  the   library  body.   For
    ;;   (ikarus.init) there is only one: $INIT-SYMBOL-VALUE!
    ;;
    ;;The procedure $INIT-SYMBOL-VALUE! has the following signature:
    ;;
    ;;   ($init-symbol-value! primloc val)
    ;;
    ;;where: PRIMLOC is  the loc gensym of  a lexical primitive exported  by the boot
    ;;image; VAL  is the  value of  the primitive,  either a  closure object  or some
    ;;datum.   $INIT-SYMBOL-VALUE!  stores  VAL in  the field  "value" of  the symbol
    ;;PRIMLOC; if VAL is a closure object: VAL  is also stored in the field "proc" of
    ;;the symbol  PRIMLOC.  Whenever  the boot  image is  loaded: $INIT-SYMBOL-VALUE!
    ;;must be applied  to all the loc  gensyms of the lexical  primitives exported by
    ;;the boot image.
    ;;
    ;;The first  code to  run when  initialising the boot  image must  initialise the
    ;;fields  "value"  and "proc"  of  the  location gensym  for  $INIT-SYMBOL-VALUE!
    ;;itself.  We fake a library as if we have processed the following form:
    ;;
    ;;   (library (ikarus.init)
    ;;     (export $init-symbol-value!)
    ;;     (import (vicare))
    ;;     (define ($init-symbol-value! primloc val)
    ;; 	     ($set-symbol-value! primloc val)
    ;; 	     (if (procedure? val)
    ;; 	         ($set-symbol-proc! primloc val)
    ;; 	       ($set-symbol-proc! primloc
    ;; 	         (lambda args
    ;; 	           (error 'apply "not a procedure" ($symbol-value primloc)))))))
    ;;
    ;;but  we cannot  do  it this  way because  $INIT-SYMBOL-VALUE!   must be  itself
    ;;initialised, by storing the closure object  in the appropriate loc gensym.  So,
    ;;rather  than generating  a LIBRARY-LETREC*  form,  we generate  an invoke  code
    ;;expression  that directly  implements  the  procedure $INIT-SYMBOL-VALUE!   and
    ;;initialises its loc gensym.
    ;;
    ;;NOTE Whenever binary code  performs a call to a global  closure object, it does
    ;;the following:
    ;;
    ;;*  From the  relocation vector  of the  current code  object: retrieve  the loc
    ;;  gensym of the procedure to call.
    ;;
    ;;* From the loc gensym: extract the value  of the "proc" slot, which is meant to
    ;;  be a closure object.
    ;;
    ;;* Actually call the closure object.
    ;;
    ;;so  the initialisation  code must  check if  a lexical  primitive's value  is a
    ;;closure object, and store it in the "proc" slot.
    ;;
    (define loc   (gensym)) ;this is the loc   gensym of $INIT-SYMBOL-VALUE!
    (define label (gensym)) ;this is the label gensym of $INIT-SYMBOL-VALUE!
    ;;Just to be  safe we use gensyms  for the formal arguments of  procedures in the
    ;;core language.
    (let ((proc.arg	(gensym))
	  (primloc.arg	(gensym))
	  (val.arg	(gensym))
	  (args		(gensym)))
      (values (list '(ikarus.init))
	      (list `((case-lambda
		       ;;This  CASE-LAMBDA  receives  $INIT-SYMBOL-VALUE!   as  ,PROC
		       ;;argument and applies  it to its own loc  gensym.  The return
		       ;;value is unspecified and discarded.
		       ((,proc.arg)
			(,proc.arg ',loc ,proc.arg)))
		      ;;This CASE-LAMBDA implements $INIT-SYMBOL-VALUE!.
		      (case-lambda
		       ((,primloc.arg ,val.arg)
			(begin
			  #;(foreign-call (quote "ikrt_scheme_print") ,primloc.arg)
			  #;(foreign-call (quote "ikrt_scheme_print") ,val.arg)
			  ((primitive $set-symbol-value!) ,primloc.arg ,val.arg)
			  (if ((primitive procedure?) ,val.arg)
			      (begin
				#;(foreign-call (quote "ikrt_print_emergency") '#ve(ascii "is procedure"))
				((primitive $set-symbol-proc!) ,primloc.arg ,val.arg))
			    ((primitive $set-symbol-proc!) ,primloc.arg
			     (case-lambda
			      ;;Raise an  error if  this lexical  primitive is  not a
			      ;;procedure and someone attempts to apply it.
			      (,args
			       ((primitive error) 'apply
				(quote "not a procedure")
				((primitive $symbol-value) ,primloc.arg))))))
			  )))))
	      `(($init-symbol-value! . ,label))
	      `((,label . (global . ,loc))))))

  (define (prune-subst export-subst global-env)
    ;;Remove  from EXPORT-SUBST  all re-exported  identifiers (those  with labels  in
    ;;EXPORT-SUBST but no binding in GLOBAL-ENV).
    ;;
    (cond ((null? export-subst)
	   '())
	  ((not (assq (cdar export-subst) global-env))
	   (prune-subst (cdr export-subst) global-env))
	  (else
	   (cons (car export-subst)
		 (prune-subst (cdr export-subst) global-env)))))

  (define (make-system-data export-subst global-env)
    ;;EXPORT-SUBST has  an entry for  each primitive binding  to export from  all the
    ;;source libraries  in the boot image.   GLOBAL-ENV has an entry  for each global
    ;;binding from all the source libraries in the boot image.
    ;;
    ;;Return 4 values: an EXPORT-SUBST alist with entries:
    ;;
    ;;   (?prim-name  . ?label)
    ;;   (?macro-name . ?label)
    ;;
    ;;an GLOBAL-ENV alist with entries:
    ;;
    ;;   (?label . (core-prim . ?prim-name))
    ;;   (?label . ?macro-binding)
    ;;
    ;;an EXPORT-PRIMLOCS alist with entries:
    ;;
    ;;   (?prim-name . ?loc)
    ;;
    (define-constant __who__ 'make-system-data)
    (define-syntax-rule (macro-identifier? x)
      (and (or (assq x VICARE-SYSTEM-MACROS)
	       (assq x VICARE-SYSTEM-FLUIDS))
	   #t))
    (define-syntax-rule (procedure-identifier? x)
      (not (macro-identifier? x)))
    (let ((export-subst-clt    (make-collection))
	  (global-env-clt      (make-collection))
	  (export-primlocs-clt (make-collection)))
      ;;Build bindings for the macros exported by the boot image.  Here we create the
      ;;binding labels.  The expected format of the entries is:
      ;;
      ;;   (?macro-name ?binding)
      ;;
      ;;and specifically:
      ;;
      ;;   (?built-in-macro-name	(?built-in-macro-name))
      ;;   (?core-macro-name		(core-macro	. ?core-macro-name))
      ;;   (?non-core-macro-name	(macro		. ?non-core-macro-name))
      ;;   (?fluid-macro-name		($fluid		. ?fluid-macro-name))
      ;;   (?condition-type-name	($core-rtd	. (?condition-rtd ?condition-rcd)))
      ;;
      ;;We accumulate  in the subst  and env collections the  associations name/label
      ;;and label/binding
      ;;
      (each-for VICARE-SYSTEM-MACROS
	(lambda (entry)
	  (let* ((name		(car  entry))
		 (binding	(cadr entry))
		 (label		(gensym (string-append "prim-label." (symbol->string name)))))
	    (export-subst-clt (cons name label))
	    (global-env-clt   (cons label binding)))))
      (each-for VICARE-SYSTEM-FLUIDS
	(lambda (entry)
	  (let* ((name		(car  entry))
		 (binding	(cadr entry))
		 (label		(gensym (string-append "prim-label." (symbol->string name)))))
	    (export-subst-clt (cons name label))
	    (global-env-clt   (cons label binding)))))
      (each-for VICARE-SYSTEM-FLUIDS-DEFAULTS
	(lambda (entry)
	  (let* ((label		(car  entry))
		 (binding	(cadr entry)))
	    (global-env-clt   (cons label binding)))))
      ;;For every  exported primitive function  we expect an  entry to be  present in
      ;;GLOBAL-ENV with the format:
      ;;
      ;;   (?label ?type . ?loc)
      ;;
      ;;here we add to the subst collection an entry:
      ;;
      ;;   (?prim-name . ?label)
      ;;
      ;;to the env collection an entry:
      ;;
      ;;   (?label . (core-prim . ?prim-name))
      ;;
      ;;to the primlocs collection an entry:
      ;;
      ;;   (?prim-name . ?loc)
      ;;
      (each-for (map car IDENTIFIER->LIBRARY-MAP)
	(lambda (prim-name)
	  (when (procedure-identifier? prim-name)
	    (cond ((assq prim-name (export-subst-clt))
		   (error __who__ "identifier exported twice?" prim-name))

		  ((assq prim-name export-subst)
		   ;;Primitive defined (exported) within the compiled libraries.
		   => (lambda (name.label)
			(unless (pair? name.label)
			  (error __who__ "invalid exports" name.label prim-name))
			(let ((label (cdr name.label)))
			  (cond ((assq label global-env)
				 => (lambda (label.binding)
				      (let ((binding (cdr label.binding)))
					(case (car binding)
					  ((global)
					   (export-subst-clt    (cons prim-name label))
					   (global-env-clt      (cons label     (cons 'core-prim prim-name)))
					   (export-primlocs-clt (cons prim-name (cdr binding))))
					  (else
					   (error __who__
					     "invalid binding for identifier"
					     label.binding prim-name))))))
				(else
				 (error __who__
				   "binding from the export list not present in the global environment"
				   prim-name label))))))

		  (else
		   ;;Core  primitive with  no  backing definition  from the  expanded
		   ;;libraries; we assume it is defined in other strata of the system
		   ;;
		   #;(fprintf (console-error-port) "undefined primitive ~s\n" prim-name)
		   (let ((label (gensym (string-append "prim-label." (symbol->string prim-name)))))
		     (export-subst-clt (cons prim-name label))
		     (global-env-clt   (cons label     (cons 'core-prim prim-name)))))))))

      (values (export-subst-clt) (global-env-clt) (export-primlocs-clt))))

  (module (build-system-library)

    (define (build-system-library export-subst global-env export-primlocs)
      ;;EXPORT-SUBST is an alist with entries:
      ;;
      ;;   (?prim-name  . ?label)
      ;;   (?macro-name . ?label)
      ;;
      ;;GLOBAL-ENV is an alist with entries:
      ;;
      ;;   (?label . (core-prim . ?prim-name))
      ;;   (?label . ?macro-binding)
      ;;
      ;;EXPORT-PRIMLOCS is an alist with entries:
      ;;
      ;;   (?prim-name . ?loc)
      ;;
      ;;Build a form for the library "(ikarus primitive-locations-init)" which:
      ;;
      ;;* Iterates the symbol names  representing primitive functions exported by the
      ;;  boot image, storing the associated loc gensym in their "value" slot.
      ;;
      ;;*  Initialises  the  compiler  parameter  CURRENT-PRIMITIVE-LOCATIONS  to  an
      ;;  appropriate  function.  This way  the compile  can retrieve the  loc gensym
      ;;  from the primitive function symbol name.
      ;;
      ;;* Interns all the libraries composing the boot image.
      ;;
      ;;Return 2 values: the library name and the library invoke-code.
      ;;
      (define library-sexp
	`(library (ikarus primitive-locations-init)
	   (export) ;;; must be empty
	   (import
	       ;;Notice that the  library (vicare) imported here is the  one from the
	       ;;OLD boot image!!!
	       (except (vicare)
		       system-value-gensym
		       system-label-gensym)
	     (only (psyntax.config)
		   expander-initialisation/initialise-label-gensyms-and-interned-libraries)
	     (only (psyntax.library-manager)
		   make-library
		   just-intern-library)
	     (only (ikarus.compiler)
		   compiler-initialisation/storage-location-gensyms-associations-func
		   system-value-gensym
		   current-primitive-locations)
	     ;;These gensyms are fresh ones generated by the source libraries for the
	     ;;new boot image.
	     (only (psyntax.lexical-environment)
		   SYSTEM-LABEL-GENSYM)
	     (only (ikarus.symbols)
		   $putprop
		   $getprop))
	   (define (initialise-storage-location-gensyms-associations)
	     (define SYSTEM-VALUE-GENSYM
	       (system-value-gensym))
	     ;;Store in the  property list of each primitive  procedure's symbol name
	     ;;its loc gensym.
	     (for-each
		 (lambda (func-name.loc)
		   ($putprop (car func-name.loc) SYSTEM-VALUE-GENSYM (cdr func-name.loc)))
	       ',export-primlocs)
	     ;;Initialise the  internal parameter CURRENT-PRIMITIVE-LOCATIONS  with a
	     ;;function  capable of  retrieving  a primitive  procedure's loc  gensym
	     ;;given its symbol name.
	     (current-primitive-locations (lambda (func-name)
					    ($getprop func-name SYSTEM-VALUE-GENSYM))))
	   (define (initialise-label-gensyms-and-interned-libraries)
	     ;;Store in the  property list of each primitive  procedure's symbol name
	     ;;its label gensym.
	     (for-each
		 (lambda (func-name.lab)
		   ($putprop (car func-name.lab) SYSTEM-LABEL-GENSYM (cdr func-name.lab)))
	       ',export-subst)
	     ;;This evaluates to a spliced list of INTERN-LIBRARY forms.
	     ,@(map (lambda (legend-entry)
		      (build-intern-library-form legend-entry export-subst global-env))
		 LIBRARY-LEGEND))
	   ;;Set up.
	   (compiler-initialisation/storage-location-gensyms-associations-func initialise-storage-location-gensyms-associations)
	   (expander-initialisation/initialise-label-gensyms-and-interned-libraries initialise-label-gensyms-and-interned-libraries)
	   #| end of LIBRARY |# ))

      ;;Logging this  symbolic expression  gives some insight  about what  happens at
      ;;boot image initialisation time.
      #;(debug-print library-sexp)

      ;;Expand the library in CODE; we know that the EXPORT form is empty, so we know
      ;;that the last two values returned by BOOT-LIBRARY-EXPAND are empty.
      ;;
      (receive (name invoke-code empty-subst empty-env)
	  (boot-library-expand library-sexp)
	(values name invoke-code)))

    (define (build-intern-library-form legend-entry export-subst global-env)
      ;;Return a sexp representing a call to the function INTERN-LIBRARY.
      ;;
      ;;Each entry from the LIBRARY-LEGEND has the format:
      ;;
      ;;   (?nickname	?fullname	?visible	?required)
      ;;
      (let* ((nickname		(car	legend-entry))
	     (fullname		(cadr	legend-entry))
	     (visible?		(caddr	legend-entry))
	     (id		(gensym))
	     (version		(cond ((eq? 'rnrs (car fullname))
				       '(6))
				      ((or (equal? fullname '(vicare))
					   (equal? fullname '(vicare language-extensions)))
				       (%vicare-version-numbers))
				      ;;This  adds versions  to all  the
				      ;;vicare libraries.  Is this fine?
				      ((eq? (car fullname) 'vicare)
				       (%vicare-version-numbers))
				      (else
				       '())))
	     (system-all?	(equal? fullname '(psyntax system $all)))
	     (env		(if system-all? global-env '()))
	     (subst		(if system-all?
				    export-subst
				  (get-export-subset nickname export-subst)))
	     (source-file-name	#f)
	     (option*		'()))
	`(just-intern-library
	  (make-library ',id					  ;uid
			(quote ,(append fullname (list version))) ;name
			'()					  ;imp-lib*
			'()					  ;vis-lib*
			'()					  ;inv-lib*
			',subst					  ;export-subst
			',env					  ;global-env
			void					  ;visit-state
			void					  ;invoke-state
			'#f					  ;visit-code
			'#f					  ;invoke-code
			'#f					  ;guard-code
			'()					  ;guard-lib*
			',visible?				  ;visible*
			(quote ,source-file-name)		  ;source-file-name
			(quote ,option*)			  ;option*
			'()					  ;foreign-library*
			))))

    (define (get-export-subset nickname export-subst)
      ;;Given the alist of substitutions EXPORT-SUBST, build and return the subset of
      ;;substitutions  corresponding  to  identifiers  in  the  library  selected  by
      ;;NICKNAME.
      ;;
      (let loop ((ls export-subst))
	(if (null? ls)
	    '()
	  (let ((x (car ls)))
	    (let ((name (car x)))
	      (cond ((assq name IDENTIFIER->LIBRARY-MAP)
		     => (lambda (q)
			  (if (memq nickname (cdr q))
			      (cons x (loop (cdr ls)))
			    (loop (cdr ls)))))
		    (else ;not going to any library?
		     (loop (cdr ls)))))))))

    (define %vicare-version-numbers
      ;;Here we  build a version  list with  fixnums representing: the  major version
      ;;number, the minor version number, the  build year, the build month, the build
      ;;day.
      ;;
      (let ((V (list BOOT-IMAGE-MAJOR-VERSION
		     BOOT-IMAGE-MINOR-VERSION
		     BOOT-IMAGE-YEAR-VERSION
		     BOOT-IMAGE-MONTH-VERSION
		     BOOT-IMAGE-DAY-VERSION)))
	(lambda () V)))

    #| end of module: BUILD-SYSTEM-LIBRARY |# )

  (define (boot-library-expand library-sexp)
    ;;This function  is used to expand  the libraries composing the  boot image.  The
    ;;LIBRARY form in the given symbolic expression is fully expanded and the library
    ;;is interned in the internal collection.
    ;;
    ;;When bootstrapping  the system: the visit-code  is not (and cannot  be) used in
    ;;the "next" system, so we drop it.
    ;;
    ;;The returned values are:
    ;;
    ;;LIBNAME -
    ;;   A R6RS library name.
    ;;
    ;;INVOKE-CODE -
    ;;   A list of symbolic expressions representing the body of the library.
    ;;
    ;;EXPORT-SUBST -
    ;;   A subst selecting the bindings to be exported from the ones in GLOBAL-ENV.
    ;;
    ;;GLOBAL-ENV -
    ;;   Represents the global bindings defined by the library body.
    ;;
    ;;FIXME To be fixed at the next boot image rotation.  (Marco Maggi; Sun May 10, 2015)
    (if-building-rotation-boot-image? "extracting values after library expansion"
	(let ((lib (expand-library library-sexp)))
	  (values (library-name         lib)
		  (library-invoke-code  lib)
		  (library-export-subst lib)
		  (library-global-env   lib)))
      (receive (uid libname
		    imp-libdesc* vis-libdesc* inv-libdesc*
		    invoke-code visit-code
		    export-subst global-env
		    guard-code guard-libdesc*
		    option*)
	  (expand-library library-sexp)
	(values libname invoke-code export-subst global-env))))

  #| end of module: EXPAND-ALL |# )


;;;; do it

;;Setting this variable  causes the compiler libraries to configure  themselves to be
;;part of a boot image.
;;
(foreign-call "ikrt_posix_setenv"
	      #ve(ascii "BUILDING_FOR_INCLUSION_IN_BOOT_IMAGE")
	      #ve(ascii "yes"))

;;Internal  consistency  check:  verify  that  all  the  library  nicknames  used  in
;;IDENTIFIER->LIBRARY-MAP are defined by LIBRARY-LEGEND.
;;
(for-each (lambda (x)
	    (for-each (lambda (x)
			(unless (assq x LIBRARY-LEGEND)
			  (error 'IDENTIFIER->LIBRARY-MAP "not in the libraries list" x)))
	      (cdr x)))
  IDENTIFIER->LIBRARY-MAP)

;;Perform the bootstrap process generating the boot image.
;;
(time-it "the entire bootstrap process"
  (lambda ()
    (receive (name* invoke-code* export-primlocs)
	(time-it "macro expansion"
	  (lambda ()
	    (parameterize ((bootstrap.current-library-collection bootstrap-collection))
	      (expand-all SCHEME-LIBRARY-FILES))))
      ;;Before applying COMPILE-CORE-EXPR-TO-PORT to the invoke code of each library:
      ;;we must register  in the state of  the compiler a closure  capable of mapping
      ;;lexical-primitive symbol-names to their location gensyms.  The loc gensyms of
      ;;core primitives are created by this very "makefile.sps" script.
      ;;
      ;;EXPORT-PRIMLOCS is an  alist whose keys are the primitive's  symbol names and
      ;;whose values are the primitive's location gensyms.
      (compiler.current-primitive-locations
       (lambda (primitive-name.sym)
	 (cond ((assq primitive-name.sym export-primlocs)
		=> cdr)
	       (else
		(error 'bootstrap
		  "no location gensym found for boot image lexical primitive"
		  primitive-name.sym)))))
      (let ((port (open-file-output-port BOOT-FILE-NAME (file-options no-fail))))
	(time-it "code generation and serialization"
	  (lambda ()
	    (debug-printf "\nCompiling and writing to fasl (one code object for each library form): ")
	    (for-each (lambda (name core)
			;; (begin
			;;   (print-gensym #f)
			;;   (when (equal? name '(ikarus chars))
			;;     (pretty-print (syntax->datum core))))
			(debug-printf "compiling: ~s\n" name)
			(compiler.compile-core-expr-to-port core port))
	      name*
	      invoke-code*)))
	(close-output-port port)))))

(fprintf (console-error-port) "Happy Happy Joy Joy\n")

;;; end of file
;; Local Variables:
;; coding: utf-8-unix
;; eval: (put 'time-it					'scheme-indent-function 1)
;; eval: (put 'each-for					'scheme-indent-function 1)
;; eval: (put 'if-building-rotation-boot-image?		'scheme-indent-function 2)
;; End:
