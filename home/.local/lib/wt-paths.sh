# Shared git worktree path helpers for wt/wd/wl and mux popups.
# New checkouts land under:
#   ${WT_ROOT:-$HOME/dev/worktrees}/<bucket>/<repo>/<branch-path>
#
# Existing checkouts anywhere stay valid. git worktree list is the source of truth.

wt_root() {
  local root="${WT_ROOT:-$HOME/dev/worktrees}"

  root="${root/#\~/$HOME}"
  printf '%s\n' "${root%/}"
}

wt_abs_git_common_dir() {
  local start="${1:-.}"
  local common

  common="$(git -C "$start" rev-parse --git-common-dir 2>/dev/null)" || return 1
  if [[ "$common" != /* ]]; then
    common="$(cd "$start" && pwd)/$common"
  fi
  (cd "$(dirname "$common")" && printf '%s/%s\n' "$(pwd)" "$(basename "$common")")
}

# Main clone directory (parent of .git), even when called from a linked worktree.
wt_main_checkout() {
  local start="${1:-.}"
  local common

  common="$(wt_abs_git_common_dir "$start")" || return 1
  if [[ "$(basename "$common")" == ".git" ]]; then
    dirname "$common"
    return 0
  fi
  printf '%s\n' "$common"
}

wt_slug_component() {
  local value="$1"

  value="$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]' | tr '/ ._ ' '----')"
  value="$(printf '%s' "$value" | tr -cd 'a-z0-9_-')"
  value="$(printf '%s' "$value" | tr -s '-' | sed -E 's/^-+//; s/-+$//')"
  printf '%s\n' "$value"
}

# Prints: <bucket> <repo>
# Repo is a single path component (basename of the main clone).
wt_bucket_and_repo() {
  local main="${1:-}"
  local home="${HOME%/}"
  local dev="$home/dev"

  if [[ -z "$main" ]]; then
    return 1
  fi

  case "$main" in
    "$home/.dotfiles")
      printf '%s %s\n' "dotfiles" "dotfiles"
      ;;
    "$dev/projects/"*)
      printf '%s %s\n' "projects" "$(basename "$main")"
      ;;
    "$dev/repos/"*|"$dev/open-source/"*)
      printf '%s %s\n' "repos" "$(basename "$main")"
      ;;
    "$dev/work/"*)
      printf '%s %s\n' "work" "$(basename "$main")"
      ;;
    "$dev/school/"*|"$home/personal/Learning/"*)
      printf '%s %s\n' "school" "$(basename "$main")"
      ;;
    "$dev/tools/"*)
      printf '%s %s\n' "tools" "$(basename "$main")"
      ;;
    "$dev/ideas/"*)
      printf '%s %s\n' "ideas" "$(basename "$main")"
      ;;
    *)
      printf '%s %s\n' "other" "$(basename "$main")"
      ;;
  esac
}

# Branch name -> path under the repo worktree root.
# issue-12-foo and issue/12-foo both become issue/12-foo.
wt_branch_relpath() {
  local branch_name="$1"

  case "$branch_name" in
    issue/*)
      printf 'issue/%s\n' "${branch_name#issue/}"
      ;;
    pr/*)
      printf 'pr/%s\n' "${branch_name#pr/}"
      ;;
    issue-*)
      printf 'issue/%s\n' "${branch_name#issue-}"
      ;;
    pr-*)
      printf 'pr/%s\n' "${branch_name#pr-}"
      ;;
    *)
      printf '%s\n' "$branch_name"
      ;;
  esac
}

wt_display_name_for_branch() {
  local branch_name="$1"

  case "$branch_name" in
    issue-*)
      printf 'issue/%s\n' "${branch_name#issue-}"
      ;;
    pr-*)
      printf 'pr/%s\n' "${branch_name#pr-}"
      ;;
    *)
      printf '%s\n' "$branch_name"
      ;;
  esac
}

# Destination for a newly created worktree. Absolute.
wt_new_checkout_path() {
  local main="$1"
  local branch_name="$2"
  local bucket repo rel

  read -r bucket repo < <(wt_bucket_and_repo "$main")
  rel="$(wt_branch_relpath "$branch_name")"

  if [[ "$bucket" == "dotfiles" && "$repo" == "dotfiles" ]]; then
    printf '%s/dotfiles/%s\n' "$(wt_root)" "$rel"
    return 0
  fi

  printf '%s/%s/%s/%s\n' "$(wt_root)" "$bucket" "$repo" "$rel"
}

# Human label for an existing checkout. Prefers branch-shaped suffix.
wt_display_name_for_path() {
  local path="$1"
  local main="${2:-}"
  local root legacy rel

  if [[ -n "$main" && "$path" == "$main" ]]; then
    printf 'main\n'
    return 0
  fi

  root="$(wt_root)"
  if [[ "$path" == "$root/"* ]]; then
    rel="${path#"$root/"}"
    # ~/dev/worktrees/dotfiles/<branch> has no extra repo component.
    # Other plants are <bucket>/<repo>/<branch>. Herdr plants <repo>/<branch>.
    case "$rel" in
      dotfiles/*)
        printf '%s\n' "${rel#dotfiles/}"
        return 0
        ;;
      */*/*)
        rel="${rel#*/}" # drop bucket
        rel="${rel#*/}" # drop repo
        printf '%s\n' "$rel"
        return 0
        ;;
      */*)
        printf '%s\n' "${rel#*/}"
        return 0
        ;;
      *)
        printf '%s\n' "$rel"
        return 0
        ;;
    esac
  fi

  if [[ -n "$main" && "$path" == "$main/.worktrees/"* ]]; then
    printf '%s\n' "${path#"$main/.worktrees/"}"
    return 0
  fi

  if [[ -n "$main" && "$path" == "$main/"* ]]; then
    printf '%s\n' "${path#"$main/"}"
    return 0
  fi

  basename "$path"
}

# Compact name for tmux/herdr agent labels: repo or repo-branch.
wt_path_suffix() {
  local current_path="$1"
  local repo_root main repo name

  repo_root="$(cd "$current_path" && git rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -z "$repo_root" ]]; then
    wt_slug_component "$(basename "$current_path")"
    return 0
  fi

  main="$(wt_main_checkout "$current_path" 2>/dev/null || true)"
  if [[ -z "$main" ]]; then
    main="$repo_root"
  fi
  repo="$(wt_slug_component "$(basename "$main")")"

  if [[ "$repo_root" == "$main" ]]; then
    printf '%s\n' "$repo"
    return 0
  fi

  name="$(wt_display_name_for_path "$repo_root" "$main")"
  name="$(wt_slug_component "$name")"
  if [[ -n "$name" ]]; then
    printf '%s-%s\n' "$repo" "$name"
  else
    printf '%s\n' "$repo"
  fi
}
