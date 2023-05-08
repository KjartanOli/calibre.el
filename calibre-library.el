;;; calibre-library.el --- View and interact with the Calibre library -*- lexical-binding:t -*-

;; Copyright (C) 2023  Kjartan Oli Agustsson

;; Author: Kjartan Oli Agustsson <kjartanoli@disroot.org>
;; Maintainer: Kjartan Oli Agustsson <kjartanoli@disroot.org>

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; View the contents of a Library, add new books, remove books, and
;; open books in Emacs.

;;; Code:
(require 'dired)
(require 'calibre-db)
(require 'calibre-book)
(require 'calibre-search)
(require 'calibre-virtual-library)

;;;###autoload
(defun calibre-library-add-book (file)
  "Add FILE to the Calibre library."
  (interactive "f")
  (calibre-library-add-books (list file)))

(defun calibre-library-add-books (files)
  "Add FILES to the Calibre library."
  (calibre-exec--queue-command
   `("add" "-r" ,@(mapcar #'expand-file-name files)))
  (calibre-exec--start-execution))

;;;###autoload
(defun calibre-dired-add ()
  "Add marked files to the Calibre library."
    (interactive)
    (if (derived-mode-p 'dired-mode)
        (calibre-library-add-books (dired-get-marked-files))))

(defun calibre-library-remove-books (books)
  "Remove BOOKS from the Calibre library."
  (let ((ids (mapcar #'int-to-string (mapcar #'calibre-book-id books))))
    (calibre-exec--queue-command `("remove" ,(string-join ids ",")))))

(defun calibre-library-mark-remove (&optional _num)
  "Mark a book for removal and move to the next line."
  (interactive "p" calibre-library-mode)
  (tabulated-list-put-tag "D" t))

(defun calibre-library-mark-unmark (&optional _num)
  "Clear any mark on a book and move to the next line."
  (interactive "p" calibre-library-mode)
  (tabulated-list-put-tag " " t))

(defun calibre-library-execute ()
  "Performed marked Library actions."
  (interactive nil calibre-library-mode)
  (let (remove-list mark)
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
        (setf mark (char-after))
        (cl-case mark
          (?\D (push (tabulated-list-get-id) remove-list)))
        (forward-line)))
    (when remove-list (calibre-library-remove-books remove-list)))
  (calibre--books t)
  (calibre-library--refresh))

(defun calibre-library--find-book (book)
  "Move point to the line representing BOOK."
  (goto-char (point-min))
        (while (not (or (eobp)
                        (= (calibre-book-id (tabulated-list-get-id))
                           (calibre-book-id book))))
          (forward-line)))

(defun calibre-library-revert (&rest _IGNORED)
  (let ((pos (tabulated-list-get-id)))
    (calibre-library--refresh t)
    (if (not pos)
        (goto-char (point-max))
      (calibre-library--find-book pos))))

(defun calibre-library-open-book (book)
  "Open BOOK in its preferred format."
  (interactive (list (tabulated-list-get-id)) calibre-library-mode)
  (find-file (calibre-book--file book (calibre-book--pick-format book))))

(defun calibre-library-open-book-other-window (book)
  "Open BOOK in its preferred format."
  (interactive (list (tabulated-list-get-id)) calibre-library-mode)
  (find-file-other-window (calibre-book--file book (calibre-book--pick-format book))))

(defvar-keymap calibre-library-mode-map
  :doc "Local keymap for Calibre Library buffers."
  :parent tabulated-list-mode-map
  "d" #'calibre-library-mark-remove
  "u" #'calibre-library-mark-unmark
  "x" #'calibre-library-execute
  "a" #'calibre-library-add-book
  "v" #'calibre-select-virtual-library
  "s" #'calibre-search
  "RET" #'calibre-library-open-book
  "o" #'calibre-library-open-book-other-window)

(define-derived-mode calibre-library-mode tabulated-list-mode
  (setf tabulated-list-padding 2)
  (setq-local revert-buffer-function #'calibre-library-revert)
  (calibre-library--set-header))

;;;###autoload
(defun calibre-library ()
  "List all books in Calibre Library `calibrary-dir'."
  (interactive)
  (let ((buffer (get-buffer-create calibre-library-buffer)))
    (with-current-buffer buffer
      (calibre-library-mode)
      (calibre-library--refresh t)
      (display-buffer buffer))))

(provide 'calibre-library)
;;; calibre-library.el ends here
