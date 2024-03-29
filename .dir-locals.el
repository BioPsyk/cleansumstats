((nil .
   ((eval .
      (progn
        (defun ibp/tmux-pane-cmd (pane cmd)
          "Runs the given shell command in a subshell inside a tmux pane."
          (interactive)
          (let* ((resolved-pane (concat "ibp-cleansumstats:" pane))
                  (resolved-cmd (format "'%s'" cmd))
                  (cmd-parts (list "tmux"
                               "send-keys"
                               "-t"
                               resolved-pane
                               resolved-cmd
                               "C-m")))
            (shell-command (format "tmux clear-history -t %s" resolved-pane))
            (shell-command (mapconcat 'identity cmd-parts " "))))

        (defun get-file-in-project (filename)
          "Gets absolute path to file inside the project"
          (interactive "P")
          (expand-file-name filename (projectile-project-root)))

        (defun ibp/docker-build ()
          "Builds the docker container with all dependencies"
          (interactive)
          (ibp/tmux-pane-cmd "0.0" "(clear && ./scripts/docker-build.sh)"))

        (defun ibp/docker-run-tests ()
          "Runs all tests inside the docker container"
          (interactive)
          (ibp/tmux-pane-cmd "0.0" "(clear && ./scripts/docker-run.sh /cleansumstats/tests/run-tests.sh)"))

        (defun ibp/docker-shell ()
          "Starts a docker shell"
          (interactive)
          (ibp/tmux-pane-cmd "0.0" "(clear && ./scripts/docker-shell.sh)"))

        (defun ibp/kill-nextflow ()
          "Starts a docker shell"
          (interactive)
          (shell-command (get-file-in-project "scripts/kill-nextflow.sh")))

        (defun ibp/run-scratch-buffer ()
          "Runs the scratch buffer"
          (interactive)
          (ibp/tmux-pane-cmd "0.0"
            (format "(clear && %s)" (get-file-in-project "scratch-buffer.sh"))))

        (global-set-key (kbd "<f1>") 'ibp/docker-build)
        (global-set-key (kbd "<f2>") 'ibp/docker-run-tests)
        (global-set-key (kbd "<f3>") 'ibp/docker-shell)
        (global-set-key (kbd "<f4>") 'ibp/kill-nextflow)
        (global-set-key (kbd "<f5>") 'ibp/run-scratch-buffer)

        )))))
