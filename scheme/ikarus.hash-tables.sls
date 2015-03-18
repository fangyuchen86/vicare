;;;Ikarus Scheme -- A compiler for R6RS Scheme.
;;;Copyright (C) 2006,2007,2008  Abdulaziz Ghuloum
;;;Mofified by Marco Maggi <marco.maggi-ipsu@poste.it>
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


;;See the paper:
;;
;;  Ghuloum, Dybvig.  "Generation-Friendly Eq Hash Tables".  Proceedings
;;  of the 2007 Workshop on Scheme and Functional Programming.
;;


#!vicare
(library (ikarus hash-tables)
  (export
    make-eq-hashtable		make-eqv-hashtable	make-hashtable
    hashtable?			hashtable-mutable?	mutable-hashtable?
    hashtable-ref		hashtable-set!
    hashtable-size
    hashtable-delete!		hashtable-clear!
    hashtable-contains?
    hashtable-update!
    hashtable-keys		hashtable-entries
    hashtable-copy
    hashtable-equivalence-function
    hashtable-hash-function

    ;; hash functions
    string-hash			string-ci-hash
    symbol-hash			bytevector-hash
    equal-hash
    fixnum-hash			exact-integer-hash
    flonum-hash			number-hash
    char-hash			char-ci-hash
    boolean-hash		void-hash
    eof-object-hash		would-block-hash
    struct-hash			record-hash
    object-hash

    ;; unsafe operations
    $string-hash		$string-ci-hash
    $symbol-hash		$bytevector-hash)
  (import (except (vicare)
		  make-eq-hashtable		make-eqv-hashtable
		  make-hashtable
		  hashtable?			hashtable-mutable?	mutable-hashtable?
		  hashtable-ref			hashtable-set!
		  hashtable-size
		  hashtable-delete!		hashtable-clear!
		  hashtable-contains?
		  hashtable-update!
		  hashtable-keys		hashtable-entries
		  hashtable-copy
		  hashtable-equivalence-function
		  hashtable-hash-function
		  string-hash			string-ci-hash
		  symbol-hash			bytevector-hash
		  equal-hash
		  fixnum-hash			exact-integer-hash
		  flonum-hash			number-hash
		  char-hash			char-ci-hash
		  boolean-hash			void-hash
		  eof-object-hash		would-block-hash
		  struct-hash			record-hash
		  object-hash)
    (vicare system $bignums)
    (vicare system $chars)
    (vicare system $compnums)
    (vicare system $flonums)
    (vicare system $fx)
    (vicare system $numerics)
    (vicare system $pairs)
    (vicare system $ratnums)
    (vicare system $tcbuckets)
    (vicare system $vectors))


;;;; helpers

(define (%initial-capacity? obj)
  (and (or (fixnum? obj)
	   (bignum? obj))
       (>= obj 0)))

(define (%boolean-or-non-negative-fixnum? obj)
  (or (boolean? obj)
      (and (fixnum? obj)
	   (fxnonnegative? obj))))

(define (%not-void? obj)
  (not (eq? obj (void))))


;;;; data structure

(define-struct hasht
  (buckets-vector
		;Scheme vector representing the tables' buckets vector.
   size
		;Non-negative fixnum representing the number of entries in the table.
		;Limiting this value to a fixnum is a constraint deriving from:
		;
		;* The R6RS, which includes in  the API functions that return vectors
		;  holding all the keys and values in the table.
		;
		;* The implementation  of Vicare, which defines vectors  as having at
		;  most (greatest-fixnum) elements.
   tc
   mutable?
		;Boolean.   True if  values can  be added  to and  removed from  this
		;hashtable; otherwise false.
   hashf
		;The hash function  to be used to compute keys's  hash values.  It is
		;the same  value of  the field  HASHF0 only  if it  is one  among the
		;built-in hash functions,  otherwise it is a wrapper  for HASHF0 that
		;validates the return value as exact integer.
   equivf
		;The equivalence function given to the constructor of this struct.
   hashf0
		;The hash function given to the constructor of this struct.
   ))


;;;; directly from Dybvig's paper

(define (tc-pop tc)
  (let ((x ($car tc)))
    (if (eq? x ($cdr tc))
	#f
      (let ((v ($car x)))
	($set-car! tc ($cdr x))
	($set-car! x #f)
	($set-cdr! x #f)
	v))))

;; assq-like lookup
(define (direct-lookup x b)
  (if (fixnum? b)
      #f
    (if (eq? x ($tcbucket-key b))
	b
      (direct-lookup x ($tcbucket-next b)))))

(define (rehash-lookup h tc x)
  (cond ((tc-pop tc)
	 => (lambda (b)
	      (if (eq? ($tcbucket-next b) #f)
		  (rehash-lookup h tc x)
		(begin
		  (re-add! h b)
		  (if (eq? x ($tcbucket-key b))
		      b
		    (rehash-lookup h tc x))))))
	(else #f)))

(define (get-bucket-index b)
  (let ((next ($tcbucket-next b)))
    (if (fixnum? next)
	next
      (get-bucket-index next))))

(define (replace! lb x y)
  (let ((n ($tcbucket-next lb)))
    (cond ((eq? n x)
	   ($set-tcbucket-next! lb y)
	   (void))
	  (else
	   (replace! n x y)))))

(define (re-add! h b)
  (let ((vec (hasht-buckets-vector h))
	(next ($tcbucket-next b)))
    ;; first remove it from its old place
    (let ((idx
	   (if (fixnum? next)
	       next
	     (get-bucket-index next))))
      (let ((fst ($vector-ref vec idx)))
	(cond
	 ((eq? fst b)
	  ($vector-set! vec idx next))
	 (else
	  (replace! fst b next)))))
;;; reset the tcbucket-tconc FIRST
    ($set-tcbucket-tconc! b (hasht-tc h))
;;; then add it to the new place
    (let ((k ($tcbucket-key b)))
      (let ((ih (pointer-value k)))
	(let ((idx ($fxlogand ih ($fxsub1 ($vector-length vec)))))
	  (let ((n ($vector-ref vec idx)))
	    ($set-tcbucket-next! b n)
	    ($vector-set! vec idx b)
	    (void)))))))

(define (get-bucket h x)
  (define (get-hashed h x ih)
    (let ((equiv? (hasht-equivf h))
	  (vec (hasht-buckets-vector h)))
      (let ((idx ($fxlogand ih ($fxsub1 ($vector-length vec)))))
	(let f ((b ($vector-ref vec idx)))
	  (cond ((fixnum? b)
		 #f)
		((equiv? x ($tcbucket-key b))
		 b)
		(else
		 (f ($tcbucket-next b))))))))
  (cond ((hasht-hashf h)
	 => (lambda (hashf)
	      (get-hashed h x (hashf x))))
	((and (eq? eqv? (hasht-equivf h))
	      (number? x))
	 (get-hashed h x (number-hash x)))
	(else
	 (let ((pv (pointer-value x))
	       (vec (hasht-buckets-vector h)))
	   (let ((ih pv))
	     (let ((idx ($fxlogand ih ($fxsub1 ($vector-length vec)))))
	       (let ((b ($vector-ref vec idx)))
		 (or (direct-lookup x b)
		     (rehash-lookup h (hasht-tc h) x)))))))))

(define (get-hash h x v)
  (cond ((get-bucket h x)
	 => (lambda (b)
	      ($tcbucket-val b)))
	(else v)))

(define (in-hash? h x)
  (and (get-bucket h x) #t))

(define (del-hash h x)
  (define (unlink! h b)
    (let ((vec (hasht-buckets-vector h))
	  (next ($tcbucket-next b)))
      ;; first remove it from its old place
      (let ((idx (if (fixnum? next)
		     next
		   (get-bucket-index next))))
	(let ((fst ($vector-ref vec idx)))
	  (cond ((eq? fst b)
		 ($vector-set! vec idx next))
		(else
		 (replace! fst b next)))))
      ;; set next to be #f, denoting, not in table
      ($set-tcbucket-next! b #f)))
  (cond ((get-bucket h x)
	 => (lambda (b)
	      (receive-and-return (key val)
		  ;;Returning these values is a Vicare extension.
		  (values ($tcbucket-key b)
			  ($tcbucket-val b))
		(unlink! h b)
		;; don't forget the count.
		(set-hasht-size! h (fxsub1 (hasht-size h))))))))

(define (put-hash! h x v)
  (define (put-hashed h x v ih)
    (let ((equiv? (hasht-equivf h))
	  (vec (hasht-buckets-vector h)))
      (let ((idx ($fxlogand ih ($fxsub1 ($vector-length vec)))))
	(let f ((b ($vector-ref vec idx)))
	  (cond ((fixnum? b)
		 ($vector-set! vec idx (vector x v ($vector-ref vec idx)))
		 (let ((ct (hasht-size h)))
		   (set-hasht-size! h (fxadd1 ct))
		   (when ($fx> ct ($vector-length vec))
		     (enlarge-table h))))
		((equiv? x ($tcbucket-key b))
		 ($set-tcbucket-val! b v))
		(else
		 (f ($tcbucket-next b))))))))
  (cond ((hasht-hashf h)
	 => (lambda (hashf)
	      (put-hashed h x v (hashf x))))
	((and (eq? eqv? (hasht-equivf h))
	      (number? x))
	 (put-hashed h x v (number-hash x)))
	(else
	 (let ((pv  (pointer-value x))
	       (vec (hasht-buckets-vector h)))
	   (let ((ih pv))
	     (let ((idx ($fxlogand ih ($fxsub1 ($vector-length vec)))))
	       (let ((b ($vector-ref vec idx)))
		 (cond ((or (direct-lookup x b)
			    (rehash-lookup h (hasht-tc h) x))
			=> (lambda (b)
			     ($set-tcbucket-val! b v)
			     (void)))
		       (else
			(let ((bucket ($make-tcbucket (hasht-tc h)	       ;tconc
						      x			       ;key
						      v			       ;val
						      ($vector-ref vec idx)))) ;next
			  (if ($fx= (pointer-value x) pv)
			      ($vector-set! vec idx bucket)
			    (let* ((ih  (pointer-value x))
				   (idx ($fxlogand ih ($fxsub1 ($vector-length vec)))))
			      ($set-tcbucket-next! bucket ($vector-ref vec idx))
			      ($vector-set! vec idx bucket))))
			(let ((ct (hasht-size h)))
			  (set-hasht-size! h (fxadd1 ct))
			  (when ($fx> ct ($vector-length vec))
			    (enlarge-table h))))))))))))

(define (update-hash! h x proc default)
  (cond ((get-bucket h x)
	 => (lambda (b)
	      ($set-tcbucket-val! b (proc ($tcbucket-val b)))))
	(else
	 (put-hash! h x (proc default)))))

(define (enlarge-table h)
  (define (enlarge-hashtable h hashf)
    (define (insert-b b vec mask)
      (let* ((x    ($tcbucket-key b))
	     (ih   (hashf x))
	     (idx  ($fxlogand ih mask))
	     (next ($tcbucket-next b)))
	($set-tcbucket-next! b ($vector-ref vec idx))
	($vector-set! vec idx b)
	(unless (fixnum? next)
	  (insert-b next vec mask))))
    (define (move-all vec1 i n vec2 mask)
      (unless ($fx= i n)
	(let ((b ($vector-ref vec1 i)))
	  (unless (fixnum? b)
	    (insert-b b vec2 mask))
	  (move-all vec1 (fxadd1 i) n vec2 mask))))
    (let* ((vec1 (hasht-buckets-vector h))
	   (n1   ($vector-length vec1))
	   (n2   ($fxsll n1 1))
	   (vec2 (make-base-vec n2)))
      (move-all vec1 0 n1 vec2 ($fxsub1 n2))
      (set-hasht-buckets-vector! h vec2)))
  (cond ((hasht-hashf h)
	 => (lambda (hashf)
	      (enlarge-hashtable h hashf)))
	((eq? eq? (hasht-equivf h))
	 (enlarge-hashtable h (lambda (x)
				(pointer-value x))))
	(else
	 (enlarge-hashtable h (lambda (x)
				(if (number? x)
				    (number-hash x)
				  (pointer-value x)))))))

(define (init-vec v i n)
  (if ($fx= i n)
      v
    (begin
      ($vector-set! v i i)
      (init-vec v (fxadd1 i) n))))

(define (make-base-vec n)
  (init-vec (make-vector n) 0 n))

(define (clear-hash! h)
  (let ((v (hasht-buckets-vector h)))
    (init-vec v 0 (vector-length v)))
  (unless (hasht-hashf h)
    (set-hasht-tc! h (let ((x (cons #f #f)))
		       (cons x x))))
  (set-hasht-size! h 0))

(define (get-keys h)
  (let ((v (hasht-buckets-vector h))
	(n (hasht-size h)))
    (let ((kv (make-vector n)))
      (let f ((i  ($fxsub1 n))
	      (j  ($fxsub1 (vector-length v)))
	      (kv kv)
	      (v  v))
	(cond (($fx= i -1)
	       kv)
	      (else
	       (let ((b ($vector-ref v j)))
		 (if (fixnum? b)
		     (f i ($fxsub1 j) kv v)
		   (f (let f ((i i) (b b) (kv kv))
			($vector-set! kv i ($tcbucket-key b))
			(let ((b ($tcbucket-next b))
			      (i ($fxsub1 i)))
			  (cond
			   ((fixnum? b) i)
			   (else (f i b kv)))))
		      ($fxsub1 j) kv v)))))))))

(define (get-entries table)
  ;;This is the implementation of HASHTABLE-ENTRIES as defined by R6RS.
  ;;
  (let* ((buck-vec (hasht-buckets-vector   table))
	 (N        (hasht-size  table))
	 (keys-vec (make-vector N))
	 (vals-vec (make-vector N)))
    (let next-bucket ((i        ($fxsub1 N))
		      (buck-idx ($fxsub1 ($vector-length buck-vec)))
		      (keys-vec keys-vec)
		      (vals-vec vals-vec)
		      (buck-vec buck-vec))
      (if ($fx= i -1)
	  (values keys-vec vals-vec)
	(let ((b ($vector-ref buck-vec buck-idx)))
	  (if (fixnum? b)
	      (next-bucket i ($fxsub1 buck-idx) keys-vec vals-vec buck-vec)
	    (next-bucket (let inner-loop ((i i) (b b) (keys-vec keys-vec) (vals-vec vals-vec))
			   ($vector-set! keys-vec i ($tcbucket-key b))
			   ($vector-set! vals-vec i ($tcbucket-val b))
			   (let ((b ($tcbucket-next b))
				 (i ($fxsub1 i)))
			     (if (fixnum? b)
				 i
			       (inner-loop i b keys-vec vals-vec))))
			 ($fxsub1 buck-idx)
			 keys-vec vals-vec buck-vec)))))))

(define (hasht-copy h mutable?)
  (define (dup-hasht h mutable? n)
    (let* ((hashf (hasht-hashf h))
	   (tc (and (not hashf) (let ((x (cons #f #f))) (cons x x)))))
      (make-hasht (make-base-vec n) 0 tc mutable?
		  hashf (hasht-equivf h) (hasht-hashf0 h))))
  (let ((v (hasht-buckets-vector h))
	(n (hasht-size h)))
    (let ((r (dup-hasht h mutable? (vector-length v))))
      (let f ((i ($fxsub1 n))
	      (j ($fxsub1 (vector-length v)))
	      (r r)
	      (v v))
	(cond (($fx= i -1)
	       r)
	      (else
	       (let ((b ($vector-ref v j)))
		 (if (fixnum? b)
		     (f i ($fxsub1 j) r v)
		   (f (let f ((i i) (b b) (r r))
			(put-hash! r ($tcbucket-key b) ($tcbucket-val b))
			(let ((b ($tcbucket-next b))
			      (i ($fxsub1 i)))
			  (cond ((fixnum? b)
				 i)
				(else
				 (f i b r)))))
		      ($fxsub1 j) r v)))))))))


;;;; public interface: constructors and predicate

(define hashtable? hasht?)

(case-define* make-eq-hashtable
  (()
   (let* ((x  (cons #f #f))
	  (tc (cons x x)))
     (make-hasht (make-base-vec 32) ;vec
		 0		    ;count
		 tc		    ;tc
		 #t		    ;mutable?
		 #f		    ;hashf
		 eq?		    ;equivf
		 #f)))		    ;hashf0
  (({cap %initial-capacity?})
   (make-eq-hashtable)))

(case-define* make-eqv-hashtable
  (()
   (let* ((x  (cons #f #f))
	  (tc (cons x x)))
     (make-hasht (make-base-vec 32) ;vec
		 0		    ;count
		 tc		    ;tc
		 #t		    ;mutable?
		 #f		    ;hashf
		 eqv?		    ;equivf
		 #f)))		    ;hashf0
  (({cap %initial-capacity?})
   (make-eqv-hashtable)))

(module (make-hashtable)

  (case-define* make-hashtable
    (({hashf procedure?} {equivf procedure?})
     (make-hasht (make-base-vec 32)	       ;vec
		 0			       ;count
		 #f			       ;tc
		 #t			       ;mutable?
		 (%make-hashfun-wrapper hashf) ;hashf
		 equivf			       ;equivf
		 hashf))		       ;hashf0
    (({hashf procedure?} {equivf procedure?} {cap %initial-capacity?})
     (make-hashtable hashf equivf)))

  (define (%make-hashfun-wrapper f)
    (if (or (eq? f symbol-hash)
	    (eq? f string-hash)
	    (eq? f string-ci-hash)
	    (eq? f fixnum-hash)
	    (eq? f exact-integer-hash)
	    (eq? f flonum-hash)
	    (eq? f number-hash)
	    (eq? f char-hash)
	    (eq? f char-ci-hash)
	    (eq? f bytevector-hash)
	    (eq? f boolean-hash)
	    (eq? f struct-hash)
	    (eq? f record-hash)
	    (eq? f object-hash)
	    (eq? f void-hash)
	    (eq? f eof-object-hash)
	    (eq? f would-block-hash)
	    (eq? f equal-hash))
	f
      (lambda (k)
	(fluid-let-syntax
	    ((__who__ (identifier-syntax 'hashfunc-wrapper)))
	  (receive-and-return (i)
	      (f k)
	    (unless (exact-integer? i)
	      (procedure-argument-violation __who__
		"invalid hash value from custom hash function"
		i)))))))

  #| end of module: MAKE-HASHTABLE |# )

;;; --------------------------------------------------------------------

(case-define* hashtable-copy
  (({table hashtable?})
   (if (hasht-mutable? table)
       (hasht-copy table #f)
     table))
  (({table hashtable?} mutable?)
   (if (or mutable?
	   (hasht-mutable? table))
       (hasht-copy table (and mutable? #t))
     table)))


;;;; public interface: accessors and mutators

(case-define* hashtable-ref
  (({table hashtable?} key)
   (get-hash table key (void)))
  (({table hashtable?} key default)
   (get-hash table key default)))

(define* (hashtable-set! {table mutable-hashtable?} key {val %not-void?})
  (put-hash! table key val))

;;; --------------------------------------------------------------------

(define* (hashtable-contains? {table hashtable?} key)
  (in-hash? table key))

;;; --------------------------------------------------------------------

(define* (hashtable-update! {table mutable-hashtable?} key {proc procedure?} {default %not-void?})
  (update-hash! table key proc default))

(define* (hashtable-delete! {table mutable-hashtable?} key)
  ;;Remove any association for KEY within TABLE;  if there is no association for KEY:
  ;;do nothing.
  ;;
  ;;As Vicare extension:
  ;;
  ;;* If an  association is  found: return  two values,  the key  and value.
  ;;
  ;;* If no association is found: return two values, void and void.
  ;;
  ;;FIXME: should shrink table if number of keys drops below:
  ;;
  ;;(sqrt (vector-length (hasht-buckets-vector h)))
  ;;
  ;;(Abdulaziz Ghuloum)
  ;;
  (del-hash table key))

(define* (hashtable-clear! {table mutable-hashtable?})
  (clear-hash! table))


;;;; public interface: inspection

;; (define* (hashtable-size {table hashtable?})
;;   (hasht-size table))

(define hashtable-size hasht-size)

(define* (hashtable-entries {table hashtable?})
  (get-entries table))

(define* (hashtable-keys {table hashtable?})
  (get-keys table))

(define* (hashtable-mutable? {table hashtable?})
  (hasht-mutable? table))

(define (mutable-hashtable? obj)
  (and (hashtable?     obj)
       (hasht-mutable? obj)))

;;; --------------------------------------------------------------------

(define* (hashtable-equivalence-function {table hashtable?})
  (hasht-equivf table))

(define* (hashtable-hash-function {table hashtable?})
  (hasht-hashf0 table))


;;;; hash functions

(case-define* string-hash
  ;;Defined by Vicare.
  ;;
  (({bv string?})
   ($string-hash bv #f))
  (({bv string?} {max-len %boolean-or-non-negative-fixnum?})
   ($string-hash bv max-len)))

(case-define $string-hash
  ((s)
   (foreign-call "ikrt_string_hash" s #f))
  ((s max-len)
   (foreign-call "ikrt_string_hash" s max-len)))

;;; --------------------------------------------------------------------

(case-define* string-ci-hash
  ;;Defined by Vicare.
  ;;
  (({bv string?})
   ($string-ci-hash bv #f))
  (({bv string?} {max-len %boolean-or-non-negative-fixnum?})
   ($string-ci-hash bv max-len)))

(case-define $string-ci-hash
  ((s)
   (foreign-call "ikrt_string_hash" (string-foldcase s) #f))
  ((s max-len)
   (foreign-call "ikrt_string_hash" (string-foldcase s) max-len)))

;;; --------------------------------------------------------------------

(define* (symbol-hash {sym symbol?})
  ($symbol-hash sym))

(define ($symbol-hash sym)
  (foreign-call "ikrt_string_hash" (symbol->string sym)))

;;; --------------------------------------------------------------------

(case-define* bytevector-hash
  ;;Defined by Vicare.
  ;;
  (({bv bytevector?})
   ($bytevector-hash bv #f))
  (({bv bytevector?} {max-len %boolean-or-non-negative-fixnum?})
   ($bytevector-hash bv max-len)))

(case-define $bytevector-hash
  ((bv)
   (foreign-call "ikrt_bytevector_hash" bv #f))
  ((bv max-len)
   (foreign-call "ikrt_bytevector_hash" bv max-len)))

;;; --------------------------------------------------------------------

(define* (fixnum-hash {fx fixnum?})
  ($fixnum-hash fx))

(define ($fixnum-hash fx)
  ($abs-fixnum fx))

;;; --------------------------------------------------------------------

(define* (exact-integer-hash {N exact-integer?})
  (if (fixnum? N)
      ($fixnum-hash N)
    ($bignum-hash N)))

(define ($bignum-hash N)
  (foreign-call "ikrt_bignum_hash" N))

;;; --------------------------------------------------------------------

(define* (flonum-hash {fl flonum?})
  ($flonum-hash fl))

(define* ($flonum-hash fl)
  (foreign-call "ikrt_flonum_hash" fl))

;;; --------------------------------------------------------------------

(define* (number-hash Z)
  (cond ((fixnum? Z)
	 ($fixnum-hash Z))
	((flonum? Z)
	 ($flonum-hash Z))
	((bignum? Z)
	 ($bignum-hash Z))
	((ratnum? Z)
	 (fxxor (number-hash ($ratnum-n Z))
		(number-hash ($ratnum-d Z))))
	((cflonum? Z)
	 (fxxor ($flonum-hash ($cflonum-real Z))
		($flonum-hash ($cflonum-imag Z))))
	((compnum? Z)
	 (fxxor (number-hash ($compnum-real Z))
		(number-hash ($compnum-imag Z))))
	(else
	 (procedure-argument-violation __who__ "expected number object" Z))))

;;; --------------------------------------------------------------------

(define* (char-hash {ch char?})
  ($char-hash ch))

(define ($char-hash ch)
  ($fixnum-hash ($char->fixnum ch)))

;;; --------------------------------------------------------------------

(define* (char-ci-hash {ch char?})
  ($char-ci-hash ch))

(define ($char-ci-hash ch)
  ($fixnum-hash ($char->fixnum (char-foldcase ch))))

;;; --------------------------------------------------------------------

(define* (struct-hash {stru struct?})
  ($struct-hash stru))

(define ($struct-hash stru)
  (if (zero? (struct-length stru))
      (symbol-hash (struct-type-symbol (struct-rtd stru)))
    (object-hash (struct-ref stru 0))))

;;; --------------------------------------------------------------------

(define* (record-hash {rec record?})
  ($record-hash rec))

(define ($record-hash rec)
  (let ((rtd (record-rtd rec)))
    (if (zero? (vector-length (record-type-field-names rtd)))
	(let ((uid (record-type-uid rtd)))
	  (if uid
	      (symbol-hash uid)
	    0))
      (object-hash (struct-ref rec 0)))))

;;; --------------------------------------------------------------------

(define (void-hash obj)
  0)

(define (eof-object-hash obj)
  1)

(define (would-block-hash obj)
  2)

;;; --------------------------------------------------------------------

(define* (boolean-hash {obj boolean?})
  ($boolean-hash obj))

(define ($boolean-hash obj)
  (if obj 1 0))

;;; --------------------------------------------------------------------

(define (object-hash obj)
  (cond ((string? obj)
	 ($string-hash obj #f))
	((symbol? obj)
	 ($symbol-hash obj))
	((bytevector? obj)
	 ($bytevector-hash obj #f))
	((fixnum? obj)
	 ($fixnum-hash obj))
	((flonum? obj)
	 ($flonum-hash obj))
	((bignum? obj)
	 ($bignum-hash obj))
	((number? obj)
	 (number-hash obj))
	((char? obj)
	 ($char-hash obj))
	((boolean? obj)
	 ($boolean-hash obj))
	((record? obj)
	 ($record-hash obj))
	((struct? obj)
	 ($struct-hash obj))
	((eq? obj (void))
	 (void-hash obj))
	((eof-object? obj)
	 (eof-object-hash obj))
	((would-block-object? obj)
	 (would-block-hash obj))
	(else
	 (equal-hash obj))))

;;; --------------------------------------------------------------------

(define (equal-hash obj)
  (string-hash (call-with-string-output-port
		   (lambda (port)
		     (write obj port)))))


;;;; done

(set-rtd-printer! (type-descriptor hasht)	(lambda (x p wr)
						  (display "#<hashtable>" p)))

#| end of library |# )

;;; end of file
