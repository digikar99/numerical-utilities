;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8 -*-

(in-package #:cl-num-utils)

(defun silent (&rest arguments)
  "Make arguments vanish.  Used to avoid large displays/their cost in
benchmarking."
  (declare (ignore arguments))
  (values))

(defmacro check-types ((&rest arguments) type)
  "CHECK-TYPE for multiple places of the same type.  Each argument is either a
place, or a list of a place and a type-string."
  `(progn
     ,@(iter
         (for argument :in arguments)
         (collecting (if (atom argument)
                         `(check-type ,argument ,type)
                         (bind (((place type-string) argument))
                           `(check-type ,place ,type ,type-string)))))))

(defmacro define-with-multiple-bindings (macro &key 
                                         (plural (intern (format nil "~aS" macro)))
                                         (docstring (format nil "Multiple binding version of ~(~a~)." macro)))
  "Define a version of `macro' with multiple arguments, given as a
list.  Application of `macro' will be nested.  The new name is the 
plural of the old one (generated using format by default)."
  `(defmacro ,plural (bindings &body body)
     ,docstring
     (if bindings
         `(,',macro ,(car bindings)
                    (,',plural ,(cdr bindings)
			       ,@body))
         `(progn ,@body))))

(defun concatenate-as-strings (args)
  (apply #'concatenate 'string (mapcar #'string args)))

(defun make-symbol-in (package &rest args)
  "Build a symbol by concatenating each element of ARGS as strings,
  and intern it in PACKAGE."
  (intern (concatenate-as-strings args) package))

(defun make-symbol* (&rest args)
  "Build a symbol by concatenating each element of ARGS as strings,
  and intern it (in *PACKAGE*, INTERN's default)."
  (apply #'make-symbol-in *package* args))

(defun make-keyword* (&rest args)
  "Build a symbol by concatenating each element of ARGS as strings,
  and intern it the KEYWORD package."
  (apply #'make-symbol-in (load-time-value (find-package :keyword)) args))

(defun gensym* (&rest args)
  "Gensym with concatenating each element of ARGS as strings."
  (gensym (concatenate-as-strings args)))

(defmacro define-make-symbol% (package &optional
                               (name (make-symbol-in package '#:make-symbol%)))
  "Define a MAKE-SYMBOL% that interns in PACKAGE."
  `(defun ,name (&rest args) 
     ,(format nil "Build a symbol by concatenating each element of ~
                   ARGS as strings, and intern it in ~A." package)
     (intern (concatenate-as-strings args) ,package)))


(defmacro lazy-let-block ((variable init-form) &body body)
  "Building block for LAZY-LET*.  Not exported."
  (with-unique-names (value flag)
    `(let (,value ,flag)
       (symbol-macrolet ((,variable (if ,flag 
                                        ,value
                                        (setf ,flag t 
                                              ,value ,init-form))))
         ,@body))))

(define-with-multiple-bindings lazy-let-block 
    :plural lazy-let*
    :docstring "Similar to LET*, except that the values are evaluated on demand.")