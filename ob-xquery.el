;;; ob-xquery.el --- org-babel functions for template evaluation

;; Copyright (C) Stefan Schuh

;; Author: Stefan Schuh
;; Keywords: literate programming, reproducible research
;; Homepage: https://github.com/schuach
;; Version: 0.01
;; Package-Requires: ((emacs "26.1"))

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This file is not intended to ever be loaded by org-babel, rather it is a
;; template for use in adding new language support to Org-babel. Good first
;; steps are to copy this file to a file named by the language you are adding,
;; and then use `query-replace' to replace all strings of "template" in this
;; file with the name of your new language.

;; After the `query-replace' step, it is recommended to load the file and
;; register it to org-babel either via the customize menu, or by evaluating the
;; line: (add-to-list 'org-babel-load-languages '(template . t)) where
;; `template' should have been replaced by the name of the language you are
;; implementing (note that this applies to all occurrences of 'template' in this
;; file).

;; After that continue by creating a simple code block that looks like e.g.
;;
;; #+begin_src template

;; test

;; #+end_src

;; Finally you can use `edebug' to instrumentalize
;; `org-babel-expand-body:xquery' and continue to evaluate the code block. You
;; try to add header keywords and change the body of the code block and
;; reevaluate the code block to observe how things get handled.

;;
;; If you have questions as to any of the portions of the file defined
;; below please look to existing language support for guidance.
;;
;; If you are planning on adding a language to org-babel we would ask
;; that if possible you fill out the FSF copyright assignment form
;; available at https://orgmode.org/request-assign-future.txt as this
;; will make it possible to include your language support in the core
;; of Org-mode, otherwise unassigned language support files can still
;; be included in the contrib/ directory of the Org-mode repository.


;;; Requirements:

;; Use this section to list the requirements of this language.  Most
;; languages will require that at least the language be installed on
;; the user's system, and the Emacs major mode relevant to the
;; language be installed as well.

;;; Code:
(require 'ob)
;; (require 'ob-ref)
;; (require 'ob-comint)
;; (require 'ob-eval)
;; possibly require modes required for your language

;; optionally define a file extension for this language
(add-to-list 'org-babel-tangle-lang-exts '("xquery" . "xq"))

;; optionally declare default header arguments for this language
(defvar org-babel-default-header-args:xquery '())

;; This function expands the body of a source code block by doing things like
;; prepending argument definitions to the body, it should be called by the
;; `org-babel-execute:xquery' function below. Variables get concatenated in
;; the `mapconcat' form, therefore to change the formatting you can edit the
;; `format' form.
(defun org-babel-expand-body:xquery (body params &optional processed-params)
  "Expand BODY according to PARAMS, return the expanded body."
  (require 'inf-xquery nil t)
  (let ((vars (org-babel--get-vars (or processed-params (org-babel-process-params params)))))
    (concat
     (mapconcat ;; define any variables
      (lambda (pair)
        (format "%s=%S"
                (car pair) (org-babel-xquery-var-to-xquery (cdr pair))))
      vars "\n")
     "\n" body "\n")))

;; This is the main function which is called to evaluate a code
;; block.
;;
;; This function will evaluate the body of the source code and
;; return the results as emacs-lisp depending on the value of the
;; :results header argument
;; - output means that the output to STDOUT will be captured and
;;   returned
;; - value means that the value of the last statement in the
;;   source code block will be returned
;;
;; The most common first step in this function is the expansion of the
;; PARAMS argument using `org-babel-process-params'.
;;
;; Please feel free to not implement options which aren't appropriate
;; for your language (e.g. not all languages support interactive
;; "session" evaluation).  Also you are free to define any new header
;; arguments which you feel may be useful -- all header arguments
;; specified by the user will be available in the PARAMS variable.
(defun org-babel-execute:xquery (body params)
  "Execute a block of xquery with org-babel using basex.
This function is called by `org-babel-execute-src-block'."
  (message "executing xquery source code block")
  (let* (
         (basexdb (or (cdr (assq :db params)) nil))
         (preamble (or (cdr (assq :preamble params)) ""))
         (in-file (org-babel-temp-file "xquery-"))
         (out-file (org-babel-temp-file "xquery-output-"))
         (basexcmd (concat "basex"
                           (if basexdb
                               (concat " -i " basexdb)
                             "")
                           (if (> (length body) 0)
                               (concat " " (org-babel-process-file-name in-file))
                             ""))))
    (with-temp-file in-file (insert (concat preamble "\n" body)))
    (message "%s" basexcmd)
    (with-output-to-string
      (shell-command (concat basexcmd " > " (org-babel-process-file-name out-file))))
    (with-temp-buffer (insert-file-contents out-file) (buffer-string))))


;; This function should be used to assign any variables in params in
;; the context of the session environment.
(defun org-babel-prep-session:xquery (session params)
  "Prepare SESSION according to the header arguments specified in PARAMS."
  (error "XQuery does not support sessions"))

(provide 'ob-xquery)
;;; ob-xquery.el ends here
