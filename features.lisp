(in-package :cl-user)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (setf *features* (remove  :its-alive! *features*)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (setf *features* (remove  :rms-s3 *features*)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (setf *features* (remove  :debugging-alive! *features*)))

