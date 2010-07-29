(in-package :cl-user)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (setf *features* (pushnew  :its-alive! *features*)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (setf *features* (remove  :debugging-alive! *features*)))

