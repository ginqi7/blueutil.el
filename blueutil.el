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

;; Emacs package for managing Bluetooth devices on macOS using the blueutil command-line utility.
;;
;; Usage:
;;   M-x blueutil-search-paired  ; Interactive interface to manage paired devices
;;
;; Or programmatically:
;;   (blueutil-paired)       ; List paired devices
;;   (blueutil-connected)    ; List connected devices
;;   (blueutil-connect id)   ; Connect to a device
;;   (blueutil-disconnect id) ; Disconnect a device

;;; Code:

(defcustom blueutil-command (executable-find "blueutil")
  "Path to the blueutil command-line executable.

This variable holds the full path to the blueutil binary used for
Bluetooth device management on macOS.  By default, it searches for
the executable in the system PATH.")

;;; Internal Functions

(defun blueutil--run-json (command &optional options)
  "Execute COMMAND with OPTIONS and parse the output as JSON.

COMMAND is a symbol representing the blueutil subcommand to execute.
OPTIONS is an optional list of additional command-line arguments.

Returns the parsed JSON result as Emacs Lisp data structures,
with arrays converted to lists and JSON booleans to nil.
Returns nil if the command produces no output."
  (let ((output (blueutil--run command options)))
    (unless (string-empty-p output)
      (json-parse-string
       output
       :array-type 'list
       :false-object nil))))

(defun blueutil--run (command &optional options)
  "Execute a blueutil COMMAND with OPTIONS and return the raw output.

COMMAND is a symbol representing the blueutil subcommand (e.g., 'paired, 'connected).
OPTIONS is an optional list of additional command-line arguments.

Returns the raw string output from the shell command.  The command
is executed with --format json and the specified COMMAND and OPTIONS."
  (let ((opts (if options (string-join options " ") "")))
    (shell-command-to-string
     (format "%s --format json --%s %s" blueutil-command command opts))))

(defun blueutil--info-key (info)
  "Generate a display key for a Bluetooth device INFO hash.

INFO is a hash table containing device information with at least
\"name\" and \"connected\" keys.

Returns a formatted string of the device name, highlighted with
the `secondary-selection` face if the device is currently connected.
This is used for display in completing-read prompts."
  (let ((name (gethash "name" info))
        (connected (gethash "connected" info)))
    (format "%s"
            (if connected (propertize name 'face 'secondary-selection) name))))

;;; API Functions

(defun blueutil-paired ()
  "Return a list of all paired Bluetooth devices.

Queries the blueutil utility for devices that have been previously
paired with this Mac.  Each device is returned as a hash table
containing keys such as \"address\", \"name\", \"connected\", etc.

Example:
  (blueutil-paired)
  ;; => ((\"address\" . \"xx:xx:xx:xx:xx:xx\")
  ;;     (\"name\" . \"AirPods\")
  ;;     (\"connected\" . t)
  ;;     ...)"
  (blueutil--run-json 'paired))

(defun blueutil-connected ()
  "Return a list of currently connected Bluetooth devices.

Queries the blueutil utility for devices that are currently
connected and active.  Each device is returned as a hash table
containing keys such as \"address\", \"name\", etc.

Example:
  (blueutil-connected)
  ;; => ((\"address\" . \"xx:xx:xx:xx:xx:xx\")
  ;;     (\"name\" . \"Magic Mouse\")
  ;;     ...)"
  (blueutil--run-json 'connected))

(defun blueutil-connect-device (id action)
  "Connect or disconnect a Bluetooth device with the specified ID.

ID is the unique address (MAC address) of the Bluetooth device.
ACTION is a symbol, either 'connect or 'disconnect."
  (blueutil--run action (list id)))

(defun blueutil-search-paired ()
  "Interactively select and manage a paired Bluetooth device.

This interactive command presents a completing-read interface to:
1. Select a paired Bluetooth device from a list
2. Choose an action (connect or disconnect) to perform on it

Connected devices are highlighted in the selection list for easy
identification.  After selecting a device and action, the appropriate
command is executed to perform the operation.

Example usage:
  M-x blueutil-search-paired"
  (interactive)
  (let ((pairs (blueutil-paired)))
    (when pairs
      (let* ((choices (mapcar (lambda (p)
                                (cons (blueutil--info-key p)
                                      (gethash "address" p)))
                              pairs))
             (selected (completing-read "Select a bluetooth: " choices))
             (address (cdr (assoc selected choices)))
             (action (completing-read (format "What are you doing for %s: " selected)
                                      '(connect disconnect))))
        (blueutil-connect-device address (intern action))))))

(provide 'blueutil)
;;; blueutil.el ends here
