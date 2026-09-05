## Dotfiles

A dump of some random dotfiles from my WSL machine.

I've spent virtually zero time looking over this or thinking about portability. Just want to dump my current configurations in case I want to use them to set up a different machine.

## Resume a Codex task overnight

`codex-overnight` resumes an existing Codex transcript. If a failed turn emits
the `You've hit your usage limit` error, the script waits 15 minutes and
resumes the same session. It exits after a successful turn or any other
failure.

From this dotfiles checkout, put the script on your `PATH` once:

```sh
mkdir -p "$HOME/.local/bin"
ln -s "$PWD/codex-overnight" "$HOME/.local/bin/codex-overnight"
export PATH="$HOME/.local/bin:$PATH"
command -v codex-overnight
```

The wrapper does not pass model or sandbox overrides. Codex exec restores the
transcript but resolves the model and permissions from the current
configuration. It cannot stop for interactive approvals. If the session uses a
named profile, pass the same profile to the wrapper:

```sh
cd "$HOME/src/my-project"
CODEX_OVERNIGHT_PROFILE=overnight \
  codex-overnight "CHAT_ID" "Continue until the task is complete."
```

Changes made only inside a session with `/model` or `/permissions` are not
automatically restored by the current exec client. Save those settings in the
default configuration or the named profile before leaving the task.

To start an overnight run:

1. In the existing session, run `/status`. Copy the chat ID and verify the
   displayed model and permissions match the configuration or profile that the
   wrapper will use.
2. Exit with `/quit`. Do not run interactive and overnight clients against the
   same session at the same time.
3. In the target Git repository, pass the chat ID and your follow-up prompt:

   ```sh
   cd "$HOME/src/my-project"
   codex-overnight "CHAT_ID" "Continue until the task is complete."
   ```

The resumed model sees the original prompt and transcript. The follow-up starts
a new turn after the limit error. If you omit it, the wrapper asks Codex to
continue the existing task and reconcile the transcript with the repository's
current state.

The non-interactive client does not show the interactive "Approaching rate
limits" picker. In an interactive session, choose `Keep current model` or
`Keep current model (never show again)` if you do not want to switch.

Run the command inside tmux so it survives a terminal disconnect:

```sh
tmux new -s codex-overnight
cd "$HOME/src/my-project"
codex-overnight "CHAT_ID" "Continue until the task is complete."
```

This repository changes the tmux prefix to `Alt-a`, so detach with `Alt-a d`.
You can also run `tmux detach-client`. Reattach with
`tmux attach -t codex-overnight`. tmux protects against terminal disconnects,
not Windows power-state changes.

Keep Windows plugged in and configure it not to sleep or hibernate. Sleep,
hibernation, lid-close actions, Windows restarts, and `wsl --shutdown` stop or
pause work inside WSL. After an interruption, reattach and inspect the log.
Rerun the same command if the wrapper stopped.

Logs are private to your user by default and live under
`${XDG_STATE_HOME:-$HOME/.local/state}/codex-overnight`. They can contain Codex
JSON events and output from the target repository. The wrapper prints the log
path when it starts. To use a different retry delay or state directory, set
`CODEX_OVERNIGHT_RETRY_SECONDS` or `CODEX_OVERNIGHT_STATE_DIR`:

```sh
CODEX_OVERNIGHT_RETRY_SECONDS=60 \
  codex-overnight "CHAT_ID" "Continue until the task is complete."
```

Press `Ctrl-C` to stop. Rerun the same command to recover after a non-limit
failure or an interrupted WSL instance.

Run the hermetic test with:

```sh
tests/codex-overnight-test.sh
```
