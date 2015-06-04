;;; -*- coding: utf-8-unix -*-
;;;
;;;Part of: Vicare
;;;Contents: tests for bytevector's conversion functions
;;;Date: Tue Jun  2, 2015
;;;
;;;Abstract
;;;
;;;
;;;
;;;Copyright (C) 2015 Marco Maggi <marco.maggi-ipsu@poste.it>
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
  (prefix (vicare platform words) words.)
  #;(vicare system $bytevectors)
  (prefix (vicare unsafe unicode) unicode.)
  (vicare checks))

(check-set-mode! 'report-failed)
(check-display "*** testing Vicare bytevector conversion functions\n")

(printer-integer-radix 16)


;;;; helpers

(define* (code-point->utf16/2-words {code-point unicode.utf-16-two-words-code-point?})
  (values (unicode.utf-16-encode-first-of-two-words  code-point)
	  (unicode.utf-16-encode-second-of-two-words code-point)))

(define* (code-point->utf16/1-word {code-point unicode.utf-16-single-word-code-point?})
  (unicode.utf-16-encode-single-word code-point))

(define* (utf16-string-mirror/little {str string?})
  (utf16->string (string->utf16 str (endianness little)) (endianness little) #t))

(define* (utf16-string-mirror/big {str string?})
  (utf16->string (string->utf16 str (endianness big))    (endianness big) #t))



(parametrise ((check-test-name	'string-utf8))

  (check (utf8->string-length '#vu8())				=> 0)
  (check (utf8->string-length '#vu8(1 2 3))			=> 3)

  ;;BOM!!!
  (check (utf8->string-length '#vu8(#xEF #xBB #xBF))		=> 0)
  (check (utf8->string-length '#vu8(#xEF #xBB #xBF 1 2 3))	=> 3)

  ;;Invalid  sequence starting  with  valid  first byte  in  3-octet sequence.   When
  ;;ignoring or replacing: we process the whole triplet.
  (begin
    (check (utf8->string-length '#vu8(#xe0 #x67 #x0a) 'ignore)	=> 0)
    (check (utf8->string-length '#vu8(#xe0 #x67 #x0a) 'replace)	=> 1)
    (check
	(guard (E ((error? E)
		   #t)
		  (else E))
	  (utf8->string-length '#vu8(#xe0 #x67 #x0a) 'raise))
      => #t))

;;; --------------------------------------------------------------------

  (check (utf8->string '#vu8())				=> "")
  (check (utf8->string '#vu8(1 2 3))			=> "\x01;\x02;\x03;")

  ;;BOM!!!
  (check (utf8->string '#vu8(#xEF #xBB #xBF))		=> "")
  (check (utf8->string '#vu8(#xEF #xBB #xBF 1 2 3))	=> "\x01;\x02;\x03;")

  ;;Invalid  sequence starting  with  valid  first byte  in  3-octet sequence.   When
  ;;ignoring or replacing: we process the whole triplet.
  (begin
    (check (utf8->string '#vu8(#xe0 #x67 #x0a) 'ignore)		=> "")
    (check (utf8->string '#vu8(#xe0 #x67 #x0a) 'replace)	=> "\xFFFD;")
    (check
	(guard (E ((error? E)
		   #t)
		  (else E))
	  (utf8->string '#vu8(#xe0 #x67 #x0a) 'raise))
      => #t))

  #t)


(parametrise ((check-test-name	'string-utf16-length))

  ;; characters encoded with 1 word
  (check (utf16->string-length '#vu8(#x12 #x34) (endianness big))	=> 1)
  (check (utf16->string-length '#vu8(#x34 #x12) (endianness little))	=> 1)

  ;; characters encoded with 2 words
  (check (utf16->string-length '#vu8(#xAA #xBB) (endianness big))	=> 1)
  (check (utf16->string-length '#vu8(#xAA #xBB) (endianness little))	=> 1)

;;; --------------------------------------------------------------------

;;Code points in the  range [0, #x10000) are encoded with a  single UTF-16 word; code
;;points in the range [#x10000, #x10FFFF] are encoded in a surrogate pair.

  (check (string->utf16-length "\x00;")				=> 2)

  (check (string->utf16-length "\x00;\x01;\x02;\x03;")		=> 8)
  (check (string->utf16-length "\x00;\x01;\x02;\x03;")		=> 8)

  (check (string->utf16-length "\xFFFE;")				=> 2)
  (check (string->utf16-length "\xFFFE;")				=> 2)
  (check (utf16->string-length '#vu8(#xFF #xFE) (endianness big)    #t)	=> 1)
  (check (utf16->string-length '#vu8(#xFE #xFF) (endianness little) #t)	=> 1)

  ;;BOM processing:
  ;;
  ;;* #xFEFF is the BOM for big endian.
  ;;
  ;;* #xFFFE is the BOM for little endian.
  ;;
  ;;In all these tests: the endianness argument  is ignored; the BOM is processed; an
  ;;empty string is generated.
  (begin
    ;;Big endian BOM.
    (check (utf16->string-length '#vu8(#xFE #xFF) (endianness big)    #f)	=> 0)
    (check (utf16->string-length '#vu8(#xFE #xFF) (endianness little) #f)	=> 0)
    ;;Little endian BOM.
    (check (utf16->string-length '#vu8(#xFF #xFE) (endianness big)    #f)	=> 0)
    (check (utf16->string-length '#vu8(#xFF #xFE) (endianness little) #f)	=> 0))
  ;;In all these tests:  the endianness argument is ignored; the  BOM is processed; a
  ;;string of 1 character is generated.
  (begin
    ;;Big endian BOM.
    (check (utf16->string-length '#vu8(#xFE #xFF #xAA #xBB) (endianness big)    #f)	=> 1)
    (check (utf16->string-length '#vu8(#xFE #xFF #xAA #xBB) (endianness little) #f)	=> 1)
    ;;Little endian BOM.
    (check (utf16->string-length '#vu8(#xFF #xFE #xAA #xBB) (endianness big)    #f)	=> 1)
    (check (utf16->string-length '#vu8(#xFF #xFE #xAA #xBB) (endianness little) #f)	=> 1))

  ;; highest code point that is encoded with 1 16-bit word
  (begin
    (check (string->utf16-length "\xFFFF;")	=> 2))

;;; --------------------------------------------------------------------

  ;; lowest code point that is encoded with 2 16-bit words
  (begin
    (check (string->utf16-length "\x10000;")						=> 4)
    (check (string->utf16-length "\x10000;")						=> 4)
    (check (utf16->string-length '#vu8(#xD8 #x00 #xDC #x00) (endianness big))		=> 1)
    (check (utf16->string-length '#vu8(#x00 #xD8 #x00 #xDC) (endianness little))	=> 1))

  ;; generic code point that is encoded with 2 16-bit words
  (begin
    (check (string->utf16-length "\x12345;")						=> 4)
    (check (string->utf16-length "\x12345;")						=> 4)
    (check (utf16->string-length '#vu8(#xD8 #x08 #xDF #x45)	(endianness big))	=> 1)
    (check (utf16->string-length '#vu8(#x08 #xD8 #x45 #xDF)	(endianness little))	=> 1))

  ;; highest code point that is encoded with 2 16-bit words
  (begin
    (check (string->utf16-length "\x10FFFF;")						=> 4)
    (check (string->utf16-length "\x10FFFF;")						=> 4)
    (check (utf16->string-length '#vu8(#xDB #xFF #xDF #xFF)	(endianness big))	=> 1)
    (check (utf16->string-length '#vu8(#xFF #xDB #xFF #xDF)	(endianness little))	=> 1))

;;; --------------------------------------------------------------------
;;; error handling mode: replace

  (internal-body
    (define (do-big str)
      (utf16->string-length str (endianness big)    #f (error-handling-mode replace)))
    (define (do-lit str)
      (utf16->string-length str (endianness little) #f (error-handling-mode replace)))

    ;;The string "\x1234;" is encoded as:
    ;;
    ;;* With big endian:		#vu8(#x12 #x34)
    ;;
    ;;* With little endian:		#vu8(#x34 #x12)
    ;;

    ;;The string "\x12345;" is encoded as:
    ;;
    ;;* With big endian:		#vu8(#xD8 #x08 #xDF #x45)
    ;;
    ;;* With little endian:		#vu8(#x08 #xD8 #x45 #xDF)
    ;;

    ;;Error: replace mode, 1-word character, missing second octet.
    ;;
    (check (do-big '#vu8(#x00))				=> 1)
    (check (do-big '#vu8(#x12 #x34   #x00))		=> 2)
    (check (do-lit '#vu8(#x00))				=> 1)
    (check (do-lit '#vu8(#x34 #x12   #x00))		=> 2)

    ;;Error: replace mode, 2-words character, missing second octet of second word.
    ;;
    (check (do-big '#vu8(#xD8 #x08   #xDF))		=> 1)
    (check (do-big '#vu8(#x12 #x34   #xD8 #x08 #xDF))	=> 2)
    (check (do-lit '#vu8(#x08 #xD8   #xDF))		=> 1)
    (check (do-lit '#vu8(#x34 #x12   #x08 #xD8 #x45))	=> 2)

    ;;Error: replace mode, 2-words character, missing second word.
    ;;
    (check (do-big '#vu8(#xD8 #x08))			=> 1)
    (check (do-big '#vu8(#x12 #x34   #xD8 #x08))	=> 2)
    (check (do-lit '#vu8(#x08 #xD8))			=> 1)
    (check (do-lit '#vu8(#x34 #x12   #x08 #xD8))	=> 2)

    ;;Error: replace mode, 2-words character, missing second octet of first word.
    ;;
    (check (do-big '#vu8(#xD8))				=> 1)
    (check (do-big '#vu8(#x12 #x34   #xD8))		=> 2)
    (check (do-lit '#vu8(#x08))				=> 1)
    (check (do-lit '#vu8(#x34 #x12   #x08))		=> 2)

    #| end of INTERNAL-BODY |# )

;;; --------------------------------------------------------------------
;;; error handling mode: ignore

  (internal-body
    (define (do-big str)
      (utf16->string-length str (endianness big)    #f (error-handling-mode ignore)))
    (define (do-lit str)
      (utf16->string-length str (endianness little) #f (error-handling-mode ignore)))

    ;;The string "\x1234;" is encoded as:
    ;;
    ;;* With big endian:		#vu8(#x12 #x34)
    ;;
    ;;* With little endian:		#vu8(#x34 #x12)
    ;;

    ;;The string "\x12345;" is encoded as:
    ;;
    ;;* With big endian:		#vu8(#xD8 #x08 #xDF #x45)
    ;;
    ;;* With little endian:		#vu8(#x08 #xD8 #x45 #xDF)
    ;;

    ;;Error: ignore mode, 1-word character, missing second octet.
    ;;
    (check (do-big '#vu8(#x00))				=> 0)
    (check (do-big '#vu8(#x12 #x34   #x00))		=> 1)
    (check (do-lit '#vu8(#x00))				=> 0)
    (check (do-lit '#vu8(#x34 #x12   #x00))		=> 1)

    ;;Error: ignore mode, 2-words character, missing second octet of second word.
    ;;
    (check (do-big '#vu8(#xD8 #x08   #xDF))		=> 0)
    (check (do-big '#vu8(#x12 #x34   #xD8 #x08 #xDF))	=> 1)
    (check (do-lit '#vu8(#x08 #xD8   #xDF))		=> 0)
    (check (do-lit '#vu8(#x34 #x12   #x08 #xD8 #x45))	=> 1)

    ;;Error: ignore mode, 2-words character, missing second word.
    ;;
    (check (do-big '#vu8(#xD8 #x08))			=> 0)
    (check (do-big '#vu8(#x12 #x34   #xD8 #x08))	=> 1)
    (check (do-lit '#vu8(#x08 #xD8))			=> 0)
    (check (do-lit '#vu8(#x34 #x12   #x08 #xD8))	=> 1)

    ;;Error: ignore mode, 2-words character, missing second octet of first word.
    ;;
    (check (do-big '#vu8(#xD8))				=> 0)
    (check (do-big '#vu8(#x12 #x34   #xD8))		=> 1)
    (check (do-lit '#vu8(#x08))				=> 0)
    (check (do-lit '#vu8(#x34 #x12   #x08))		=> 1)

    #| end of INTERNAL-BODY |# )

;;; --------------------------------------------------------------------
;;; error handling mode: raise

  (internal-body
    (define (do-big str)
      (utf16->string-length str (endianness big)    #f (error-handling-mode raise)))
    (define (do-lit str)
      (utf16->string-length str (endianness little) #f (error-handling-mode raise)))

    ;;The string "\x1234;" is encoded as:
    ;;
    ;;* With big endian:		#vu8(#x12 #x34)
    ;;
    ;;* With little endian:		#vu8(#x34 #x12)
    ;;

    ;;The string "\x12345;" is encoded as:
    ;;
    ;;* With big endian:		#vu8(#xD8 #x08 #xDF #x45)
    ;;
    ;;* With little endian:		#vu8(#x08 #xD8 #x45 #xDF)
    ;;

    ;;Error: ignore mode, 1-word character, missing second octet.
    ;;
    (check
	(try
	    (do-big '#vu8(#x00))
	  (catch E
	    ((&utf16-string-decoding-standalone-octet)
	     (values (utf16-string-decoding-standalone-octet.index E)
		     (utf16-string-decoding-standalone-octet.octet E)))
	    (else E)))
      => 0 0)
    (check
	(try
	    (do-big '#vu8(#x12 #x34   #x00))
	  (catch E
	    ((&utf16-string-decoding-standalone-octet)
	     (values (utf16-string-decoding-standalone-octet.index E)
		     (utf16-string-decoding-standalone-octet.octet E)))
	    (else E)))
      => 2 0)
    (check
	(try
	    (do-lit '#vu8(#x00))
	  (catch E
	    ((&utf16-string-decoding-standalone-octet)
	     (values (utf16-string-decoding-standalone-octet.index E)
		     (utf16-string-decoding-standalone-octet.octet E)))
	    (else E)))
      => 0 0)
    (check
	(try
	    (do-lit '#vu8(#x34 #x12   #x00))
	  (catch E
	    ((&utf16-string-decoding-standalone-octet)
	     (values (utf16-string-decoding-standalone-octet.index E)
		     (utf16-string-decoding-standalone-octet.octet E)))
	    (else E)))
      => 2 0)

    ;;Error: ignore mode, 2-words character, missing second octet of second word.
    ;;
    (check
	(try
	    (do-big '#vu8(#xD8 #x08   #xDF))
	  (catch E
	    ((&utf16-string-decoding-standalone-octet)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-standalone-octet.index E)
		     (utf16-string-decoding-standalone-octet.octet E)))
	    (else E)))
      => 2 #xDF)
    (check
	(try
	    (do-big '#vu8(#x12 #x34   #xD8 #x08 #xDF))
	  (catch E
	    ((&utf16-string-decoding-standalone-octet)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-standalone-octet.index E)
		     (utf16-string-decoding-standalone-octet.octet E)))
	    (else E)))
      => 4 #xDF)
    (check
	(try
	    (do-lit '#vu8(#x08 #xD8   #xDF))
	  (catch E
	    ((&utf16-string-decoding-standalone-octet)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-standalone-octet.index E)
		     (utf16-string-decoding-standalone-octet.octet E)))
	    (else E)))
      => 2 #xDF)
    (check
	(try
	    (do-lit '#vu8(#x34 #x12   #x08 #xD8 #x45))
	  (catch E
	    ((&utf16-string-decoding-standalone-octet)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-standalone-octet.index E)
		     (utf16-string-decoding-standalone-octet.octet E)))
	    (else E)))
      => 4 #x45)

    ;;Error: ignore mode, 2-words character, missing second word.
    ;;
    (check
	(try
	    (do-big '#vu8(#xD8 #x08))
	  (catch E
	    ((&utf16-string-decoding-missing-second-word)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-missing-second-word.index E)
		     (utf16-string-decoding-missing-second-word.word E)))
	    (else E)))
      => 0 #xD808)
    (check
	(try
	    (do-big '#vu8(#x12 #x34   #xD8 #x08))
	  (catch E
	    ((&utf16-string-decoding-missing-second-word)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-missing-second-word.index E)
		     (utf16-string-decoding-missing-second-word.word E)))
	    (else E)))
      => 2 #xD808)
    (check
	(try
	    (do-lit '#vu8(#x08 #xD8))
	  (catch E
	    ((&utf16-string-decoding-missing-second-word)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-missing-second-word.index E)
		     (utf16-string-decoding-missing-second-word.word E)))
	    (else E)))
      => 0 #xD808)
    (check
	(try
	    (do-lit '#vu8(#x34 #x12   #x08 #xD8))
	  (catch E
	    ((&utf16-string-decoding-missing-second-word)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-missing-second-word.index E)
		     (utf16-string-decoding-missing-second-word.word E)))
	    (else E)))
      => 2 #xD808)

    ;;Error: ignore mode, 2-words character, missing second octet of first word.
    ;;
    (check
	(try
	    (do-big '#vu8(#xD8))
	  (catch E
	    ((&utf16-string-decoding-standalone-octet)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-standalone-octet.index E)
		     (utf16-string-decoding-standalone-octet.octet E)))
	    (else E)))
      => 0 #xD8)
    (check
	(try
	    (do-big '#vu8(#x12 #x34   #xD8))
	  (catch E
	    ((&utf16-string-decoding-standalone-octet)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-standalone-octet.index E)
		     (utf16-string-decoding-standalone-octet.octet E)))
	    (else E)))
      => 2 #xD8)
    (check
	(try
	    (do-lit '#vu8(#x08))
	  (catch E
	    ((&utf16-string-decoding-standalone-octet)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-standalone-octet.index E)
		     (utf16-string-decoding-standalone-octet.octet E)))
	    (else E)))
      => 0 #x08)
    (check
	(try
	    (do-lit '#vu8(#x34 #x12   #x08))
	  (catch E
	    ((&utf16-string-decoding-standalone-octet)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-standalone-octet.index E)
		     (utf16-string-decoding-standalone-octet.octet E)))
	    (else E)))
      => 2 #x08)

    ;;Error: ignore mode, 2-words character, invalid second word.
    ;;
    (check
	(try
	    (do-big '#vu8(#xD8 #x08 #x00 #x45))
	  (catch E
	    ((&utf16-string-decoding-invalid-second-word)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-invalid-second-word.index E)
		     (utf16-string-decoding-invalid-second-word.first-word E)
		     (utf16-string-decoding-invalid-second-word.second-word E)))
	    (else E)))
      => 2 #xD808 #x0045)
    (check
	(try
	    (do-big '#vu8(#x12 #x34   #xD8 #x08 #x00 #x45))
	  (catch E
	    ((&utf16-string-decoding-invalid-second-word)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-invalid-second-word.index E)
		     (utf16-string-decoding-invalid-second-word.first-word E)
		     (utf16-string-decoding-invalid-second-word.second-word E)))
	    (else E)))
      => 4 #xD808 #x0045)
    (check
	(try
	    (do-lit '#vu8(#x08 #xD8 #x45 #x00))
	  (catch E
	    ((&utf16-string-decoding-invalid-second-word)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-invalid-second-word.index E)
		     (utf16-string-decoding-invalid-second-word.first-word E)
		     (utf16-string-decoding-invalid-second-word.second-word E)))
	    (else E)))
      => 2 #xD808 #x0045)
    (check
	(try
	    (do-lit '#vu8(#x34 #x12   #x08 #xD8 #x45 #x00))
	  (catch E
	    ((&utf16-string-decoding-invalid-second-word)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-invalid-second-word.index E)
		     (utf16-string-decoding-invalid-second-word.first-word E)
		     (utf16-string-decoding-invalid-second-word.second-word E)))
	    (else E)))
      => 4 #xD808 #x0045)

    #| end of INTERNAL-BODY |# )

  #t)


(parametrise ((check-test-name	'string-utf16))

;;; tests for use in the documentation

  ;; characters encoded with 1 word
  (check (utf16->string '#vu8(#x12 #x34) (endianness big))	=> "\x1234;")
  (check (utf16->string '#vu8(#x34 #x12) (endianness little))	=> "\x1234;")

  ;; characters encoded with 2 words
  (check (utf16->string '#vu8(#xAA #xBB) (endianness big))	=> "\xAABB;")
  (check (utf16->string '#vu8(#xAA #xBB) (endianness little))	=> "\xBBAA;")

;;; --------------------------------------------------------------------

;;Code points in the  range [0, #x10000) are encoded with a  single UTF-16 word; code
;;points in the range [#x10000, #x10FFFF] are encoded in a surrogate pair.

  (check (string->utf16 "\x00;\x01;\x02;\x03;" (endianness big))	=> '#vu8(#x00 #x00   #x00 #x01   #x00 #x02   #x00 #x03))
  (check (string->utf16 "\x00;\x01;\x02;\x03;" (endianness little))	=> '#vu8(#x00 #x00   #x01 #x00   #x02 #x00   #x03 #x00))

  ;; code point that is encoded with 1 16-bit word, and it is equal to the BOM
  (begin
    (check (code-point->utf16/1-word #xFFFE)				=> #xFFFE)
    (check (string->utf16 "\xFFFE;"		(endianness big))	=> '#vu8(#xFF #xFE))
    (check (string->utf16 "\xFFFE;"		(endianness little))	=> '#vu8(#xFE #xFF))
    (check (utf16->string '#vu8(#xFF #xFE)	(endianness big)    #t)	=> "\xFFFE;")
    (check (utf16->string '#vu8(#xFE #xFF)	(endianness little) #t)	=> "\xFFFE;")
    (check (utf16-string-mirror/little "\xFFFE;")			=> "\xFFFE;")
    (check (utf16-string-mirror/big    "\xFFFE;")			=> "\xFFFE;"))

  ;;BOM processing:
  ;;
  ;;* #xFEFF is the BOM for big endian.
  ;;
  ;;* #xFFFE is the BOM for little endian.
  ;;
  ;;In all these tests: the endianness argument  is ignored; the BOM is processed; an
  ;;empty string is generated.
  (begin
    ;;Big endian BOM.
    (check (utf16->string '#vu8(#xFE #xFF) (endianness big)    #f)	=> "")
    (check (utf16->string '#vu8(#xFE #xFF) (endianness little) #f)	=> "")
    ;;Little endian BOM.
    (check (utf16->string '#vu8(#xFF #xFE) (endianness big)    #f)	=> "")
    (check (utf16->string '#vu8(#xFF #xFE) (endianness little) #f)	=> ""))
  ;;In all these tests:  the endianness argument is ignored; the  BOM is processed; a
  ;;string of 1 character is generated.
  (begin
    ;;Big endian BOM.
    (check (utf16->string '#vu8(#xFE #xFF #xAA #xBB) (endianness big)    #f)	=> "\xAABB;")
    (check (utf16->string '#vu8(#xFE #xFF #xAA #xBB) (endianness little) #f)	=> "\xAABB;")
    ;;Little endian BOM.
    (check (utf16->string '#vu8(#xFF #xFE #xAA #xBB) (endianness big)    #f)	=> "\xBBAA;")
    (check (utf16->string '#vu8(#xFF #xFE #xAA #xBB) (endianness little) #f)	=> "\xBBAA;"))

  ;; highest code point that is encoded with 1 16-bit word
  (begin
    (check (code-point->utf16/1-word #xFFFF)			=> #xFFFF)
    (check (string->utf16 "\xFFFF;" (endianness big))		=> '#vu8(#xFF #xFF))
    (check (string->utf16 "\xFFFF;" (endianness little))	=> '#vu8(#xFF #xFF))
    (check (utf16-string-mirror/little "\xFFFF;")		=> "\xFFFF;")
    (check (utf16-string-mirror/big    "\xFFFF;")		=> "\xFFFF;"))

;;; --------------------------------------------------------------------

  ;; lowest code point that is encoded with 2 16-bit words
  (begin
    (check (code-point->utf16/2-words #x10000)			=> #xD800 #xDC00)
    (check (string->utf16 "\x10000;" (endianness big))		=> '#vu8(#xD8 #x00 #xDC #x00))
    (check (string->utf16 "\x10000;" (endianness little))	=> '#vu8(#x00 #xD8 #x00 #xDC))
    (check (utf16-string-mirror/little "\x10000;")		=> "\x10000;")
    (check (utf16-string-mirror/big    "\x10000;")		=> "\x10000;"))

  ;; generic code point that is encoded with 2 16-bit words
  (begin
    (check (code-point->utf16/2-words #x12345)			=> #xD808 #xDF45)
    (check (string->utf16 "\x12345;" (endianness big))		=> '#vu8(#xD8 #x08 #xDF #x45))
    (check (string->utf16 "\x12345;" (endianness little))	=> '#vu8(#x08 #xD8 #x45 #xDF))
    (check (utf16-string-mirror/little "\x12345;")		=> "\x12345;")
    (check (utf16-string-mirror/big    "\x12345;")		=> "\x12345;"))

  ;; highest code point that is encoded with 2 16-bit words
  (begin
    (check (code-point->utf16/2-words #x10FFFF)			=> #xDBFF #xDFFF)
    (check (string->utf16 "\x10FFFF;" (endianness big))		=> '#vu8(#xDB #xFF #xDF #xFF))
    (check (string->utf16 "\x10FFFF;" (endianness little))	=> '#vu8(#xFF #xDB #xFF #xDF)))

;;; --------------------------------------------------------------------
;;; error handling mode: replace

  (internal-body
    (define (do-big str)
      (utf16->string str (endianness big)    #f (error-handling-mode replace)))
    (define (do-lit str)
      (utf16->string str (endianness little) #f (error-handling-mode replace)))

    ;;The string "\x1234;" is encoded as:
    ;;
    ;;* With big endian:		#vu8(#x12 #x34)
    ;;
    ;;* With little endian:		#vu8(#x34 #x12)
    ;;

    ;;The string "\x12345;" is encoded as:
    ;;
    ;;* With big endian:		#vu8(#xD8 #x08 #xDF #x45)
    ;;
    ;;* With little endian:		#vu8(#x08 #xD8 #x45 #xDF)
    ;;

    ;;Error: replace mode, 1-word character, missing second octet.
    ;;
    (check (do-big '#vu8(#x00))				=> "\xFFFD;")
    (check (do-big '#vu8(#x12 #x34   #x00))		=> "\x1234;\xFFFD;")
    (check (do-lit '#vu8(#x00))				=> "\xFFFD;")
    (check (do-lit '#vu8(#x34 #x12   #x00))		=> "\x1234;\xFFFD;")

    ;;Error: replace mode, 2-words character, missing second octet of second word.
    ;;
    (check (do-big '#vu8(#xD8 #x08   #xDF))		=> "\xFFFD;")
    (check (do-big '#vu8(#x12 #x34   #xD8 #x08 #xDF))	=> "\x1234;\xFFFD;")
    (check (do-lit '#vu8(#x08 #xD8   #xDF))		=> "\xFFFD;")
    (check (do-lit '#vu8(#x34 #x12   #x08 #xD8 #x45))	=> "\x1234;\xFFFD;")

    ;;Error: replace mode, 2-words character, missing second word.
    ;;
    (check (do-big '#vu8(#xD8 #x08))			=> "\xFFFD;")
    (check (do-big '#vu8(#x12 #x34   #xD8 #x08))	=> "\x1234;\xFFFD;")
    (check (do-lit '#vu8(#x08 #xD8))			=> "\xFFFD;")
    (check (do-lit '#vu8(#x34 #x12   #x08 #xD8))	=> "\x1234;\xFFFD;")

    ;;Error: replace mode, 2-words character, missing second octet of first word.
    ;;
    (check (do-big '#vu8(#xD8))				=> "\xFFFD;")
    (check (do-big '#vu8(#x12 #x34   #xD8))		=> "\x1234;\xFFFD;")
    (check (do-lit '#vu8(#x08))				=> "\xFFFD;")
    (check (do-lit '#vu8(#x34 #x12   #x08))		=> "\x1234;\xFFFD;")

    #| end of INTERNAL-BODY |# )

;;; --------------------------------------------------------------------
;;; error handling mode: ignore

  (internal-body
    (define (do-big str)
      (utf16->string str (endianness big)    #f (error-handling-mode ignore)))
    (define (do-lit str)
      (utf16->string str (endianness little) #f (error-handling-mode ignore)))

    ;;The string "\x1234;" is encoded as:
    ;;
    ;;* With big endian:		#vu8(#x12 #x34)
    ;;
    ;;* With little endian:		#vu8(#x34 #x12)
    ;;

    ;;The string "\x12345;" is encoded as:
    ;;
    ;;* With big endian:		#vu8(#xD8 #x08 #xDF #x45)
    ;;
    ;;* With little endian:		#vu8(#x08 #xD8 #x45 #xDF)
    ;;

    ;;Error: ignore mode, 1-word character, missing second octet.
    ;;
    (check (do-big '#vu8(#x00))				=> "")
    (check (do-big '#vu8(#x12 #x34   #x00))		=> "\x1234;")
    (check (do-lit '#vu8(#x00))				=> "")
    (check (do-lit '#vu8(#x34 #x12   #x00))		=> "\x1234;")

    ;;Error: ignore mode, 2-words character, missing second octet of second word.
    ;;
    (check (do-big '#vu8(#xD8 #x08   #xDF))		=> "")
    (check (do-big '#vu8(#x12 #x34   #xD8 #x08 #xDF))	=> "\x1234;")
    (check (do-lit '#vu8(#x08 #xD8   #xDF))		=> "")
    (check (do-lit '#vu8(#x34 #x12   #x08 #xD8 #x45))	=> "\x1234;")

    ;;Error: ignore mode, 2-words character, missing second word.
    ;;
    (check (do-big '#vu8(#xD8 #x08))			=> "")
    (check (do-big '#vu8(#x12 #x34   #xD8 #x08))	=> "\x1234;")
    (check (do-lit '#vu8(#x08 #xD8))			=> "")
    (check (do-lit '#vu8(#x34 #x12   #x08 #xD8))	=> "\x1234;")

    ;;Error: ignore mode, 2-words character, missing second octet of first word.
    ;;
    (check (do-big '#vu8(#xD8))				=> "")
    (check (do-big '#vu8(#x12 #x34   #xD8))		=> "\x1234;")
    (check (do-lit '#vu8(#x08))				=> "")
    (check (do-lit '#vu8(#x34 #x12   #x08))		=> "\x1234;")

    #| end of INTERNAL-BODY |# )

;;; --------------------------------------------------------------------
;;; error handling mode: raise

  (internal-body
    (define (do-big str)
      (utf16->string str (endianness big)    #f (error-handling-mode raise)))
    (define (do-lit str)
      (utf16->string str (endianness little) #f (error-handling-mode raise)))

    ;;The string "\x1234;" is encoded as:
    ;;
    ;;* With big endian:		#vu8(#x12 #x34)
    ;;
    ;;* With little endian:		#vu8(#x34 #x12)
    ;;

    ;;The string "\x12345;" is encoded as:
    ;;
    ;;* With big endian:		#vu8(#xD8 #x08 #xDF #x45)
    ;;
    ;;* With little endian:		#vu8(#x08 #xD8 #x45 #xDF)
    ;;

    ;;Error: ignore mode, 1-word character, missing second octet.
    ;;
    (check
	(try
	    (do-big '#vu8(#x00))
	  (catch E
	    ((&utf16-string-decoding-standalone-octet)
	     (values (utf16-string-decoding-standalone-octet.index E)
		     (utf16-string-decoding-standalone-octet.octet E)))
	    (else E)))
      => 0 0)
    (check
	(try
	    (do-big '#vu8(#x12 #x34   #x00))
	  (catch E
	    ((&utf16-string-decoding-standalone-octet)
	     (values (utf16-string-decoding-standalone-octet.index E)
		     (utf16-string-decoding-standalone-octet.octet E)))
	    (else E)))
      => 2 0)
    (check
	(try
	    (do-lit '#vu8(#x00))
	  (catch E
	    ((&utf16-string-decoding-standalone-octet)
	     (values (utf16-string-decoding-standalone-octet.index E)
		     (utf16-string-decoding-standalone-octet.octet E)))
	    (else E)))
      => 0 0)
    (check
	(try
	    (do-lit '#vu8(#x34 #x12   #x00))
	  (catch E
	    ((&utf16-string-decoding-standalone-octet)
	     (values (utf16-string-decoding-standalone-octet.index E)
		     (utf16-string-decoding-standalone-octet.octet E)))
	    (else E)))
      => 2 0)

    ;;Error: ignore mode, 2-words character, missing second octet of second word.
    ;;
    (check
	(try
	    (do-big '#vu8(#xD8 #x08   #xDF))
	  (catch E
	    ((&utf16-string-decoding-standalone-octet)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-standalone-octet.index E)
		     (utf16-string-decoding-standalone-octet.octet E)))
	    (else E)))
      => 2 #xDF)
    (check
	(try
	    (do-big '#vu8(#x12 #x34   #xD8 #x08 #xDF))
	  (catch E
	    ((&utf16-string-decoding-standalone-octet)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-standalone-octet.index E)
		     (utf16-string-decoding-standalone-octet.octet E)))
	    (else E)))
      => 4 #xDF)
    (check
	(try
	    (do-lit '#vu8(#x08 #xD8   #xDF))
	  (catch E
	    ((&utf16-string-decoding-standalone-octet)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-standalone-octet.index E)
		     (utf16-string-decoding-standalone-octet.octet E)))
	    (else E)))
      => 2 #xDF)
    (check
	(try
	    (do-lit '#vu8(#x34 #x12   #x08 #xD8 #x45))
	  (catch E
	    ((&utf16-string-decoding-standalone-octet)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-standalone-octet.index E)
		     (utf16-string-decoding-standalone-octet.octet E)))
	    (else E)))
      => 4 #x45)

    ;;Error: ignore mode, 2-words character, missing second word.
    ;;
    (check
	(try
	    (do-big '#vu8(#xD8 #x08))
	  (catch E
	    ((&utf16-string-decoding-missing-second-word)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-missing-second-word.index E)
		     (utf16-string-decoding-missing-second-word.word E)))
	    (else E)))
      => 0 #xD808)
    (check
	(try
	    (do-big '#vu8(#x12 #x34   #xD8 #x08))
	  (catch E
	    ((&utf16-string-decoding-missing-second-word)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-missing-second-word.index E)
		     (utf16-string-decoding-missing-second-word.word E)))
	    (else E)))
      => 2 #xD808)
    (check
	(try
	    (do-lit '#vu8(#x08 #xD8))
	  (catch E
	    ((&utf16-string-decoding-missing-second-word)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-missing-second-word.index E)
		     (utf16-string-decoding-missing-second-word.word E)))
	    (else E)))
      => 0 #xD808)
    (check
	(try
	    (do-lit '#vu8(#x34 #x12   #x08 #xD8))
	  (catch E
	    ((&utf16-string-decoding-missing-second-word)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-missing-second-word.index E)
		     (utf16-string-decoding-missing-second-word.word E)))
	    (else E)))
      => 2 #xD808)

    ;;Error: ignore mode, 2-words character, missing second octet of first word.
    ;;
    (check
	(try
	    (do-big '#vu8(#xD8))
	  (catch E
	    ((&utf16-string-decoding-standalone-octet)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-standalone-octet.index E)
		     (utf16-string-decoding-standalone-octet.octet E)))
	    (else E)))
      => 0 #xD8)
    (check
	(try
	    (do-big '#vu8(#x12 #x34   #xD8))
	  (catch E
	    ((&utf16-string-decoding-standalone-octet)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-standalone-octet.index E)
		     (utf16-string-decoding-standalone-octet.octet E)))
	    (else E)))
      => 2 #xD8)
    (check
	(try
	    (do-lit '#vu8(#x08))
	  (catch E
	    ((&utf16-string-decoding-standalone-octet)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-standalone-octet.index E)
		     (utf16-string-decoding-standalone-octet.octet E)))
	    (else E)))
      => 0 #x08)
    (check
	(try
	    (do-lit '#vu8(#x34 #x12   #x08))
	  (catch E
	    ((&utf16-string-decoding-standalone-octet)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-standalone-octet.index E)
		     (utf16-string-decoding-standalone-octet.octet E)))
	    (else E)))
      => 2 #x08)

    ;;Error: ignore mode, 2-words character, invalid second word.
    ;;
    (check
	(try
	    (do-big '#vu8(#xD8 #x08 #x00 #x45))
	  (catch E
	    ((&utf16-string-decoding-invalid-second-word)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-invalid-second-word.index E)
		     (utf16-string-decoding-invalid-second-word.first-word E)
		     (utf16-string-decoding-invalid-second-word.second-word E)))
	    (else E)))
      => 2 #xD808 #x0045)
    (check
	(try
	    (do-big '#vu8(#x12 #x34   #xD8 #x08 #x00 #x45))
	  (catch E
	    ((&utf16-string-decoding-invalid-second-word)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-invalid-second-word.index E)
		     (utf16-string-decoding-invalid-second-word.first-word E)
		     (utf16-string-decoding-invalid-second-word.second-word E)))
	    (else E)))
      => 4 #xD808 #x0045)
    (check
	(try
	    (do-lit '#vu8(#x08 #xD8 #x45 #x00))
	  (catch E
	    ((&utf16-string-decoding-invalid-second-word)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-invalid-second-word.index E)
		     (utf16-string-decoding-invalid-second-word.first-word E)
		     (utf16-string-decoding-invalid-second-word.second-word E)))
	    (else E)))
      => 2 #xD808 #x0045)
    (check
	(try
	    (do-lit '#vu8(#x34 #x12   #x08 #xD8 #x45 #x00))
	  (catch E
	    ((&utf16-string-decoding-invalid-second-word)
	     #;(debug-print (condition-message E))
	     (values (utf16-string-decoding-invalid-second-word.index E)
		     (utf16-string-decoding-invalid-second-word.first-word E)
		     (utf16-string-decoding-invalid-second-word.second-word E)))
	    (else E)))
      => 4 #xD808 #x0045)

    #| end of INTERNAL-BODY |# )

  #t)


(parametrise ((check-test-name	'string-utf32-length))

;;Unicode code points are exact integers in the ranges:
;;
;;   [0, #xD800)  (#xDFFF, #x10FFFF]
;;

;;; tests for documentation

  (check (string->utf32-length "\x0;")			=> 4)
  (check (string->utf32-length "\x10FFFF;")		=> 4)

  (check (string->utf32-length "\xABCD;")		=> 4)
  (check (string->utf32-length "\xABCD;\x1234;")	=> 8)
  (check (string->utf32-length "\xABCD;")		=> 4)
  (check (string->utf32-length "\xABCD;\x1234;")	=> 8)

  (check (utf32->string-length '#vu8(#x00 #x10 #xFF #xFF)			(endianness big))	=> 1)
  (check (utf32->string-length '#vu8(#x00 #x01 #x23 #x45  #x00 #x10 #xFF #xFF)	(endianness big))	=> 2)
  (check (utf32->string-length '#vu8(#xFF #xFF #x10 #x00)			(endianness little))	=> 1)
  (check (utf32->string-length '#vu8(#x45 #x23 #x10 #x00  #xFF #xFF #x10 #x00)	(endianness little))	=> 2)

;;; --------------------------------------------------------------------

  ;;BOM processing:
  ;;
  ;;* #x0000FEFF is the BOM for big endian.
  ;;
  ;;* #xFFFE0000 is the BOM for little endian.
  ;;
  ;;In all these tests: the endianness argument  is ignored; the BOM is processed; an
  ;;empty string is generated.
  (begin
    ;;Big endian BOM.
    (check (utf32->string-length '#vu8(#x00 #x00  #xFE #xFF) (endianness big)    #f)	=> 0)
    (check (utf32->string-length '#vu8(#x00 #x00  #xFE #xFF) (endianness little) #f)	=> 0)
    ;;Little endian BOM.
    (check (utf32->string-length '#vu8(#xFF #xFE  #x00 #x00) (endianness big)    #f)	=> 0)
    (check (utf32->string-length '#vu8(#xFF #xFE  #x00 #x00) (endianness little) #f)	=> 0))
  ;;In all these tests:  the endianness argument is ignored; the  BOM is processed; a
  ;;string of 1 character is generated.
  (begin
    ;;Big endian BOM.
    (check (utf32->string-length '#vu8(#x00 #x00  #xFE #xFF   #x00 #x10 #xFF #xFF) (endianness big)    #f)	=> 1)
    (check (utf32->string-length '#vu8(#x00 #x00  #xFE #xFF   #x00 #x10 #xFF #xFF) (endianness little) #f)	=> 1)
    ;;Little endian BOM.
    (check (utf32->string-length '#vu8(#xFF #xFE  #x00 #x00   #xFF #xFF #x10 #x00) (endianness big)    #f)	=> 1)
    (check (utf32->string-length '#vu8(#xFF #xFE  #x00 #x00   #xFF #xFF #x10 #x00) (endianness little) #f)	=> 1))

;;; --------------------------------------------------------------------
;;; error handling mode: replace

  (internal-body
    (define (do-big str)
      (utf32->string-length str (endianness big)    #f (error-handling-mode replace)))
    (define (do-lit str)
      (utf32->string-length str (endianness little) #f (error-handling-mode replace)))

    ;;The string "\xABCD;\x1234;" is encoded as:
    ;;
    ;;* With big endian:	#vu8(#x00 #x00 #xAB #xCD  #x00 #x00 #x12 #x34)
    ;;
    ;;* With little endian:	#vu8(#xCD #xAB #x00 #x00  #x34 #x12 #x00 #x00)
    ;;

    ;;Error: replace mode, orphan octets.
    ;;
    (check (do-big '#vu8(#x00 #x00 #xAB #xCD  #x00 #x00 #x12))			=> 2)
    (check (do-big '#vu8(#x00 #x00 #xAB #xCD  #x00 #x00))			=> 2)
    (check (do-big '#vu8(#x00 #x00 #xAB #xCD  #x00))				=> 2)
    (check (do-lit '#vu8(#xCD #xAB #x00 #x00  #x34 #x12 #x00))			=> 2)
    (check (do-lit '#vu8(#xCD #xAB #x00 #x00  #x34 #x12))			=> 2)
    (check (do-lit '#vu8(#xCD #xAB #x00 #x00  #x34))				=> 2)

    ;;Error: replace mode, wrong word.
    ;;
    (check (do-big '#vu8(#x00 #x00 #xAB #xCD  #xFF #x00 #x00 #xFF))		=> 2)
    (check (do-lit '#vu8(#xCD #xAB #x00 #x00  #x00 #x00 #x00 #xFF))		=> 2)

    #| end of INTERNAL-BODY |# )

;;; --------------------------------------------------------------------
;;; error handling mode: ignore

  (internal-body
    (define (do-big str)
      (utf32->string-length str (endianness big)    #f (error-handling-mode ignore)))
    (define (do-lit str)
      (utf32->string-length str (endianness little) #f (error-handling-mode ignore)))

    ;;The string "\xABCD;\x1234;" is encoded as:
    ;;
    ;;* With big endian:	#vu8(#x00 #x00 #xAB #xCD  #x00 #x00 #x12 #x34)
    ;;
    ;;* With little endian:	#vu8(#xCD #xAB #x00 #x00  #x34 #x12 #x00 #x00)
    ;;

    ;;Error: replace mode, orphan octets.
    ;;
    (check (do-big '#vu8(#x00 #x00 #x12))					=> 0)
    (check (do-big '#vu8(#x00 #x00))						=> 0)
    (check (do-big '#vu8(#x00))							=> 0)
    (check (do-big '#vu8(#x00 #x00 #xAB #xCD  #x00 #x00 #x12))			=> 1)
    (check (do-big '#vu8(#x00 #x00 #xAB #xCD  #x00 #x00))			=> 1)
    (check (do-big '#vu8(#x00 #x00 #xAB #xCD  #x00))				=> 1)
    (check (do-lit '#vu8(#x34 #x12 #x00))					=> 0)
    (check (do-lit '#vu8(#x34 #x12))						=> 0)
    (check (do-lit '#vu8(#x34))							=> 0)
    (check (do-lit '#vu8(#xCD #xAB #x00 #x00  #x34 #x12 #x00))			=> 1)
    (check (do-lit '#vu8(#xCD #xAB #x00 #x00  #x34 #x12))			=> 1)
    (check (do-lit '#vu8(#xCD #xAB #x00 #x00  #x34))				=> 1)

    ;;Error: replace mode, wrong word.
    ;;
    (check (do-big '#vu8(#xFF #x00 #x00 #xFF))					=> 0)
    (check (do-big '#vu8(#x00 #x00 #xAB #xCD  #xFF #x00 #x00 #xFF))		=> 1)
    (check (do-lit '#vu8(#x00 #x00 #x00 #xFF))					=> 0)
    (check (do-lit '#vu8(#xCD #xAB #x00 #x00  #x00 #x00 #x00 #xFF))		=> 1)

    #| end of INTERNAL-BODY |# )

;;; --------------------------------------------------------------------
;;; error handling mode: raise

  (internal-body
    (define (do-big str)
      (utf32->string-length str (endianness big)    #f (error-handling-mode raise)))
    (define (do-lit str)
      (utf32->string-length str (endianness little) #f (error-handling-mode raise)))

    ;;The string "\xABCD;\x1234;" is encoded as:
    ;;
    ;;* With big endian:	#vu8(#x00 #x00 #xAB #xCD  #x00 #x00 #x12 #x34)
    ;;
    ;;* With little endian:	#vu8(#xCD #xAB #x00 #x00  #x34 #x12 #x00 #x00)
    ;;

    ;;Error: raise mode, orphan octets.
    ;;
    (check
	(try
	    (do-big '#vu8(#x00 #x00 #x12))
	  (catch E
	    ((&utf32-string-decoding-orphan-octets)
	     (values (utf32-string-decoding-orphan-octets.index E)
		     (utf32-string-decoding-orphan-octets.octets E)))
	    (else E)))
      => 0 '(#x00 #x00 #x12))
    (check
	(try
	    (do-big '#vu8(#x00 #x00))
	  (catch E
	    ((&utf32-string-decoding-orphan-octets)
	     (values (utf32-string-decoding-orphan-octets.index E)
		     (utf32-string-decoding-orphan-octets.octets E)))
	    (else E)))
      => 0 '(#x00 #x00))
    (check
	(try
	    (do-big '#vu8(#x00))
	  (catch E
	    ((&utf32-string-decoding-orphan-octets)
	     (values (utf32-string-decoding-orphan-octets.index E)
		     (utf32-string-decoding-orphan-octets.octets E)))
	    (else E)))
      => 0 '(#x00))
    (check
	(try
	    (do-lit '#vu8(#x00 #x00 #x12))
	  (catch E
	    ((&utf32-string-decoding-orphan-octets)
	     (values (utf32-string-decoding-orphan-octets.index E)
		     (utf32-string-decoding-orphan-octets.octets E)))
	    (else E)))
      => 0 '(#x00 #x00 #x12))
    (check
	(try
	    (do-lit '#vu8(#x00 #x00))
	  (catch E
	    ((&utf32-string-decoding-orphan-octets)
	     (values (utf32-string-decoding-orphan-octets.index E)
		     (utf32-string-decoding-orphan-octets.octets E)))
	    (else E)))
      => 0 '(#x00 #x00))
    (check
	(try
	    (do-lit '#vu8(#x00))
	  (catch E
	    ((&utf32-string-decoding-orphan-octets)
	     (values (utf32-string-decoding-orphan-octets.index E)
		     (utf32-string-decoding-orphan-octets.octets E)))
	    (else E)))
      => 0 '(#x00))
    (check
	(try
	    (do-big '#vu8(#x00 #x00 #xAB #xCD  #x00 #x00 #x12))
	  (catch E
	    ((&utf32-string-decoding-orphan-octets)
	     (values (utf32-string-decoding-orphan-octets.index E)
		     (utf32-string-decoding-orphan-octets.octets E)))
	    (else E)))
      => 4 '(#x00 #x00 #x12))
    (check
	(try
	    (do-big '#vu8(#x00 #x00 #xAB #xCD  #x00 #x00))
	  (catch E
	    ((&utf32-string-decoding-orphan-octets)
	     (values (utf32-string-decoding-orphan-octets.index E)
		     (utf32-string-decoding-orphan-octets.octets E)))
	    (else E)))
      => 4 '(#x00 #x00))
    (check
	(try
	    (do-big '#vu8(#x00 #x00 #xAB #xCD  #x00))
	  (catch E
	    ((&utf32-string-decoding-orphan-octets)
	     (values (utf32-string-decoding-orphan-octets.index E)
		     (utf32-string-decoding-orphan-octets.octets E)))
	    (else E)))
      => 4 '(#x00))
    (check
	(try
	    (do-lit '#vu8(#xCD #xAB #x00 #x00  #x00 #x00 #x12))
	  (catch E
	    ((&utf32-string-decoding-orphan-octets)
	     (values (utf32-string-decoding-orphan-octets.index E)
		     (utf32-string-decoding-orphan-octets.octets E)))
	    (else E)))
      => 4 '(#x00 #x00 #x12))
    (check
	(try
	    (do-lit '#vu8(#xCD #xAB #x00 #x00  #x00 #x00))
	  (catch E
	    ((&utf32-string-decoding-orphan-octets)
	     (values (utf32-string-decoding-orphan-octets.index E)
		     (utf32-string-decoding-orphan-octets.octets E)))
	    (else E)))
      => 4 '(#x00 #x00))
    (check
	(try
	    (do-lit '#vu8(#xCD #xAB #x00 #x00  #x00))
	  (catch E
	    ((&utf32-string-decoding-orphan-octets)
	     (values (utf32-string-decoding-orphan-octets.index E)
		     (utf32-string-decoding-orphan-octets.octets E)))
	    (else E)))
      => 4 '(#x00))

    ;;Error: replace mode, wrong word.
    ;;
    (check
	(try
	    (do-big '#vu8(#xFF #x00 #x00 #x00))
	  (catch E
	    ((&utf32-string-decoding-invalid-word)
	     #;(debug-print (condition-message E))
	     (values (utf32-string-decoding-invalid-word.index E)
		     (utf32-string-decoding-invalid-word.word E)))
	    (else E)))
      => 0 #xFF000000)
    (check
	(try
	    (do-big '#vu8(#x00 #x00 #xAB #xCD  #xFF #x00 #x00 #x00))
	  (catch E
	    ((&utf32-string-decoding-invalid-word)
	     #;(debug-print (condition-message E))
	     (values (utf32-string-decoding-invalid-word.index E)
		     (utf32-string-decoding-invalid-word.word E)))
	    (else E)))
      => 4 #xFF000000)
    (check
	(try
	    (do-lit '#vu8(#x00 #x00 #x00 #xFF))
	  (catch E
	    ((&utf32-string-decoding-invalid-word)
	     #;(debug-print (condition-message E))
	     (values (utf32-string-decoding-invalid-word.index E)
		     (utf32-string-decoding-invalid-word.word E)))
	    (else E)))
      => 0 #xFF000000)
    (check
	(try
	    (do-lit '#vu8(#xCD #xAB #x00 #x00  #x00 #x00 #x00 #xFF))
	  (catch E
	    ((&utf32-string-decoding-invalid-word)
	     #;(debug-print (condition-message E))
	     (values (utf32-string-decoding-invalid-word.index E)
		     (utf32-string-decoding-invalid-word.word E)))
	    (else E)))
      => 4 #xFF000000)

    #| end of INTERNAL-BODY |# )

  #t)


(parametrise ((check-test-name	'string-utf32))

;;; tests for documentation

  (check (string->utf32 "\xABCD;"		(endianness big))	=> '#vu8(#x00 #x00 #xAB #xCD))
  (check (string->utf32 "\xABCD;\x1234;"	(endianness big))	=> '#vu8(#x00 #x00 #xAB #xCD  #x00 #x00 #x12 #x34))
  (check (string->utf32 "\xABCD;"		(endianness little))	=> '#vu8(#xCD #xAB #x00 #x00))
  (check (string->utf32 "\xABCD;\x1234;"	(endianness little))	=> '#vu8(#xCD #xAB #x00 #x00  #x34 #x12 #x00 #x00))

  (check (utf32->string '#vu8(#x00 #x00 #xAB #xCD)			(endianness big))	=> "\xABCD;")
  (check (utf32->string '#vu8(#x00 #x00 #xAB #xCD  #x00 #x00 #x12 #x34)	(endianness big))	=> "\xABCD;\x1234;")
  (check (utf32->string '#vu8(#xCD #xAB #x00 #x00)			(endianness little))	=> "\xABCD;")
  (check (utf32->string '#vu8(#xCD #xAB #x00 #x00  #x34 #x12 #x00 #x00)	(endianness little))	=> "\xABCD;\x1234;")

;;; --------------------------------------------------------------------

  ;;BOM processing:
  ;;
  ;;* #x0000FEFF is the BOM for big endian.
  ;;
  ;;* #xFFFE0000 is the BOM for little endian.
  ;;
  ;;In all these tests: the endianness argument  is ignored; the BOM is processed; an
  ;;empty string is generated.
  (begin
    ;;Big endian BOM.
    (check (utf32->string '#vu8(#x00 #x00  #xFE #xFF) (endianness big)    #f)	=> "")
    (check (utf32->string '#vu8(#x00 #x00  #xFE #xFF) (endianness little) #f)	=> "")
    ;;Little endian BOM.
    (check (utf32->string '#vu8(#xFF #xFE  #x00 #x00) (endianness big)    #f)	=> "")
    (check (utf32->string '#vu8(#xFF #xFE  #x00 #x00) (endianness little) #f)	=> ""))
  ;;In all these tests:  the endianness argument is ignored; the  BOM is processed; a
  ;;string of 1 character is generated.
  (begin
    ;;Big endian BOM.
    (check (utf32->string '#vu8(#x00 #x00  #xFE #xFF   #x00 #x10 #xFF #xFF) (endianness big)    #f)	=> "\x10FFFF;")
    (check (utf32->string '#vu8(#x00 #x00  #xFE #xFF   #x00 #x10 #xFF #xFF) (endianness little) #f)	=> "\x10FFFF;")
    ;;Little endian BOM.
    (check (utf32->string '#vu8(#xFF #xFE  #x00 #x00   #xFF #xFF #x10 #x00) (endianness big)    #f)	=> "\x10FFFF;")
    (check (utf32->string '#vu8(#xFF #xFE  #x00 #x00   #xFF #xFF #x10 #x00) (endianness little) #f)	=> "\x10FFFF;"))

;;; --------------------------------------------------------------------
;;; error handling mode: replace

  (internal-body
    (define (do-big str)
      (utf32->string str (endianness big)    #f (error-handling-mode replace)))
    (define (do-lit str)
      (utf32->string str (endianness little) #f (error-handling-mode replace)))

    ;;The string "\xABCD;\x1234;" is encoded as:
    ;;
    ;;* With big endian:	#vu8(#x00 #x00 #xAB #xCD  #x00 #x00 #x12 #x34)
    ;;
    ;;* With little endian:	#vu8(#xCD #xAB #x00 #x00  #x34 #x12 #x00 #x00)
    ;;

    ;;Error: replace mode, orphan octets.
    ;;
    (check (do-big '#vu8(#x00 #x00 #xAB #xCD  #x00 #x00 #x12))			=> "\xABCD;\xFFFD;")
    (check (do-big '#vu8(#x00 #x00 #xAB #xCD  #x00 #x00))			=> "\xABCD;\xFFFD;")
    (check (do-big '#vu8(#x00 #x00 #xAB #xCD  #x00))				=> "\xABCD;\xFFFD;")
    (check (do-lit '#vu8(#xCD #xAB #x00 #x00  #x34 #x12 #x00))			=> "\xABCD;\xFFFD;")
    (check (do-lit '#vu8(#xCD #xAB #x00 #x00  #x34 #x12))			=> "\xABCD;\xFFFD;")
    (check (do-lit '#vu8(#xCD #xAB #x00 #x00  #x34))				=> "\xABCD;\xFFFD;")

    ;;Error: replace mode, wrong word.
    ;;
    (check (do-big '#vu8(#x00 #x00 #xAB #xCD  #xFF #x00 #x00 #xFF))		=> "\xABCD;\xFFFD;")
    (check (do-lit '#vu8(#xCD #xAB #x00 #x00  #x00 #x00 #x00 #xFF))		=> "\xABCD;\xFFFD;")

    #| end of INTERNAL-BODY |# )

;;; --------------------------------------------------------------------
;;; error handling mode: ignore

  (internal-body
    (define (do-big str)
      (utf32->string str (endianness big)    #f (error-handling-mode ignore)))
    (define (do-lit str)
      (utf32->string str (endianness little) #f (error-handling-mode ignore)))

    ;;The string "\xABCD;\x1234;" is encoded as:
    ;;
    ;;* With big endian:	#vu8(#x00 #x00 #xAB #xCD  #x00 #x00 #x12 #x34)
    ;;
    ;;* With little endian:	#vu8(#xCD #xAB #x00 #x00  #x34 #x12 #x00 #x00)
    ;;

    ;;Error: replace mode, orphan octets.
    ;;
    (check (do-big '#vu8(#x00 #x00 #x12))					=> "")
    (check (do-big '#vu8(#x00 #x00))						=> "")
    (check (do-big '#vu8(#x00))							=> "")
    (check (do-big '#vu8(#x00 #x00 #xAB #xCD  #x00 #x00 #x12))			=> "\xABCD;")
    (check (do-big '#vu8(#x00 #x00 #xAB #xCD  #x00 #x00))			=> "\xABCD;")
    (check (do-big '#vu8(#x00 #x00 #xAB #xCD  #x00))				=> "\xABCD;")
    (check (do-lit '#vu8(#x34 #x12 #x00))					=> "")
    (check (do-lit '#vu8(#x34 #x12))						=> "")
    (check (do-lit '#vu8(#x34))							=> "")
    (check (do-lit '#vu8(#xCD #xAB #x00 #x00  #x34 #x12 #x00))			=> "\xABCD;")
    (check (do-lit '#vu8(#xCD #xAB #x00 #x00  #x34 #x12))			=> "\xABCD;")
    (check (do-lit '#vu8(#xCD #xAB #x00 #x00  #x34))				=> "\xABCD;")

    ;;Error: replace mode, wrong word.
    ;;
    (check (do-big '#vu8(#xFF #x00 #x00 #xFF))					=> "")
    (check (do-big '#vu8(#x00 #x00 #xAB #xCD  #xFF #x00 #x00 #xFF))		=> "\xABCD;")
    (check (do-lit '#vu8(#x00 #x00 #x00 #xFF))					=> "")
    (check (do-lit '#vu8(#xCD #xAB #x00 #x00  #x00 #x00 #x00 #xFF))		=> "\xABCD;")

    #| end of INTERNAL-BODY |# )

;;; --------------------------------------------------------------------
;;; error handling mode: raise

  (internal-body
    (define (do-big str)
      (utf32->string str (endianness big)    #f (error-handling-mode raise)))
    (define (do-lit str)
      (utf32->string str (endianness little) #f (error-handling-mode raise)))

    ;;The string "\xABCD;\x1234;" is encoded as:
    ;;
    ;;* With big endian:	#vu8(#x00 #x00 #xAB #xCD  #x00 #x00 #x12 #x34)
    ;;
    ;;* With little endian:	#vu8(#xCD #xAB #x00 #x00  #x34 #x12 #x00 #x00)
    ;;

    ;;Error: raise mode, orphan octets.
    ;;
    (check
	(try
	    (do-big '#vu8(#x00 #x00 #x12))
	  (catch E
	    ((&utf32-string-decoding-orphan-octets)
	     (values (utf32-string-decoding-orphan-octets.index E)
		     (utf32-string-decoding-orphan-octets.octets E)))
	    (else E)))
      => 0 '(#x00 #x00 #x12))
    (check
	(try
	    (do-big '#vu8(#x00 #x00))
	  (catch E
	    ((&utf32-string-decoding-orphan-octets)
	     (values (utf32-string-decoding-orphan-octets.index E)
		     (utf32-string-decoding-orphan-octets.octets E)))
	    (else E)))
      => 0 '(#x00 #x00))
    (check
	(try
	    (do-big '#vu8(#x00))
	  (catch E
	    ((&utf32-string-decoding-orphan-octets)
	     (values (utf32-string-decoding-orphan-octets.index E)
		     (utf32-string-decoding-orphan-octets.octets E)))
	    (else E)))
      => 0 '(#x00))
    (check
	(try
	    (do-lit '#vu8(#x00 #x00 #x12))
	  (catch E
	    ((&utf32-string-decoding-orphan-octets)
	     (values (utf32-string-decoding-orphan-octets.index E)
		     (utf32-string-decoding-orphan-octets.octets E)))
	    (else E)))
      => 0 '(#x00 #x00 #x12))
    (check
	(try
	    (do-lit '#vu8(#x00 #x00))
	  (catch E
	    ((&utf32-string-decoding-orphan-octets)
	     (values (utf32-string-decoding-orphan-octets.index E)
		     (utf32-string-decoding-orphan-octets.octets E)))
	    (else E)))
      => 0 '(#x00 #x00))
    (check
	(try
	    (do-lit '#vu8(#x00))
	  (catch E
	    ((&utf32-string-decoding-orphan-octets)
	     (values (utf32-string-decoding-orphan-octets.index E)
		     (utf32-string-decoding-orphan-octets.octets E)))
	    (else E)))
      => 0 '(#x00))
    (check
	(try
	    (do-big '#vu8(#x00 #x00 #xAB #xCD  #x00 #x00 #x12))
	  (catch E
	    ((&utf32-string-decoding-orphan-octets)
	     (values (utf32-string-decoding-orphan-octets.index E)
		     (utf32-string-decoding-orphan-octets.octets E)))
	    (else E)))
      => 4 '(#x00 #x00 #x12))
    (check
	(try
	    (do-big '#vu8(#x00 #x00 #xAB #xCD  #x00 #x00))
	  (catch E
	    ((&utf32-string-decoding-orphan-octets)
	     (values (utf32-string-decoding-orphan-octets.index E)
		     (utf32-string-decoding-orphan-octets.octets E)))
	    (else E)))
      => 4 '(#x00 #x00))
    (check
	(try
	    (do-big '#vu8(#x00 #x00 #xAB #xCD  #x00))
	  (catch E
	    ((&utf32-string-decoding-orphan-octets)
	     (values (utf32-string-decoding-orphan-octets.index E)
		     (utf32-string-decoding-orphan-octets.octets E)))
	    (else E)))
      => 4 '(#x00))
    (check
	(try
	    (do-lit '#vu8(#xCD #xAB #x00 #x00  #x00 #x00 #x12))
	  (catch E
	    ((&utf32-string-decoding-orphan-octets)
	     (values (utf32-string-decoding-orphan-octets.index E)
		     (utf32-string-decoding-orphan-octets.octets E)))
	    (else E)))
      => 4 '(#x00 #x00 #x12))
    (check
	(try
	    (do-lit '#vu8(#xCD #xAB #x00 #x00  #x00 #x00))
	  (catch E
	    ((&utf32-string-decoding-orphan-octets)
	     (values (utf32-string-decoding-orphan-octets.index E)
		     (utf32-string-decoding-orphan-octets.octets E)))
	    (else E)))
      => 4 '(#x00 #x00))
    (check
	(try
	    (do-lit '#vu8(#xCD #xAB #x00 #x00  #x00))
	  (catch E
	    ((&utf32-string-decoding-orphan-octets)
	     (values (utf32-string-decoding-orphan-octets.index E)
		     (utf32-string-decoding-orphan-octets.octets E)))
	    (else E)))
      => 4 '(#x00))

    ;;Error: replace mode, wrong word.
    ;;
    (check
	(try
	    (do-big '#vu8(#xFF #x00 #x00 #x00))
	  (catch E
	    ((&utf32-string-decoding-invalid-word)
	     #;(debug-print (condition-message E))
	     (values (utf32-string-decoding-invalid-word.index E)
		     (utf32-string-decoding-invalid-word.word E)))
	    (else E)))
      => 0 #xFF000000)
    (check
	(try
	    (do-big '#vu8(#x00 #x00 #xAB #xCD  #xFF #x00 #x00 #x00))
	  (catch E
	    ((&utf32-string-decoding-invalid-word)
	     #;(debug-print (condition-message E))
	     (values (utf32-string-decoding-invalid-word.index E)
		     (utf32-string-decoding-invalid-word.word E)))
	    (else E)))
      => 4 #xFF000000)
    (check
	(try
	    (do-lit '#vu8(#x00 #x00 #x00 #xFF))
	  (catch E
	    ((&utf32-string-decoding-invalid-word)
	     #;(debug-print (condition-message E))
	     (values (utf32-string-decoding-invalid-word.index E)
		     (utf32-string-decoding-invalid-word.word E)))
	    (else E)))
      => 0 #xFF000000)
    (check
	(try
	    (do-lit '#vu8(#xCD #xAB #x00 #x00  #x00 #x00 #x00 #xFF))
	  (catch E
	    ((&utf32-string-decoding-invalid-word)
	     #;(debug-print (condition-message E))
	     (values (utf32-string-decoding-invalid-word.index E)
		     (utf32-string-decoding-invalid-word.word E)))
	    (else E)))
      => 4 #xFF000000)

    #| end of INTERNAL-BODY |# )

  #t)


;;;; done

(printer-integer-radix 10)
(check-report)

;;; end of file
;;Local Variables:
;;eval: (put 'with-check-for-procedure-argument-validation 'scheme-indent-function 1)
;;End:

