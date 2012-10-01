;;; -*- coding: utf-8-unix -*-
;;;
;;;Part of: Vicare Scheme
;;;Contents: tests for arguments validation library
;;;Date: Mon Oct  1, 2012
;;;
;;;Abstract
;;;
;;;
;;;
;;;Copyright (C) 2012 Marco Maggi <marco.maggi-ipsu@poste.it>
;;;
;;;This program is free software:  you can redistribute it and/or modify
;;;it under the terms of the  GNU General Public License as published by
;;;the Free Software Foundation, either version 3 of the License, or (at
;;;your option) any later version.
;;;
;;;This program is  distributed in the hope that it  will be useful, but
;;;WITHOUT  ANY   WARRANTY;  without   even  the  implied   warranty  of
;;;MERCHANTABILITY or  FITNESS FOR  A PARTICULAR  PURPOSE.  See  the GNU
;;;General Public License for more details.
;;;
;;;You should  have received a  copy of  the GNU General  Public License
;;;along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;;


#!r6rs
(import (vicare)
  (vicare syntactic-extensions)
  (vicare arguments validation)
  (prefix (vicare posix) px.)
  (vicare checks))

(check-set-mode! 'report-failed)
(check-display "*** testing Vicare arguments validation library\n")


;;;; helpers

(define-syntax catch
  (syntax-rules ()
    ((_ print? . ?body)
     (guard (E ((assertion-violation? E)
		(when print?
		  (check-pretty-print (condition-message E)))
		(condition-irritants E))
	       (else E))
       (begin . ?body)))))

(define-syntax doit
  (syntax-rules ()
    ((_ ?print ?validator . ?objs)
     (catch ?print
       (let ((who 'test))
	 (with-arguments-validation (who)
	     ((?validator . ?objs))
	   #t))))))


(parametrise ((check-test-name	'config))

  (check
      (eval 'config.arguments-validation
	    (environment '(prefix (vicare installation-configuration)
				  config.)))
    => #t)

  (check
      (begin
	(px.setenv "VICARE_ARGUMENTS_VALIDATION" "yes" #t)
	(eval 'config.arguments-validation
	      (environment '(prefix (vicare installation-configuration)
				    config.))))
    => #t)

  (check
      (begin
	(px.setenv "VICARE_ARGUMENTS_VALIDATION" "no" #t)
	(eval 'config.arguments-validation
	      (environment '(prefix (vicare installation-configuration)
				    config.))))
    => #f)

  (check
      (begin
	(px.setenv "VICARE_ARGUMENTS_VALIDATION" "1" #t)
	(eval 'config.arguments-validation
	      (environment '(prefix (vicare installation-configuration)
				    config.))))
    => #t)

  (check
      (begin
	(px.setenv "VICARE_ARGUMENTS_VALIDATION" "0" #t)
	(eval 'config.arguments-validation
	      (environment '(prefix (vicare installation-configuration)
				    config.))))
    => #f)

  (px.setenv "VICARE_ARGUMENTS_VALIDATION" "yes" #t))


(parametrise ((check-test-name	'validate-fixnums))

;;; fixnum

  (check
      (doit #f fixnum 123)
    => #t)

  (check
      (doit #f fixnum 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; fixnum/false

  (check
      (doit #f fixnum/false 123)
    => #t)

  (check
      (doit #f fixnum/false #f)
    => #t)

  (check
      (doit #f fixnum/false 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; positive-fixnum

  (check
      (doit #f positive-fixnum 123)
    => #t)

  (check
      (doit #f positive-fixnum 'ciao)
    => '(ciao))

  (check
      (doit #f positive-fixnum 0)
    => '(0))

  (check
      (doit #f positive-fixnum -1)
    => '(-1))

;;; --------------------------------------------------------------------
;;; negative-fixnum

  (check
      (doit #f negative-fixnum -123)
    => #t)

  (check
      (doit #f negative-fixnum 'ciao)
    => '(ciao))

  (check
      (doit #f negative-fixnum 0)
    => '(0))

  (check
      (doit #f negative-fixnum +1)
    => '(+1))

;;; --------------------------------------------------------------------
;;; non-positive-fixnum

  (check
      (doit #f non-positive-fixnum -123)
    => #t)

  (check
      (doit #f non-positive-fixnum 'ciao)
    => '(ciao))

  (check
      (doit #f non-positive-fixnum 0)
    => #t)

  (check
      (doit #f non-positive-fixnum +1)
    => '(+1))

;;; --------------------------------------------------------------------
;;; non-negative-fixnum

  (check
      (doit #f non-negative-fixnum +123)
    => #t)

  (check
      (doit #f non-negative-fixnum 'ciao)
    => '(ciao))

  (check
      (doit #f non-negative-fixnum 0)
    => #t)

  (check
      (doit #f non-negative-fixnum -1)
    => '(-1))

;;; --------------------------------------------------------------------
;;; fixnum-in-inclusive-range

  (check
      (doit #f fixnum-in-inclusive-range +123 100 200)
    => #t)

  (check
      (doit #f fixnum-in-inclusive-range +100 100 200)
    => #t)

  (check
      (doit #f fixnum-in-inclusive-range +200 100 200)
    => #t)

  (check
      (doit #f fixnum-in-inclusive-range 'ciao 100 200)
    => '(ciao))

  (check
      (doit #f fixnum-in-inclusive-range 0 100 200)
    => '(0))

;;; --------------------------------------------------------------------
;;; fixnum-in-exclusive-range

  (check
      (doit #f fixnum-in-exclusive-range +123 100 200)
    => #t)

  (check
      (doit #f fixnum-in-exclusive-range +100 100 200)
    => '(100))

  (check
      (doit #f fixnum-in-exclusive-range +200 100 200)
    => '(200))

  (check
      (doit #f fixnum-in-exclusive-range 'ciao 100 200)
    => '(ciao))

  (check
      (doit #f fixnum-in-exclusive-range 0 100 200)
    => '(0))

;;; --------------------------------------------------------------------
;;; even-fixnum

  (check
      (doit #f even-fixnum 2)
    => #t)

  (check
      (doit #f even-fixnum 3)
    => '(3))

  (check
      (doit #f even-fixnum -2)
    => #t)

  (check
      (doit #f even-fixnum -3)
    => '(-3))

  (check
      (doit #f even-fixnum 'ciao)
    => '(ciao))

  (check
      (doit #f even-fixnum 0)
    => #t)

;;; --------------------------------------------------------------------
;;; odd-fixnum

  (check
      (doit #f odd-fixnum 2)
    => '(2))

  (check
      (doit #f odd-fixnum 3)
    => #t)

  (check
      (doit #f odd-fixnum -2)
    => '(-2))

  (check
      (doit #f odd-fixnum -3)
    => #t)

  (check
      (doit #f odd-fixnum 'ciao)
    => '(ciao))

  (check
      (doit #f odd-fixnum 0)
    => '(0))

  #t)


(parametrise ((check-test-name	'validate-exact-integer))

;;; exact-integer

  (check
      (doit #f exact-integer 123)
    => #t)

  (check
      (doit #f exact-integer 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; exact-integer/false

  (check
      (doit #f exact-integer/false 123)
    => #t)

  (check
      (doit #f exact-integer/false #f)
    => #t)

  (check
      (doit #f exact-integer/false 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; positive-exact-integer

  (check
      (doit #f positive-exact-integer 123)
    => #t)

  (check
      (doit #f positive-exact-integer 'ciao)
    => '(ciao))

  (check
      (doit #f positive-exact-integer 0)
    => '(0))

  (check
      (doit #f positive-exact-integer -1)
    => '(-1))

;;; --------------------------------------------------------------------
;;; negative-exact-integer

  (check
      (doit #f negative-exact-integer -123)
    => #t)

  (check
      (doit #f negative-exact-integer 'ciao)
    => '(ciao))

  (check
      (doit #f negative-exact-integer 0)
    => '(0))

  (check
      (doit #f negative-exact-integer +1)
    => '(+1))

;;; --------------------------------------------------------------------
;;; non-positive-exact-integer

  (check
      (doit #f non-positive-exact-integer -123)
    => #t)

  (check
      (doit #f non-positive-exact-integer 'ciao)
    => '(ciao))

  (check
      (doit #f non-positive-exact-integer 0)
    => #t)

  (check
      (doit #f non-positive-exact-integer +1)
    => '(+1))

;;; --------------------------------------------------------------------
;;; non-negative-exact-integer

  (check
      (doit #f non-negative-exact-integer +123)
    => #t)

  (check
      (doit #f non-negative-exact-integer 'ciao)
    => '(ciao))

  (check
      (doit #f non-negative-exact-integer 0)
    => #t)

  (check
      (doit #f non-negative-exact-integer -1)
    => '(-1))

;;; --------------------------------------------------------------------
;;; exact-integer-in-inclusive-range

  (check
      (doit #f exact-integer-in-inclusive-range +123 100 200)
    => #t)

  (check
      (doit #f exact-integer-in-inclusive-range +100 100 200)
    => #t)

  (check
      (doit #f exact-integer-in-inclusive-range +200 100 200)
    => #t)

  (check
      (doit #f exact-integer-in-inclusive-range 'ciao 100 200)
    => '(ciao))

  (check
      (doit #f exact-integer-in-inclusive-range 0 100 200)
    => '(0))

;;; --------------------------------------------------------------------
;;; exact-integer-in-exclusive-range

  (check
      (doit #f exact-integer-in-exclusive-range +123 100 200)
    => #t)

  (check
      (doit #f exact-integer-in-exclusive-range +100 100 200)
    => '(100))

  (check
      (doit #f exact-integer-in-exclusive-range +200 100 200)
    => '(200))

  (check
      (doit #f exact-integer-in-exclusive-range 'ciao 100 200)
    => '(ciao))

  (check
      (doit #f exact-integer-in-exclusive-range 0 100 200)
    => '(0))

;;; --------------------------------------------------------------------
;;; even-exact-integer

  (check
      (doit #f even-exact-integer 2)
    => #t)

  (check
      (doit #f even-exact-integer 3)
    => '(3))

  (check
      (doit #f even-exact-integer -2)
    => #t)

  (check
      (doit #f even-exact-integer -3)
    => '(-3))

  (check
      (doit #f even-exact-integer 'ciao)
    => '(ciao))

  (check
      (doit #f even-exact-integer 0)
    => #t)

;;; --------------------------------------------------------------------
;;; odd-exact-integer

  (check
      (doit #f odd-exact-integer 2)
    => '(2))

  (check
      (doit #f odd-exact-integer 3)
    => #t)

  (check
      (doit #f odd-exact-integer -2)
    => '(-2))

  (check
      (doit #f odd-exact-integer -3)
    => #t)

  (check
      (doit #f odd-exact-integer 'ciao)
    => '(ciao))

  (check
      (doit #f odd-exact-integer 0)
    => '(0))

  #t)


(parametrise ((check-test-name	'validate-bits))

;;; u8

  (check
      (doit #f word-u8 123)
    => #t)

  (check
      (doit #f word-u8 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; s8

  (check
      (doit #f word-s8 123)
    => #t)

  (check
      (doit #f word-s8 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; u16

  (check
      (doit #f word-u16 123)
    => #t)

  (check
      (doit #f word-u16 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; s16

  (check
      (doit #f word-s16 123)
    => #t)

  (check
      (doit #f word-s16 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; u32

  (check
      (doit #f word-u32 123)
    => #t)

  (check
      (doit #f word-u32 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; s32

  (check
      (doit #f word-s32 123)
    => #t)

  (check
      (doit #f word-s32 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; u64

  (check
      (doit #f word-u64 123)
    => #t)

  (check
      (doit #f word-u64 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; s64

  (check
      (doit #f word-s64 123)
    => #t)

  (check
      (doit #f word-s64 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; u128

  (check
      (doit #f word-u128 123)
    => #t)

  (check
      (doit #f word-u128 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; s128

  (check
      (doit #f word-s128 123)
    => #t)

  (check
      (doit #f word-s128 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; u256

  (check
      (doit #f word-u256 123)
    => #t)

  (check
      (doit #f word-u256 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; s256

  (check
      (doit #f word-s256 123)
    => #t)

  (check
      (doit #f word-s256 'ciao)
    => '(ciao))

  #t)


(parametrise ((check-test-name	'validate-bits-false))

;;; u8/false

  (check
      (doit #f word-u8/false 123)
    => #t)

  (check
      (doit #f word-u8/false 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; s8/false

  (check
      (doit #f word-s8/false 123)
    => #t)

  (check
      (doit #f word-s8/false 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; u16/false

  (check
      (doit #f word-u16/false 123)
    => #t)

  (check
      (doit #f word-u16/false 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; s16/false

  (check
      (doit #f word-s16/false 123)
    => #t)

  (check
      (doit #f word-s16/false 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; u32/false

  (check
      (doit #f word-u32/false 123)
    => #t)

  (check
      (doit #f word-u32/false 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; s32/false

  (check
      (doit #f word-s32/false 123)
    => #t)

  (check
      (doit #f word-s32/false 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; u64/false

  (check
      (doit #f word-u64/false 123)
    => #t)

  (check
      (doit #f word-u64/false 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; s64/false

  (check
      (doit #f word-s64/false 123)
    => #t)

  (check
      (doit #f word-s64/false 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; u128/false

  (check
      (doit #f word-u128/false 123)
    => #t)

  (check
      (doit #f word-u128/false 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; s128/false

  (check
      (doit #f word-s128/false 123)
    => #t)

  (check
      (doit #f word-s128/false 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; u256/false

  (check
      (doit #f word-u256/false 123)
    => #t)

  (check
      (doit #f word-u256/false 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; s256/false

  (check
      (doit #f word-s256/false 123)
    => #t)

  (check
      (doit #f word-s256/false 'ciao)
    => '(ciao))

  #t)


(parametrise ((check-test-name	'validate-signed-int))

;;; signed-int

  (check
      (doit #f signed-int 123)
    => #t)

  (check
      (doit #f signed-int 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; signed-int/false

  (check
      (doit #f signed-int/false 123)
    => #t)

  (check
      (doit #f signed-int/false #f)
    => #t)

  (check
      (doit #f signed-int/false 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; positive-signed-int

  (check
      (doit #f positive-signed-int 123)
    => #t)

  (check
      (doit #f positive-signed-int 'ciao)
    => '(ciao))

  (check
      (doit #f positive-signed-int 0)
    => '(0))

  (check
      (doit #f positive-signed-int -1)
    => '(-1))

;;; --------------------------------------------------------------------
;;; negative-signed-int

  (check
      (doit #f negative-signed-int -123)
    => #t)

  (check
      (doit #f negative-signed-int 'ciao)
    => '(ciao))

  (check
      (doit #f negative-signed-int 0)
    => '(0))

  (check
      (doit #f negative-signed-int +1)
    => '(+1))

;;; --------------------------------------------------------------------
;;; non-positive-signed-int

  (check
      (doit #f non-positive-signed-int -123)
    => #t)

  (check
      (doit #f non-positive-signed-int 'ciao)
    => '(ciao))

  (check
      (doit #f non-positive-signed-int 0)
    => #t)

  (check
      (doit #f non-positive-signed-int +1)
    => '(+1))

;;; --------------------------------------------------------------------
;;; non-negative-signed-int

  (check
      (doit #f non-negative-signed-int +123)
    => #t)

  (check
      (doit #f non-negative-signed-int 'ciao)
    => '(ciao))

  (check
      (doit #f non-negative-signed-int 0)
    => #t)

  (check
      (doit #f non-negative-signed-int -1)
    => '(-1))

;;; --------------------------------------------------------------------
;;; signed-int-in-inclusive-range

  (check
      (doit #f signed-int-in-inclusive-range +123 100 200)
    => #t)

  (check
      (doit #f signed-int-in-inclusive-range +100 100 200)
    => #t)

  (check
      (doit #f signed-int-in-inclusive-range +200 100 200)
    => #t)

  (check
      (doit #f signed-int-in-inclusive-range 'ciao 100 200)
    => '(ciao))

  (check
      (doit #f signed-int-in-inclusive-range 0 100 200)
    => '(0))

;;; --------------------------------------------------------------------
;;; signed-int-in-exclusive-range

  (check
      (doit #f signed-int-in-exclusive-range +123 100 200)
    => #t)

  (check
      (doit #f signed-int-in-exclusive-range +100 100 200)
    => '(100))

  (check
      (doit #f signed-int-in-exclusive-range +200 100 200)
    => '(200))

  (check
      (doit #f signed-int-in-exclusive-range 'ciao 100 200)
    => '(ciao))

  (check
      (doit #f signed-int-in-exclusive-range 0 100 200)
    => '(0))

;;; --------------------------------------------------------------------
;;; even-signed-int

  (check
      (doit #f even-signed-int 2)
    => #t)

  (check
      (doit #f even-signed-int 3)
    => '(3))

  (check
      (doit #f even-signed-int -2)
    => #t)

  (check
      (doit #f even-signed-int -3)
    => '(-3))

  (check
      (doit #f even-signed-int 'ciao)
    => '(ciao))

  (check
      (doit #f even-signed-int 0)
    => #t)

;;; --------------------------------------------------------------------
;;; odd-signed-int

  (check
      (doit #f odd-signed-int 2)
    => '(2))

  (check
      (doit #f odd-signed-int 3)
    => #t)

  (check
      (doit #f odd-signed-int -2)
    => '(-2))

  (check
      (doit #f odd-signed-int -3)
    => #t)

  (check
      (doit #f odd-signed-int 'ciao)
    => '(ciao))

  (check
      (doit #f odd-signed-int 0)
    => '(0))

  #t)


(parametrise ((check-test-name	'validate-clang))

;;; unsigned-char

  (check
      (doit #f unsigned-char 123)
    => #t)

  (check
      (doit #f unsigned-char 500)
    => '(500))

  (check
      (doit #f unsigned-char -123)
    => '(-123))

  (check
      (doit #f unsigned-char 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; signed-char

  (check
      (doit #f signed-char 123)
    => #t)

  (check
      (doit #f signed-char 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; unsigned-short

  (check
      (doit #f unsigned-short 123)
    => #t)

  (check
      (doit #f unsigned-short 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; signed-short

  (check
      (doit #f signed-short 123)
    => #t)

  (check
      (doit #f signed-short 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; unsigned-int

  (check
      (doit #f unsigned-int 123)
    => #t)

  (check
      (doit #f unsigned-int 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; unsigned-long

  (check
      (doit #f unsigned-long 123)
    => #t)

  (check
      (doit #f unsigned-long 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; signed-long

  (check
      (doit #f signed-long 123)
    => #t)

  (check
      (doit #f signed-long 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; unsigned-long-long

  (check
      (doit #f unsigned-long-long 123)
    => #t)

  (check
      (doit #f unsigned-long-long 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; signed-long-long

  (check
      (doit #f signed-long-long 123)
    => #t)

  (check
      (doit #f signed-long-long 'ciao)
    => '(ciao))

  #t)


(parametrise ((check-test-name	'validate-clang-false))

;;; unsigned-char/false

  (check
      (doit #f unsigned-char/false 123)
    => #t)

  (check
      (doit #f unsigned-char/false 500)
    => '(500))

  (check
      (doit #f unsigned-char/false -123)
    => '(-123))

  (check
      (doit #f unsigned-char/false 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; signed-char/false

  (check
      (doit #f signed-char/false 123)
    => #t)

  (check
      (doit #f signed-char/false 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; unsigned-short/false

  (check
      (doit #f unsigned-short/false 123)
    => #t)

  (check
      (doit #f unsigned-short/false 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; signed-short/false

  (check
      (doit #f signed-short/false 123)
    => #t)

  (check
      (doit #f signed-short/false 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; unsigned-int/false

  (check
      (doit #f unsigned-int/false 123)
    => #t)

  (check
      (doit #f unsigned-int/false 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; unsigned-long/false

  (check
      (doit #f unsigned-long/false 123)
    => #t)

  (check
      (doit #f unsigned-long/false 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; signed-long/false

  (check
      (doit #f signed-long/false 123)
    => #t)

  (check
      (doit #f signed-long/false 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; unsigned-long-long/false

  (check
      (doit #f unsigned-long-long/false 123)
    => #t)

  (check
      (doit #f unsigned-long-long/false 'ciao)
    => '(ciao))

;;; --------------------------------------------------------------------
;;; signed-long-long/false

  (check
      (doit #f signed-long-long/false 123)
    => #t)

  (check
      (doit #f signed-long-long/false 'ciao)
    => '(ciao))

  #t)


;;;; done

(check-report)

;;; end of file
