(in-package :cells)


(defvar *src-root*)
(defvar *c?*)
(defvar *cv*)
(defvar *c-making*)
(defvar *filename*)
(defvar *dump*)
(defvar *c-using*)
(defvar *c-defining*)

(defconstant *src-extension* "cl")

#+test
(dolist (f (directory (make-pathname :device "c"
                       :directory `(:absolute "cs2100"))))
  (print (list f (pathname-directory f))))

(count-directory (make-pathname :device "k"
                     :directory `(:absolute "OLD C drive" ))

(defun count-directory (dtree)
  (let ((directory (make-pathname :device "c"
                     :directory `(:absolute ,@dtree))))
    ;(print `(analyzing directory ,directory))
    (loop for file in (directory directory)
        for fname = (intern (pathname-name file))
        do (cond
            ((file-directory-p file)
             (c-analyze-directory
              (cdr (assoc fname
                     (pushnew (cons fname (copy-symbol fname))
                       (get ddb 'directories)
                       :key 'car)))
              (append dtree (list (pathname-name file)))))
            ((string-equal "CL" (pathname-type file))
             (with-open-file (in file :direction :input)
               ;;(print `(analyzingfile ,fname ,ddb))
               (c-analyze-file (cdar (push (cons fname (copy-symbol fname))
                                       (get ddb 'files))) in)))))))

(defun c-analyze-file (db stream &optional (istate 'init))
  (declare (ignorable istate))
  (loop with state = istate
      and word
      for char = (read-char stream nil :eof)
      when (eql char :eof) do (loop-finish) 
      do  (unless (or (and (or (eql char #\space) (eql char #\tab))
                        (eql state 'init))
                    (find state '(in-line-comment in-block-rem)))
            (incf (get db 'char-count 0)))
        (unless (find state '(init in-block-rem))
          (when (eql char #\newline)
            (incf (get db 'line-count 0))))
        (if (eql char #\newline)
            (progn
              (unless (find state '(in-block-rem))
                (incf (get db 'line-count 0)))
              (unless (find state '(in-string in-block-rem))
                (setf state 'init)))
          (ecase state
            ((init un-white)
             (cond
              ((or (alpha-char-p char)
                 (eql char #\*))
               (push char word)
               (setf state 'in-word))
              ((eql char #\;)
               (setf state 'in-line-comment)
               )
              ((eql char #\")
               (c-analyze-file db stream 'in-string)
               (setf state 'un-white))
              ((eql char #\#)
               (setf state 'got-octothorpe))
              ))
            
            (in-string
             (cond
              ((eql char #\\)
               (read-char stream))
              ((eql char #\")
               (ecase istate
                 (init (setf state 'un-white))
                 (in-string (return-from c-analyze-file)))))
             (let ((db (get db 'string (gensym))))
               (incf (get db 'count 0))
               (incf (get db 'char-count 0))))
            
            (got-octothorpe
             (cond
              ((eql char #\|)
               (let ((db (get db 'comments (gensym))))
                 (incf (get db 'count 0)))
               (c-analyze-file db stream 'in-block-rem)
               (setf state 'un-white))
              (t (ecase istate
                   (init (setf state 'un-white))
                   (got-octothorpe (return-from c-analyze-file))))))
            
            (in-block-rem
             (let ((db (get db 'comments (gensym))))
               (incf (get db 'char-count 0)))
             (cond
              ((eql char #\|)
               (let ((next (read-char stream)))
                 (when (eql next #\#)
                   (ecase istate
                     (init (setf state 'un-white))
                     (in-block-rem (return-from c-analyze-file))))))
              ((eql char #\#)
               (c-analyze-file db stream 'got-octothorpe))))
            
            (in-word
             (if (or (alphanumericp char)
                   (eql char #\-)
                   (eql char #\*))
                 (push char word)
               (progn
                 (setf state 'un-white)
                 (when word
                   (let ((sym (intern (string-upcase
                                       (coerce (nreverse word) 'string)))))
                     (when (or (member sym *c-defining*)
                             (member sym *c-using*)
                             (member sym *c-making*))
                       (incf (get db sym 0))))
                   (setf word nil)))))
            
            (in-line-comment
             (when (eql char #\newline)
               (setf state 'init)))))))



