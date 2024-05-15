
(import (scheme base)
        (scheme cxr)
        (scheme file)
        (scheme write)
        (scheme process-context)
        (srfi 1))
(cond-expand (gauche (import (sxml ssax)
                             (only (gauche base) make-write-controls))))

(define sxml
  (call-with-input-file (cadr (command-line))
    (lambda (port)
      (read-line port)
      (read-line port)
      (read-line port)
      (ssax:xml->sxml port '()))))

(define alist
  `((number . 300)
    (title . "Example title")
    (authors . ("John Doe" "Jane Doe"))
    (received . "1970-01-01")
    (draft-dates . ("1970-01-10" "1970-01-20"))
    (status . draft) ; draft/final/withdrawn
    (see-also . ("1: List Library" "1: List Library"))
    (keywords . (operating-system syntax))
    (finalized . "1970-02-01") ; or ISO 8601 date string
    (abstract . ,(list (list-ref (car (cddr (cadr (last (last sxml))))) 3)))
    (content . ,(drop (cdr (cddr (cadr (last (last sxml))))) 0))))

(call-with-output-file (caddr (command-line))
  (lambda (port)
    (write alist port (make-write-controls ':pretty #t))
    (newline port)))
