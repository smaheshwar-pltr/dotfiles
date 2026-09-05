## Dotfiles

A dump of some random dotfiles from my WSL machine.

I've spent virtually zero time looking over this or thinking about portability. Just want to dump my current configurations in case I want to use them to set up a different machine.

## Resume a Codex task overnight

`codex-overnight` resumes an existing Codex transcript. If a failed turn emits
the `You've hit your usage limit` error, the script waits 15 minutes and
resumes the same session. It exits after a successful turn or any other
failure.

Before leaving a task unattended:

- Install and authenticate the Codex CLI. Install `flock` from the WSL
  `util-linux` package. The target directory must be a Git repository.
- Keep Windows plugged in and configure it not to sleep or hibernate. Sleep,
  hibernation, lid-close actions, Windows restarts, and `wsl --shutdown` stop
  or pause work inside WSL.
- Make sure the active Codex configuration grants every permission the task
  needs. Exec is headless and cannot stop for interactive approvals.

Codex exec restores the transcript but resolves the model and permissions from
the current configuration. It does not automatically restore changes made only
inside the session with `/model` or `/permissions`. If the session uses a named
profile, pass that profile to the wrapper:

```sh
CODEX_OVERNIGHT_PROFILE=overnight \
  ./codex-overnight "$HOME/src/my-project" "CHAT_ID"
```

To start an overnight run:

1. Open the existing Codex session in the target Git repository. Give it the
   full task if you have not already done so.
2. Run `/status` and copy the chat ID.
3. Exit the interactive session with `/quit`. Do not run the interactive and
   overnight clients against the same session at the same time.
4. Run the wrapper from this repository:

   ```sh
   ./codex-overnight "$HOME/src/my-project" "CHAT_ID"
   ```

The non-interactive client does not show the interactive "Approaching rate
limits" picker. In an interactive session, choose `Keep current model` or
`Keep current model (never show again)` if you do not want to switch.

Run the command inside tmux so it survives a terminal disconnect:

```sh
tmux new -s codex-overnight
./codex-overnight "$HOME/src/my-project" "CHAT_ID"
```

This repository changes the tmux prefix to `Alt-a`, so detach with `Alt-a d`.
You can also run `tmux detach-client`. Reattach with
`tmux attach -t codex-overnight`. tmux protects against terminal disconnects,
not Windows power-state changes.

Logs are private to your user by default and live under
`${XDG_STATE_HOME:-$HOME/.local/state}/codex-overnight`. They can contain Codex
JSON events and output from the target repository. The wrapper prints the log
path when it starts. To use a different retry delay or state directory, set
`CODEX_OVERNIGHT_RETRY_SECONDS` or `CODEX_OVERNIGHT_STATE_DIR`:

```sh
CODEX_OVERNIGHT_RETRY_SECONDS=60 ./codex-overnight "$PWD" "CHAT_ID"
```

Press `Ctrl-C` to stop. Rerun the same command to recover after a non-limit
failure or an interrupted WSL instance. `flock` prevents two wrappers from
resuming the same session, even when they use different log directories.

Run the hermetic test with:

```sh
tests/codex-overnight-test.sh
```
