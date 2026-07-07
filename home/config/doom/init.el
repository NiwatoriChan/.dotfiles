;;; init.el -*- lexical-binding: t; -*-

;; This file controls what Doom modules are enabled and what order they
;; load in. Remember to run 'doom sync' after modifying it!

(doom! :input
       ;;layout            ; auie, dvorak, colemak

       :completion
       company           ; the ultimate code completion backend
       ivy               ; a search library for everything

       :ui
       doom              ; what makes Doom look like Doom
       doom-dashboard    ; a nifty dashboard for Emacs
       doom-quit         ; a subverted quitting experience
       hl-todo           ; highlight TODO/FIXME/NOTE/DEPRECATED/HACK/TODO
       modeline          ; a snazzy Atom-inspired mode-line
       ophints           ; highlight the region being operated on
       treemacs          ; a project drawer, like neotree but on steroids
       vc-gutter         ; vcs diff in the fringe
       vi-tilde-fringe   ; fringe tildes to mark beyond EOB
       window-select     ; visually switch windows
       workspaces        ; tab emulation, Chris' way

       :editor
       (evil +everywhere); come to the dark side, we have cookies
       file-templates    ; auto-snippets for empty files
       fold              ; (nils) folds code for you
       snippets          ; my life in templates

       :emacs
       dired             ; making dired pretty [functional]
       electric          ; smarter, keyword-based electric-indent
       undo              ; persistent, smarter undo for your eyes

       :term
       vterm             ; the best terminal emulation in Emacs

       :checkers
       syntax            ; tasing you for your typos

       :tools
       direnv
       editorconfig      ; let's all be reasonable here
       eval              ; run code, run (or block it)
       lookup            ; navigate your code and its docs
       magit             ; a git elisp interface

       :lang
       emacs-lisp        ; drown in parentheses
       markdown          ; writing docs for people to ignore
       nix               ; I'm in flake hell help
       org               ; organize your plain life in plain text
       sh                ; she-ells

       :config
       default
       )
