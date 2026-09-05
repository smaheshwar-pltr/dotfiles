## Dotfiles

A dump of some random dotfiles from my WSL machine.

I've spent virtually zero time looking over this or thinking about portability. Just want to dump my current configurations in case I want to use them to set up a different machine.

## Resume a Codex task overnight

`codex-overnight` resumes an existing Codex session. If Codex exits with
`You've hit your usage limit`, the script waits 15 minutes and resumes the same
session. It exits after a successful turn or any other failure.

To start an overnight run:

1. Start Codex in the target Git repository and give it the full task.
2. Run `/status` and copy the chat ID.
3. Exit the interactive session with `/quit`. Do not run the interactive and
   overnight clients against the same session at the same time.
4. Run the wrapper from this repository:

   ```sh
   ./codex-overnight "$HOME/src/my-project" "CHAT_ID"
   ```

The wrapper uses `codex exec --sandbox workspace-write`. It does not pass a
model override, so Codex uses its normal model resolution when it resumes the
session. The non-interactive client does not show the interactive
"Approaching rate limits" picker. In an interactive session, choose
`Keep current model` or `Keep current model (never show again)` if you do not
want to switch.

Run the command inside tmux so it survives a terminal disconnect:

```sh
tmux new -s codex-overnight
./codex-overnight "$HOME/src/my-project" "CHAT_ID"
```

Detach with `Ctrl-b d`. Reattach with `tmux attach -t codex-overnight`. The WSL
instance and the Windows machine must remain running. tmux cannot survive a
Windows restart or `wsl --shutdown`.

Logs are private to your user by default and live under
`${XDG_STATE_HOME:-$HOME/.local/state}/codex-overnight`. They can contain Codex
output from the target repository. To use a different retry delay or state
directory, set `CODEX_OVERNIGHT_RETRY_SECONDS` or
`CODEX_OVERNIGHT_STATE_DIR`:

```sh
CODEX_OVERNIGHT_RETRY_SECONDS=60 ./codex-overnight "$PWD" "CHAT_ID"
```

Press `Ctrl-C` to stop. Rerun the same command to recover after a non-limit
failure. On WSL, `flock` prevents two wrappers from resuming the same session
at once.

Run the hermetic test with:

```sh
tests/codex-overnight-test.sh
```
