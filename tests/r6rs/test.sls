;;;Copyright (c) 2008 Matthew Flatt
;;;Modified by Marco Maggi <marco.maggi-ipsu@poste.it>
;;;
;;;This library is free software;  you can redistribute it and/or modify
;;;it  under the  terms of  the GNU  Library General  Public  License as
;;;published by  the Free Software  Foundation; either version 2  of the
;;;License, or (at your option) any later version.
;;;
;;;This library is  distributed in the hope that it  will be useful, but
;;;WITHOUT  ANY   WARRANTY;  without   even  the  implied   warranty  of
;;;MERCHANTABILITY  or FITNESS FOR  A PARTICULAR  PURPOSE.  See  the GNU
;;;Library General Public License for more details.
;;;
;;;You should  have received  a copy of  the GNU Library  General Public
;;;License along with  this library; if not, write  to the Free Software
;;;Foundation,  Inc.,  51  Franklin  Street,  Fifth  Floor,  Boston,  MA
;;;02110-1301 USA.


#!r6rs
(library (r6rs test)
  (export test
          test/approx
          test/alts
          test/exn
          test/values
          test/output
          test/unspec
          test/unspec-or-exn
          test/unspec-flonum-or-exn
          test/output/unspec
          run-test
          report-test-results)
  (import (rnrs)
    (prefix (vicare checks) checks.))


(define-record-type err
  (fields err-c))

(define-record-type expected-exception
  (fields))

(define-record-type multiple-results
  (fields values))

(define-record-type approx
  (fields value))

(define-record-type alts
  (fields values))

(define-syntax test
  (syntax-rules ()
    [(_ expr expected)
     (begin
       ;; (checks.check-write 'expr) (newline)
       (run-test 'expr
		 (catch-exns (lambda () expr))
		 expected))]))

(define (catch-exns thunk)
  (guard (c [#t (make-err c)])
    (call-with-values thunk
      (lambda x
	(if (= 1 (length x))
	    (car x)
	  (make-multiple-results x))))))

(define-syntax test/approx
  (syntax-rules ()
    [(_ expr expected)
     (run-test 'expr
	       (make-approx expr)
	       (make-approx expected))]))

(define-syntax test/alts
  (syntax-rules ()
    [(_ expr expected0 expected ...)
     (run-test 'expr
	       expr
	       (make-alts (list expected0 expected ...)))]))

(define (good-enough? x y)
  ;; relative error should be with 0.1%, but greater
  ;; relative error is allowed when the expected value
  ;; is near zero.
  (cond ((not (number? x)) #f)
	((not (number? y)) #f)
	((or (not (real? x))
	     (not (real? y)))
	 (and (good-enough? (real-part x) (real-part	y))
	      (good-enough? (imag-part x) (imag-part	y))))
	((infinite? x)
	 (=	x (* 2.0 y)))
	((infinite? y)
	 (= (* 2.0 x) y))
	((nan? y)
	 (nan? x))
	((> (magnitude y) 1e-6)
	 (< (/ (magnitude (- x y))
	       (magnitude y))
	    1e-3))
	(else
	 (< (magnitude (- x y)) 1e-6))))

(define-syntax test/exn
  (syntax-rules ()
    [(_ expr condition)
     (test (guard (c [((condition-predicate (record-type-descriptor condition)) c)
		      (make-expected-exception)])
	     expr)
	   (make-expected-exception))]))

(define-syntax test/values
  (syntax-rules ()
    [(_ expr val ...)
     (run-test 'expr
	       (catch-exns (lambda () expr))
	       (make-multiple-results (list val ...)))]))

(define-syntax test/output
  (syntax-rules ()
    [(_ expr expected str)
     (run-test 'expr
	       (capture-output
		(lambda ()
		  (run-test 'expr
			    (guard (c [#t (make-err c)])
			      expr)
			    expected)))
	       str)]))

(define-syntax test/unspec
  (syntax-rules ()
    [(_ expr)
     (test (begin expr 'unspec) 'unspec)]))

(define-syntax test/unspec-or-exn
  (syntax-rules ()
    [(_ expr condition)
     (test (guard (c [((condition-predicate (record-type-descriptor condition)) c)
		      'unspec])
	     (begin expr 'unspec))
	   'unspec)]))

(define-syntax test/unspec-flonum-or-exn
  (syntax-rules ()
    [(_ expr condition)
     (test (guard (c [((condition-predicate (record-type-descriptor condition)) c)
		      'unspec-or-flonum])
	     (let ([v expr])
	       (if (flonum? v)
		   'unspec-or-flonum
		 (if (eq? v 'unspec-or-flonum)
		     (list v)
		   v))))
	   'unspec-or-flonum)]))

(define-syntax test/output/unspec
  (syntax-rules ()
    [(_ expr str)
     (test/output (begin expr 'unspec) 'unspec str)]))

(define checked 0)
(define failures '())

(define (capture-output thunk)
  (if (file-exists? "tmp-catch-out")
      (delete-file "tmp-catch-out"))
  (dynamic-wind
      (lambda () 'nothing)
      (lambda ()
	(with-output-to-file "tmp-catch-out"
	  thunk)
	(call-with-input-file "tmp-catch-out"
	  (lambda (p)
	    (get-string-n p 1024))))
      (lambda ()
	(if (file-exists? "tmp-catch-out")
	    (delete-file "tmp-catch-out")))))

(define (same-result? got expected)
  (cond
   [(and (real? expected) (nan? expected))
    (and (real? got) (nan? got))]
   [(expected-exception? expected)
    (expected-exception? got)]
   [(approx? expected)
    (and (approx? got)
	 (good-enough? (approx-value expected)
		       (approx-value got)))]
   [(multiple-results? expected)
    (and (multiple-results? got)
	 (= (length (multiple-results-values expected))
	    (length (multiple-results-values got)))
	 (for-all same-result?
	   (multiple-results-values expected)
	   (multiple-results-values got)))]
   [(alts? expected)
    (exists (lambda (e) (same-result? got e))
      (alts-values expected))]
   [else (equal? got expected)]))

(define (run-test expr got expected)
  (set! checked (+ 1 checked))
  (unless (same-result? got expected)
    (set! failures
	  (cons (list expr got expected)
		failures))))

(define (write-result prefix v)
  (cond
   [(multiple-results? v)
    (for-each (lambda (v)
		(write-result prefix v))
      (multiple-results-values v))]
   [(approx? v)
    (checks.check-display prefix)
    (checks.check-display "approximately ")
    (checks.check-write (approx-value v))]
   [(alts? v)
    (write-result (string-append prefix "   ")
		  (car (alts-values v)))
    (for-each (lambda (v)
		(write-result (string-append prefix "OR ")
			      v))
      (cdr (alts-values v)))]
   [else
    (checks.check-display prefix)
    (checks.check-write v)]))

(define (report-test-results)
  (if (null? failures)
      (begin
	(checks.check-display "; *** checks *** : ")
	(checks.check-display checked)
	(checks.check-display " correct,")
	(checks.check-display " 0 failed.\n\n\n"))
    (begin
      (checks.check-display (length failures))
      (checks.check-display " tests failed:\n\n")
      (for-each (lambda (t)
		  (checks.check-display "Expression:\n ")
		  (checks.check-write (car t))
		  (checks.check-display "\nResult:")
		  (write-result "\n " (cadr t))
		  (checks.check-display "\nExpected:")
		  (write-result "\n " (caddr t))
		  (checks.check-display "\n\n"))
	(reverse failures))
      (checks.check-display "; *** checks *** : ")
      (checks.check-display (- checked (length failures)))
      (checks.check-display " correct, ")
      (checks.check-display (length failures))
      (checks.check-display " failed.\n\n\n")))
  (cond ((null? failures)
	 ;;Success for GNU Automake.
	 (exit 0))
	((not (null? failures))
	 ;;Test failure for GNU Automake.
	 (exit 1))
;;;	((something)
;;;	 ;;Skipped test for GNU Automake.
;;;	 (exit 77))
	(else
	 ;;Hard error for GNU Automake.
	 (exit 99))))


;;;; done

)

;;; end of file
