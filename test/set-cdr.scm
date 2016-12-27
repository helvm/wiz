(define list '(1 2 3))

(define length
  (lambda (lst)
    (if (nil? lst)
        0
        (+ 1 (length (cdr lst))))))

(set-cdr! list '(20 30))
