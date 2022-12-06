;;; doct-org-roam.el --- An org-roam extension for doct
;; Copyright (C) 2020 Nicholas Vollmer
;; Copyright (C) 2022 Valentin Herrmann

;; Author: Nicholas Vollmer <progfolio@protonmail.com>
;; URL: https://github.com/cashpw/doct-org-roam
;; Created: July 27, 2020
;; Keywords: org, org-roam, convenience
;; Package-Requires: ((emacs "26.1"))
;; Version: 0.0.0

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; This package adds support for an :org-roam keyword to doct's declarations.
;; Please see the docstring for `doct-org-roam' and `doct' for more information.

;;; Code:

(require 'doct)
(require 'cl-lib)
(eval-when-compile (require 'subr-x))

(defun doct-org-roam-convert (groups)
  "Convert GROUPS of templates to `org-roam' compatible templates."
  (setq doct-templates
        (mapcar (lambda (template)
                  (if-let* ((props (nthcdr (if (= (length template) 4) 2 5) template))
                            (org-roam-props (plist-get (plist-get props :doct) :org-roam)))
                      `(,@template ,@org-roam-props)
                    template))
                (doct-flatten-lists-in groups))))

(defun doct-org-roam--target-file (value)
  "Convert declaration's :file VALUE and extensions to capture template syntax."
  (let (type target)
    ;; TODO: This doesn't catch :olp used together with :datetree
    (when-let ((olp (doct--get :olp)))
      (push :olp type)
      (push olp target))
    (if-let ((head (doct--get :head)))
        (progn
          (push :head type)
          (push (pcase head
                  ((pred stringp) (if (doct--expansion-syntax-p head)
                                      (doct--replace-template-strings
                                       head)
                                    head))
                  ((pred functionp) (doct--fill-template (funcall head)))
                  ((pred doct--list-of-strings-p)
                   (mapconcat (lambda (element)
                                (if (doct--expansion-syntax-p element)
                                    (doct--fill-template element)
                                  element))
                              head "\n")))
           target))
      (when-let ((datetree (doct--get :datetree)))
        (push :datetree type)
        (push datetree target)))
    (push :file type)
    (push (doct--type-check :file value '(stringp doct--variable-p)) target)
    `(,(intern (mapconcat (lambda (keyword)
                            (substring (symbol-name keyword) 1))
                          (delq nil type) "+"))
      ,@(delq nil target))))

(defun doct-org-roam--target ()
  "Convert declaration's target to template target."
  (let ((doct-exclusive-target-keywords '(:file :node)))
    (pcase (doct--first-in doct-exclusive-target-keywords)
      ('nil (signal 'doct-no-target `(,doct-exclusive-target-keywords nil ,doct--current)))
      (`(:id ,id) `(id ,(doct--type-check :id id '(stringp))))
      (`(:file ,file) (doct-org-roam--target-file file)))))

(defun doct-org-roam--compose-entry (keys name parent)
  "Return a template suitable for `org-roam-capture-templates'.
The list is of the form: (KEYS NAME type target template additional-options...).
`doct--current-plist' provides the type, target template and additional options.
If PARENT is non-nil, list is of the form (KEYS NAME)."
  `(,keys ,name
          ,@(unless parent
              `(,(doct--entry-type)
                ,(doct--template)
                :target ,(doct-org-roam--target)
                ,@(doct--additional-options)))
          :doct ( :doct-name ,name
                  ,@(cdr doct--current)
                  ,@(when-let ((custom (doct--custom-properties)))
                      `(:doct-custom ,custom)))))

(defun doct-org-roam (declarations)
  "Convert DECLARATIONS to `org-roam-capture-templates'.
DECLARATIONS must be of the same form that `doct' expects with
one addition: the :org-roam keyword.
The :org-roam keyword's value must be a plist mapping `org-roam''s
template syntax extensions (e.g. :file-name :head) to their appropriate values.
Note this does validate the :org-roam plist's values or keywords."

;;TODO: we should preserve doct-after-conversion-functions
;;in case user already has other functions set.
(let ((doct-after-conversion-functions (append '(doct-org-roam-convert)
                                               doct-after-conversion-functions)))
  (cl-letf (((symbol-function 'doct--compose-entry) #'doct-org-roam--compose-entry))
      (doct declarations))))


(provide 'doct-org-roam)

;;; doct-org-roam.el ends here
