;;; blueutil.el ---                               -*- lexical-binding: t; -*-

;; Copyright (C) 2025  Qiqi Jin

;; Author: Qiqi Jin <ginqi7@gmail.com>
;; Keywords:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:

(defcustom blueutil-command (executable-find "blueutil")
  "")

;;; Internal Functgions

(defun blueutil--run-json (command &optional options)
  (let ((output (blueutil--run command options)))
    (json-parse-string
     output
     :array-type 'list
     :false-object nil)))

;; (defun blueutil--run-str ())

(defun blueutil--run (command &optional options)
  (shell-command-to-string (format "%s --format json --%s %s" blueutil-command command (string-join options " "))))

(defun blueutil--info-key (info)
  (let ((name (gethash "name" info))
        (connected (gethash "connected" info)))
    (format "%s"
            (if connected (propertize name 'face 'secondary-selection) name))))

;;; API Functions
(defun blueutil-paired ()
  (blueutil--run-json 'paired))

(defun blueutil-connected ()
  (blueutil--run-json 'connected))

(defun blueutil-connect (id)
  (blueutil--run 'connect (list id)))

(defun blueutil-disconnect (id)
  (blueutil--run 'disconnect (list id)))

(defun blueutil-search-paired ()
  (interactive)
  (when-let* ((pairs (blueutil-paired))
              (selected (completing-read "Select a bluetooth: " (mapcar #'blueutil--info-key pairs)))
              (action (completing-read (format "What are you doing for %s: " selected)
                                       '(connect disconnect)))
              (selected-pair (find-if (lambda (pair) (string= (blueutil--info-key pair) selected)) pairs)))
    (pcase action
      ("connect"
       (blueutil-connect (gethash "address" selected-pair)))
      ("disconnect"
       (blueutil-disconnect (gethash "address" selected-pair))))))

(provide 'blueutil)
;;; blueutil.el ends here
