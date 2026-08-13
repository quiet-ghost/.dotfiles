#!/usr/bin/env bash
# OpenCode/OpenCode 2/Pi persistent agent launcher.
# Host agent lives in workspace "Agents" and is focused directly for native input.
set -euo pipefail

HERDR="${HERDR_BIN_PATH:-herdr}"
AGENTS_LABEL="Agents"
KIND=""
CURRENT_PATH=""

usage() {
	printf 'usage: %s <opencode|opencode2|pi> [cwd]\n' "$(basename "$0")" >&2
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

	if [[ -f "$HOME/dev/tools/dev-tools/lib/wt-paths.sh" ]]; then
		# shellcheck source=/dev/null
		source "$HOME/dev/tools/dev-tools/lib/wt-paths.sh"
		wt_path_suffix "$current_path"
		return
	fi

	sanitize_name "$(basename "$current_path")"
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

ensure_opencode2_agent() {
	local cwd="$1"
	local name="$2"
	local ws="$3"
	local pane_id tab_id info attempt

	pane_id="$(find_pane_by_label "$name")"
	if [ -z "$pane_id" ]; then
		pane_id="$(create_host_tab "$ws" "$cwd" "$name")"
	else
		tab_id="$(pane_tab_id "$pane_id")"
		mark_host "$pane_id" "$tab_id" "$name"
	fi

	if ! herdr_json agent get "$pane_id" >/dev/null 2>&1; then
		herdr_json pane run "$pane_id" "$OPENCODE2" >/dev/null
		for attempt in {1..60}; do
			if info="$(herdr_json agent get "$pane_id" 2>/dev/null)"; then
				break
			fi
			sleep 0.25
		done
		[ -n "${info:-}" ] || die "opencode2 was not detected on pane $pane_id"
	fi

	herdr_json agent rename "$pane_id" "$name" >/dev/null
	printf '%s\n' "$name"
}

main() {
	if [ "$#" -lt 1 ]; then
		usage
		exit 2
	fi

	KIND="$1"
	shift
	case "$KIND" in
	opencode | opencode2 | pi) ;;
	*)
		usage
		die "unsupported kind: $KIND"
		;;
	esac

	CURRENT_PATH="${1:-${HERDR_ACTIVE_PANE_CWD:-$PWD}}"

	need_cmd jq
	need_cmd git
	need_cmd flock
	need_cmd "$HERDR"
	if [ "$KIND" = "opencode2" ]; then
		OPENCODE2="$HOME/.local/bin/opencode2-isolated"
		[ -x "$OPENCODE2" ] || die "missing executable: $OPENCODE2"
	else
		need_cmd "$KIND"
	fi
	CURRENT_PATH="$(normalize_path "$CURRENT_PATH")"

	local agent_name ws lock_dir
	agent_name="$(build_agent_name "$KIND" "$CURRENT_PATH")"
	lock_dir="${XDG_RUNTIME_DIR:-/tmp}/herdr-agent-popup-$UID"
	mkdir -p "$lock_dir"
	chmod 700 "$lock_dir"
	exec 9>"$lock_dir/$agent_name.lock"
	flock 9
	ws="$(ensure_agents_workspace)"
	if [ "$KIND" = "opencode2" ]; then
		agent_name="$(ensure_opencode2_agent "$CURRENT_PATH" "$agent_name" "$ws")"
	else
		ensure_named_agent "$KIND" "$CURRENT_PATH" "$agent_name" "$ws"
	fi

	local target_info target_pane target_tab target_pgid return_dir return_file socket_key tmp
	target_info="$(herdr_json agent get "$agent_name")"
	target_pane="$(json_field "$target_info" '.result.agent.pane_id')"
	target_tab="$(json_field "$target_info" '.result.agent.tab_id')"
	target_pgid="$(json_field "$(herdr_json pane process-info --pane "$target_pane")" '.result.process_info.foreground_process_group_id')"
	return_dir="${XDG_RUNTIME_DIR:-/tmp}/herdr-agent-return-$UID"
	mkdir -p "$return_dir"
	chmod 700 "$return_dir"
	socket_key="$(printf '%s' "${HERDR_SOCKET_PATH:-default}" | sha256sum | cut -c1-12)"
	return_file="$return_dir/$socket_key.json"
	if [ -n "${HERDR_ACTIVE_TAB_ID:-}" ] && [ "${HERDR_ACTIVE_WORKSPACE_ID:-}" != "$ws" ]; then
		tmp="$return_file.$$"
		jq -n \
			--arg return_tab "$HERDR_ACTIVE_TAB_ID" \
			--arg agents_workspace "$ws" \
			'{return_tab: $return_tab, agents_workspace: $agents_workspace}' >"$tmp"
		chmod 600 "$tmp"
		mv "$tmp" "$return_file"
	fi
	herdr_json agent focus "$agent_name" >/dev/null
	"$HOME/.config/herdr/scripts/agent-exit-watch.sh" \
		"$target_pane" "$target_tab" "$target_pgid" "$return_file" >/dev/null 2>&1 &
}

main "$@"
