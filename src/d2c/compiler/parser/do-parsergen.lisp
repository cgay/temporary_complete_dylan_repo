;;; -*- Package: PARSER -*-
;;;
;;; **********************************************************************
;;; Copyright (c) 1994 Carnegie Mellon University, all rights reserved.
;;; 
(ext:file-comment
  "$Header: /home/housel/work/rcs/gd/src/d2c/compiler/parser/do-parsergen.lisp,v 1.2 1995/12/11 15:33:48 wlott Exp $")
;;;
;;; **********************************************************************

(in-package :user)

(eval-when (compile load eval)
  (or (find-package :parser) (make-package :parser)))

(in-package :parser)
(use-package :ext)

(handler-case
    (progn
      (unless (= (length *command-line-words*) 2)
	(error
	 "usage: cmucl .../parsergen.lisp .../parser.input"))
      (let ((hpf-write-date (file-write-date "parsergen.hpf"))
	    (source-file (first *command-line-words*)))
	(if (or (not hpf-write-date)
		(< hpf-write-date (file-write-date source-file)))
	    (compile-file source-file :load t :output-file "parsergen.hpf")
	    (load "parsergen.hpf"))))
  (error (cond)
    (format *error-output* "~2&It didn't work:~%~A~%" cond)
    (quit 1)))

(handler-case
    (progn
      (grovel-file (second *command-line-words*) "parser.dylan")
      (quit 0))
  (error (cond)
    (format *error-output* "~2&It didn't work:~%~A~%" cond)
    (quit 1)))
