;;; install.el  --- configure an arch linux system  -*- lexical-binding: t; -*-

(setq-default mode-line-format nil)
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(load-theme 'modus-vivendi t)

(require 'widget)
(require 'org)

(defvar archinstall/aur-helper "paru"
  "Which AUR helper to install")

(defvar archinstall/packages '(sway snapper onepassword grim)
  "List of configurable package groups to install.")

(defun archinstall/notify-packages (widget &rest ignore)
  (let ((value (widget-value widget))
        (name (widget-get widget :item)))
    (if value
        (add-to-list 'archinstall/packages name)
      (delete name archinstall/packages))))

(defun archinstall/open-pacman-conf ()
  (find-file-other-window "/sudo::/etc/pacman.conf"))

(defun run-install (widget &rest ignore)
  (let ((script "echo Running Install...\n"))
    ;; Sway
    (when (member 'sway archinstall/packages)
      (setq script
            (concat script "sudo pacman -S --needed sway swaybg swaylock swayidle\n")))

    ;; 1Password
    (when (member 'onepassword archinstall/packages)
      (setq script
            (concat script "yay -S --needed 1password 1password-cli\n")))

    (async-shell-command script "*arch-install-output*")))

(defun main-layout ()
  (interactive)
  (switch-to-buffer "*arch-install*")
  ;; Clear the buffer
  (kill-all-local-variables)
  (let ((inhibit-read-only t))
    (erase-buffer))
  (remove-overlays)

  (widget-insert "* Arch.el Setup\n")
  (widget-insert "Press <tab> and <s-tab> to move between fields.\n")

  (widget-insert
   "
** Pacman Configuration

Before installing anything, you may want to edit your /etc/pacman.conf
file. In particular, consider color and parallel downloads.
\n")

  (widget-create 'link
                 :tag "Edit /etc/pacman.conf"
                 :action #'(lambda (widget &rest ignore)
                             (find-file-other-window "/sudo::/etc/pacman.conf")))


  (widget-insert "\n\n")


  (widget-insert
   "
** Arch User Repository
\n")

  (widget-insert "AUR HELPER:\n")
  (widget-create 'radio-button-choice
                 :value "paru"
                 :notify #'(lambda (widget &rest ignore)
                           (setq archinstall/aur-helper (widget-value widget)))
                 '(item "paru")
                 '(item "yay")
                 '(item "none"))

  (widget-insert "\n")


  (widget-insert
   "
** Packages
\n")

  (widget-create 'checkbox
                 :value t
                 :item 'sway
                 :notify #'archinstall/notify-packages)
  (widget-insert " Install Sway and related packages\n")

  (widget-create 'checkbox 
                 :value t
                 :item 'snapper
                 :notify #'archinstall/notify-packages)
  (widget-insert " Install snapper and snap-pac\n")

  (widget-create 'checkbox 
                 :value t
                 :item 'onepassword
                 :notify #'archinstall/notify-packages)
  (widget-insert " 1Password & cli")

  (widget-insert "\n")
  (widget-create 'push-button
		 :notify #'run-install
		 :help-echo "Run the installer"
		 :highlight t
		 "Install")

  (org-mode)
  (use-local-map widget-keymap)
  (widget-setup)
  (goto-char (point-min)))

(add-hook 'emacs-startup-hook 'main-layout)

