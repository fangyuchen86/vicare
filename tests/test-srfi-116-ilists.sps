;;;
;;;Part of: Vicare Scheme
;;;Contents: tests for SRFI 116
;;;Date: Fri Jun 12, 2015
;;;
;;;Abstract
;;;
;;;
;;;
;;;Copyright (C) John Cowan 2014.  All Rights Reserved.
;;;Modified by Marco Maggi <marco.maggi-ipsu@poste.it>
;;;
;;;Permission is  hereby granted, free  of charge, to any  person obtaining a  copy of
;;;this software and associated documentation files (the ``Software''), to deal in the
;;;Software without restriction, including without limitation the rights to use, copy,
;;;modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
;;;and to permit  persons to whom the Software  is furnished to do so,  subject to the
;;;following conditions:
;;;
;;;The above  copyright notice  and this  permission notice shall  be included  in all
;;;copies or substantial portions of the Software.
;;;
;;;THE  SOFTWARE IS  PROVIDED ``AS  IS'',  WITHOUT WARRANTY  OF ANY  KIND, EXPRESS  OR
;;;IMPLIED, INCLUDING  BUT NOT LIMITED  TO THE WARRANTIES OF  MERCHANTABILITY, FITNESS
;;;FOR A  PARTICULAR PURPOSE AND  NONINFRINGEMENT.  IN NO  EVENT SHALL THE  AUTHORS OR
;;;COPYRIGHT HOLDERS BE  LIABLE FOR ANY CLAIM, DAMAGES OR  OTHER LIABILITY, WHETHER IN
;;;AN ACTION  OF CONTRACT, TORT  OR OTHERWISE, ARISING FROM,  OUT OF OR  IN CONNECTION
;;;WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#!r6rs
(import (vicare)
  (srfi :114)
  (srfi :116)
  (srfi :116 comparators)
  (vicare checks))

(check-set-mode! 'report-failed)
(check-display "*** testing Vicare libraries: SRFI 116, immutable lists\n")


;;;; helpers

(define-syntax test-group
  (syntax-rules ()
    ((_ ?name . ?body)
     (begin . ?body))
    ))

(define (%compar a b)
  (cond ((and (ilist? a)
	      (ilist? b))
	 (ilist= %compar a b))
	((and (ipair? a)
	      (ipair? b))
	 (and (%compar (icar a) (icar b))
	      (%compar (icdr a) (icdr b))))
	((and (list? a)
	      (list? b))
	 (for-all %compar a b))
	((and (pair? a)
	      (pair? b))
	 (and (%compar (car a) (car b))
	      (%compar (cdr a) (cdr b))))
	((and (vector? a)
	      (vector? b))
	 (vector-for-all %compar a b))
	(else
	 (equal? a b))))

(define current-test-comparator
  (make-parameter %compar))

(define-syntax test
  (syntax-rules ()
    ((_ ?expected ?form)
     (check ?form (=> (current-test-comparator)) ?expected))
    ((_ ?dummy ?expected ?form)
     (check ?form (=> (current-test-comparator)) ?expected))
    ))

(define-syntax test-assert
  (syntax-rules ()
    ((_ ?form)
     (check-for-true ?form))
    ))

(define-syntax test-error
  (syntax-rules ()
    ((_ ?form)
     (check
	 (guard (E ((error? E)
		    #t)
		   (else E))
	   ?form)
       => #t))
    ))

(define-syntax test-procedure-argument-violation
  (syntax-rules ()
    ((_ ?form)
     (check
	 (guard (E ((procedure-argument-violation? E)
		    #t)
		   (else E))
	   ?form)
       => #t))
    ))



(test-group "ilists"

(test-group "ilists/constructors"
  (define abc (ilist 'a 'b 'c))
  (test 'a (icar abc))
  (test 'b (icadr abc))
  (test 'c (icaddr abc))
  (test (ipair 2 1) (xipair 1 2))
  (define abc-dot-d (ipair* 'a 'b 'c 'd))
  (test 'd (icdddr abc-dot-d))
  (test (iq c c c c) (make-ilist 4 'c))
  (test (iq 0 1 2 3) (ilist-tabulate 4 values))
  (test (iq 0 1 2 3 4) (iiota 5))
) ; end ilists/constructors

(test-group "ilists/predicates"
  (test-assert (ipair? (ipair 1 2)))
  (test-assert (proper-ilist? '()))
  (test-assert (proper-ilist? (iq 1 2 3)))
  (test-assert (ilist? '()))
  (test-assert (ilist? (iq 1 2 3)))
  (test-assert (dotted-ilist? (ipair 1 2)))
  (test-assert (dotted-ilist? 2))
  (test-assert (null-ilist? '()))
  (test-assert (not (null-ilist? (iq 1 2 3))))
  (test-error (null-ilist? 'a))
  (test-assert (not-ipair? 'a))
  (test-assert (not (not-ipair? (ipair 'a 'b))))
  (test-assert (ilist= = (iq 1 2 3) (iq 1 2 3)))
  (test-assert (not (ilist= = (iq 1 2 3 4) (iq 1 2 3))))
  (test-assert (not (ilist= = (iq 1 2 3) (iq 1 2 3 4))))
  (test-assert (ilist= = (iq 1 2 3) (iq 1 2 3)))
  (test-assert (not (ilist= = (iq 1 2 3) (iq 1 2 3 4) (iq 1 2 3 4))))
  (test-assert (not (ilist= = (iq 1 2 3) (iq 1 2 3) (iq 1 2 3 4))))
) ; end ilist/predicates

(test-group "ilist/cxrs"
  (define ab (ipair 'a 'b))
  (define cd (ipair 'c 'd))
  (define ef (ipair 'e 'f))
  (define gh (ipair 'g 'h))
  (define abcd (ipair ab cd))
  (define efgh (ipair ef gh))
  (define abcdefgh (ipair abcd efgh))
  (define ij (ipair 'i 'j))
  (define kl (ipair 'k 'l))
  (define mn (ipair 'm 'n))
  (define op (ipair 'o 'p))
  (define ijkl (ipair ij kl))
  (define mnop (ipair mn op))
  (define ijklmnop (ipair ijkl mnop))
  (define abcdefghijklmnop (ipair abcdefgh ijklmnop))
  (test 'a (icaar abcd))
  (test 'b (icdar abcd))
  (test 'c (icadr abcd))
  (test 'd (icddr abcd))
  (test 'a (icaaar abcdefgh))
  (test 'b (icdaar abcdefgh))
  (test 'c (icadar abcdefgh))
  (test 'd (icddar abcdefgh))
  (test 'e (icaadr abcdefgh))
  (test 'f (icdadr abcdefgh))
  (test 'g (icaddr abcdefgh))
  (test 'h (icdddr abcdefgh))
  (test 'a (icaaaar abcdefghijklmnop))
  (test 'b (icdaaar abcdefghijklmnop))
  (test 'c (icadaar abcdefghijklmnop))
  (test 'd (icddaar abcdefghijklmnop))
  (test 'e (icaadar abcdefghijklmnop))
  (test 'f (icdadar abcdefghijklmnop))
  (test 'g (icaddar abcdefghijklmnop))
  (test 'h (icdddar abcdefghijklmnop))
  (test 'i (icaaadr abcdefghijklmnop))
  (test 'j (icdaadr abcdefghijklmnop))
  (test 'k (icadadr abcdefghijklmnop))
  (test 'l (icddadr abcdefghijklmnop))
  (test 'm (icaaddr abcdefghijklmnop))
  (test 'n (icdaddr abcdefghijklmnop))
  (test 'o (icadddr abcdefghijklmnop))
  (test 'p (icddddr abcdefghijklmnop))
) ; end ilists/cxrs

(test-group "ilists/selectors"
  (test 'c (ilist-ref (iq a b c d) 2))
  (define ten (ilist 1 2 3 4 5 6 7 8 9 10))
  (test 1 (ifirst ten))
  (test 2 (isecond ten))
  (test 3 (ithird ten))
  (test 4 (ifourth ten))
  (test 5 (ififth ten))
  (test 6 (isixth ten))
  (test 7 (iseventh ten))
  (test 8 (ieighth ten))
  (test 9 (ininth ten))
  (test 10 (itenth ten))
  (test-procedure-argument-violation (ilist-ref '() 2))
  (test '(1 2) (call-with-values (lambda () (icar+icdr (ipair 1 2))) list))
  (define abcde (iq a b c d e))
  (define dotted (ipair 1 (ipair 2 (ipair 3 'd))))
  (test (iq a b) (itake abcde 2))
  (test (iq c d e) (idrop abcde 2))
  (test (iq c d e) (ilist-tail abcde 2))
  (test (iq 1 2) (itake dotted 2))
  (test (ipair 3 'd) (idrop dotted 2))
  (test (ipair 3 'd) (ilist-tail dotted 2))
  (test 'd (idrop dotted 3))
  (test 'd (ilist-tail dotted 3))
  (test abcde (iappend (itake abcde 4) (idrop abcde 4)))
  (test (iq d e) (itake-right abcde 2))
  (test (iq a b c) (idrop-right abcde 2))
  (test (ipair 2 (ipair 3 'd)) (itake-right dotted 2))
  (test (iq 1) (idrop-right dotted 2))
  (test 'd (itake-right dotted 0))
  (test (iq 1 2 3) (idrop-right dotted 0))
  (test abcde (call-with-values (lambda () (isplit-at abcde 3)) iappend))
  (test 'c (ilast (iq a b c)))
  (test (iq c) (last-ipair (iq a b c)))
) ; end ilists/selectors

(test-group "ilists/misc"
  (test 0 (ilength '()))
  (test 3 (ilength (iq 1 2 3)))
  (test (iq x y) (iappend (iq x) (iq y)))
  (test (iq a b c d) (iappend (iq a b) (iq c d)))
  (test (iq a) (iappend '() (iq a)))
  (test (iq x y) (iappend (iq x y)))
  (test '() (iappend))
  (test (iq a b c d) (iconcatenate (iq (a b) (c d))))
  (test (iq c b a) (ireverse (iq a b c)))
  (test (iq (e (f)) d (b c) a) (ireverse (iq a (b c) d (e (f)))))
  (test (ipair 2 (ipair 1 'd)) (iappend-reverse (iq 1 2) 'd))
  (test (iq (one 1 odd) (two 2 even) (three 3 odd))
    (izip (iq one two three) (iq 1 2 3) (iq odd even odd)))
  (test (iq (1) (2) (3)) (izip (iq 1 2 3)))
  (test (iq 1 2 3) (iunzip1 (iq (1) (2) (3))))
  (test (iq (1 2 3) (one two three))
    (call-with-values
      (lambda () (iunzip2 (iq (1 one) (2 two) (3 three))))
      ilist))
  (test (iq (1 2 3) (one two three) (a b c))
    (call-with-values
      (lambda () (iunzip3 (iq (1 one a) (2 two b) (3 three c))))
      ilist))
  (test (iq (1 2 3) (one two three) (a b c) (4 5 6))
    (call-with-values
      (lambda () (iunzip4 (iq (1 one a 4) (2 two b 5) (3 three c 6))))
      ilist))
  (test (iq (1 2 3) (one two three) (a b c) (4 5 6) (#t #f #t))
    (call-with-values
      (lambda () (iunzip5 (iq (1 one a 4 #t) (2 two b 5 #f) (3 three c 6 #t))))
      ilist))
  (test 3 (icount even? (iq 3 1 4 1 5 9 2 5 6)))
  (test 3 (icount < (iq 1 2 4 8) (iq 2 4 6 8 10 12 14 16)))
) ; end ilists/misc

(test-group "ilists/folds"
  ;; We have to be careful to test both single-list and multiple-list
  ;; code paths, as they are different in this implementation.

  (define lis (iq 1 2 3))
  (test 6 (ifold + 0 lis))
  (test (iq 3 2 1) (ifold ipair '() lis))
  (test 2 (ifold
            (lambda (x count) (if (symbol? x) (+ count 1) count))
            0
            (iq a 0 b)))
  (test 4 (ifold
            (lambda (s max-len) (max max-len (string-length s)))
            0
            (iq "ab" "abcd" "abc")))
  (test 32 (ifold
             (lambda (a b ans) (+ (* a b) ans))
             0
             (iq 1 2 3)
             (iq 4 5 6)))
  (define (z x y ans) (ipair (ilist x y) ans))
  (test (iq (b d) (a c))
    (ifold z '() (iq a b) (iq c d)))
  (test lis (ifold-right ipair '() lis))
  (test (iq 0 2 4) (ifold-right
                   (lambda (x l) (if (even? x) (ipair x l) l))
                   '()
                   (iq 0 1 2 3 4)))
  (test (iq (a c) (b d))
    (ifold-right z '() (iq a b) (iq c d)))
  (test (iq (c) (b c) (a b c))
    (ipair-fold ipair '() (iq a b c)))
  (test (iq ((b) (d)) ((a b) (c d)))
    (ipair-fold z '() (iq a b) (iq c d)))
  (test (iq (a b c) (b c) (c))
    (ipair-fold-right ipair '() (iq a b c)))
  (test (iq ((a b) (c d)) ((b) (d)))
    (ipair-fold-right z '() (iq a b) (iq c d)))
  (test 5 (ireduce max 0 (iq 1 3 5 4 2 0)))
  (test 1 (ireduce - 0 (iq 1 2)))
  (test -1 (ireduce-right - 0 (iq 1 2)))
  (define squares (iq 1 4 9 16 25 36 49 64 81 100))
  (test squares
   (iunfold (lambda (x) (> x 10))
     (lambda (x) (* x x))
     (lambda (x) (+ x 1))
     1))
  (test squares
    (iunfold-right zero?
      (lambda (x) (* x x))
      (lambda (x) (- x 1))
      10))
  (test (iq 1 2 3) (iunfold null-ilist? icar icdr (iq 1 2 3)))
  (test (iq 3 2 1) (iunfold-right null-ilist? icar icdr (iq 1 2 3)))
  (test (iq 1 2 3 4)
    (iunfold null-ilist? icar icdr (iq 1 2) (lambda (x) (iq 3 4))))
  (test (iq b e h) (imap icadr (iq (a b) (d e) (g h))))
  (test (iq b e h) (imap-in-order icadr (iq (a b) (d e) (g h))))
  (test (iq 5 7 9) (imap + (iq 1 2 3) (iq 4 5 6)))
  (test (iq 5 7 9) (imap-in-order + (iq 1 2 3) (iq 4 5 6)))
  (let ((z (let ((count 0)) (lambda (ignored) (set! count (+ count 1)) count))))
    (test (iq 1 2) (imap-in-order z (iq a b))))
  (test '#(0 1 4 9 16)
    (let ((v (make-vector 5)))
      (ifor-each (lambda (i)
                  (vector-set! v i (* i i)))
                (iq 0 1 2 3 4))
    v))
  (test '#(5 7 9 11 13)
    (let ((v (make-vector 5)))
      (ifor-each (lambda (i j)
                  (vector-set! v i (+ i j)))
                (iq 0 1 2 3 4)
                (iq 5 6 7 8 9))
    v))
  (test (iq 1 -1 3 -3 8 -8)
    (iappend-map (lambda (x) (ilist x (- x))) (iq 1 3 8)))
  (test (iq 1 4 2 5 3 6)
    (iappend-map ilist (iq 1 2 3) (iq 4 5 6)))
  (test (vector (iq 0 1 2 3 4) (iq 1 2 3 4) (iq 2 3 4) (iq 3 4) (iq 4))
    (let ((v (make-vector 5)))
      (ipair-for-each (lambda (lis) (vector-set! v (icar lis) lis)) (iq 0 1 2 3 4))
    v))
  (test (vector (iq 5 6 7 8 9) (iq 6 7 8 9) (iq 7 8 9) (iq 8 9) (iq 9))
    (let ((v (make-vector 5)))
      (ipair-for-each (lambda (i j) (vector-set! v (icar i) j))
                (iq 0 1 2 3 4)
                (iq 5 6 7 8 9))
    v))
  (test (iq 1 9 49)
    (ifilter-map (lambda (x) (and (number? x) (* x x))) (iq a 1 b 3 c 7)))
  (test (iq 5 7 9)
    (ifilter-map
      (lambda (x y) (and (number? x) (number? y) (+ x y)))
      (iq 1 a 2 b 3 4)
      (iq 4 0 5 y 6 z)))
) ; end ilists/folds

(test-group "ilists/filtering"
  (test (iq 0 8 8 -4) (ifilter even? (iq 0 7 8 8 43 -4)))
  (test (list (iq one four five) (iq 2 3 6))
    (call-with-values
      (lambda () (ipartition symbol? (iq one 2 3 four five 6)))
      list))
  (test (iq 7 43) (iremove even? (iq 0 7 8 8 43 -4)))
) ; end ilists/filtering

(test-group "ilists/searching"
  (test 2 (ifind even? (iq 1 2 3)))
  (test #t (iany  even? (iq 1 2 3)))
  (test #f (ifind even? (iq 1 7 3)))
  (test #f (iany  even? (iq 1 7 3)))
  (test-error (ifind even? (ipair 1 (ipair 3 'x))))
  (test-error (iany  even? (ipair 1 (ipair 3 'x))))
  (test 4 (ifind even? (iq 3 1 4 1 5 9)))
  (test (iq -8 -5 0 0) (ifind-tail even? (iq 3 1 37 -8 -5 0 0)))
  (test (iq 2 18) (itake-while even? (iq 2 18 3 10 22 9)))
  (test (iq 3 10 22 9) (idrop-while even? (iq 2 18 3 10 22 9)))
  (test (list (iq 2 18) (iq 3 10 22 9))
    (call-with-values
      (lambda () (ispan even? (iq 2 18 3 10 22 9)))
      list))
  (test (list (iq 3 1) (iq 4 1 5 9))
    (call-with-values
      (lambda () (ibreak even? (iq 3 1 4 1 5 9)))
      list))
  (test #t (iany integer? (iq a 3 b 2.7)))
  (test #f (iany integer? (iq a 3.1 b 2.7)))
  (test #t (iany < (iq 3 1 4 1 5) (iq 2 7 1 8 2)))
  (test #t (ievery integer? (iq 1 2 3 4 5)))
  (test #f (ievery integer? (iq 1 2 3 4.5 5)))
  (test #t (ievery < (iq 1 2 3) (iq 4 5 6)))
  (test 2 (ilist-index even? (iq 3 1 4 1 5 9)))
  (test 1 (ilist-index < (iq 3 1 4 1 5 9 2 5 6) (iq 2 7 1 8 2)))
  (test #f (ilist-index = (iq 3 1 4 1 5 9 2 5 6) (iq 2 7 1 8 2)))
  (test (iq a b c) (imemq 'a (iq a b c)))
  (test (iq b c) (imemq 'b (iq a b c)))
  (test #f (imemq 'a (iq b c d)))
  (test #f (imemq (ilist 'a) (iq b (a) c)))
  (test (iq (a) c) (imember (ilist 'a) (iq b (a) c)))
  (test (iq 101 102) (imemv 101 (iq 100 101 102)))
) ; end ilists/searching

(test-group "ilists/deletion"
  (test (iq 1 2 4 5) (idelete 3 (iq 1 2 3 4 5)))
  (test (iq 3 4 5) (idelete 5 (iq 3 4 5 6 7) <))
  (test (iq a b c z) (idelete-duplicates (iq a b a c a b c z)))
) ; end ilists/deletion

(test-group "ilists/alists"
  (define e (iq (a 1) (b 2) (c 3))) (test (iq a 1) (iassq 'a e))
  (test (iq b 2) (iassq 'b e))
  (test #f (iassq 'd e))
  (test #f (iassq (ilist 'a) (iq ((a)) ((b)) ((c)))))
  (test (iq (a)) (iassoc (ilist 'a) (iq ((a)) ((b)) ((c)))))
  (define e2 (iq (2 3) (5 7) (11 13)))
  (test (iq 5 7) (iassv 5 e2))
  (test (iq 11 13) (iassoc 5 e2 <))
  (test (ipair (iq 1 1) e2) (ialist-cons 1 (ilist 1) e2))
  (test (iq (2 3) (11 13)) (ialist-delete 5 e2))
  (test (iq (2 3) (5 7)) (ialist-delete 5 e2 <))
) ; end ilists/alists

(test-group "ilists/replacers"
  (test (ipair 1 3) (replace-icar (ipair 2 3) 1))
  (test (ipair 1 3) (replace-icdr (ipair 1 2) 3))
) ; end ilists/replacers

(test-group "ilists/conversion"
  (test (ipair 1 2) (pair->ipair '(1 . 2)))
  (test '(1 . 2) (ipair->pair (ipair 1 2)))
  (test (iq 1 2 3) (list->ilist '(1 2 3)))
  (test '(1 2 3) (ilist->list (iq 1 2 3)))
  (test (ipair 1 (ipair 2 3)) (list->ilist '(1 2 . 3)))
  (test '(1 2 . 3) (ilist->list (ipair 1 (ipair 2 3))))
  (test (ipair (ipair 1 2) (ipair 3 4)) (tree->itree '((1 . 2) . (3 . 4))))
  (test '((1 . 2) . (3 . 4)) (itree->tree (ipair (ipair 1 2) (ipair 3 4))))
  (test (ipair (ipair 1 2) (ipair 3 4)) (gtree->itree (cons (ipair 1 2) (ipair 3 4))))
  (test '((1 . 2) . (3 . 4)) (gtree->tree (cons (ipair 1 2) (ipair 3 4))))
  (test 6 (iapply + (iq 1 2 3)))
  (test 15 (iapply + 1 2 (iq 3 4 5)))
) ; end ilists/conversion

) ; end ilists


(parametrise ((check-test-name	'comparator-predicates))

  (check-for-true (comparator? ipair-comparator))
  (check-for-true (comparator? ilist-comparator))

;;; --------------------------------------------------------------------

  (check-for-true (comparator-comparison-procedure? ipair-comparator))
  (check-for-true (comparator-comparison-procedure? ilist-comparator))

;;; --------------------------------------------------------------------

  (check-for-true (comparator-hash-function? ipair-comparator))
  (check-for-true (comparator-hash-function? ilist-comparator))

  #t)


(parametrise ((check-test-name	'comparator-accessors))

  (define-syntax doit
    (syntax-rules ()
      ((_ ?C ?a ?b)
       (begin
	 (check-for-true  ((comparator-type-test-procedure ?C) ?a))
	 (check-for-true  ((comparator-type-test-procedure ?C) ?b))
	 (check-for-false ((comparator-type-test-procedure ?C) (void)))
	 (check-for-true  ((comparator-equality-predicate ?C) ?a ?a))
	 (check-for-false ((comparator-equality-predicate ?C) ?a ?b))
	 (check
	     ((comparator-comparison-procedure ?C) ?a ?a)
	   => 0)
	 (check
	     ((comparator-comparison-procedure ?C) ?a ?b)
	   => -1)
	 (check
	     ((comparator-comparison-procedure ?C) ?b ?a)
	   => +1)
	 (check-for-true
	  (non-negative-exact-integer? ((comparator-hash-function ?C) ?a)))
	 (check-for-true
	  (non-negative-exact-integer? ((comparator-hash-function ?C) ?b)))
	 ))
      ))

;;; --------------------------------------------------------------------

  (doit ipair-comparator (iq 1 . 2) (iq 3 . 4))
  (doit ilist-comparator (iq 1 2) (iq 3 4))

;;; --------------------------------------------------------------------
;;; pair comparison

  (let ((cmp (comparator-comparison-procedure ipair-comparator)))
    (check (cmp (iq 1 . 2) (iq 1 . 2)) =>  0)
    (check (cmp (iq 1 . 2) (iq 1 . 3)) => -1) ;2 < 3
    (check (cmp (iq 1 . 4) (iq 1 . 3)) => +1) ;4 > 3
    (check (cmp (iq 1 . 0) (iq 2 . 0)) => -1)
    (check (cmp (iq 3 . 0) (iq 2 . 0)) => +1)
    #f)

;;; --------------------------------------------------------------------
;;; list comparison

  (let ((cmp (comparator-comparison-procedure ilist-comparator)))
    (check (cmp (iq 1 2) (iq 1 2)) =>  0)
    (check (cmp (iq 1 2) (iq 1 3)) => -1) ;2 < 3
    (check (cmp (iq 1 4) (iq 1 3)) => +1) ;4 > 3
    (check (cmp (iq 1 0) (iq 2 0)) => -1)
    (check (cmp (iq 3 0) (iq 2 0)) => +1)

    (check (cmp (iq ) (iq ))	=> 0)
    (check (cmp (iq ) (iq 1))	=> -1)
    (check (cmp (iq 1) (iq ))	=> +1)

    ;;If first items are equal: compare the CADRs.  Here one of the CADRs is null.
    (check (cmp (iq 1 2) (iq 1))	=> +1)
    (check (cmp (iq 1)   (iq 1 2))	=> -1)

    ;;Lists  of  different length,  but  it  does not  matter  because  the CARs  are
    ;;non-equal.
    (check (cmp (iq 1 2) (iq 2))	=> -1)
    (check (cmp (iq 2)   (iq 1 2))	=> +1)
    #f)

  #t)


(parametrise ((check-test-name	'comparator-applicators))

  (define-syntax doit
    (syntax-rules ()
      ((_ ?C ?a ?b)
       (begin
	 (check-for-true  (comparator-test-type ?C ?a))
	 (check-for-true  (comparator-test-type ?C ?b))
	 (check-for-false (comparator-test-type ?C (void)))
	 (check-for-true  (comparator-check-type ?C ?a))
	 (check-for-true  (comparator-check-type ?C ?b))
	 (check-for-true
	  (try
	      (comparator-check-type ?C (void))
	    (catch E
	      ((&comparator-type-error)
	       #t)
	      (else #f))))
	 (check-for-true  (comparator-equal? ?C ?a ?a))
	 (check-for-false (comparator-equal? ?C ?a ?b))
	 (check
	     (comparator-compare ?C ?a ?a)
	   => 0)
	 (check
	     (comparator-compare ?C ?a ?b)
	   => -1)
	 (check
	     (comparator-compare ?C ?b ?a)
	   => +1)
	 (check-for-true
	  (non-negative-exact-integer? (comparator-hash ?C ?a)))
	 (check-for-true
	  (non-negative-exact-integer? (comparator-hash ?C ?b)))
	 ))
      ))

;;; --------------------------------------------------------------------

  (doit ipair-comparator (iq 1 . 2) (iq 3 . 4))
  (doit ilist-comparator (iq 1 2) (iq 3 4))

;;; --------------------------------------------------------------------
;;; pair comparison

  (let ((cmp (comparator-comparison-procedure ipair-comparator)))
    (check (cmp (iq 1 . 2) (iq 1 . 2)) =>  0)
    (check (cmp (iq 1 . 2) (iq 1 . 3)) => -1) ;2 < 3
    (check (cmp (iq 1 . 4) (iq 1 . 3)) => +1) ;4 > 3
    (check (cmp (iq 1 . 0) (iq 2 . 0)) => -1)
    (check (cmp (iq 3 . 0) (iq 2 . 0)) => +1)
    #f)

;;; --------------------------------------------------------------------
;;; list comparison

  (let ((cmp (comparator-comparison-procedure ilist-comparator)))
    (check (cmp (iq 1 2) (iq 1 2)) =>  0)
    (check (cmp (iq 1 2) (iq 1 3)) => -1) ;2 < 3
    (check (cmp (iq 1 4) (iq 1 3)) => +1) ;4 > 3
    (check (cmp (iq 1 0) (iq 2 0)) => -1)
    (check (cmp (iq 3 0) (iq 2 0)) => +1)

    (check (cmp (iq ) (iq ))	=> 0)
    (check (cmp (iq ) (iq 1))	=> -1)
    (check (cmp (iq 1) (iq ))	=> +1)

    ;;If first items are equal: compare the CADRs.  Here one of the CADRs is null.
    (check (cmp (iq 1 2) (iq 1))	=> +1)
    (check (cmp (iq 1)   (iq 1 2))	=> -1)

    ;;Lists  of  different length,  but  it  does not  matter  because  the CARs  are
    ;;non-equal.
    (check (cmp (iq 1 2) (iq 2))	=> -1)
    (check (cmp (iq 2)   (iq 1 2))	=> +1)
    #f)



  #t)


(parametrise ((check-test-name	'ipair-comparator))

  (define-constant C
    (make-ipair-comparator exact-integer-comparator
			   real-comparator))

  ;; type test
  (check-for-true  (comparator-test-type C (iq 1 . 2.0)))
  (check-for-true  (comparator-test-type C (iq 1 . 2.0)))
  (check-for-false (comparator-test-type C (iq )))
  (check-for-false (comparator-test-type C (iq 1 . 2+1i)))
  (check-for-false (comparator-test-type C "ciao"))

  ;; type check
  (check-for-true  (comparator-check-type C (iq 1 . 2.0)))
  (check-for-true
   (try
       (comparator-check-type C (void))
     (catch E
       ((&comparator-type-error)
	#t)
       (else E))))

  ;; comparison
  (check (comparator-compare C (iq 1 . 2.0) (iq 1 . 2.0))	=> 0)
  (check (comparator-compare C (iq 1 . 2.0) (iq 1 . 3))	=> -1)
  (check (comparator-compare C (iq 1 . 3)   (iq 1 . 2.0))	=> +1)

  ;; hash
  (check-for-true
   (non-negative-exact-integer? (comparator-hash C (iq 1 . 2.0))))

  #t)


(parametrise ((check-test-name	'icar-comparator))

  (define-constant C
    (make-icar-comparator exact-integer-comparator))

  ;; type test
  (check-for-true  (comparator-test-type C (iq 1 . 2.0)))
  (check-for-true  (comparator-test-type C (iq 1 . 2.0)))
  (check-for-true  (comparator-test-type C (iq 1 . 2+1i)))
  (check-for-false (comparator-test-type C (iq 2.0 . 1)))
  (check-for-false (comparator-test-type C (iq )))
  (check-for-false (comparator-test-type C "ciao"))

  ;; type check
  (check-for-true  (comparator-check-type C (iq 1 . 2.0)))
  (check-for-true
   (try
       (comparator-check-type C (void))
     (catch E
       ((&comparator-type-error)
	#t)
       (else E))))

  ;; comparison
  (check (comparator-compare C (iq 1 . 2) (iq 1 . 3))	=> 0)
  (check (comparator-compare C (iq 1 . 2) (iq 2 . 3))	=> -1)
  (check (comparator-compare C (iq 2 . 2) (iq 1 . 2))	=> +1)

  ;; hash
  (check-for-true
   (non-negative-exact-integer? (comparator-hash C (iq 1 . 2.0))))

  #t)


(parametrise ((check-test-name	'icdr-comparator))

  (define-constant C
    (make-icdr-comparator exact-integer-comparator))

  ;; type test
  (check-for-true  (comparator-test-type C (iq 2.0 . 1)))
  (check-for-true  (comparator-test-type C (iq 2.0 . 1)))
  (check-for-true  (comparator-test-type C (iq 2+1i . 1)))
  (check-for-false (comparator-test-type C (iq 1 . 2.0)))
  (check-for-false (comparator-test-type C (iq )))
  (check-for-false (comparator-test-type C "ciao"))

  ;; type check
  (check-for-true  (comparator-check-type C (iq 2.0 . 1)))
  (check-for-true
   (try
       (comparator-check-type C (void))
     (catch E
       ((&comparator-type-error)
	#t)
       (else E))))

  ;; comparison
  (check (comparator-compare C (iq 2 . 1) (iq 3 . 1))	=> 0)
  (check (comparator-compare C (iq 2 . 1) (iq 3 . 2))	=> -1)
  (check (comparator-compare C (iq 2 . 2) (iq 2 . 1))	=> +1)

  ;; hash
  (check-for-true
   (non-negative-exact-integer? (comparator-hash C (iq 2.0 . 1))))

  #t)


(parametrise ((check-test-name	'ilist-comparator))

  (define-constant C
    (make-ilist-comparator exact-integer-comparator))

  ;; type test
  (check-for-true  (comparator-test-type C (iq )))
  (check-for-true  (comparator-test-type C (iq 1 2)))
  (check-for-false (comparator-test-type C (iq 1 2 . 3)))
  (check-for-false (comparator-test-type C (iq 1 2.0)))
  (check-for-false (comparator-test-type C "ciao"))
  (check-for-false (comparator-test-type C (iq 1+2i)))

  ;; type check
  (check-for-true  (comparator-check-type C (iq 1 2)))
  (check-for-true
   (try
       (comparator-check-type C (void))
     (catch E
       ((&comparator-type-error)
	#t)
       (else E))))

  ;; comparison
  (check (comparator-compare C (iq 1 2) (iq 1 2))	=> 0)
  (check (comparator-compare C (iq 1 2) (iq 1 3))	=> -1)
  (check (comparator-compare C (iq 1 3) (iq 1 2))	=> +1)

  (check (comparator-compare C (iq )    (iq ))	=> 0)
  (check (comparator-compare C (iq )    (iq 1 2))	=> -1)
  (check (comparator-compare C (iq 1 2) (iq ))	=> +1)

  ;; hash
  (check-for-true
   (non-negative-exact-integer? (comparator-hash C (iq ))))
  (check-for-true
   (non-negative-exact-integer? (comparator-hash C (iq 1 2))))

  #t)


(parametrise ((check-test-name	'improper-ilist-comparator))

  (module (C)

    (define element-compare
      (let ((compare (comparator-comparison-procedure exact-integer-comparator)))
	(lambda (A B)
	  (if (ipair? A)
	      (begin
		(assert (ipair? B))
		(let ((rv (compare (icar A) (icar B))))
		  (if (zero? rv)
		      (comparator-compare C (icdr A) (icdr B))
		    rv)))
	    (compare A B)))))

    (define-constant E
      (make-comparator #t #t
		       element-compare
		       (comparator-hash-function default-comparator)))

    (define-constant C
      (make-improper-ilist-comparator E))

    #| end of module |# )

  ;; type test
  (check-for-true (comparator-test-type C (iq )))
  (check-for-true (comparator-test-type C (iq 1 2)))
  (check-for-true (comparator-test-type C (iq 1 2 . 3)))
  (check-for-true (comparator-test-type C (iq 1 2.0)))
  (check-for-true (comparator-test-type C "ciao"))
  (check-for-true (comparator-test-type C (iq 1+2i)))

  ;; type check
  (check-for-true (comparator-check-type C (iq 1 2)))
  (check-for-true (comparator-check-type C (void)))

  ;; comparison
  (check (comparator-compare C (iq 1 2) (iq 1 2))	=> 0)
  (check (comparator-compare C (iq 1 2) (iq 1 3))	=> -1)
  (check (comparator-compare C (iq 1 3) (iq 1 2))	=> +1)

  (check (comparator-compare C (iq )    (iq ))	=> 0)
  (check (comparator-compare C (iq )    (iq 1 2))	=> -1)
  (check (comparator-compare C (iq 1 2) (iq ))	=> +1)

  (check (comparator-compare C (iq 1 2 . 3) (iq 1 2 . 3))	=> 0)
  (check (comparator-compare C (iq 1 2 . 3) (iq 1 2 . 4))	=> -1)
  (check (comparator-compare C (iq 1 2 . 4) (iq 1 2 . 3))	=> +1)

  (check (comparator-compare C (iq 1 2 9 . 3) (iq 1 2 9 . 3))	=> 0)
  (check (comparator-compare C (iq 1 2 9 . 3) (iq 1 2 9 . 4))	=> -1)
  (check (comparator-compare C (iq 1 2 9 . 4) (iq 1 2 9 . 3))	=> +1)

  ;; hash
  (check-for-true
   (non-negative-exact-integer? (comparator-hash C (iq ))))
  (check-for-true
   (non-negative-exact-integer? (comparator-hash C (iq 1 2))))
  (check-for-true
   (non-negative-exact-integer? (comparator-hash C (iq 1 2 . 3))))
  (check-for-true
   (non-negative-exact-integer? (comparator-hash C "ciao")))

  #t)


;;;; done

(collect 4)
(check-report)

;;; end of file
;; Local Variables:
;; mode: vicare
;; coding: utf-8
;; End:
