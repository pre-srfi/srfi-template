;; Convert an SXML structure into the HTML SRFI template.
;; SPDX-License-Identifier: MIT
;; TODO: An org-mode exporter would be nice too!

(import (scheme base)
        (scheme file)
        (scheme process-context)
        (scheme read)
        (scheme write)
        (srfi 1)
        (srfi 13)
        (srfi 19)
        (srfi 28))
(cond-expand (gauche (import (sxml serializer))))

;; HTML templates.

(define index-html-template "<!DOCTYPE html>
<html>
    <head>
      <!-- SPDX-FileCopyrightText: 2024 Arthur A. Gleckler -->
      <!-- SPDX-License-Identifier: MIT -->
      <title>~a</title>
      <link href=\"https://srfi.schemers.org/admin.css\" rel=\"stylesheet\">
      <link href=\"https://srfi.schemers.org/list.css\" rel=\"stylesheet\">
      <link href=\"/favicon.png\" rel=\"icon\" sizes=\"192x192\" type=\"image/png\">
      <meta charset=\"utf-8\">
      <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
      <script type=\"text/x-mathjax-config\">MathJax.Hub.Config({tex2jax: {inlineMath: [['$','$'], ['\\\\(','\\\\)']]}});</script>
      <script crossorigin=\"anonymous\" integrity=\"sha384-Ra6zh6uYMmH5ydwCqqMoykyf1T/+ZcnOQfFPhDrp2kI4OIxadnhsvvA2vv9A7xYv\" src=\"https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=TeX-AMS-MML_HTMLorMML\" type=\"text/javascript\"></script></head>
    <body>
      <h1>SRFI ~a: ~a</h1>
      <p class=\"authors\">by ~a</p>
      <p class=\"based-on\"></p>
      <p class=\"status\">status: <em>~a</em> (~a)</p>
      <p class=\"keywords\">keywords: ~a</p>
      ~a
      <ul class=\"info\">
        <li><a href=\"srfi-~a.html\">The SRFI Document</a></li>
        <li><a href=\"https://srfi-email.schemers.org/srfi-~a/\">Discussion Archive</a></li>
        <li><a href=\"https://github.com/scheme-requests-for-implementation/srfi-~a\">Git repo (on GitHub)</a></li>
        <li><a href=\"mailto:srfi-~a@srfi.schemers.org\">srfi-~a@<span class=\"antispam\">nospam</span>srfi.schemers.org (subscribers only)</a></li>
        <li><span class=\"firefox-column-workaround\">
            <form method=\"POST\" action=\"https://www.simplelists.com/subscribe.php\">
              <div class=\"title\">Subscribe to srfi-~a mailing list</div><input name=\"email\" placeholder=\"email address\" tabindex=\"1\" type=\"email\"><input name=\"name\" placeholder=\"full name\" tabindex=\"2\" type=\"text\">
              <p><input id=\"sub-digest\" name=\"digest\" tabindex=\"3\" type=\"checkbox\" value=\"digest\"><label for=\"sub-digest\">daily digest?</label></p><input class=\"submit\" name=\"submit\" tabindex=\"4\" type=\"submit\" value=\"Subscribe to srfi-~a\"><input type=\"hidden\" name=\"action\" value=\"subscribe\"><input type=\"hidden\" name=\"list\" value=\"srfi-~a@srfi.schemers.org\"></form></span></li>
        <li><span class=\"firefox-column-workaround\">
            <form method=\"POST\" action=\"https://www.simplelists.com/subscribe.php\">
              <div class=\"title\">Unsubscribe from srfi-~a mailing list</div><input name=\"email\" placeholder=\"email address\" tabindex=\"5\" type=\"email\"><input class=\"submit\" name=\"submit\" tabindex=\"6\" type=\"submit\" value=\"Unsubscribe from srfi-~a\"><input type=\"hidden\" name=\"action\" value=\"unsubscribe\"><input name=\"list\" type=\"hidden\" value=\"srfi-~a@srfi.schemers.org\"></form></span></li></ul>
      <h2>Abstract</h2>
      ~a
    </body>
</html>")

(define readme-org-template "
# SPDX-FileCopyrightText: ~a Arthur A. Gleckler
# SPDX-License-Identifier: MIT
* SRFI ~a: ~a

** by ~a



keywords: ~a

This repository hosts [[https://srfi.schemers.org/srfi-~a/][SRFI ~a]]: ~a, a [[https://srfi.schemers.org/][Scheme Request for Implementation]].

This SRFI is in /~a/ status.
~a.
The full documentation for this SRFI can be found in the [[https://srfi.schemers.org/srfi-~a/srfi-~a.html][SRFI Document]].

If you'd like to participate in the discussion of this SRFI, or report issues with it, please [[https://srfi.schemers.org/srfi-~a/][join the SRFI-~a mailing list]] and send your message there.

Thank you.

[[mailto:srfi-editors@srfi.schemers.org][The SRFI Editors]]\n")

(define srfi-html-template "<!DOCTYPE html>
<html lang=\"en\">
  <head>
<!--
SPDX-FileCopyrightText: ~a ~a
SPDX-License-Identifier: MIT
-->
    <meta charset=\"utf-8\">
    <title>~a: ~a</title>
    <link href=\"/favicon.png\" rel=\"icon\" sizes=\"192x192\" type=\"image/png\">
    <link rel=\"stylesheet\" href=\"https://srfi.schemers.org/srfi.css\" type=\"text/css\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
    <style>
     small { font-size: 14px; vertical-align: 2px; }
     body  { line-height: 24px; }
     pre  { font-family: inherit; line-height: 20px; }
    </style>
  </head>
  <body>
    <h1><a href=\"https://srfi.schemers.org/\"><img class=\"srfi-logo\" src=\"https://srfi.schemers.org/srfi-logo.svg\" alt=\"SRFI surfboard logo\" /></a>~a: ~a</h1>

<p>by ~a</p>

<h2 id=\"status\">Status</h2>

    <p>
      This SRFI is currently in <em>~a</em> status.
      Here is <a href=\"https://srfi.schemers.org/srfi-process.html\">an explanation</a> of each status that a SRFI can hold.
      To provide input on this SRFI, please send email to <code><a href=\"mailto:srfi+minus+~a+at+srfi+dotschemers+dot+org\">srfi-~a@<span class=\"antispam\">nospam</span>srfi.schemers.org</a></code>.
      To subscribe to the list, follow <a href=\"https://srfi.schemers.org/srfi-list-subscribe.html\">these instructions</a>.
      You can access previous messages via the mailing list <a href=\"https://srfi-email.schemers.org/srfi-~a/\">archive</a>.
    </p>

    <ul>
      <li>Received: ~a</li>
~a
      ~a
    </ul>

<h2 id=\"abstract\">Abstract</h2>

~a

~a

<h2 id=\"copyright\">Copyright</h2>
<p>&copy; ~a ~a</p>

<p>
  Permission is hereby granted, free of charge, to any person
  obtaining a copy of this software and associated documentation files
  (the \"Software\"), to deal in the Software without restriction,
  including without limitation the rights to use, copy, modify, merge,
  publish, distribute, sublicense, and/or sell copies of the Software,
  and to permit persons to whom the Software is furnished to do so,
  subject to the following conditions:</p>

<p>
  The above copyright notice and this permission notice (including the
  next paragraph) shall be included in all copies or substantial
  portions of the Software.</p>
<p>
  THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.</p>

  <hr>
  <address>Editor: <a href=\"mailto:srfi-editors+at+srfi+dot+schemers+dot+org\">~a</a></address>
  </body>
</html>\n")

;; Helpers.

;; Remove the tag prefix Gauche adds.
(define (filter-prefix str)
  (let loop ((str str))
    (let ((prfx (string-contains str "prfx1:")))
      (if prfx
          (loop (string-append (string-take str prfx)
                               (string-drop str (+ prfx 6))))
          str))))

(define (sxml->string tree)
  (cond-expand
   (gauche
    (filter-prefix (srl:sxml->html tree)))))

(define (assoc-ref key alist)
  (let ((pair (assoc key alist)))
    (and pair (cdr pair))))

(define (iso-date->date str)
  (string->date str "~Y-~m-~d"))

(define (authors->string lst)
  (cond ((= (length lst) 1)
         (car lst))
        ((= (length lst) 2)
         (string-append (car lst) " and " (cadr lst)))
        (else
         (let ((last-name (string-append "and " (last lst))))
           (string-join (append (drop-right lst 1) (list last-name)) ", ")))))

(define (revisions->tags revs)
  (string-join
   (map (lambda (num rev)
          (format "      <li>Draft #~a published: ~a</li>" num rev))
        (iota (length revs) 1)
        revs)
   "\n"))

(define (see-also->org-links see-alsos)
  (if (null? see-alsos)
      ""
      (string-append
       "See also "
       (cond ((= (length see-alsos) 1)
              (format "[[/srfi-~a/][SRFI ~a]]"
                      (string-take (car see-alsos)
                                   (string-index (car see-alsos) #\:))
                      (car see-alsos)))
             ((= (length see-alsos) 2)
              (format "[[/srfi-~a/][SRFI ~a]] and [[/srfi-~a/][SRFI ~a]]"
                      (string-take (car see-alsos)
                                   (string-index (car see-alsos) #\:))
                      (car see-alsos)
                      (string-take (cadr see-alsos)
                                   (string-index (cadr see-alsos) #\:))
                      (cadr see-alsos)))
             (else
              (string-join
               (append (map (lambda (see-also)
                              (format "[[/srfi-~a/][SRFI ~a]]"
                                      (string-take see-also
                                                   (string-index see-also #\:))
                                      see-also))
                            (drop-right see-alsos 1))
                       (list (format "and [[/srfi-~a/][SRFI ~a]]"
                                     (string-take
                                      (last see-alsos)
                                      (string-index (last see-alsos) #\:))
                                     (last see-alsos))))
               ", "))))))

(define (see-also->html-links see-alsos)
  (if (null? see-alsos)
      ""
      (format
       "<span class=\"see-also\">See also ~a.</span>"
       (cond ((= (length see-alsos) 1)
              (format "<a href=\"/srfi-~a/\">SRFI ~a</a>"
                      (string-take (car see-alsos)
                                   (string-index (car see-alsos) #\:))
                      (car see-alsos)))
             ((= (length see-alsos) 2)
              (format "<a href=\"/srfi-~a/\">SRFI ~a</a> and <a href=\"/srfi-~a/\">SRFI ~a</a>"
                      (string-take (car see-alsos)
                                   (string-index (car see-alsos) #\:))
                      (car see-alsos)
                      (string-take (cadr see-alsos)
                                   (string-index (cadr see-alsos) #\:))
                      (cadr see-alsos)))
             (else
              (string-join
               (append (map (lambda (see-also)
                              (format "<a href=\"/srfi-~a/\">SRFI ~a</a>"
                                      (string-take see-also
                                                   (string-index see-also #\:))
                                      see-also))
                            (drop-right see-alsos 1))
                       (list (format "and <a href=\"/srfi-~a/\">SRFI ~a</a>"
                                     (string-take
                                      (last see-alsos)
                                      (string-index (last see-alsos) #\:))
                                     (last see-alsos))))
               ", "))))))

(define (keyword->string keyword)
  (cond ((eq? keyword 'algorithm) "Algorithm")
        ((eq? keyword 'assignment) "Assignment")
        ((eq? keyword 'binding) "Binding")
        ((eq? keyword 'comparison) "Comparison")
        ((eq? keyword 'concurrency) "Concurrency")
        ((eq? keyword 'continuations) "Continuations")
        ((eq? keyword 'control-flow) "Control Flow")
        ((eq? keyword 'data-structure) "Data Structure")
        ((eq? keyword 'error-handling) "Error Handling")
        ((eq? keyword 'exceptions) "Exceptions")
        ((eq? keyword 'features) "Features")
        ((eq? keyword 'garbage-collection) "Garbage Collection")
        ((eq? keyword 'i/o) "I/O")
        ((eq? keyword 'internationalization) "Interationalization")
        ((eq? keyword 'introspection) "Introspection")
        ((eq? keyword 'lazy-evaluation) "Lazy Evaluation")
        ((eq? keyword 'miscellaneous) "Miscellaneous")
        ((eq? keyword 'modules) "Modules")
        ((eq? keyword 'multiple-value-returns) "Multiple-Value Returns")
        ((eq? keyword 'numbers) "Numbers")
        ((eq? keyword 'operating-system) "Operating System")
        ((eq? keyword 'optimization) "Optimization")
        ((eq? keyword 'parameters) "Parameters")
        ((eq? keyword 'pattern-matching) "Pattern Matching")
        ((eq? keyword 'r6rs-process) "R6RS Process")
        ((eq? keyword 'r7rs-large) "R7RS Large")
        ((eq? keyword 'r7rs-large-red) "R7RS Large: Red Edition")
        ((eq? keyword 'r7rs-large-tangerine) "R7RS Large: Tangerine Edition")
        ((eq? keyword 'randomness) "Randomness")
        ((eq? keyword 'reader-syntax) "Reader Syntax")
        ((eq? keyword 'sicp) "SICP")
        ((eq? keyword 'superseded) "Superseded")
        ((eq? keyword 'syntax) "Syntax")
        ((eq? keyword 'testing) "Testing")
        ((eq? keyword 'type-checking) "Type Checking")
        (else (error "Unrecognized keyword: " keyword))))

(define (keywords->org-links keywords)
  (string-join
   (map (lambda (kw)
          (format "[[https://srfi.schemers.org/?keywords=~a][~a]]"
                  (symbol->string kw)
                  (keyword->string kw)))
        keywords)
   " "))

(define (keywords->html-links keywords)
  (string-join
   (map (lambda (kw)
          (format "<a href=\"https://srfi.schemers.org/?keywords=~a\">~a</a>"
                  (symbol->string kw)
                  (keyword->string kw)))
        keywords)
   " "))

(define (status->string status)
  (cond ((eq? status 'draft) "draft")
        ((eq? status 'final) "final")
        ((eq? status 'withdrawn) "withdrawn")
        (else (error "Unrecognized status: " status))))

;; srfi-???.html generator code begins here.

;; Accepts an alist of the format:
;; '((number . 300)
;;   (title . "Example")
;;   (authors . ("John Doe"))
;;   (abstract . ((p "Example text...")))
;;   (received . "1970-01-01")
;;   (draft-dates . ("1970-01-10" ...))
;;   (status . draft) ; final/withdrawn/draft
;;   (see-also . ("1: List Library"))
;;   (keywords . (operating-system r7rs-large-red)) ; matches filter URL
;;   (finalized . #f) ; or ISO 8601 date string
;;   (content . ((h2 (@ (id "rationale")) "Rationale") ...)))
;;
;; Do not include copyright section in the SXML.
;;
;; Returns the entire HTML as a string.
(define (alist->srfi-html alist)
  (let* ((finalized (assoc-ref 'finalized alist))
         (authors-str (authors->string (assoc-ref 'authors alist)))
         (received (assoc-ref 'received alist))
         (title (assoc-ref 'title alist))
         (status (assoc-ref 'status alist))
         (revisions (assoc-ref 'draft-dates alist))
         (abstract (assoc-ref 'abstract alist))
         (body (assoc-ref 'content alist))
         (year (if finalized
                   (number->string (date-year (iso-date->date finalized)))
                   (number->string (date-year (iso-date->date received)))))
         (num (number->string (assoc-ref 'number alist)))
         (editor "Arthur A. Gleckler"))
    (format srfi-html-template
            year authors-str num title num title authors-str status num num num
            received
            (revisions->tags revisions)
            (if finalized
                (string-append "<li>Finalized: " finalized "</li>")
                "")
            (sxml->string abstract)
            (sxml->string body)
            year authors-str editor)))

;; Like alist->srfi-html, but writes to a file in the current directory.
;; Returns #f.
(define (alist->srfi-html-file alist)
  (let ((fname (string-append "srfi-"
                              (number->string (assoc-ref 'number alist))
                              ".html")))
    (call-with-output-file fname
      (lambda (port)
        (display (alist->srfi-html alist) port)))))

;; README.org generator code begins here.

;; Return a string containing the contents of README.org.
(define (alist->readme-org alist)
  (let* ((finalized (assoc-ref 'finalized alist))
         (received (assoc-ref 'received alist))
         (authors-str (authors->string (assoc-ref 'authors alist)))
         (year (if finalized
                   (number->string (date-year (iso-date->date finalized)))
                   (number->string (date-year (iso-date->date received)))))
         (num (number->string (assoc-ref 'number alist)))
         (title (assoc-ref 'title alist))
         (status (assoc-ref 'status alist))
         (keywords (assoc-ref 'keywords alist))
         (see-also (assoc-ref 'see-also alist)))
    (format readme-org-template
            year num title authors-str
            (keywords->org-links keywords)
            num num title (status->string status)
            (see-also->org-links see-also)
            num num num num)))

;; Same as alist->readme-org but writes the README.org file to the current dir.
(define (alist->readme-org-file alist)
  (call-with-output-file "README.org"
    (lambda (port)
      (display (alist->readme-org alist) port))))

;; index.html generator code begins here.

(define (alist->index-html alist)
  (let* ((title (assoc-ref 'title alist))
         (num (number->string (assoc-ref 'number alist)))
         (authors-str (authors->string (assoc-ref 'authors alist)))
         (status (assoc-ref 'status alist))
         (finalized (assoc-ref 'finalized alist))
         (received (assoc-ref 'received alist))
         (see-also (assoc-ref 'see-also alist))
         (keywords (assoc-ref 'keywords alist))
         (abstract (assoc-ref 'abstract alist)))
    (format index-html-template
            title num title authors-str
            (status->string status)
            (if finalized finalized received)
            (keywords->html-links keywords)
            (see-also->html-links see-also)
            num num num num num num num num num num
            (sxml->string abstract)
            (sxml->string abstract))))

;; Same as alist->index-html but writes the index.html file to the current dir.
(define (alist->index-html-file alist)
  (call-with-output-file "index.html"
    (lambda (port)
      (display (alist->index-html alist) port))))

;; Entry point.

(define (gen-all alist)
  (alist->srfi-html-file alist)
  (alist->readme-org-file alist)
  (alist->index-html-file alist))

(call-with-input-file (cadr (command-line))
  (lambda (port)
    (gen-all (read port))))
