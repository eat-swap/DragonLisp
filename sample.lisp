(
    defun f (x)
    (
        if (<= x 1)
        1
        (
            +
            (f (- x 1))
            (f (- x 2))
        )
    )
)

(f 15)
