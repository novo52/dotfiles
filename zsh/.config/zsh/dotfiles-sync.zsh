# Fast-forward the dotfiles checkouts from their remotes, at most once an hour.
# The fetch runs in the background so it never delays the prompt; its result is
# printed before the first prompt after it finishes. A failed fetch (offline) is
# silent. Uncommitted changes do not block the pull: git refuses a fast-forward
# that would overwrite them, and nvim keeps lazy-lock.json modified.

_dotfiles_sync_repos=($HOME/dotfiles $HOME/dotfiles-private)
_dotfiles_sync_stamp=$HOME/.cache/zsh/dotfiles-sync.stamp
_dotfiles_sync_out=$HOME/.cache/zsh/dotfiles-sync.out

_dotfiles_sync() {
  local repo name behind ahead
  for repo in $_dotfiles_sync_repos; do
    [[ -d $repo/.git ]] || continue
    name=${repo:t}
    GIT_TERMINAL_PROMPT=0 git -C $repo fetch -q 2>/dev/null || continue
    git -C $repo rev-parse -q --verify '@{u}' > /dev/null || continue
    behind=$(git -C $repo rev-list --count 'HEAD..@{u}')
    (( behind )) || continue
    ahead=$(git -C $repo rev-list --count '@{u}..HEAD')
    if (( ahead )); then
      print "$name: $behind behind and $ahead ahead of upstream; not pulled"
    elif git -C $repo merge -q --ff-only '@{u}' > /dev/null 2>&1; then
      print "$name: pulled $behind commit(s)"
    else
      print "$name: $behind behind; local changes block the fast-forward"
    fi
  done
}

_dotfiles_sync_report() {
  [[ -e $_dotfiles_sync_out ]] || return
  [[ -s $_dotfiles_sync_out ]] && print -P "%F{yellow}$(<$_dotfiles_sync_out)%f"
  rm -f $_dotfiles_sync_out
}

() {
  local recent=($_dotfiles_sync_stamp(N.mh-1))
  (( $#recent )) && return
  touch $_dotfiles_sync_stamp
  { _dotfiles_sync > $_dotfiles_sync_out.tmp; mv $_dotfiles_sync_out.tmp $_dotfiles_sync_out } &!
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _dotfiles_sync_report
