;;Copyright (C) John Cowan 2014.  All Rights Reserved.
;;Modified by Marco Maggi <marco.maggi-ipsu@poste.it>
;;
;;Permission is  hereby granted, free  of charge, to any  person obtaining a  copy of
;;this software and associated documentation files (the ``Software''), to deal in the
;;Software without restriction, including without limitation the rights to use, copy,
;;modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
;;and to permit  persons to whom the Software  is furnished to do so,  subject to the
;;following conditions:
;;
;;The above  copyright notice  and this  permission notice shall  be included  in all
;;copies or substantial portions of the Software.
;;
;;THE  SOFTWARE IS  PROVIDED ``AS  IS'',  WITHOUT WARRANTY  OF ANY  KIND, EXPRESS  OR
;;IMPLIED, INCLUDING  BUT NOT LIMITED  TO THE WARRANTIES OF  MERCHANTABILITY, FITNESS
;;FOR A  PARTICULAR PURPOSE AND  NONINFRINGEMENT.  IN NO  EVENT SHALL THE  AUTHORS OR
;;COPYRIGHT HOLDERS BE  LIABLE FOR ANY CLAIM, DAMAGES OR  OTHER LIABILITY, WHETHER IN
;;AN ACTION  OF CONTRACT, TORT  OR OTHERWISE, ARISING FROM,  OUT OF OR  IN CONNECTION
;;WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
;;

(library (srfi :116)
  (export
    iq
    ipair ilist xipair ipair* make-ilist ilist-tabulate iiota ilist-copy
    ipair?
    proper-ilist? ilist? dotted-ilist? not-ipair? null-ilist? ilist=
    icar icdr ilist-ref
    ifirst isecond ithird ifourth ififth isixth iseventh ieighth ininth itenth
    icaar icadr icdar icddr
    icaaar icaadr icadar icaddr icdaar icdadr icddar icdddr
    icaaaar icaaadr icaadar icaaddr icadaar icadadr icaddar icadddr
    icdaaar icdaadr icdadar icdaddr icddaar icddadr icdddar icddddr
    icar+icdr itake idrop ilist-tail
    (rename (itake	itake-left)
	    (idrop	idrop-left))
    itake-right idrop-right isplit-at ilast last-ipair
    ilength iappend iconcatenate ireverse iappend-reverse
    izip iunzip1 iunzip2 iunzip3 iunzip4 iunzip5
    icount imap ifor-each ifold iunfold ipair-fold ireduce
    ifold-right iunfold-right ipair-fold-right ireduce-right
    iappend-map ipair-for-each ifilter-map imap-in-order
    ifilter ipartition iremove imember imemq imemv
    ifind ifind-tail iany ievery
    ilist-index itake-while idrop-while ispan ibreak
    idelete idelete-duplicates
    iassoc iassq iassv ialist-cons ialist-copy ialist-delete
    replace-icar replace-icdr
    pair->ipair			ipair->pair
    list->ilist			ilist->list
    ilist->vector		vector->ilist
    tree->itree itree->tree gtree->itree gtree->tree
    iapply)
  (import (srfi :116 ilists)))

;;; end of file
