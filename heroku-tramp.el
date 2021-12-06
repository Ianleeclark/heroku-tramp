;;; heroku-tramp.el --- TRAMP integration for heroku  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; `heroku-tramp.el' offers a TRAMP method for Heroku dynos

(eval-when-compile (require 'cl-lib))

(require 'tramp)
(require 'tramp-cache)



(defgroup heroku-tramp nil
  "TRAMP integration for Heroku."
  :prefix "heroku-tramp-"
  :group 'applications
  :link '(url-link :tag "Github" "https://github.com/ianleeclark/heroku-tramp")
  :link '(emacs-commentary-link :tag "Commentary" "heroku-tramp"))

;;;###autoload
(defcustom heroku-tramp-heroku-options nil
  "List of heroku options."
  :type '(repeat string)
  :group 'heroku-tramp)

(defcustom heroku-tramp-heroku-executable "heroku"
  "Path to heroku."
  :type '(choice
          (const "heroku")
          (string))
  :group 'heroku-tramp)

;;;###autoload
(defconst heroku-tramp-method "heroku"
  "Method to connect heroku dynos.")


(defun heroku-tramp--available-apps (&optional ignored)
  "Collect heroku running containers."
  (cl-loop for line in
           (cdr (ignore-errors
              (apply #'process-lines heroku-tramp-heroku-executable
                     (append heroku-tramp-heroku-options (list "apps" "--all")))))
           ;; Here we get something roughly following the structure
           ;; ("app-name" "(eu)" "test@email.com"))
           for (app-name region email) = (split-string line "[[:space:]]+" t)
           ;; So we take only the first element (or: "app-name")
           collect (list "" app-name)))

(defconst heroku-tramp-completion-function-alist
  '((heroku-tramp--available-apps  ""))
  "Autocompletion for heroku tramp")

;;;###autoload
(defun heroku-tramp-cleanup ()
  "Cleanup TRAMP cache for heroku method."
  (interactive)
  (let ((containers (apply 'append (heroku-tramp--available-apps))))
    (maphash (lambda (key _)
               (and (vectorp key)
                    (string-equal heroku-tramp-method (tramp-file-name-method key))
                    (not (member (tramp-file-name-host key) containers))
                    (remhash key tramp-cache-data)))
             tramp-cache-data))
  (setq tramp-cache-data-changed t)
  (if (zerop (hash-table-count tramp-cache-data))
      (ignore-errors (delete-file tramp-persistency-file-name))
    (tramp-dump-connection-properties)))

;;;###autoload
(defun heroku-tramp-add-method ()
  "Add heroku tramp method."
  (add-to-list 'tramp-methods
               `(,heroku-tramp-method
                 (tramp-login-program      ,heroku-tramp-heroku-executable)
                 (tramp-login-args         (,heroku-tramp-heroku-options ("run" "/bin/bash")))
                 (tramp-remote-shell       "/bin/bash"))))

;;;###autoload
(eval-after-load 'tramp
  '(progn
     (message "Loaded heroku-tramp")
     (heroku-tramp-add-method)
     (tramp-set-completion-function heroku-tramp-method heroku-tramp-completion-function-alist)))

(provide 'heroku-tramp)

;;;###autoload
(message "Post-load")
