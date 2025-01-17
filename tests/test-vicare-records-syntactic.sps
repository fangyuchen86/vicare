;;; -*- coding: utf-8-unix -*-
;;;
;;;Part of: Vicare Scheme
;;;Contents: tests for R6RS records, syntactic layer
;;;Date: Thu Mar 22, 2012
;;;
;;;Abstract
;;;
;;;
;;;
;;;Copyright (C) 2012-2015 Marco Maggi <marco.maggi-ipsu@poste.it>
;;;
;;;This program is free software:  you can redistribute it and/or modify
;;;it under the terms of the  GNU General Public License as published by
;;;the Free Software Foundation, either version 3 of the License, or (at
;;;your option) any later version.
;;;
;;;This program is  distributed in the hope that it  will be useful, but
;;;WITHOUT  ANY   WARRANTY;  without   even  the  implied   warranty  of
;;;MERCHANTABILITY  or FITNESS FOR  A PARTICULAR  PURPOSE.  See  the GNU
;;;General Public License for more details.
;;;
;;;You should  have received  a copy of  the GNU General  Public License
;;;along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;;


#!vicare
(import (vicare)
  (vicare language-extensions syntaxes)
  (vicare system $structs)
  (libtest records-lib)
  (vicare checks))

(check-set-mode! 'report-failed)
(check-display "*** testing Vicare R6RS records, syntactic layer\n")


(parametrise ((check-test-name	'definition))

  (check	;safe accessors
      (let ()
	(define-record-type color
	  (fields (mutable red)
		  (mutable green)
		  (mutable blue)))
	(define X
	  (make-color 1 2 3))
	(list (color-red   X)
	      (color-green X)
	      (color-blue  X)))
    => '(1 2 3))

  (check	;safe accessors and mutators
      (let ()
	(define-record-type color
	  (fields (mutable red)
		  (mutable green)
		  (mutable blue)))
	(define X
	  (make-color 1 2 3))
	(color-red-set!   X 10)
	(color-green-set! X 20)
	(color-blue-set!  X 30)
	(list (color-red   X)
	      (color-green X)
	      (color-blue  X)))
    => '(10 20 30))

  (check	;safe accessors and mutators
      (let ()
	(define-record-type color
	  (fields (mutable red   the-red   set-the-red!)
		  (mutable green the-green set-the-green!)
		  (mutable blue  the-blue  set-the-blue!)))
	(define X
	  (make-color 1 2 3))
	(set-the-red!   X 10)
	(set-the-green! X 20)
	(set-the-blue!  X 30)
	(list (the-red   X)
	      (the-green X)
	      (the-blue  X)))
    => '(10 20 30))

  #t)


(parametrise ((check-test-name	'protocol))

  ;;Record-type without parent.
  ;;
  (check
      (internal-body

	(define-record-type alpha
	  (fields a b c)
	  (protocol
	   (lambda (alpha-initialiser)
	     (lambda (a b c)
	       (receive-and-return (R)
		   (alpha-initialiser a b c)
		 (assert (alpha? R)))))))

	(let ((R (make-alpha 1 2 3)))
	  (values (alpha-a R)
		  (alpha-b R)
		  (alpha-c R))))
    => 1 2 3)

  ;;Record-type with single parent.
  ;;
  (check
      (internal-body

	(define-record-type alpha
	  (fields a b c)
	  (protocol
	   (lambda (alpha-initialiser)
	     (lambda (a b c)
	       (receive-and-return (R)
		   (alpha-initialiser a b c)
		 (assert (alpha? R)))))))

	(define-record-type beta
	  (parent alpha)
	  (fields d e f)
	  (protocol
	   (lambda (alpha-maker)
	     (lambda (a b c d e f)
	       (receive-and-return (R)
		   ((alpha-maker a b c) d e f)
		 (assert (beta? R)))))))

	(let ((R (make-beta 1 2 3 4 5 6)))
	  (values (alpha-a R)
		  (alpha-b R)
		  (alpha-c R)
		  (beta-d R)
		  (beta-e R)
		  (beta-f R))))
    => 1 2 3 4 5 6)

  ;;Record-type with double parent.
  ;;
  (check
      (internal-body

	(define-record-type alpha
	  (fields a b c)
	  (protocol
	   (lambda (alpha-initialiser)
	     (lambda (a b c)
	       (receive-and-return (R)
		   (alpha-initialiser a b c)
		 (assert (alpha? R)))))))

	(define-record-type beta
	  (parent alpha)
	  (fields d e f)
	  (protocol
	   (lambda (alpha-maker)
	     (lambda (a b c d e f)
	       (receive-and-return (R)
		   ((alpha-maker a b c) d e f)
		 (assert (beta? R)))))))

	(define-record-type gamma
	  (parent beta)
	  (fields g h i)
	  (protocol
	   (lambda (beta-maker)
	     (lambda (a b c d e f g h i)
	       (receive-and-return (R)
		   ((beta-maker a b c d e f) g h i)
		 (assert (gamma? R)))))))

	(let ((R (make-gamma 1 2 3 4 5 6 7 8 9)))
	  (values (alpha-a R)
		  (alpha-b R)
		  (alpha-c R)
		  (beta-d R)
		  (beta-e R)
		  (beta-f R)
		  (gamma-g R)
		  (gamma-h R)
		  (gamma-i R))))
    => 1 2 3 4 5 6 7 8 9)

  #t)


(parametrise ((check-test-name	'unsafe-accessors))

  (check	;unsafe accessors
      (let ()
	(define-record-type color
	  (fields (mutable red)
		  (mutable green)
		  (mutable blue)))
	(define X
	  (make-color 1 2 3))
	(list ($color-red   X)
	      ($color-green X)
	      ($color-blue  X)))
    => '(1 2 3))

  (check	;unsafe accessors and mutators
      (let ()
	(define-record-type color
	  (fields (mutable red)
		  (mutable green)
		  (mutable blue)))
	(define X
	  (make-color 1 2 3))
	($color-red-set!   X 10)
	($color-green-set! X 20)
	($color-blue-set!  X 30)
	(list ($color-red   X)
	      ($color-green X)
	      ($color-blue  X)))
    => '(10 20 30))

  (check	;unsafe accessors and mutators
      (let ()
	(define-record-type color
	  (fields (mutable red   the-red   set-the-red!)
		  (mutable green the-green set-the-green!)
		  (mutable blue  the-blue  set-the-blue!)))
	(define X
	  (make-color 1 2 3))
	($color-red-set!   X 10)
	($color-green-set! X 20)
	($color-blue-set!  X 30)
	(list ($color-red   X)
	      ($color-green X)
	      ($color-blue  X)))
    => '(10 20 30))

;;; --------------------------------------------------------------------

  (check	;unsafe accessors, with inheritance
      (let ()
	(define-record-type alpha
	  (fields (mutable a)
		  (mutable b)
		  (mutable c)))
	(define-record-type beta
	  (parent alpha)
	  (fields (mutable a)
		  (mutable b)
		  (mutable c)))
	(define O
	  (make-beta 1 2 3 4 5 6))
	(list ($alpha-a O)
	      ($alpha-b O)
	      ($alpha-c O)
	      ($beta-a O)
	      ($beta-b O)
	      ($beta-c O)))
    => '(1 2 3 4 5 6))

  (check	;unsafe accessors and mutators, with inheritance
      (let ()
	(define-record-type alpha
	  (fields (mutable a)
		  (mutable b)
		  (mutable c)))
	(define-record-type beta
	  (parent alpha)
	  (fields (mutable a)
		  (mutable b)
		  (mutable c)))
	(define O
	  (make-beta 1 2 3 4 5 6))
	($alpha-a-set! O 10)
	($alpha-b-set! O 20)
	($alpha-c-set! O 30)
	($beta-a-set! O 40)
	($beta-b-set! O 50)
	($beta-c-set! O 60)
	(list ($alpha-a O)
	      ($alpha-b O)
	      ($alpha-c O)
	      ($beta-a O)
	      ($beta-b O)
	      ($beta-c O)))
    => '(10 20 30 40 50 60))

  (check	;unsafe accessors and mutators, with inheritance
      (let ()
	(define-record-type alpha
	  (fields (mutable a)
		  (immutable b)
		  (mutable c)))
	(define-record-type beta
	  (parent alpha)
	  (fields (mutable a)
		  (immutable b)
		  (mutable c)))
	(define O
	  (make-beta 1 2 3 4 5 6))
	($alpha-a-set! O 10)
	#;($alpha-b-set! O 20)
	($alpha-c-set! O 30)
	($beta-a-set! O 40)
	#;($beta-b-set! O 50)
	($beta-c-set! O 60)
	(list ($alpha-a O)
	      ($alpha-b O)
	      ($alpha-c O)
	      ($beta-a O)
	      ($beta-b O)
	      ($beta-c O)))
    => '(10 2 30 40 5 60))

  (check	;unsafe accessors and mutators, with inheritance
      (let ()
	(define-record-type alpha
	  (fields (mutable a)
		  (immutable b)
		  (mutable c)))
	(define-record-type beta
	  (parent alpha)
	  (fields (mutable a)
		  (immutable b)
		  (mutable c)))
	(define-record-type gamma
	  (parent beta)
	  (fields (mutable a)
		  (immutable b)
		  (mutable c)))
	(define O
	  (make-gamma 1 2 3 4 5 6 7 8 9))
	($alpha-a-set! O 10)
	#;($alpha-b-set! O 20)
	($alpha-c-set! O 30)
	($beta-a-set! O 40)
	#;($beta-b-set! O 50)
	($beta-c-set! O 60)
	($gamma-a-set! O 70)
	#;($gamma-b-set! O 80)
	($gamma-c-set! O 90)
	(list ($alpha-a O)
	      ($alpha-b O)
	      ($alpha-c O)
	      ($beta-a O)
	      ($beta-b O)
	      ($beta-c O)
	      ($gamma-a O)
	      ($gamma-b O)
	      ($gamma-c O)))
    => '(10 2 30 40 5 60 70 8 90))

  #t)


(parametrise ((check-test-name	'record-type-field))

  (check	;safe accessors
      (let ()
	(define-record-type color
	  (fields (mutable red)
		  (mutable green)
		  (mutable blue)))
	(define X
	  (make-color 1 2 3))
	(list (record-type-field-ref color red   X)
	      (record-type-field-ref color green X)
	      (record-type-field-ref color blue  X)))
    => '(1 2 3))

  (check	;safe accessors and mutators
      (let ()
	(define-record-type color
	  (fields (mutable red)
		  (mutable green)
		  (mutable blue)))
	(define X
	  (make-color 1 2 3))
	(record-type-field-set! color red   X 10)
	(record-type-field-set! color green X 20)
	(record-type-field-set! color blue  X 30)
	(list (record-type-field-ref color red   X)
	      (record-type-field-ref color green X)
	      (record-type-field-ref color blue  X)))
    => '(10 20 30))

  (check	;safe accessors and mutators
      (let ()
	(define-record-type color
	  (fields (mutable red   the-red   set-the-red!)
		  (mutable green the-green set-the-green!)
		  (mutable blue  the-blue  set-the-blue!)))
	(define X
	  (make-color 1 2 3))
	(record-type-field-set! color red   X 10)
	(record-type-field-set! color green X 20)
	(record-type-field-set! color blue  X 30)
	(list (record-type-field-ref color red   X)
	      (record-type-field-ref color green X)
	      (record-type-field-ref color blue  X)))
    => '(10 20 30))

;;; --------------------------------------------------------------------

  (check	;safe accessors, with inheritance
      (let ()
	(define-record-type alpha
	  (fields (mutable a)
		  (mutable b)
		  (mutable c)))
	(define-record-type beta
	  (parent alpha)
	  (fields (mutable a)
		  (mutable b)
		  (mutable c)))
	(define O
	  (make-beta 1 2 3 4 5 6))
	(list (record-type-field-ref alpha a O)
	      (record-type-field-ref alpha b O)
	      (record-type-field-ref alpha c O)
	      (record-type-field-ref beta a O)
	      (record-type-field-ref beta b O)
	      (record-type-field-ref beta c O)))
    => '(1 2 3 4 5 6))

  (check	;safe accessors, with inheritance, sub-rtd access
      (let ()
	(define-record-type alpha
	  (fields (mutable a)
		  (mutable b)
		  (mutable c)))
	(define-record-type beta
	  (parent alpha)
	  (fields (mutable d)
		  (mutable e)
		  (mutable f)))
	(define O
	  (make-beta 1 2 3 4 5 6))
	(list (record-type-field-ref beta a O)
	      (record-type-field-ref beta b O)
	      (record-type-field-ref beta c O)
	      (record-type-field-ref beta d O)
	      (record-type-field-ref beta e O)
	      (record-type-field-ref beta f O)))
    => '(1 2 3 4 5 6))

  (check	;safe accessors and mutators, with inheritance, sub-rtd access
      (let ()
	(define-record-type alpha
	  (fields (mutable a)
		  (mutable b)
		  (mutable c)))
	(define-record-type beta
	  (parent alpha)
	  (fields (mutable d)
		  (mutable e)
		  (mutable f)))
	(define O
	  (make-beta 1 2 3 4 5 6))
	(record-type-field-set! beta a O 19)
	(record-type-field-set! beta b O 29)
	(record-type-field-set! beta c O 39)
	(record-type-field-set! beta d O 49)
	(record-type-field-set! beta e O 59)
	(record-type-field-set! beta f O 69)
	(list (record-type-field-ref beta a O)
	      (record-type-field-ref beta b O)
	      (record-type-field-ref beta c O)
	      (record-type-field-ref beta d O)
	      (record-type-field-ref beta e O)
	      (record-type-field-ref beta f O)))
    => '(19 29 39 49 59 69))

  (check	;safe accessors and mutators, with inheritance
      (let ()
	(define-record-type alpha
	  (fields (mutable a)
		  (mutable b)
		  (mutable c)))
	(define-record-type beta
	  (parent alpha)
	  (fields (mutable a)
		  (mutable b)
		  (mutable c)))
	(define O
	  (make-beta 1 2 3 4 5 6))
	(record-type-field-set! alpha a O 10)
	(record-type-field-set! alpha b O 20)
	(record-type-field-set! alpha c O 30)
	(record-type-field-set! beta a O 40)
	(record-type-field-set! beta b O 50)
	(record-type-field-set! beta c O 60)
	(list (record-type-field-ref alpha a O)
	      (record-type-field-ref alpha b O)
	      (record-type-field-ref alpha c O)
	      (record-type-field-ref beta a O)
	      (record-type-field-ref beta b O)
	      (record-type-field-ref beta c O)))
    => '(10 20 30 40 50 60))

  (check	;safe accessors and mutators, with inheritance
      (let ()
	(define-record-type alpha
	  (fields (mutable a)
		  (immutable b)
		  (mutable c)))
	(define-record-type beta
	  (parent alpha)
	  (fields (mutable a)
		  (immutable b)
		  (mutable c)))
	(define O
	  (make-beta 1 2 3 4 5 6))
	(record-type-field-set! alpha a O 10)
	#;(record-type-field-set! alpha b O 20)
	(record-type-field-set! alpha c O 30)
	(record-type-field-set! beta a O 40)
	#;(record-type-field-set! beta b O 50)
	(record-type-field-set! beta c O 60)
	(list (record-type-field-ref alpha a O)
	      (record-type-field-ref alpha b O)
	      (record-type-field-ref alpha c O)
	      (record-type-field-ref beta a O)
	      (record-type-field-ref beta b O)
	      (record-type-field-ref beta c O)))
    => '(10 2 30 40 5 60))

  (check	;safe accessors and mutators, with inheritance
      (let ()
	(define-record-type alpha
	  (fields (mutable a)
		  (immutable b)
		  (mutable c)))
	(define-record-type beta
	  (parent alpha)
	  (fields (mutable a)
		  (immutable b)
		  (mutable c)))
	(define-record-type gamma
	  (parent beta)
	  (fields (mutable a)
		  (immutable b)
		  (mutable c)))
	(define O
	  (make-gamma 1 2 3 4 5 6 7 8 9))
	(record-type-field-set! alpha a O 10)
	#;(record-type-field-set! alpha b O 20)
	(record-type-field-set! alpha c O 30)
	(record-type-field-set! beta a O 40)
	#;(record-type-field-set! beta b O 50)
	(record-type-field-set! beta c O 60)
	(record-type-field-set! gamma a O 70)
	#;(record-type-field-set! gamma b O 80)
	(record-type-field-set! gamma c O 90)
	(list (record-type-field-ref alpha a O)
	      (record-type-field-ref alpha b O)
	      (record-type-field-ref alpha c O)
	      (record-type-field-ref beta a O)
	      (record-type-field-ref beta b O)
	      (record-type-field-ref beta c O)
	      (record-type-field-ref gamma a O)
	      (record-type-field-ref gamma b O)
	      (record-type-field-ref gamma c O)))
    => '(10 2 30 40 5 60 70 8 90))

;;; --------------------------------------------------------------------
;;; here we use records from the library (libtest records-lib)

  (check	;safe accessors
      (let ((X (make-<alpha> 1 2)))
	(list (record-type-field-ref <alpha> one X)
	      (record-type-field-ref <alpha> two X)))
    => '(1 2))

  (check	;safe accessors and mutators
      (let ((X (make-<alpha> 1 2)))
	(record-type-field-set! <alpha> one X 10)
	(list (record-type-field-ref <alpha> one X)
	      (record-type-field-ref <alpha> two X)))
    => '(10 2))

  (check	;safe accessors
      (let ((X (make-<gamma> 1 2 3 4)))
	(list (record-type-field-ref <beta>  one   X)
	      (record-type-field-ref <beta>  two   X)
	      (record-type-field-ref <gamma> three X)
	      (record-type-field-ref <gamma> four  X)
	      ))
    => '(1 2 3 4))

  (check	;safe accessors and mutators
      (let ((X (make-<gamma> 1 2 3 4)))
	(record-type-field-set! <beta>  one   X 10)
	(record-type-field-set! <gamma> three X 30)
	(list (record-type-field-ref <beta>  one   X)
	      (record-type-field-ref <beta>  two   X)
	      (record-type-field-ref <gamma> three X)
	      (record-type-field-ref <gamma> four  X)
	      ))
    => '(10 2 30 4))

  #t)


(parametrise ((check-test-name	'unsafe-record-type-field))

  (check	;unsafe accessors
      (let ()
	(define-record-type color
	  (fields (mutable red)
		  (mutable green)
		  (mutable blue)))
	(define X
	  (make-color 1 2 3))
	(list ($record-type-field-ref color red   X)
	      ($record-type-field-ref color green X)
	      ($record-type-field-ref color blue  X)))
    => '(1 2 3))

  (check	;unsafe accessors and mutators
      (let ()
	(define-record-type color
	  (fields (mutable red)
		  (mutable green)
		  (mutable blue)))
	(define X
	  (make-color 1 2 3))
	($record-type-field-set! color red   X 10)
	($record-type-field-set! color green X 20)
	($record-type-field-set! color blue  X 30)
	(list ($record-type-field-ref color red   X)
	      ($record-type-field-ref color green X)
	      ($record-type-field-ref color blue  X)))
    => '(10 20 30))

  (check	;unsafe accessors and mutators
      (let ()
	(define-record-type color
	  (fields (mutable red   the-red   set-the-red!)
		  (mutable green the-green set-the-green!)
		  (mutable blue  the-blue  set-the-blue!)))
	(define X
	  (make-color 1 2 3))
	($record-type-field-set! color red   X 10)
	($record-type-field-set! color green X 20)
	($record-type-field-set! color blue  X 30)
	(list ($record-type-field-ref color red   X)
	      ($record-type-field-ref color green X)
	      ($record-type-field-ref color blue  X)))
    => '(10 20 30))

;;; --------------------------------------------------------------------

  (check	;unsafe accessors, with inheritance
      (let ()
	(define-record-type alpha
	  (fields (mutable a)
		  (mutable b)
		  (mutable c)))
	(define-record-type beta
	  (parent alpha)
	  (fields (mutable a)
		  (mutable b)
		  (mutable c)))
	(define O
	  (make-beta 1 2 3 4 5 6))
	(list ($record-type-field-ref alpha a O)
	      ($record-type-field-ref alpha b O)
	      ($record-type-field-ref alpha c O)
	      ($record-type-field-ref beta a O)
	      ($record-type-field-ref beta b O)
	      ($record-type-field-ref beta c O)))
    => '(1 2 3 4 5 6))

  (check	;unsafe accessors and mutators, with inheritance
      (let ()
	(define-record-type alpha
	  (fields (mutable a)
		  (mutable b)
		  (mutable c)))
	(define-record-type beta
	  (parent alpha)
	  (fields (mutable a)
		  (mutable b)
		  (mutable c)))
	(define O
	  (make-beta 1 2 3 4 5 6))
	($record-type-field-set! alpha a O 10)
	($record-type-field-set! alpha b O 20)
	($record-type-field-set! alpha c O 30)
	($record-type-field-set! beta a O 40)
	($record-type-field-set! beta b O 50)
	($record-type-field-set! beta c O 60)
	(list ($record-type-field-ref alpha a O)
	      ($record-type-field-ref alpha b O)
	      ($record-type-field-ref alpha c O)
	      ($record-type-field-ref beta a O)
	      ($record-type-field-ref beta b O)
	      ($record-type-field-ref beta c O)))
    => '(10 20 30 40 50 60))

  (check	;unsafe accessors and mutators, with inheritance
      (let ()
	(define-record-type alpha
	  (fields (mutable a)
		  (immutable b)
		  (mutable c)))
	(define-record-type beta
	  (parent alpha)
	  (fields (mutable a)
		  (immutable b)
		  (mutable c)))
	(define O
	  (make-beta 1 2 3 4 5 6))
	($record-type-field-set! alpha a O 10)
	#;($record-type-field-set! alpha b O 20)
	($record-type-field-set! alpha c O 30)
	($record-type-field-set! beta a O 40)
	#;($record-type-field-set! beta b O 50)
	($record-type-field-set! beta c O 60)
	(list ($record-type-field-ref alpha a O)
	      ($record-type-field-ref alpha b O)
	      ($record-type-field-ref alpha c O)
	      ($record-type-field-ref beta a O)
	      ($record-type-field-ref beta b O)
	      ($record-type-field-ref beta c O)))
    => '(10 2 30 40 5 60))

  (check	;unsafe accessors and mutators, with inheritance
      (let ()
	(define-record-type alpha
	  (fields (mutable a)
		  (immutable b)
		  (mutable c)))
	(define-record-type beta
	  (parent alpha)
	  (fields (mutable a)
		  (immutable b)
		  (mutable c)))
	(define-record-type gamma
	  (parent beta)
	  (fields (mutable a)
		  (immutable b)
		  (mutable c)))
	(define O
	  (make-gamma 1 2 3 4 5 6 7 8 9))
	($record-type-field-set! alpha a O 10)
	#;($record-type-field-set! alpha b O 20)
	($record-type-field-set! alpha c O 30)
	($record-type-field-set! beta a O 40)
	#;($record-type-field-set! beta b O 50)
	($record-type-field-set! beta c O 60)
	($record-type-field-set! gamma a O 70)
	#;($record-type-field-set! gamma b O 80)
	($record-type-field-set! gamma c O 90)
	(list ($record-type-field-ref alpha a O)
	      ($record-type-field-ref alpha b O)
	      ($record-type-field-ref alpha c O)
	      ($record-type-field-ref beta a O)
	      ($record-type-field-ref beta b O)
	      ($record-type-field-ref beta c O)
	      ($record-type-field-ref gamma a O)
	      ($record-type-field-ref gamma b O)
	      ($record-type-field-ref gamma c O)))
    => '(10 2 30 40 5 60 70 8 90))

;;; --------------------------------------------------------------------
;;; here we use records from the library (libtest records-lib)

  (check	;safe accessors
      (let ((X (make-<alpha> 1 2)))
	(list ($record-type-field-ref <alpha> one X)
	      ($record-type-field-ref <alpha> two X)))
    => '(1 2))

  (check	;safe accessors and mutators
      (let ((X (make-<alpha> 1 2)))
	($record-type-field-set! <alpha> one X 10)
	(list ($record-type-field-ref <alpha> one X)
	      ($record-type-field-ref <alpha> two X)))
    => '(10 2))

  (check	;safe accessors
      (let ((X (make-<gamma> 1 2 3 4)))
	(list ($record-type-field-ref <beta>  one   X)
	      ($record-type-field-ref <beta>  two   X)
	      ($record-type-field-ref <gamma> three X)
	      ($record-type-field-ref <gamma> four  X)
	      ))
    => '(1 2 3 4))

  (check	;safe accessors and mutators
      (let ((X (make-<gamma> 1 2 3 4)))
	($record-type-field-set! <beta>  one   X 10)
	($record-type-field-set! <gamma> three X 30)
	(list ($record-type-field-ref <beta>  one   X)
	      ($record-type-field-ref <beta>  two   X)
	      ($record-type-field-ref <gamma> three X)
	      ($record-type-field-ref <gamma> four  X)
	      ))
    => '(10 2 30 4))

  #t)


(parametrise ((check-test-name	'record-accessor-constructor))

  (check	;record accessor constructor with symbol argument
      (let ()
	(define-record-type alpha
	  (fields a b c))
	(define alpha-rtd
	  (record-type-descriptor alpha))
	(define R
	  (make-alpha 1 2 3))
	(list ((record-accessor alpha-rtd 'a) R)
	      ((record-accessor alpha-rtd 'b) R)
	      ((record-accessor alpha-rtd 'c) R)))
    => '(1 2 3))

  (check	;Record  accessor constructor  with  symbol argument;  a
		;field in ALPHA has the same name of a field in BETA.
      (let ()
	(define-record-type alpha
	  (fields a b C))
	(define-record-type beta
	  (parent alpha)
	  (fields C d e))
	(define beta-rtd
	  (record-type-descriptor beta))
	(define R
	  (make-beta 1 2 3 4 5 6))
	(list ((record-accessor beta-rtd 'a) R)
	      ((record-accessor beta-rtd 'b) R)
	      ((record-accessor beta-rtd 'C) R)
	      ((record-accessor beta-rtd 'd) R)
	      ((record-accessor beta-rtd 'e) R)))
    => '(1 2 4 5 6))

  #t)


(parametrise ((check-test-name	'record-mutator-constructor))

  (check	;record mutator constructor with symbol argument
      (let ()
	(define-record-type alpha
	  (fields (mutable a)
		  (mutable b)
		  (mutable c)))
	(define alpha-rtd
	  (record-type-descriptor alpha))
	(define R
	  (make-alpha 1 2 3))
	((record-mutator alpha-rtd 'a) R 19)
	((record-mutator alpha-rtd 'b) R 29)
	((record-mutator alpha-rtd 'c) R 39)
	(list ((record-accessor alpha-rtd 'a) R)
	      ((record-accessor alpha-rtd 'b) R)
	      ((record-accessor alpha-rtd 'c) R)))
    => '(19 29 39))

  (check	;Record  accessor constructor  with  symbol argument;  a
		;field in ALPHA has the same name of a field in BETA.
      (let ()
	(define-record-type alpha
	  (fields (mutable a)
		  (mutable b)
		  (mutable C)))
	(define-record-type beta
	  (parent alpha)
	  (fields (mutable C)
		  (mutable d)
		  (mutable e)))
	(define beta-rtd
	  (record-type-descriptor beta))
	(define R
	  (make-beta 1 2 3 4 5 6))
	((record-mutator beta-rtd 'a) R 19)
	((record-mutator beta-rtd 'b) R 29)
	((record-mutator beta-rtd 'C) R 49)
	((record-mutator beta-rtd 'd) R 59)
	((record-mutator beta-rtd 'e) R 69)
	(list ((record-accessor beta-rtd 'a) R)
	      ((record-accessor beta-rtd 'b) R)
	      ((record-accessor beta-rtd 'C) R)
	      ((record-accessor beta-rtd 'd) R)
	      ((record-accessor beta-rtd 'e) R)))
    => '(19 29 49 59 69))

  #t)


(parametrise ((check-test-name	'predicates))

  (check
      (let ()
	(define-record-type alpha
	  (fields a))
	(define A
	  (make-alpha 1))
	(record-and-rtd? A (record-type-descriptor alpha)))
    => #t)

  (check
      (let ()
	(define-record-type alpha
	  (fields a))
	(define-record-type beta
	  (parent alpha)
	  (fields b))
	(define B
	  (make-beta 1 2))
	(list (record-and-rtd? B (record-type-descriptor alpha))
	      (record-and-rtd? B (record-type-descriptor beta))))
    => '(#t #t))

  (check
      (let ()
	(define-record-type alpha
	  (fields a))
	(define-record-type beta
	  (parent alpha)
	  (fields b))
	(define A
	  (make-alpha 1))
	(list (record-and-rtd? A (record-type-descriptor alpha))
	      (record-and-rtd? A (record-type-descriptor beta))))
    => '(#t #f))

;;; --------------------------------------------------------------------

  (check
      (let ()
	(define-record-type alpha
	  (fields a))
	(define A
	  (make-alpha 1))
	(record-type-and-record? alpha A))
    => #t)

  (check
      (let ()
	(define-record-type alpha
	  (fields a))
	(define-record-type beta
	  (parent alpha)
	  (fields b))
	(define B
	  (make-beta 1 2))
	(list (record-type-and-record? alpha B)
	      (record-type-and-record? beta  B)))
    => '(#t #t))

  (check
      (let ()
	(define-record-type alpha
	  (fields a))
	(define-record-type beta
	  (parent alpha)
	  (fields b))
	(define A
	  (make-alpha 1))
	(list (record-type-and-record? alpha A)
	      (record-type-and-record? beta  A)))
    => '(#t #f))

  #t)


(parametrise ((check-test-name	'generic-rtd-syntax))

  (let ()	;application syntax
    (define-record-type alpha
      (fields a b c))

    (check
	(eq? (record-type-descriptor alpha)
	     (type-descriptor alpha))
      => #t)

    (void))

  #t)


(parametrise ((check-test-name	'generic-maker-syntax))

  (let ()	;application syntax
    (define-record-type alpha
      (fields a b c))

    (define-record-type beta
      (fields a b))

    (check
	(let ((reco (alpha (1 2 3))))
	  (alpha? reco))
      => #t)

    (check
	(let ((reco (beta (1 2))))
	  (beta? reco))
      => #t)

    (void))

  (let ()	;reference syntax
    (define-record-type alpha
      (fields a b c))

    (define-record-type beta
      (fields a b))

    (check
	(let ((reco (apply (alpha (...)) 1 '(2 3))))
	  (alpha? reco))
      => #t)

    (check
	(let ((reco (apply (beta (...)) '(1 2))))
	  (beta? reco))
      => #t)

    (void))

  #t)


(parametrise ((check-test-name	'generic-predicate-syntax))

  (let ()
    (define-record-type alpha
      (fields a b c))

    (define-record-type beta
      (fields a b c))

    (check
	(let ((stru (make-alpha 1 2 3)))
	  (is-a? stru alpha))
      => #t)

    (check
	(let ((stru (make-alpha 1 2 3)))
	  (is-a? stru beta))
      => #f)

    (check
	(let ((stru (make-alpha 1 2 3)))
	  ((is-a? _ alpha) stru))
      => #t)

    (check
	(is-a? 123 alpha)
      => #f)

    (check
	(is-a? 123 beta)
      => #f)

    (void))

  #t)


(parametrise ((check-test-name	'generic-slots-syntax))

  (let ()
    (define-record-type alpha
      (fields (mutable a)
	      (mutable b)
	      (mutable c)))

    (define-record-type beta
      (fields (mutable a)
	      (mutable b)
	      (mutable c)))

    (check
	(let ((stru (alpha (1 2 3))))
	  (list (slot-ref stru a alpha)
		(slot-ref stru b alpha)
		(slot-ref stru c alpha)))
      => '(1 2 3))

    (check
	(let ((stru (alpha (1 2 3))))
	  (slot-set! stru a alpha 19)
	  (slot-set! stru b alpha 29)
	  (slot-set! stru c alpha 39)
	  (list (slot-ref stru a alpha)
		(slot-ref stru b alpha)
		(slot-ref stru c alpha)))
      => '(19 29 39))

    (check
	(let ((stru (alpha (1 2 3))))
	  (list ((slot-ref <> a alpha) stru)
		((slot-ref <> b alpha) stru)
		((slot-ref <> c alpha) stru)))
      => '(1 2 3))

    (check
	(let ((stru (alpha (1 2 3))))
	  ((slot-set! <> a alpha <>) stru 19)
	  ((slot-set! <> b alpha <>) stru 29)
	  ((slot-set! <> c alpha <>) stru 39)
	  (list ((slot-ref <> a alpha) stru)
		((slot-ref <> b alpha) stru)
		((slot-ref <> c alpha) stru)))
      => '(19 29 39))

    (check
	(let ((stru (alpha (1 2 3))))
	  (list ((slot-ref _ a alpha) stru)
		((slot-ref _ b alpha) stru)
		((slot-ref _ c alpha) stru)))
      => '(1 2 3))

    (check
	(let ((stru (alpha (1 2 3))))
	  ((slot-set! _ a alpha _) stru 19)
	  ((slot-set! _ b alpha _) stru 29)
	  ((slot-set! _ c alpha _) stru 39)
	  (list ((slot-ref _ a alpha) stru)
		((slot-ref _ b alpha) stru)
		((slot-ref _ c alpha) stru)))
      => '(19 29 39))

    (void))

  #t)


(parametrise ((check-test-name	'equality))

  (define-record-type <alpha>
    (fields a b c))

;;; --------------------------------------------------------------------

  (check-for-true
   (let ((P (make-<alpha> 1 2 3)))
     (record=? P P)))

  (check-for-true
   (let ((P (make-<alpha> 1 2 3))
	 (Q (make-<alpha> 1 2 3)))
     (record=? P Q)))

  (check-for-false
   (let ((P (make-<alpha> 1 2 3))
	 (Q (make-<alpha> 1 2 9)))
     (record=? P Q)))

;;; --------------------------------------------------------------------
;;; STRUCT=? works on records

  (check-for-true
   (let ((P (make-<alpha> 1 2 3)))
     (struct=? P P)))

  (check-for-true
   (let ((P (make-<alpha> 1 2 3))
	 (Q (make-<alpha> 1 2 3)))
     (struct=? P Q)))

  (check-for-false
   (let ((P (make-<alpha> 1 2 3))
	 (Q (make-<alpha> 1 2 9)))
     (struct=? P Q)))

;;; --------------------------------------------------------------------

  (check-for-true
   (let ((P (make-<alpha> 1 2 3)))
     (equal? P P)))

  (check-for-true
   (let ((P (make-<alpha> 1 2 3))
	 (Q (make-<alpha> 1 2 3)))
     (equal? P Q)))

  (check-for-false
   (let ((P (make-<alpha> 1 2 3))
	 (Q (make-<alpha> 1 2 9)))
     (equal? P Q)))

;;; --------------------------------------------------------------------

  (check-for-true
   (let ((P (make-<alpha> 1 2 3)))
     (eqv? P P)))

  (check-for-false
   (let ((P (make-<alpha> 1 2 3))
	 (Q (make-<alpha> 1 2 3)))
     (eqv? P Q)))

  (check-for-false
   (let ((P (make-<alpha> 1 2 3))
	 (Q (make-<alpha> 1 2 9)))
     (eqv? P Q)))

  #t)


(parametrise ((check-test-name	'reset))

  (define-record-type <alpha>
    (fields a b c))

  (check
      (let ((R (make-<alpha> 1 2 3)))
	(record-reset R)
	(list (<alpha>-a R)
	      (<alpha>-b R)
	      (<alpha>-c R)))
    => (list (void) (void) (void)))

  (check
      (guard (E ((assertion-violation? E)
		 (condition-who E))
		(else E))
	(record-reset 123))
    => 'record-reset)

  #t)


(parametrise ((check-test-name		'destructor)
	      (record-guardian-logger	(lambda (S E action)
					  (check-pretty-print (list S E action)))))

  (module ()	;example for the documentation

    (define-record-type <alpha>
      (fields a b c))

    (record-destructor-set! (record-type-descriptor <alpha>)
			    (lambda (S)
			      (pretty-print (list 'finalising S)
					    (current-error-port))))

    (parametrise ((record-guardian-logger #f))
      (pretty-print (make-<alpha> 1 2 3) (current-error-port))
      (collect))

    #f)

  (define-record-type <alpha>
    (fields a b c))

  (record-destructor-set! (record-type-descriptor <alpha>)
			  (lambda (S)
			    (void)))

  (check
      (procedure? (record-destructor (record-type-descriptor <alpha>)))
    => #t)

  (check
      (parametrise ((record-guardian-logger #t))
	(let ((S (make-<alpha> 1 2 3)))
	  (check-pretty-print S)
	  (collect)))
    => (void))

  (check
      (let ((S (make-<alpha> 1 2 3)))
  	(check-pretty-print S)
  	(collect))
    => (void))

  (check
      (let ((S (make-<alpha> 1 2 3)))
  	(check-pretty-print S)
  	(collect))
    => (void))

  (collect))


(parametrise ((check-test-name	'misc))

  (let ()
    (define-record-type <alpha>
      (nongenerative ciao-hello-ciao-1)
      (fields a))

    (check
	(record-rtd (make-<alpha> 1))
      => (record-type-descriptor <alpha>))

    #f)

  #t)


(parametrise ((check-test-name	'bugs))

  (check-for-expression-return-value-violation
      (internal-body
	(define-record-type alpha
	  (fields a)
	  (protocol (lambda (maker)
		      (void))))
	(make-alpha 1))
    => '(make-record-constructor-descriptor (#!void)))

  #t)


;;;; done

(collect 4)
(check-report)

;;; end of file
;;Local Variables:
;;eval: (put 'catch 'scheme-indent-function 1)
;;End:
