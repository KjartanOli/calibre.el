;;; calibre-util.el --- Utilities with no better place  -*- lexical-binding: t; -*-

;; Copyright (C) 2023  Kjartan Oli Agustsson

;; This file is part of calibre.el.

;; calibre.el is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; calibre.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with calibre.el.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; This file contains utility functions that either don't have a
;; better place, or can to be in their more logical place due to
;; circular dependency issues.

;;; Code:
(require 'calibre-book)

(defun calibre-util-find-book (book seq)
  "Find BOOK in SEQ."
  (seq-find (lambda (b)
              (= (calibre-book-id b)
                 (calibre-book-id book)))
            seq))

(defun calibre-library--find-book (book)
  "Move point to the line representing BOOK."
  (goto-char (point-min))
  (while (not (or (eobp)
                  (and (tabulated-list-get-id)
                       (= (calibre-book-id (tabulated-list-get-id))
                          (calibre-book-id book)))))
    (forward-line)))

(defun calibre-library--preserve-marks (&optional dont-preserve-modifications)
  "Return an alist mapping books to applied marks.
If DONT-PRESERVE-MODIFICATIONS is non-nil modification marks are not
preserved."
  (save-excursion
    (let (marks)
      (goto-char (point-min))
      (while (not (eobp))
        (unless (or (char-equal (char-after) 32)
                    (and dont-preserve-modifications (char-equal (char-after) ?M)))
          (push (cons (tabulated-list-get-id) (char-after)) marks))
        (forward-line))
      marks)))

(defun calibre-library--restore-marks (marks)
  "Restore previously stored marks.
MARKS should be the return value of `calibre-library--preserve-marks'"
  (save-excursion
    (dolist (mark marks)
      (let ((book (car mark))
            (mark (cdr mark)))
        (calibre-library--find-book book)
        (tabulated-list-put-tag (format "%c" mark))))))

(defmacro calibre-with-preserved-marks (preserve-modifications &rest body)
  "Save Library Marks, execute BODY, restore marks.
If PRESERVE-MODIFICATIONS is non-nil modification marks are
preserved.  If PRESERVE-MODIFICATIONS is nil modification marks
are not preserved.  This is primarily useful when BODY will
discard any modifications."
  (declare (indent 1))
  `(let ((marks (calibre-library--preserve-marks (not ,preserve-modifications))))
     (unwind-protect (progn ,@body)
       (calibre-library--restore-marks marks))))

(provide 'calibre-util)
;;; calibre-util.el ends here
