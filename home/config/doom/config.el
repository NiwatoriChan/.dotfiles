;;; config.el -*- lexical-binding: t; -*-

;; User identity
(setq user-full-name "niwatorichan"
      user-mail-address "charloslivro2@gmail.com")

;; Doom theme
(setq doom-theme 'doom-one)

;; Beautiful modern terminal font (JetBrainsMono Nerd Font)
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 15 :weight 'light)
      doom-variable-pitch-font (font-spec :family "Inter" :size 15))

;; Wayland-native background transparency (alpha-background)
;; This leaves text at 100% opacity for perfect legibility with transparent blur.
(set-frame-parameter nil 'alpha-background 85)
(add-to-list 'default-frame-alist '(alpha-background . 85))

;; Enable line numbers globally
(setq display-line-numbers-type t)
