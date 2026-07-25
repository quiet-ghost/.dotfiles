#!/usr/bin/env bash
# OpenCode/Pi popup launcher.
# Host agent lives in workspace "Agents"; popup attaches through a Herdr key proxy.
set -euo pipefail

HERDR="${HERDR_BIN_PATH:-herdr}"
AGENTS_LABEL="Agents"
ATTACH_PROXY="$HOME/.config/herdr/scripts/herdr-attach-proxy.py"
KIND=""
CURRENT_PATH=""

usage() {
	printf 'usage: %s <opencode|pi> [cwd]\n' "$(basename "$0")" >&2
}

die() {
	local body="$1"
	if "$HERDR" notification show "agent-popup" --body "$body" >/dev/null 2>&1; then
		:
	else
		printf 'agent-popup: %s\n' "$body" >&2
	fi
	exit 1
}

need_cmd() {
	command -v "$1" >/dev/null 2>&1 || die "missing command: $1"
}

json_field() {
	jq -er "$2" <<<"$1"
}

herdr_json() {
	"$HERDR" "$@"
}

sanitize_name() {
	printf '%s' "$1" |
		tr '[:upper:]' '[:lower:]' |
		tr '/ ._ ' '----' |
		tr -cd 'a-z0-9_-' |
		tr -s '-' |
		sed -E 's/^-+//; s/-+$//'
}

path_suffix() {
	local current_path="$1"
	local repo_root common_dir common_root repo_name worktree_name

	repo_root=$(cd "$current_path" && git rev-parse --show-toplevel 2>/dev/null || true)
	if [ -z "$repo_root" ]; then
		sanitize_name "$(basename "$current_path")"
		return
	fi

	common_dir=$(cd "$current_path" && git rev-parse --git-common-dir 2>/dev/null || true)
	if [ -n "$common_dir" ]; then
		common_root=$(dirname "$(cd "$current_path" && realpath "$common_dir")")
	else
		common_root="$repo_root"
	fi

	repo_name=$(sanitize_name "$(basename "$common_root")")

	case "$repo_root" in
	"$common_root/.worktrees/"*)
		worktree_name="${repo_root#"$common_root/.worktrees/"}"
		worktree_name=$(sanitize_name "$worktree_name")
		if [ -n "$worktree_name" ]; then
			printf '%s-%s\n' "$repo_name" "$worktree_name"
		else
			printf '%s\n' "$repo_name"
		fi
		;;
	*)
		printf '%s\n' "$repo_name"
		;;
	esac
}

# Herdr agent names: ^[a-z][a-z0-9_-]{0,31}$
build_agent_name() {
	local kind="$1"
	local current_path="$2"
	local suffix candidate hash keep

	suffix=$(path_suffix "$current_path")
	[ -n "$suffix" ] || suffix="dir"
	candidate=$(sanitize_name "${kind}-${suffix}")
	if [ "${#candidate}" -le 32 ] && [[ "$candidate" =~ ^[a-z][a-z0-9_-]{0,31}$ ]]; then
		printf '%s\n' "$candidate"
		return
	fi

	hash=$(printf '%s' "${kind}-${suffix}" | sha256sum | awk '{print substr($1,1,6)}')
	keep=$((32 - 1 - ${#hash}))
	candidate=$(sanitize_name "${kind}-${suffix}")
	candidate="${candidate:0:keep}-${hash}"
	candidate=$(sanitize_name "$candidate")
	printf '%s\n' "${candidate:0:32}"
}

normalize_path() {
	local path="$1"
	if [ ! -d "$path" ]; then
		die "cwd not a directory: $path"
	fi
	cd "$path" && pwd -P
}

find_agents_workspace() {
	herdr_json workspace list |
		jq -er --arg label "$AGENTS_LABEL" '
			.result.workspaces[]
			| select(.label == $label)
			| .workspace_id
		' 2>/dev/null | head -n1 || true
}

ensure_agents_workspace() {
	local ws created
	ws="$(find_agents_workspace)"
	if [ -n "$ws" ]; then
		printf '%s\n' "$ws"
		return
	fi
	created="$(herdr_json workspace create --cwd "$HOME" --label "$AGENTS_LABEL" --no-focus)"
	json_field "$created" '.result.workspace.workspace_id'
}

find_tab_by_label() {
	local ws="$1"
	local label="$2"
	herdr_json tab list --workspace "$ws" |
		jq -er --arg label "$label" '
			.result.tabs[]
			| select(.label == $label)
			| .tab_id
		' 2>/dev/null | head -n1 || true
}

find_pane_by_label() {
	local label="$1"
	herdr_json pane list |
		jq -er --arg label "$label" '
			.result.panes[]
			| select(.label == $label)
			| .pane_id
		' 2>/dev/null | head -n1 || true
}

agent_exists() {
	local name="$1"
	herdr_json agent get "$name" >/dev/null 2>&1
}

find_agent_in_workspace() {
	local ws="$1"
	local kind="$2"
	local cwd="$3"
	herdr_json agent list |
		jq -er --arg ws "$ws" --arg kind "$kind" --arg cwd "$cwd" '
			.result.agents[]
			| select(.workspace_id == $ws and .agent == $kind and .cwd == $cwd)
			| .pane_id
		' 2>/dev/null | head -n1 || true
}

agent_name_on_pane() {
	local pane_id="$1"
	herdr_json agent list |
		jq -er --arg pane "$pane_id" '
			.result.agents[]
			| select(.pane_id == $pane)
			| .name // empty
		' 2>/dev/null | head -n1 || true
}

agent_kind_on_pane() {
	local pane_id="$1"
	herdr_json agent list |
		jq -er --arg pane "$pane_id" '
			.result.agents[]
			| select(.pane_id == $pane)
			| .agent
		' 2>/dev/null | head -n1 || true
}

mark_host() {
	local pane_id="$1"
	local tab_id="$2"
	local name="$3"
	herdr_json pane rename "$pane_id" "$name" >/dev/null 2>&1 || true
	herdr_json tab rename "$tab_id" "$name" >/dev/null 2>&1 || true
}

create_host_tab() {
	local ws="$1"
	local cwd="$2"
	local name="$3"
	local created pane_id tab_id

	created="$(
		herdr_json tab create \
			--workspace "$ws" \
			--cwd "$cwd" \
			--label "$name" \
			--no-focus
	)"
	pane_id="$(json_field "$created" '.result.root_pane.pane_id')"
	tab_id="$(json_field "$created" '.result.tab.tab_id')"
	mark_host "$pane_id" "$tab_id" "$name"
	printf '%s\n' "$pane_id"
}

pane_tab_id() {
	local pane_id="$1"
	json_field "$(herdr_json pane get "$pane_id")" '.result.pane.tab_id'
}

ensure_named_agent() {
	local kind="$1"
	local cwd="$2"
	local name="$3"
	local ws="$4"
	local pane_id tab_id existing_kind existing_name existing_info existing_cwd

	if agent_exists "$name"; then
		existing_info="$(herdr_json agent get "$name")"
		existing_kind="$(json_field "$existing_info" '.result.agent.agent')"
		existing_cwd="$(json_field "$existing_info" '.result.agent.cwd')"
		if [ "$existing_kind" != "$kind" ] || [ "$existing_cwd" != "$cwd" ]; then
			die "agent name collision: $name is $existing_kind in $existing_cwd"
		fi
		return 0
	fi

	pane_id="$(find_pane_by_label "$name")"
	if [ -z "$pane_id" ]; then
		pane_id="$(find_agent_in_workspace "$ws" "$kind" "$cwd")"
	fi

	if [ -z "$pane_id" ]; then
		local tab_id_found
		tab_id_found="$(find_tab_by_label "$ws" "$name")"
		if [ -n "$tab_id_found" ]; then
			pane_id="$(
				herdr_json pane list |
					jq -er --arg tab "$tab_id_found" '
						.result.panes[]
						| select(.tab_id == $tab)
						| .pane_id
					' 2>/dev/null | head -n1 || true
			)"
		fi
	fi

	if [ -z "$pane_id" ]; then
		pane_id="$(create_host_tab "$ws" "$cwd" "$name")"
	else
		tab_id="$(pane_tab_id "$pane_id")"
		mark_host "$pane_id" "$tab_id" "$name"
		existing_kind="$(agent_kind_on_pane "$pane_id")"
		if [ -n "$existing_kind" ]; then
			if [ "$existing_kind" != "$kind" ]; then
				die "pane $pane_id hosts $existing_kind, wanted $kind"
			fi
			existing_name="$(agent_name_on_pane "$pane_id")"
			if [ -z "$existing_name" ] || [ "$existing_name" != "$name" ]; then
				herdr_json agent rename "$pane_id" "$name" >/dev/null
			fi
			return 0
		fi
	fi

	start_agent_on_pane "$kind" "$name" "$pane_id"
}

start_agent_on_pane() {
	local kind="$1"
	local name="$2"
	local pane_id="$3"
	local attempt=0
	local max_attempts=8
	local out code

	while [ "$attempt" -lt "$max_attempts" ]; do
		attempt=$((attempt + 1))
		set +e
		out="$(herdr_json agent start "$name" --kind "$kind" --pane "$pane_id" --timeout 60000 2>&1)"
		code=$?
		set -e
		if [ "$code" -eq 0 ]; then
			return 0
		fi
		# Fresh tabs often need a moment before the shell is interactive.
		if printf '%s' "$out" | jq -e '.error.code == "agent_pane_busy"' >/dev/null 2>&1; then
			sleep 0.5
			continue
		fi
		die "failed to start $kind as $name on $pane_id: $(printf '%s' "$out" | jq -r '.error.message // .error.code // .' 2>/dev/null || printf '%s' "$out")"
	done

	die "pane not ready for agent start after ${max_attempts} tries: $pane_id"
}

main() {
	if [ "$#" -lt 1 ]; then
		usage
		exit 2
	fi

	KIND="$1"
	shift
	case "$KIND" in
	opencode | pi) ;;
	*)
		usage
		die "unsupported kind: $KIND"
		;;
	esac

	CURRENT_PATH="${1:-${HERDR_ACTIVE_PANE_CWD:-$PWD}}"

	need_cmd jq
	need_cmd git
	need_cmd flock
	need_cmd python3
	need_cmd "$HERDR"
	need_cmd "$KIND"
	[ -x "$ATTACH_PROXY" ] || die "missing executable: $ATTACH_PROXY"

	CURRENT_PATH="$(normalize_path "$CURRENT_PATH")"

	local agent_name ws lock_dir
	agent_name="$(build_agent_name "$KIND" "$CURRENT_PATH")"
	lock_dir="${XDG_RUNTIME_DIR:-/tmp}/herdr-agent-popup-$UID"
	mkdir -p "$lock_dir"
	chmod 700 "$lock_dir"
	exec 9>"$lock_dir/$agent_name.lock"
	flock 9
	ws="$(ensure_agents_workspace)"
	ensure_named_agent "$KIND" "$CURRENT_PATH" "$agent_name" "$ws"
	exec "$ATTACH_PROXY" --herdr "$HERDR" "$agent_name"
}

main "$@"
