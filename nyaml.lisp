;;;; nyaml.lisp
;;;; The main meat of the grammar for generating a parse tree from YAML

(in-package #:nyaml)

(named-readtables:in-readtable :fare-quasiquote)

(defvar *warning* (lambda (fmt-string &rest args) (declare (ignore fmt-string args))))
(defvar *error* (lambda (fmt-string args)
		  (apply 'error fmt-string args)))

;;; "nyaml" goes here. Hacks and glory await!

;; rule 1
(defrule c-printable
    (character-ranges #.(code-char #x9)
		      #.(code-char #xa)
		      #.(code-char #xd)
		      (#.(code-char #x20) #.(code-char #x7e))
		      #.(code-char #x85)
		      (#.(code-char #xa0) #.(code-char #xd7ff))
		      (#.(code-char #xe000) #.(code-char #xfffd))
		      (#.(code-char #x10000) #.(code-char #x10ffff))))

;; rule 2
(defrule nb-json (character-ranges #.(code-char #x9)
				   (#.(code-char #x20) #.(code-char #x10ffff))))

;; rule 3
(defrule c-byte-order-mark #.(code-char #xfeff))

;; rule 4
(defrule c-sequence-entry #\-)

;; rule 5
(defrule c-mapping-key #\?)

;; rule 6
(defrule c-mapping-value #\:)

;; rule 7
(defrule c-collect-entry #\,)

;; rule 8
(defrule c-sequence-start #\[)

;; rule 9
(defrule c-sequence-end #\])

;; rule 10
(defrule c-mapping-start #\{)

;; rule 11
(defrule c-mapping-end #\})

;; rule 12
(defrule c-comment #\#)

;; rule 13
(defrule c-anchor #\&)

;; rule 14
(defrule c-alias #\*)

;; rule 15
(defrule c-tag #\!)

;; rule 16
(defrule c-literal #\|)

;; rule 17
(defrule c-folded #\>)

;; rule 18
(defrule c-single-quote #\')

;; rule 19
(defrule c-double-quote #\")

;;rule 20
(defrule c-directive #\%)

;; rule 21
(defrule c-reserved (character-ranges #\@ #\`))

;; rule 22
(defrule c-indicator
    (character-ranges #\-  #\?  #\:  #\,  #\[  #\]  #\{  #\} #\#  #\&
		      #\*  #\!  #\|  #\>  #\'  #\" #\%  #\@  #\`))

;; rule 23
(defrule c-flow-indicator
    (character-ranges  #\,  #\[  #\]  #\{  #\}))

;; rule 24
(defrule b-line-feed (character-ranges #.(code-char #xa)))

;; rule 25
(defrule b-carriage-return (character-ranges #.(code-char #xd)))

;; rule 26
(defrule b-char (or b-line-feed b-carriage-return))

;; rule 27
(defrule nb-char (and (! (or b-char c-byte-order-mark)) c-printable))

;; rule 28
(defrule b-break (or
		  (and b-carriage-return b-line-feed)
		  b-carriage-return
		  b-line-feed))

;; rule 29
(defrule b-as-line-feed b-break (:constant #\Newline))

;; rule 30
(defrule b-non-content b-break (:constant nil))

;; rule 31
(defrule s-space (character-ranges #.(code-char #x20)))

;; rule 32
(defrule s-tab (character-ranges #.(code-char #x9)))

;; rule 33
(defrule s-white (or s-space s-tab))

;;rule 34
(defrule ns-char (and (! s-white) nb-char))

;;rule 35
(defrule ns-dec-digit (character-ranges (#\0 #\9)))

(defrule ns-dec-digit-positive (character-ranges (#\1 #\9)))

;;rule 36
(defrule ns-hex-digit
    (or ns-dec-digit
	(character-ranges (#\A #\F)
			 (#\a #\f))))

;;rule 37
(defrule ns-ascii-letter
    (character-ranges (#\a #\z)
		     (#\A #\Z)))

;; rule 38
(defrule ns-word-char
    (or ns-dec-digit ns-ascii-letter #\-))

;; rule 39
(defrule ns-uri-char
    (or
     (and #\% ns-hex-digit ns-hex-digit)
     ns-word-char
     (character-ranges
      #\#  #\;  #\/  #\?  #\:  #\@  #\&  #\=  #\+  #\$
      #\,  #\_  #\.  #\!  #\~  #\*  #\'  #\(  #\)  #\[  #\])))

;; rule 40
(defrule ns-tag-char
    (and
     (! (or #\! c-flow-indicator))
     ns-uri-char))

;; rule 41
(defrule c-escape #\\)

;; rule 42
(defrule ns-esc-null #\0 (:constant #\Nul))

;; rule 43
(defrule ns-esc-bell #\a (:constant (code-char #x7)))

;; rule 44
(defrule ns-esc-backspace #\b (:constant (code-char #x8)))

;; rule 45
(defrule ns-esc-horizontal-tab #\t (:constant (code-char #x9)))

(defrule ns-esc-line-feed #\n (:constant (code-char #xa)))

(defrule ns-esc-vertical-tab #\v (:constant (code-char #xb)))

(defrule ns-esc-form-feed #\f (:constant (code-char #xc)))

(defrule ns-esc-carriage-return #\r (:constant (code-char #xd)))

(defrule ns-esc-escape #\e (:constant (code-char #x1b)))

(defrule ns-esc-space #\Space)

(defrule ns-esc-double-quote #\")

(defrule ns-esc-slash #\/)

(defrule ns-esc-backslash #\\)

(defrule ns-esc-next-line #\N (:constant (code-char #x85)))

(defrule ns-esc-non-breaking-space #\_ (:constant (code-char #xa0)))

(defrule ns-esc-line-separator #\L (:constant (code-char #x2028)))

(defrule ns-esc-paragraph-separator #\P (:constant (code-char #x2029)))

(defrule ns-esc-8-bit
 (and #\x ns-hex-digit ns-hex-digit)
 (:lambda (result)
   (code-char
    (parse-integer (coerce (cdr result) 'string) :radix 16))))

(defrule ns-esc-16-bit
    (and #\u
	 ns-hex-digit ns-hex-digit
	 ns-hex-digit ns-hex-digit)
 (:lambda (result)
   (code-char
    (parse-integer (coerce (cdr result) 'string) :radix 16))))

(defrule ns-esc-32-bit
    (and #\U
	 ns-hex-digit ns-hex-digit
	 ns-hex-digit ns-hex-digit
	 ns-hex-digit ns-hex-digit
	 ns-hex-digit ns-hex-digit)
 (:lambda (result)
   (code-char
    (parse-integer (coerce (cdr result) 'string) :radix 16))))

(defrule c-ns-esc-char
    (and #\\
	 (or ns-esc-null  ns-esc-bell  ns-esc-backspace
	     ns-esc-horizontal-tab  ns-esc-line-feed
	     ns-esc-vertical-tab  ns-esc-form-feed
	     ns-esc-carriage-return  ns-esc-escape  ns-esc-space
	     ns-esc-double-quote  ns-esc-slash  ns-esc-backslash
	     ns-esc-next-line  ns-esc-non-breaking-space
	     ns-esc-line-separator  ns-esc-paragraph-separator
	     ns-esc-8-bit  ns-esc-16-bit  ns-esc-32-bit ))
  (:function second))


;; rule 63

#+(or)(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun expand-arguments (arglist &optional so-far)
    (let (name values)
      (cond
	((null arglist) (return-from expand-arguments so-far))
	((listp (car arglist))
	 (setf name (caar arglist)
	       values (cdar arglist)))
	(t (setf name (car arglist)
		 values (loop for i from 0 to 10 collect i))))
      (expand-arguments
       (cdr arglist)
       (if so-far
	   (loop for i in so-far
	      nconc (loop for j in values
		       collect `(,@i (,name ,j))))
	   (loop for i in values collect `((,name ,i))))))))

#+(or)(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun prule (name &rest arguments)
    (intern (format nil "~a~{-~a~}" name arguments) *package*)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun generate-transform (options)
    (let ((transform (list ''identity)))
      (loop for option in options
	 do
	   (case (car option)
	     (:constant
	      (push `(constantly ,(cadr option)) transform))
	     (:function
	      (push `',(cadr option) transform))
	     (:identity t)
	     (:text (push ''text transform))
	     (:lambda
		 (when (member '&bounds (cadr option))
		   (error "This feature not yet implemented"))
	       (push `(alexandria:compose
		       (lambda ,(cadr option) ,@(cddr option)))
		     transform))
	     (:destructure
	      (let ((arg (gensym)))
		(push `(alexandria:compose
			(lambda (,arg)
			  (destructuring-bind ,(cadr option)
			      ,arg
			    ,@(cddr option))))
		      transform)))
				       
	     (t (error "This feature not yet implemented"))))
      `(alexandria:compose ,@transform))))
    

;; TODO parse out declaraction &ct
(defmacro define-parameterized-rule (name arguments &body b)
  `(defun ,name (input position end ,@(mapcar (lambda (x) (if (listp x) (car x) x)) arguments))
    (let* ((pcalls
	    (let ((pcalls2))
	      (flet ((prule (name &rest args)
			   #+debug(format t "~&PRULE: ~A~%" name)
			   (push `(,(gensym (format nil "~a-~{~a-~}" name args)) ,name ,@args) pcalls2)))
		,(car b))
	      (reverse pcalls2)))
	   (unbind-me (mapcar #'car pcalls)))
      #+debug(format t "~&PCALLS: ~S~%" pcalls)
      (unwind-protect
	   (progn (loop for item in pcalls
		     do (setf (fdefinition (car item))
			      (let ((item item))
				(lambda (input position end)
				  (apply (cadr item) input position end (cddr item)))))
		       (assert (not (find-rule (car item))))
		       (add-rule (car item) (make-instance 'rule
							   :expression `(function ,(car item))))
		       #+nyaml-trace(trace-rule (car item) :recursive t))
		  (multiple-value-bind (production position result)
		      (esrap:parse
		       (flet ((prule (&rest ignoreme)
				(declare (ignore ignoreme))
				(car (pop pcalls))))
			 ,(car b))
		       input :start position :end end :junk-allowed t)
		    (if result
			(values (funcall ,(generate-transform (cdr b)) production)
				position result)
			(values production position result))))
		    
	(loop for item in unbind-me do (fmakunbound item)
	     (esrap:remove-rule item)))))

  #+(or)`(progn
     #+(or)(eval-when (:compile-toplevel :load-toplevel :execute)
       (defun ,name ,(mapcar (lambda (x) (if (listp x) (car x) x)) arguments)
	 (intern (format nil "~a~{-~a~}" ',name (list ,@(mapcar (lambda (x) (if (listp x) (car x) x)) arguments))) ,*package*)))
     ,@(loop
	  for args in (expand-arguments arguments)
	  collect `(defrule
		       ,(intern (format nil "~a~{-~a~}"
					name
					(mapcar (lambda (x) (eval (cadr x))) args)))
		       ,(eval `(let ,args
				 ,(car b)))
		     ,@(cdr b)))))

(defun parse-parameterized-rule (name parameters string)
  (apply name string 0 (length string) parameters))

;; rule 63
(define-parameterized-rule s-indent (n)
  (if (non-negative-integer-p n)
       `(and ,@(loop repeat n collect 's-space))
       `(or))
 (:text t))

;; rule 64
(define-parameterized-rule s-indent-< (n)
  `(or
    ,@(loop for i from (1- n) downto 0
	 collect `(and ,(prule 's-indent i)
		       (& (! s-space))))
    )
  (:text t))

;; rule 65
(define-parameterized-rule s-indent-<= (n)
  `(or ,(prule 's-indent n) ,(prule 's-indent-< n))
 (:text t))

(defrule s-separate-in-line
    (or
     (+ s-white)
     (function start-of-line)))

;; rule 68
(define-parameterized-rule s-block-line-prefix (n)
  (prule 's-indent n))

;; rule 69
(define-parameterized-rule s-flow-line-prefix (n)
  `(and ,(prule 's-indent n) (? s-separate-in-line)))
  

;; rule 67
(define-parameterized-rule s-line-prefix (n (c :block-out :block-in :flow-out :flow-in))
  (if
   (or (eql c :block-out)
       (eql c :block-in))
   (prule 's-block-line-prefix n)
   (prule 's-flow-line-prefix  n)))


;; rule 70
(define-parameterized-rule l-empty (n (c :block-out :block-in :flow-out :flow-in))
  `(and
    (or ,(prule 's-line-prefix n c)
	,(prule 's-indent-< n))
    b-as-line-feed)
  (:constant #\Newline))

;; rule 71
(define-parameterized-rule b-l-trimmed (n (c :block-out :block-in :flow-out :flow-in))
  `(and b-non-content
	(+
	 ,(prule 'l-empty n c)))
  (:lambda (x)
    (apply #'esrap:text (rest x))))

;; rule 72
(defrule b-as-space b-break (:constant #\Space))

;; rule 73
(define-parameterized-rule b-l-folded (n (c :block-out :block-in :flow-out :flow-in))
  `(or ,(prule 'b-l-trimmed n c)
       b-as-space)
  (:text t))

(define-parameterized-rule s-flow-folded (n)
  `(and (? s-separate-in-line)
	,(prule 'b-l-folded n :flow-in)
	,(prule 's-flow-line-prefix n))
  (:function second))

(defrule c-nb-comment-text (and #\# (* nb-char)))

;; Not a part of YAML spec
(defrule eof (! character))

(defrule b-comment (or b-non-content eof))

;; rule 77
(defrule s-b-comment
    (and
     (?
      (and
       s-separate-in-line
       (? c-nb-comment-text)))
     b-comment))

;; rule 78
(defrule l-comment
    (and s-separate-in-line
	 (? c-nb-comment-text)
	 b-comment))

;; l-comment consumes no characters at EOF
;; so we need to handle that situation for *
;; and + productions to not infinite loop
(defrule l-comment-*
    (or
     l-comment-+
     (and)))

(defrule l-comment-+
    (or
     eof
     (and
      l-comment
      l-comment-+)
     l-comment))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun start-of-line (input position end)
    (declare (ignore end))
    (if (or (= position 0)
	    (char= (elt input (1- position)) #\Newline)
	    (char= (elt input (1- position)) #\Return))
	(values "" position t)
	(values nil position))))

(defrule start-of-line
  (function start-of-line ))

;; rule 79
(defrule s-l-comments
    (and
     (or s-b-comment start-of-line)
     l-comment-*))

;; rule 81
(define-parameterized-rule s-separate-lines (n)
  `(or
    (and s-l-comments ,(prule 's-flow-line-prefix n))
    s-separate-in-line))

;; rule 80
(define-parameterized-rule s-separate (n (c :block-out :block-in :flow-out :flow-in
					    :block-key :flow-key))
  (if (member c '(:block-out :block-in :flow-out :flow-in))
      (prule 's-separate-lines n)
      's-separate-in-line))

;; rule 82
(defrule l-directive
    (and "%"
	 (or ns-yaml-directive
	     ns-tag-directive
	     ns-reserved-directive)
	 s-l-comments)
  (:lambda (x)
    `(directive ,(second x))))

;; rule 83
(defrule ns-reserved-directive
    (and (!
	  (and
	   (or "TAG" "YAML")
	   s-white))
	 ns-directive-name
	 (* (and s-separate-in-line ns-directive-parameter)))
  (:destructure (_ name args)
    (declare (ignore _))
    `(reserved ,(make-keyword (text name)) ,@(loop for (_ arg) in args collect (text arg)))))

;; rule 84
(defrule ns-directive-name (+ ns-char))

;; rule 85
(defrule ns-directive-parameter (+ ns-char))

;; rule 86
(defrule ns-yaml-directive
    (and "YAML"
	 s-separate-in-line
	 ns-yaml-version)
  (:destructure (_1 _2 version)
    (declare (ignore _1 _2))
    `(yaml ,(text version))))

;; rule 87
(defrule ns-yaml-version
    (and
     (+ ns-dec-digit)
     #\.
     (+ ns-dec-digit))
  (:lambda (production)
    (when (or (> (parse-integer (text (first production))) 1)
	      (> (parse-integer (text (third production))) 2))
      (funcall *warning* "YAML version declared: ~A newer than 1.2"
	       (text production)))
    (text production)))
	
;; rule 88
(defrule ns-tag-directive
    (and
     "TAG"
     s-separate-in-line
     c-tag-handle
     s-separate-in-line
     ns-tag-prefix)
  (:destructure (_1 _2 handle _3 prefix)
    (declare (ignore _1 _2 _3))
    `(tag ,(text handle) ,(text prefix))))

;; rule 89
(defrule c-tag-handle
    (or c-named-tag-handle c-secondary-tag-handle c-primary-tag-handle))

;; rule 90
(defrule c-primary-tag-handle #\!)

;;rule 91
(defrule c-secondary-tag-handle "!!")

;;rule 92
(defrule c-named-tag-handle
    (and #\!
	 (+ ns-word-char)
	 #\!))

;; rule 93
(defrule ns-tag-prefix
    (or c-ns-local-tag-prefix
	ns-global-tag-prefix))

;; rule 94
(defrule c-ns-local-tag-prefix
    (and
     #\!
     (* ns-uri-char)))

;; rule 95
(defrule ns-global-tag-prefix
    (and
     ns-tag-char
     (* ns-uri-char)))

;; rule 96
(define-parameterized-rule c-ns-properties (n (c :block-out :block-in :flow-out :flow-in
						 :block-key :flow-key))
  `(or
    (and
     c-ns-tag-property
     (? (and ,(prule 's-separate n c) c-ns-anchor-property)))
    (and
     c-ns-anchor-property
     (? (and ,(prule 's-separate n c) c-ns-tag-property))))
  (:destructure (prop1 prop2)
    ;;(print prop2)
    `(properties ,prop1 ,@(cdr prop2))))


;; rule 97
(defrule c-ns-tag-property
    (or c-verbatim-tag
	c-ns-shorthand-tag
	c-non-specific-tag))

;; rule 98
;; TODO handle invalid tags
(defrule c-verbatim-tag
    (and
     "!<"
     (+ ns-uri-char)
     ">")
  (:lambda (x)
    `(tag ,(text (second x)))))

;; rule 99
(defrule c-ns-shorthand-tag
    (and c-tag-handle (+ ns-tag-char))
  (:destructure (tag-handle tag-name)
    `(tag ,(text tag-handle) ,(text tag-name))))

;;rule 100
(defrule c-non-specific-tag "!"
  (:constant '(tag nonspecific)))

;;rule 101
(defrule c-ns-anchor-property
    (and #\&
	 ns-anchor-name)
  (:destructure (_ name)
    (declare (ignore _))
    `(anchor ,(text name))))

;; rule 102
(defrule ns-anchor-char
    (and
     (! c-flow-indicator)
     ns-char))

;;rule 103
(defrule ns-anchor-name
    (+ ns-anchor-char))

;; rule 104
(defrule c-ns-alias-node
    (and #\*
	 ns-anchor-name)
  (:destructure (star name)
    (declare (ignore star))
    `(alias ,(text name))))

;; rule 105
(defrule e-scalar
    (and)
  (:constant 'yaml-null))

(defrule e-node e-scalar)

;; rule 107
(defrule nb-double-char
    (or c-ns-esc-char
	(and (! (character-ranges #\\ #\"))
	     nb-json)))

;; rule 108
(defrule ns-double-char
    (and (! s-white)
	 nb-double-char))


;;rule 114
(defrule nb-ns-double-in-line 
    (*
     (and
      (* s-white)
      ns-double-char)))

;;rule 115
(define-parameterized-rule s-double-next-line (n) 
  `(and
    ,(prule 's-double-break n)
    (?
     (and
      ns-double-char nb-ns-double-in-line
      (or
       ,(prule 's-double-next-line n)
       (* s-white))))))

;; rule 116
(define-parameterized-rule nb-double-multi-line (n) 
  `(and nb-ns-double-in-line
	(or ,(prule 's-double-next-line n)
	    (* s-white))))


;; rule 110
(define-parameterized-rule nb-double-text (n (c :flow-out :flow-in
						 :block-key :flow-key))
  (if (member c '(:flow-out :flow-in))
      (prule 'nb-double-multi-line n)
      'nb-double-one-line))

;; rule 109
(define-parameterized-rule c-double-quoted (n (c :flow-out :flow-in
						 :block-key :flow-key))
  `(and #\"
	,(prule 'nb-double-text n c)
	#\")
  (:lambda (stuff)
    (destructuring-bind (sq meat eq) stuff
      (declare (ignore sq eq))
      `(dq-string ,(text meat)))))

;; rule 111
(defrule nb-double-one-line
    (* nb-double-char))

;; rule 112
(define-parameterized-rule s-double-escaped (n)
  `(and
    (* s-white)
    #\\
    b-non-content
    (* ,(prule 'l-empty n :flow-in))
    ,(prule 's-flow-line-prefix n))
  (:lambda (x)
    (car x)))

;; rule 113
(define-parameterized-rule s-double-break (n) 
  `(or
    ,(prule 's-double-escaped n)
    ,(prule 's-flow-folded n)))

;; rule 117
(defrule c-quoted-quote "''" (:constant #\'))

;;rule 118
(defrule nb-single-char
    (or c-quoted-quote
	(and
	 (! #\')
	 nb-json)))

;; rule 119
(defrule ns-single-char
    (and
     (! s-white)
     nb-single-char))

;;rule 120
(define-parameterized-rule c-single-quoted (n (c :flow-out :flow-in :block-key :flow-key))
  `(and
    #\'
    ,(prule 'nb-single-text n c)
    #\')
  (:lambda (stuff)
    (destructuring-bind (sq meat eq) stuff
      (declare (ignore sq eq))
      (text meat))))

;;rule 121
(define-parameterized-rule nb-single-text (n (c :flow-out :flow-in :block-key :flow-key))
  (if (member c '(:flow-out :flow-in))
      (prule 'nb-single-multi-line n)
      'nb-single-one-line))

;;rule 122
(defrule nb-single-one-line (* nb-single-char))

;;rule 123
(defrule nb-ns-single-in-line (* (and (* s-white) ns-single-char)))

;;rule 124
(define-parameterized-rule s-single-next-line (n)
  `(and
    ,(prule 's-flow-folded n)
    (?
     (and
      ns-single-char
      nb-ns-single-in-line
      (or ,(prule 's-single-next-line n)
	  (* s-white))))))

;;rule 125
(define-parameterized-rule nb-single-multi-line (n)
  `(and nb-ns-single-in-line
	(or ,(prule 's-single-next-line n)
	    (* s-white))))

(define-parameterized-rule ns-plain-safe-follows ((c :flow-out :flow-in :block-key :flow-key))
  `(& ,(prule 'ns-plain-safe c))
  (:constant nil))

;;rule 126
(define-parameterized-rule ns-plain-first ((c :flow-out :flow-in :block-key :flow-key))
  `(or
    (and
     (! c-indicator)
     ns-char)
    (and
     (character-ranges #\? #\: #\-)
     ,(prule 'ns-plain-safe-follows c))))

;;rule 127
(define-parameterized-rule ns-plain-safe ((c :flow-out :flow-in :block-key :flow-key))
  (if (member c '(:flow-out :block-key))
      'ns-plain-safe-out
      'ns-plain-safe-in))

;;rule 128
(defrule ns-plain-safe-out ns-char)

;;rule 129
(defrule ns-plain-safe-in (and (! c-flow-indicator) ns-char))

(defun ns-char-preceding (input position end)
  (declare (ignore end))
  (if (and (/= position 0)
	   (multiple-value-bind (production new-position result)
	       (esrap:parse 'ns-char input :start (1- position) :junk-allowed t)
	       (declare (ignore production))
	       (or result
		   (and new-position (>= new-position position)))))
      (values nil position t)
      (values nil position)))

;;rule 130
(define-parameterized-rule ns-plain-char ((c :flow-out :flow-in :block-key :flow-key))
  `(or
    (and
     (! (character-ranges #\: #\#))
     ,(prule 'ns-plain-safe c))
    (and
     (function ns-char-preceding)
     #\#)
    (and
     #\:
     ,(prule 'ns-plain-safe-follows c))))

;;rule 131
(define-parameterized-rule ns-plain (n (c :flow-out :flow-in :block-key :flow-key))
  (if (member c '(:flow-out :flow-in))
      (prule 'ns-plain-multi-line n c)
      (prule 'ns-plain-one-line c))
  (:text t))

;;rule 132
(define-parameterized-rule nb-ns-plain-in-line ((c :flow-out :flow-in :block-key :flow-key))
  `(*
    (and (* s-white)
	 ,(prule 'ns-plain-char c))))

;;rule 133
(define-parameterized-rule ns-plain-one-line ((c :flow-out :flow-in :block-key :flow-key))
  `(and
    ,(prule 'ns-plain-first c)
    ,(prule 'nb-ns-plain-in-line c)))

;;rule 134
(define-parameterized-rule s-ns-plain-next-line (n (c :flow-out :flow-in :block-key :flow-key))
  `(and
    ,(prule 's-flow-folded n)
    ,(prule 'ns-plain-char c)
    ,(prule 'nb-ns-plain-in-line c)))

;;rule 135
(define-parameterized-rule ns-plain-multi-line (n (c :flow-out :flow-in :block-key :flow-key))
  `(and
    ,(prule 'ns-plain-one-line c)
    (* ,(prule 's-ns-plain-next-line n c))))

;; rule 136
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun in-flow (c)
    (if (member c '(:flow-out :flow-in))
	:flow-in
	:flow-key)))

;; rule 137
(define-parameterized-rule c-flow-sequence (n (c :flow-out :flow-in
						 :block-key :flow-key))
  `(and
    #\[
    (? ,(prule 's-separate n c))
    (? ,(prule 'ns-s-flow-seq-entries n (in-flow c)))
    #\])
  (:lambda (stuff)
    (destructuring-bind (ob sep meat cb)
	stuff
      (declare (ignorable ob sep cb))
      (cons 'seq meat))))

;; rule 138
(define-parameterized-rule ns-s-flow-seq-entries (n (c :flow-out :flow-in 
						 :block-key :flow-key))
  `(and
    ,(prule 'ns-flow-seq-entry n c)
    (? ,(prule 's-separate n c))
    (?
     (and #\,
	  (? ,(prule 's-separate n c))
	  (? ,(prule 'ns-s-flow-seq-entries n c)))))
  (:lambda (stuff)
    (destructuring-bind
	  (first _ maybe-more) stuff
      (declare (ignore _))
	(cons  first (third maybe-more)))))
    
;; rule 139
(define-parameterized-rule ns-flow-seq-entry (n (c :flow-out :flow-in 
						   :block-key :flow-key))
  `(or
    ,(prule 'ns-flow-pair n c)
    ,(prule 'ns-flow-node n c)))


;;rule 140
(define-parameterized-rule c-flow-mapping (n (c :flow-out :flow-in 
						:block-key :flow-key))
  `(and
    "{"
    (? ,(prule 's-separate n c))
    (? ,(prule 'ns-s-flow-map-entries n (in-flow c)))
    "}")
  (:lambda (stuff)
    (destructuring-bind (ob sep meat cb) stuff
      (declare (ignore ob sep cb))
      (cons 'map meat))))

;;rule 141
(define-parameterized-rule ns-s-flow-map-entries (n (c :flow-out :flow-in 
						       :block-key :flow-key))
  `(and
    ,(prule 'ns-flow-map-entry n c)
    (? ,(prule 's-separate n c))
    (?
     (and #\,
	  (? ,(prule 's-separate n c))
	  (? ,(prule 'ns-s-flow-map-entries n c)))))
  (:lambda (stuff)
    (destructuring-bind
	  (first _ maybe-more) stuff
      (declare (ignorable _))
      (cons  first (third maybe-more)))))

;; rule 142
(define-parameterized-rule ns-flow-map-entry (n (c :flow-out :flow-in 
						   :block-key :flow-key))
  `(or
   (and "?"
	,(prule 's-separate n c)
	,(prule 'ns-flow-map-explicit-entry n c))
   ,(prule 'ns-flow-map-implicit-entry n c)))

;;rule 143
(define-parameterized-rule ns-flow-map-explicit-entry (n (c :flow-out :flow-in 
							    :block-key :flow-key))
  `(or
    ,(prule 'ns-flow-map-implicit-entry n c)
    (and e-node e-node)))

;; rule 144
(define-parameterized-rule ns-flow-map-implicit-entry (n (c :flow-out :flow-in 
							    :block-key :flow-key))
  `(or
    ,(prule 'ns-flow-map-yaml-key-entry n c)
    ,(prule 'c-ns-flow-map-empty-key-entry n c)
    ,(prule 'c-ns-flow-map-json-key-entry n c)))

;; rule 145
(define-parameterized-rule ns-flow-map-yaml-key-entry (n (c :flow-out :flow-in 
							    :block-key :flow-key))
  `(and
    ,(prule 'ns-flow-yaml-node n c)
    (or
     (and (? ,(prule 's-separate n c))
	  ,(prule 'c-ns-flow-map-separate-value n c))
     e-node))
  (:lambda (stuff)
    (destructuring-bind (key value)
	stuff
	`(entry ,key
		,(if (eql value 'yaml-null)
		     value
		     (second value))))))

;;rule 146
(define-parameterized-rule c-ns-flow-map-empty-key-entry (n (c :flow-out :flow-in 
							       :block-key :flow-key))
  `(and e-node
	,(prule 'c-ns-flow-map-separate-value n c))
  (:lambda (x)
    (cons 'entry x)))

;; rule 147
(define-parameterized-rule c-ns-flow-map-separate-value (n (c :flow-out :flow-in 
							      :block-key :flow-key))
  `(and
    #\:
    (! ,(prule 'ns-plain-safe-follows c))
    (or
     (and ,(prule 's-separate n c)
	  ,(prule 'ns-flow-node n c))
     (and (and) e-node)))
  (:lambda (stuff)
    (destructuring-bind (_ __ (___ value)) stuff
      (declare (ignore _ __ ___))
      value)))

;; rule 148
(define-parameterized-rule c-ns-flow-map-json-key-entry (n (c :flow-out :flow-in 
							      :block-key :flow-key))
  `(and
    ,(prule 'c-flow-json-node n c)
    (or
     (and
      (? ,(prule 's-separate n c))
      ,(prule 'c-ns-flow-map-adjacent-value n c))
     (and (and) e-node)))
  (:destructure
   (key (_ value))
   (declare (ignore _))
   (list 'entry key value)))

;; rule 149
(define-parameterized-rule c-ns-flow-map-adjacent-value (n (c :flow-out :flow-in 
							      :block-key :flow-key))
  `(and
    #\:
    (or
     (and (? ,(prule 's-separate n c))
	  ,(prule 'ns-flow-node n c))
     (and (and) e-node)))
  (:destructure
   (_ (__ value))
   (declare (ignore _ __))
   value))

;;rule 150
(define-parameterized-rule ns-flow-pair (n c)
  `(or
    (and
     #\?
     ,(prule 's-separate n c)
     ,(prule 'ns-flow-map-explicit-entry n c))
    (and
     ""
     ""
    ,(prule 'ns-flow-pair-entry n c)))
  (:lambda (x)
    (if (eql 'entry (car (third x)))
    `(map (entry ,@(cdr (third x))))
    `(map (entry ,@(third x))))))

;;rule 151
(define-parameterized-rule ns-flow-pair-entry (n c)
  `(or
   ,(prule 'ns-flow-pair-yaml-key-entry n c)
   ,(prule 'c-ns-flow-map-empty-key-entry n c)
   ,(prule 'c-ns-flow-pair-json-key-entry n c)))

;; rule 152
(define-parameterized-rule ns-flow-pair-yaml-key-entry (n c)
  `(and ,(prule 'ns-s-implicit-yaml-key :flow-key)

	,(prule 'c-ns-flow-map-separate-value n c)))

;; rule 153
(define-parameterized-rule c-ns-flow-pair-json-key-entry (n c)
  `(and
    ,(prule 'c-s-implicit-json-key :flow-key)
    ,(prule 'c-ns-flow-map-adjacent-value n c)))

;; rule 154
(defun size-check (fn limit input start end &rest args)
  (multiple-value-bind (result next valid)
      (apply fn input start end args)
    (cond
      ((not valid)
       (return-from size-check (values result next valid)))
      ((and next (> (- next start) limit))
       (return-from size-check (values nil start nil)))
      ((and (not next)
	    (> (- end start) limit))
       (return-from size-check (values nil start nil)))
      (t
       (values result next valid)))))

(defun ns-s-implicit-yaml-key (input start end c)
  (size-check #'ns-s-implicit-yaml-key-helper 1024 input start end c))

(define-parameterized-rule ns-s-implicit-yaml-key-helper (c)
  `(and
    ,(prule 'ns-flow-yaml-node 0 c)
    (? s-separate-in-line))
  (:function car))

;; rule 155
(defun c-s-implicit-json-key (input start end c)
  (size-check #'c-s-implicit-json-key-helper 1024 input start end c))

(define-parameterized-rule c-s-implicit-json-key-helper (c)
  `(and
    ,(prule 'c-flow-json-node 0 c)
    (? s-separate-in-line))
  (:function car))

(define-parameterized-rule ns-flow-yaml-content (n c)
  (prule 'ns-plain n c))

;; rule 157
(define-parameterized-rule c-flow-json-content (n C)
  `(or
    ,(prule 'c-flow-sequence n c)
    ,(prule 'c-flow-mapping n c)
    ,(prule 'c-single-quoted n c)
    ,(prule 'c-double-quoted n c)))

;; rule 158
(define-parameterized-rule ns-flow-content (n c)
  `(or
    ,(prule 'ns-flow-yaml-content n c)
    ,(prule 'c-flow-json-content n c)))

;; rule 159
(define-parameterized-rule ns-flow-yaml-node (n c)
  `(or
    c-ns-alias-node
    ,(prule 'ns-flow-yaml-content n c)
    (and
     ,(prule 'c-ns-properties n c)
     (or
      (and
       ,(prule 's-separate n c)
       ,(prule 'ns-flow-yaml-content n c))
      (and
       "" 				; To make destructuring easier
       e-scalar))))
  (:lambda (x)
    (trivia:match x
      (`(alias ,@_) x)
      (`((properties ,@props) (,_ ,content))
	`((properties ,@props) ,content))
      (_ x))))

;; rule 160
(define-parameterized-rule c-flow-json-node (n c)
  `(and
    (?
     (and
      ,(prule 'c-ns-properties n c)
      ,(prule 's-separate n c)))
    ,(prule 'c-flow-json-content n c))
  (:destructure (props meat)
		(if props
		    `(,(car props) ,meat)
		    meat)))


;; rule 161
(define-parameterized-rule ns-flow-node (n c)
  `(or
    c-ns-alias-node
    ,(prule 'ns-flow-content n c)
    (and
      ,(prule 'c-ns-properties n c)
      (or
       (and
	,(prule 's-separate n c)
	,(prule 'ns-flow-content n c))
       (and
	""				; To make destructuring simpler
	e-scalar))))
  (:lambda (x)
    (trivia:match x
      (`(alias ,@_) x)
      (`((properties ,@props) (,_ ,content))
	`((properties ,@props) ,content))
      (_ x))))

;; rule 162
;; Note that I'm passing in the indentation level
;; This makes autodetection a lot easier
(define-parameterized-rule c-b-block-header (n)
  `(or
     (and
      ,(prule 'c-indentation-indicator n)
      c-chomping-indicator
      s-b-comment)
     (and
      c-chomping-indicator
      ,(prule 'c-indentation-indicator n)
      s-b-comment))
  (:destructure (a b c)
		(declare (ignore c))
		(append a b)))

;; rule 163
(defrule indent-level-helper (and b-break (* s-space) (! b-break)))

(defun detect-indentation-level (n input start end)
  (let ((result (c-indentation-indicator input start end n)))
    (when (second result) (+ n (second result)))))

(defun auto-detect-indentation (input start end)
  (let ((original-start start))
    (multiple-value-bind (_ newstart success)
	(esrap:parse 's-b-comment input :start start :end end :junk-allowed t)
      (declare (ignorable _))
      (when (and success newstart) (setf start newstart)))
    (loop
      with prod
      with position
      with result
      with last-start = start
      with most-whitespace = 0
      for possible-start = (if (= start 0)
			       0 ;(1- start)
			       (position-if (rcurry #'member '(#\Newline #\Return)) input
					    :start (1- start)))
	then (position-if (rcurry #'member '(#\Newline #\Return)) input
			  :start (1+ possible-start))
      while possible-start
      do (setf most-whitespace (max most-whitespace (- possible-start last-start 1))
	       last-start  possible-start) ; the -1 is to account for newline
      when (not (or (= possible-start 0) (member (elt input possible-start) '(#\Newline #\Return))))
	return (values nil nil "Unable to detect indentation 2")
      do (setf (values prod position result)
	       (esrap:parse 'indent-level-helper
			    input :start possible-start
			    :end end :junk-allowed t))
	 ;; do (format t "~&~S ~S ~S ~S~%" possible-start prod position result)
      when result
	do (if (>= (length (second prod)) most-whitespace)
	       (return (values (length (second prod)) original-start t))
	       (return (values nil nil "Too much whitespace on blank line")))
      finally (return (values nil nil "Unable to detect indentation")))))

(defrule ns-dec-digit-positive
    (and
     (! #\0)
     ns-dec-digit)
  (:destructure (_ x)
    (declare (ignore _))
    x))

(define-parameterized-rule c-indentation-indicator (n)
  `(or 
    ns-dec-digit-positive
    (function auto-detect-indentation))
  (:lambda  (x)
    (list 'indent
	  (if (characterp x) (parse-integer (string x)) (- x n)))))

(define-parameterized-rule foo (n)
  (prule 'c-b-block-header n))

;;rule 164
(defrule c-chomping-indicator
    (or #\-
	#\+
	(and))
  (:lambda (x)
    (list 'chomp
	  (cond
	    ((string= x "-") :strip)
	    ((string= x "+") :keep)
	    ((eql x nil)     :clip)))))
      
;; rule 165
(define-parameterized-rule b-chomped-last (tee)
  (case tee
    (:strip '(or b-non-content eof))
    (:clip  '(or b-as-line-feed eof))
    (:keep '(or b-as-line-feed eof))))

;; rule 166
(define-parameterized-rule l-chomped-empty (n tee)
  (if (member tee '(:strip :clip))
      (prule 'l-strip-empty n)
      (prule 'l-keep-empty n)))

;; rule 167
(define-parameterized-rule l-strip-empty (n)
  `(and
   (*
    (and ,(prule 's-indent-<= n)
	 b-non-content))
   (? ,(prule 'l-trail-comments n)))
  (:constant nil))

;; rule 168
(define-parameterized-rule l-keep-empty (n)
  `(and
    (* ,(prule 'l-empty n :block-in))
    (? ,(prule 'l-trail-comments n)))
  (:destructure (keep _)
		(declare (ignore _))
		keep))

;;rule 169
(define-parameterized-rule l-trail-comments (n)
  `(and
    ,(prule 's-indent-< n)
    c-nb-comment-text
    b-comment
    l-comment-*))

;;rule 170
(defun block-header-then (input start end n next)
  (multiple-value-bind (production position result)
      (c-b-block-header input start end n)
    (when (not result)
      (return-from block-header-then
	(values production position result)))
    (let ((m (getf production 'indent))
	  (tee (getf production 'chomp)))
      (princ m) (princ tee) (terpri)
      (when (<= m 0)			; hack to handle cases with all blank lines
	(setf m 1))
      (funcall next input position end (+ n m) tee))))

(define-parameterized-rule c-l+literal (n)
  `(and
    #\|
    ,(prule 'block-header-then n 'l-literal-content))
  (:lambda (x)
    (text (second x))))

;; rule 171
(define-parameterized-rule l-nb-literal-text (n)
  `(and
    (* ,(prule 'l-empty n :block-in))
    ,(prule 's-indent n)
    (+ nb-char))
  (:lambda (x)
    ;(princ x)(terpri)
    (text (append (car x) (cddr x)))))

;; rule 172
(define-parameterized-rule b-nb-literal-next (n)
  `(and
    b-as-line-feed
    ,(prule 'l-nb-literal-text n)))

;; rule 173
(define-parameterized-rule l-literal-content (n tee)
  `(and
    (?
     (and
      ,(prule 'l-nb-literal-text n)
      (* ,(prule 'b-nb-literal-next n))
      ,(prule 'b-chomped-last tee)))
    ,(prule 'l-chomped-empty n tee))
  (:lambda (x)
    x))

;;rule 174
(define-parameterized-rule c-l+folded (n)
  `(and
    #\>
    ,(prule 'block-header-then n 'l-folded-content))
  (:destructure (bracket meat)
		(declare (ignore bracket)) (text meat)))

;; rule 175
(define-parameterized-rule s-nb-folded-text (n)
  `(and
    ,(prule 's-indent n)
    ns-char
    (* nb-char))
  (:lambda (x)
    (text (cdr x))))

;; rule 176
(define-parameterized-rule l-nb-folded-lines (n)
  `(and
    ,(prule 's-nb-folded-text n)
    (and
     (* (and
	 ,(prule 'b-l-folded n :block-in)
	 ,(prule 's-nb-folded-text n))))))

;; rule 177
(define-parameterized-rule s-nb-spaced-text (n)
  `(and
    ,(prule 's-indent n)
    s-white
    (* nb-char))
  (:destructure (indent space text)
		(declare (ignore indent))
		(text (list space text))))

;;rule 178
(define-parameterized-rule b-l-spaced (n)
  `(and
    b-as-line-feed
    (* ,(prule 'l-empty n :block-in))))

;; rule 179
(define-parameterized-rule l-nb-spaced-lines (n)
  `(and
    ,(prule 's-nb-spaced-text n)
    (* (and ,(prule 'b-l-spaced n)
	    ,(prule 's-nb-spaced-text n)))))

;; rule 180
(define-parameterized-rule l-nb-same-lines (n)
  `(and
    (* ,(prule 'l-empty n :block-in))
    (or ,(prule 'l-nb-folded-lines n)
	,(prule 'l-nb-spaced-lines n))))

;; rule 181
(define-parameterized-rule l-nb-diff-lines (n)
  `(and
    ,(prule 'l-nb-same-lines n)
    (* (and b-as-line-feed ,(prule 'l-nb-same-lines n)))))

;; rule 182
(define-parameterized-rule l-folded-content (n tee)
  `(and
    (? (and ,(prule 'l-nb-diff-lines n)
	    ,(prule 'b-chomped-last tee)))
    ,(prule 'l-chomped-empty n tee)))
     
;; rule 183
(define-parameterized-rule l+block-sequence (n)
  (let ((next-indent (detect-indentation-level n input position end)))
    (if (and next-indent
	     (> next-indent n))
	`(+
	  (and
	   ,(prule 's-indent next-indent)
	   ,(prule 'c-l-block-seq-entry next-indent)))
	'(or)))
  (:lambda (x)
    (cons 'seq
	  (mapcar #'second x))))

;; rule 184
(define-parameterized-rule c-l-block-seq-entry (n)
  `(and
    #\-
    (& (! ns-char))
    ,(prule 's-l+block-indented n :block-in))
  (:function third))

;;rule 185
(defun spaces-from-position (input position end)
  (length (esrap:parse '(* s-space) input :start position :end end
		       :junk-allowed t)))

(define-parameterized-rule compact-helper (n m)
  `(and
    ,(prule 's-indent m)
    (or
     ,(prule 'ns-l-compact-sequence (+ n m 1))
     ,(prule 'ns-l-compact-mapping (+ n m 1))))
  (:function second))
    
  
(define-parameterized-rule s-l+block-indented (n c)
  (let ((m (spaces-from-position input position end)))
    `(or
      ,(if (> m 0)
	   `(and
	     ,(prule 'compact-helper n m)
	    (and))
	   '(or))
      (and
       ,(prule 's-l+block-node n c)
       (and))
      (and e-node s-l-comments)))
  (:destructure (meat _)
		(declare (ignore _))
		meat))

;; rule 186
(define-parameterized-rule ns-l-compact-sequence (n)
  `(and
    ,(prule 'c-l-block-seq-entry n)
    (*
     (and ,(prule 's-indent n)
	  ,(prule 'c-l-block-seq-entry n))))
  (:lambda (x)
    `(seq ,(car x) ,@(mapcar #'second (second x)))))

;; rule 187
(define-parameterized-rule l+block-mapping (n)
  ;; next-indent here is what the YAML grammer refers to as m+n
  (let ((next-indent (detect-indentation-level n input position end)))
    (if (and next-indent
	     (> next-indent n))
	`(+
	  (and ,(prule 's-indent next-indent)
	       ,(prule 'ns-l-block-map-entry next-indent)))
	'(or)))
  (:lambda (x)
    (cons 'map
    (mapcar #'second x))))

;;rule 188
(define-parameterized-rule ns-l-block-map-entry (n)
  `(or
   ,(prule 'c-l-block-map-explicit-entry n)
   ,(prule 'ns-l-block-map-implicit-entry n)))

;; rule 189
(define-parameterized-rule c-l-block-map-explicit-entry (n)
  `(and
    ,(prule 'c-l-block-map-explicit-key n)
    (or
     ,(prule 'l-block-map-explicit-value n)
     e-node))
  (:lambda (x)
    (cons 'entry x)))

;; rule 190
(define-parameterized-rule c-l-block-map-explicit-key (n)
  `(and
    #\?
    ,(prule 's-l+block-indented n :block-out))
  (:function second))

;; rule 191
(define-parameterized-rule l-block-map-explicit-value (n)
  `(and
    ,(prule 's-indent n)
    #\:
    ,(prule 's-l+block-indented n :block-out))
  (:function third))

;; rule 192
(define-parameterized-rule ns-l-block-map-implicit-entry (n)
  `(and
    (or ns-s-block-map-implicit-key e-node)
    ,(prule 'c-l-block-map-implicit-value n))
  (:lambda (x)
    (cons 'entry x)))

;; rule 193
(defun c-s-implicit-json-key-block-key (i p e)
  (c-s-implicit-json-key i p e :block-key))

(defun ns-s-implicit-yaml-key-block-key (i p e)
  (ns-s-implicit-yaml-key i p e :block-key))

(defrule ns-s-block-map-implicit-key
  (or
   (function c-s-implicit-json-key-block-key)
   (function ns-s-implicit-yaml-key-block-key)))

;; rule 194
(define-parameterized-rule c-l-block-map-implicit-value (n)
  `(and
    #\:
    (or
     (and
      ,(prule 's-l+block-node n :block-out)
      (and))
     (and e-node s-l-comments)))
  (:function caadr))

;; rule 195
(define-parameterized-rule ns-l-compact-mapping (n)
  `(and
    ,(prule 'ns-l-block-map-entry n)
    (*
     (and ,(prule 's-indent n)
	  ,(prule 'ns-l-block-map-entry n))))
  (:lambda (x)
    `(map ,(car x) ,@(mapcar #'second (cadr x)))))

;; rule 196
(define-parameterized-rule s-l+block-node (n c)
  `(or
    ,(prule 's-l+block-in-block n c)
    ,(prule 's-l+flow-in-block n)  ))

;; rule 197
(define-parameterized-rule s-l+flow-in-block (n) 
  `(and
    ,(prule 's-separate (+ n 1) :flow-out)
    ,(prule 'ns-flow-node (+ n 1) :flow-out)
    s-l-comments)
  (:function second))

;; rule 198
(define-parameterized-rule  s-l+block-in-block (n c) 
  `(or
    ,(prule 's-l+block-scalar n c) 
    ,(prule 's-l+block-collection n c)  ))

;;rule 199
(define-parameterized-rule s-l+block-scalar (n c) 
  `(and
    ,(prule 's-separate (1+ n) c)
    (?
     (and
      ,(prule 'c-ns-properties (1+ n) c)
      ,(prule 's-separate (1+ n) c) ))
    (or
     ,(prule 'c-l+literal n)
     ,(prule 'c-l+folded n)))
  (:destructure (_ props meat)
		(declare (ignore _))
	(if props
	    `(,(car props) ,meat)
	    meat)))

;;rule 200
(define-parameterized-rule s-l+block-collection (n c) 
  `(and
    (?
     (and
      ,(prule 's-separate (1+ n) c)
      ;;N.B see https://github.com/yaml/yaml-reference-parser/blob/master/build/yaml-spec-1.2.patch
      (or
       (and ,(prule 'c-ns-properties (1+ n) c) s-l-comments)
       (and c-ns-tag-property s-l-comments)
       (and c-ns-anchor-property) s-l-comments)
       (& s-l-comments)))
    s-l-comments
    (or
     ,(prule 'l+block-sequence (seq-spaces n c))
     ,(prule 'l+block-mapping n)))
  (:destructure (props comments sequence)
		(declare (ignore comments))
		(trivia:match props
		  (`(,_ ((properties ,x) ,@_) ,@_)
		    `((properties ,x) ,sequence))
		  (`(,_ ((,x) ,@_) ,@_)
		    `(((properties (,x))) ,sequence))
		  (_  sequence))))


;; rule 201
(defun seq-spaces (n c)
  (if (eql c :block-out)
      (1- n)
      n))

;; rule 202
(defrule l-document-prefix
    (or
     (and
      c-byte-order-mark
      l-comment-*)
     l-comment-*)
  (:constant nil))

;; rule 203
(defrule c-directives-end "---")

;; rule 204
(defrule c-document-end "...")

;; rule 205
(defrule l-document-suffix (and c-document-end s-l-comments))

;; rule 206
(defrule c-forbidden
    (and
     (function start-of-line)
     (or c-directives-end c-document-end)
     (or b-char s-white eof)))

;;rule 207
(defun find-next-forbidden (input position end)
  ;; This is slow, but simple
  (loop for i from position below end
     when (nth-value 2 (esrap:parse 'c-forbidden input
				    :start i
				    :end end
				    :junk-allowed t))
     return i
     finally (return end)))
       
(defun bare-doc-start (i p e)
  (let* ((end (find-next-forbidden i p e))
	 (result (multiple-value-list
		  (s-l+block-node i p end -1 :block-in))))
    (when (null (second result))
      (setf (second result) end))
    (values-list result)))

(defrule l-bare-document
    (function bare-doc-start)
  (:lambda (x)
    (list nil x)))

;;rule 208
(defrule empty-document (and e-node s-l-comments)
  (:constant '(nil yaml-null)))

(defrule l-explicit-document
    (and c-directives-end
	 (or l-bare-document
	     empty-document))
  (:function second))

;;rule 209
(defrule l-directive-document
    (and
     (+ l-directive)
     l-explicit-document)
  (:destructure (directives document)
	;; strip off the dummy directive from
	;; the bare document
	(list directives (second document))))

;;rule 210
(defrule l-any-document
    (or l-directive-document
	l-explicit-document
	l-bare-document))

;; rule 211
(defrule l-document-prefix-*
    (or
     l-document-prefix-+
     (and)))

(defrule l-document-prefix-+
    (or
     eof
     (and
      l-document-prefix
      l-document-prefix-+)
     l-document-prefix))

(defrule l-yaml-stream-helper-rule
    (or
     (and
      (+ l-document-suffix)
      l-document-prefix-*
      (? l-any-document))
     (and 
      l-document-prefix-*
      (and)
      l-explicit-document)
     l-document-prefix-+))

(defun l-yaml-stream-helper (input position end)
  (let (prod new-pos result)
    (loop
	do (setf (values prod new-pos result)
	       (esrap:parse
		'(or
		  (and
		   (+ l-document-suffix)
		   l-document-prefix-*
		   (? l-any-document))
		  (and 
		   l-document-prefix-*
		   (and)
		   l-explicit-document)
		  l-document-prefix-+)
		input
		:start position
		:end end
		:junk-allowed t))
       collect prod into total
       when (or (null new-pos)
		(= new-pos position))
       return (values total new-pos result)
       do (setf position new-pos))))


(defrule l-yaml-stream
    (and
     l-document-prefix-+
     (? l-any-document)
     (function l-yaml-stream-helper))
  (:lambda (x)
    `(documents
      ,(second x)
      ,@(remove nil (mapcar #'third (third x))))))
