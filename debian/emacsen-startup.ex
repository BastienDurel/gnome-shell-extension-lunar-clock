;; -*-emacs-lisp-*-
;;
;; Emacs startup file, e.g.  /etc/emacs/site-start.d/50gnome-shell-extension-lunar-clock.el
;; for the Debian gnome-shell-extension-lunar-clock package
;;
;; Originally contributed by Nils Naumann <naumann@unileoben.ac.at>
;; Modified by Dirk Eddelbuettel <edd@debian.org>
;; Adapted for dh-make by Jim Van Zandt <jrv@debian.org>

;; The gnome-shell-extension-lunar-clock package follows the Debian/GNU Linux 'emacsen' policy and
;; byte-compiles its elisp files for each 'emacs flavor' (emacs19,
;; xemacs19, emacs20, xemacs20...).  The compiled code is then
;; installed in a subdirectory of the respective site-lisp directory.
;; We have to add this to the load-path:
(let ((package-dir (concat "/usr/share/"
                           (symbol-name flavor)
                           "/site-lisp/gnome-shell-extension-lunar-clock")))
;; If package-dir does not exist, the gnome-shell-extension-lunar-clock package must have
;; removed but not purged, and we should skip the setup.
  (when (file-directory-p package-dir)
    (setq load-path (cons package-dir load-path))
    (autoload 'gnome-shell-extension-lunar-clock-mode "gnome-shell-extension-lunar-clock-mode"
      "Major mode for editing gnome-shell-extension-lunar-clock files." t)
    (add-to-list 'auto-mode-alist '("\\.gnome-shell-extension-lunar-clock$" . gnome-shell-extension-lunar-clock-mode))))

