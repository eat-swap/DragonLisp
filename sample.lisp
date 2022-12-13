(defvar x (+ 3 6 9)) ;; x is 18
(print x)
(setq x (- 3 6 9)) ;; x is -12
(print x)

(defvar xconst (= (and 3 6 9) (or 9 6 3))) ;; xconst is T
(print xconst)

(pRiNt
	(>= (max 4 5 8 2 1 9) (min 3843 29 72 222))
); => NIL

(PrInT (not
	(>= (max 4 5 8 2 1 9) (min 3843 29 72 222))
)); => T

(setq
	x
	(logand (logior 28892 28348 29293) (logxor 118 48441 59410) (logeqv 3892 2938 2919))
) ; x <- 1033

(
    DeFuN fibonacci (x)
    (
        if (<= x 1)
        1
        (
            +
            (fibonacci (- x 1))
            (fibonacci (- x 2))
        )
    )
)

(fibonacci 15) ; returns 987

; This is a comment.
; This is another comment.

(print (+ 1 2 3 4 5)) ; prints 15

(print "Hello, world!") ; prints Hello, world!

(defvar lower_bound 1)
(loop
	for i from lower_bound to (+ 1505 -1495)
	do (print i)
) ; prints 1 2 3 4 5 6 7 8 9 10

(defvar i 1)
(loop (if (> i 5) (return i)) (incf i 3)) ; returns 7

(dotimes (i 10) (print i)) ; prints 0 1 2 3 4 5 6 7 8 9

(defvar arr (make-array 10))
(loop for i from 0 to 9 do (setf (aref arr i) i))
(loop for i from 0 to 9 do (print (aref arr i))) ; prints 0 1 2 3 4 5 6 7 8 9

(DoTiMeS (i (+ 99999 -99989)) (print i) (setf (aref arr i) (* i i i))) ; prints 0 1 2 3 4 5 6 7 8 9
(dOtImEs (i 10) (print (aref arr i))) ; prints 0 1 8 27 64 125 216 343 512 729
