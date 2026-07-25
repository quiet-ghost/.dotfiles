#!/usr/bin/env bash
# Fuzzy workspace switcher + create (mux-sesh twin for herdr).
# Bound as type=popup (e.g. alt+w).
#
# Phase 1 (default): live workspaces only — vim normal, i search, n → create.
# Phase 2 (n): zoxide/project dirs — type to filter, enter create, esc back.
set -euo pipefail

HERDR="${HERDR_BIN_PATH:-herdr}"
MUX_SESH_CONFIG="${MUX_SESH_CONFIG:-$HOME/.config/mux-sesh/config.json}"
FD_DEPTH="${HERDR_WS_FD_DEPTH:-3}"

# rose-pine main (match zsh FZF_DEFAULT_OPTS / herdr theme)
RP_BASE="#191724"
RP_SURFACE="#1f1d2e"
RP_OVERLAY="#26233a"
RP_MUTED="#6e6a86"
RP_SUBTLE="#908caa"
RP_TEXT="#e0def4"
RP_IRIS="#c4a7e7"
RP_FOAM="#9ccfd8"
RP_ROSE="#ebbcba"
RP_LOVE="#eb6f92"
RP_GOLD="#f6c177"

FZF_RP_COLORS="bg+:${RP_OVERLAY},bg:${RP_BASE},spinner:${RP_FOAM},hl:${RP_IRIS},fg:${RP_TEXT},header:${RP_FOAM},info:${RP_ROSE},pointer:${RP_FOAM},marker:${RP_LOVE},fg+:${RP_TEXT},prompt:${RP_IRIS},hl+:${RP_IRIS},border:${RP_MUTED},gutter:${RP_BASE},query:${RP_TEXT},separator:${RP_MUTED},label:${RP_SUBTLE}"

herdr_json() {
	"$HERDR" "$@"
}

# ANSI helpers (fzf --ansi)
c() { printf '\033[%sm' "$1"; }
c_reset() { c "0"; }
c_iris() { c "38;2;196;167;231"; }
c_foam() { c "38;2;156;207;216"; }
c_muted() { c "38;2;110;106;134"; }
c_subtle() { c "38;2;144;140;170"; }
c_text() { c "38;2;224;222;244"; }
c_love() { c "38;2;235;111;146"; }
c_gold() { c "38;2;246;193;119"; }
c_rose() { c "38;2;235;188;186"; }

notify() {
	local title="$1"
	local body="${2:-}"
	if "$HERDR" notification show "$title" --body "$body" >/dev/null 2>&1; then
		return 0
	fi
	printf '%s: %s\n' "$title" "$body" >&2 || true
}

expand_path() {
	local p="$1"
	case "$p" in
	"~") printf '%s\n' "${HOME:-/}" ;;
	"~/"*) printf '%s\n' "${HOME:-/}/${p#~/}" ;;
	*) printf '%s\n' "$p" ;;
	esac
}

short_path() {
	local p="$1"
	local home="${HOME:-}"
	if [[ -n $home && $p == "$home" ]]; then
		printf '~\n'
	elif [[ -n $home && $p == "$home"/* ]]; then
		printf '~/%s\n' "${p#"$home"/}"
	else
		printf '%s\n' "$p"
	fi
}

prompt_line() {
	local prompt="$1"
	local initial="${2:-}"
	if command -v gum >/dev/null 2>&1; then
		GUM_INPUT_PROMPT_FOREGROUND="$RP_IRIS" \
			GUM_INPUT_CURSOR_FOREGROUND="$RP_FOAM" \
			GUM_INPUT_HEADER_FOREGROUND="$RP_FOAM" \
			GUM_INPUT_PLACEHOLDER_FOREGROUND="$RP_MUTED" \
			GUM_INPUT_PROMPT_BACKGROUND="" \
			GUM_INPUT_CURSOR_BACKGROUND="" \
			gum input --prompt "$prompt " --placeholder "$initial" --value "$initial" || true
		return
	fi
	local reply=""
	if [[ -n $initial ]]; then
		printf '%s [%s]: ' "$prompt" "$initial" >/dev/tty
	else
		printf '%s: ' "$prompt" >/dev/tty
	fi
	IFS= read -r reply </dev/tty || true
	if [[ -z $reply ]]; then
		printf '%s\n' "$initial"
	else
		printf '%s\n' "$reply"
	fi
}

# workspace_id keyed by realpath cwd (best-effort from live panes)
open_cwd_map() {
	herdr_json api snapshot 2>/dev/null |
		jq -r '
			.result.snapshot.panes // []
			| map(select((.cwd // "") != ""))
			| group_by(.workspace_id)
			| .[]
			| (.[0].workspace_id) as $ws
			| (map(.cwd) | unique | .[])
			| "\($ws)\t\(.)"
		' 2>/dev/null |
		while IFS=$'\t' read -r ws cwd; do
			real="$(realpath -m -- "$cwd" 2>/dev/null || printf '%s' "$cwd")"
			printf '%s\t%s\n' "$real" "$ws"
		done
}

list_workspace_rows() {
	herdr_json workspace list |
		jq -r '
			(.result.workspaces // [])
			| sort_by(.number // 0)
			| .[]
			| [
					"ws",
					(if .focused == true then "*" else " " end),
					((.number // 0) | tostring),
					(.label // .workspace_id // "?"),
					.workspace_id
				]
			| @tsv
		' |
		while IFS=$'\t' read -r kind mark num label id; do
			if [[ $mark == "*" ]]; then
				printf 'ws\t%s●%s %s%2s%s  %s%-24s%s  %s%s%s\n' \
					"$(c_iris)" "$(c_reset)" \
					"$(c_foam)" "$num" "$(c_reset)" \
					"$(c_text)" "$label" "$(c_reset)" \
					"$(c_muted)" "$id" "$(c_reset)"
			else
				printf 'ws\t %s%2s%s  %s%-24s%s  %s%s%s\n' \
					"$(c_subtle)" "$num" "$(c_reset)" \
					"$(c_text)" "$label" "$(c_reset)" \
					"$(c_muted)" "$id" "$(c_reset)"
			fi
		done
}

project_roots() {
	if [[ -f $MUX_SESH_CONFIG ]] && command -v jq >/dev/null 2>&1; then
		jq -r '(.project_paths // [])[]?' "$MUX_SESH_CONFIG" 2>/dev/null |
			while read -r p; do
				[[ -n $p ]] || continue
				expand_path "$p"
			done
	fi
}

# dirs to offer for create: zoxide frecent + shallow children of project_paths
list_dir_candidates() {
	local -A seen=()
	local d real

	if command -v zoxide >/dev/null 2>&1; then
		while IFS= read -r d; do
			[[ -n $d && -d $d ]] || continue
			real="$(realpath -m -- "$d" 2>/dev/null || printf '%s' "$d")"
			[[ -z ${seen[$real]+x} ]] || continue
			seen[$real]=1
			printf 'dir\t%s\n' "$real"
		done < <(zoxide query -l 2>/dev/null || true)
	fi

	if command -v fd >/dev/null 2>&1; then
		while IFS= read -r root; do
			[[ -d $root ]] || continue
			real="$(realpath -m -- "$root" 2>/dev/null || printf '%s' "$root")"
			if [[ -z ${seen[$real]+x} ]]; then
				seen[$real]=1
				printf 'dir\t%s\n' "$real"
			fi
			while IFS= read -r d; do
				[[ -d $d ]] || continue
				real="$(realpath -m -- "$d" 2>/dev/null || printf '%s' "$d")"
				[[ -z ${seen[$real]+x} ]] || continue
				seen[$real]=1
				printf 'dir\t%s\n' "$real"
			done < <(fd -t d -d "$FD_DEPTH" --absolute-path . "$root" 2>/dev/null || true)
		done < <(project_roots)
	else
		while IFS= read -r root; do
			[[ -d $root ]] || continue
			real="$(realpath -m -- "$root" 2>/dev/null || printf '%s' "$root")"
			[[ -z ${seen[$real]+x} ]] || continue
			seen[$real]=1
			printf 'dir\t%s\n' "$real"
		done < <(project_roots)
	fi
}

# dir rows not already represented by an open workspace cwd
list_dir_rows() {
	local -A open_ws=()
	local cwd ws real short

	while IFS=$'\t' read -r cwd ws; do
		[[ -n $cwd && -n $ws ]] || continue
		open_ws[$cwd]="$ws"
	done < <(open_cwd_map)

	while IFS=$'\t' read -r kind real; do
		[[ $kind == dir && -n $real ]] || continue
		[[ -z ${open_ws[$real]+x} ]] || continue
		short="$(short_path "$real")"
		printf 'dir\t   %s%-40s%s  %s%s%s\n' \
			"$(c_foam)" "$short" "$(c_reset)" \
			"$(c_muted)" "$real" "$(c_reset)"
	done < <(list_dir_candidates)
}

create_at() {
	local cwd="$1"
	local label
	cwd="$(expand_path "$cwd")"
	cwd="$(realpath -m -- "$cwd" 2>/dev/null || printf '%s' "$cwd")"
	if [[ ! -d $cwd ]]; then
		notify "workspace create failed" "not a directory: $cwd"
		return 1
	fi

	label="$(prompt_line 'label' "$(basename -- "$cwd")")"
	[[ -n $label ]] || label="$(basename -- "$cwd")"

	if herdr_json workspace create --cwd "$cwd" --label "$label" --focus >/dev/null; then
		return 0
	fi
	notify "workspace create failed" "$label @ $cwd"
	return 1
}

focus_workspace() {
	local id="$1"
	if herdr_json workspace focus "$id" >/dev/null; then
		return 0
	fi
	notify "workspace focus failed" "$id"
	return 1
}

close_workspace() {
	local id="$1"
	if herdr_json workspace close "$id" >/dev/null 2>&1; then
		return 0
	fi
	notify "workspace close failed" "$id"
	return 1
}

# if dir already open in some workspace, focus that instead of creating duplicate
focus_or_create_dir() {
	local dir="$1"
	local real ws
	real="$(realpath -m -- "$(expand_path "$dir")" 2>/dev/null || expand_path "$dir")"

	ws="$(
		open_cwd_map | awk -F '\t' -v d="$real" '$1 == d { print $2; exit }'
	)"
	if [[ -n $ws ]]; then
		focus_workspace "$ws"
		return
	fi
	create_at "$real"
}

strip_ansi() { sed 's/\x1b\[[0-9;]*m//g'; }

parse_ws_id_from_line() {
	strip_ansi | awk '{ print $NF }'
}

# dd arm: first d marks id in place; second d closes and reloads.
dd_transform_action() {
	local arm_file="$1"
	local self="$2"
	local hdr_normal="$3"
	local line="$4"
	local id armed
	id="$(printf '%s\n' "$line" | parse_ws_id_from_line)"
	[[ -n $id ]] || return 0
	armed="$(cat -- "$arm_file" 2>/dev/null || true)"
	if [[ -n $armed && $armed == "$id" ]]; then
		if close_workspace "$id"; then
			: >"$arm_file"
			printf 'reload(%q --emit-ws)+change-pointer(▶)+change-header(%s)\n' \
				"$self" "$hdr_normal"
		else
			printf 'change-pointer(✖)+change-header(close failed for %s · d retry · move cancels)\n' "$id"
		fi
	else
		printf '%s' "$id" >"$arm_file"
		printf 'change-pointer(✖)+change-header(d again to kill %s · move/esc cancels)\n' "$id"
	fi
}

fzf_chrome() {
	# shared flags as args after caller-specific ones — used via eval-free arrays
	printf '%s\0' \
		--ansi \
		--height=100% \
		--reverse \
		--cycle \
		--no-multi \
		--border=rounded \
		--border-label=' herdr ' \
		--border-label-pos=3 \
		--padding=1,2 \
		--margin=0 \
		--pointer='▶' \
		--marker='●' \
		--separator='─' \
		--info=inline-right \
		--color="$FZF_RP_COLORS" \
		--delimiter=$'\t' \
		--with-nth=2..
}

# Phase 1: workspaces only. Prints selected line, or "new\\t" when user hits n.
pick_workspace() {
	local self arm_file qself qarm qhdr
	local clear_arm
	self="$(realpath -- "${BASH_SOURCE[0]}")"
	arm_file="$(mktemp "${TMPDIR:-/tmp}/herdr-ws-dd.XXXXXX")"
	# shellcheck disable=SC2064
	trap "rm -f -- $(printf '%q' "$arm_file")" RETURN

	local prompt_normal='󰿄 › '
	local prompt_insert='󰿄 / › '
	local hdr_normal='j/k move · i search ws · n new · dd kill · enter focus · q quit'
	local hdr_insert='type filter ws · esc normal · enter focus'
	qself="$(printf '%q' "$self")"
	qarm="$(printf '%q' "$arm_file")"
	qhdr="$(printf '%q' "$hdr_normal")"
	clear_arm="execute-silent(: >${qarm})+change-pointer(▶)"

	local -a normal_bind_parts=(
		"j:${clear_arm}+down+change-header(${hdr_normal})"
		"k:${clear_arm}+up+change-header(${hdr_normal})"
		"h:${clear_arm}+up+change-header(${hdr_normal})"
		"l:${clear_arm}+down+change-header(${hdr_normal})"
		'q:abort'
		# become replaces fzf; stdout becomes this function's output
		"n:become(printf '%s\\n' 'new"$'\t'"')"
		"d:transform(${qself} --dd-action ${qarm} ${qself} ${qhdr} {})"
	)
	local -a normal_keys=(j k h l i n q d)
	local c
	for c in {a..z}; do
		case $c in j | k | h | l | i | n | q | d) continue ;; esac
		normal_bind_parts+=("${c}:ignore")
		normal_keys+=("$c")
	done
	local normal_binds normal_key_csv
	normal_binds="$(IFS=,; printf '%s' "${normal_bind_parts[*]}")"
	normal_key_csv="$(IFS=,; printf '%s' "${normal_keys[*]}")"
	local bind_enter_insert bind_leave_insert
	bind_enter_insert="i:${clear_arm}+enable-search+unbind(${normal_key_csv})+change-prompt(${prompt_insert})+change-header(${hdr_insert})"
	bind_leave_insert="esc:${clear_arm}+disable-search+rebind(${normal_key_csv})+clear-query+change-prompt(${prompt_normal})+change-header(${hdr_normal})"

	local -a chrome=()
	while IFS= read -r -d '' flag; do
		chrome+=("$flag")
	done < <(fzf_chrome)

	list_workspace_rows | fzf \
		"${chrome[@]}" \
		--disabled \
		--prompt="$prompt_normal" \
		--header="$hdr_normal" \
		--bind="$normal_binds" \
		--bind="$bind_enter_insert" \
		--bind="$bind_leave_insert"
}

# Phase 2: dirs only, search on immediately. Empty/abort → caller loops back.
pick_dir_for_new() {
	local -a chrome=()
	while IFS= read -r -d '' flag; do
		chrome+=("$flag")
	done < <(fzf_chrome)

	list_dir_rows | fzf \
		"${chrome[@]}" \
		--prompt='󰿄 new › ' \
		--header='type filter dir · enter create · esc back'
}

main() {
	if ! command -v fzf >/dev/null 2>&1; then
		notify "workspace picker" "fzf not found"
		exit 1
	fi
	if ! command -v jq >/dev/null 2>&1; then
		notify "workspace picker" "jq not found"
		exit 1
	fi

	local choice kind rest id path dir_choice

	while true; do
		choice="$(pick_workspace)" || true
		[[ -n ${choice:-} ]] || exit 0

		kind="${choice%%$'\t'*}"
		rest="$(strip_ansi <<<"${choice#*$'\t'}")"

		case "$kind" in
		new)
			dir_choice="$(pick_dir_for_new)" || true
			[[ -n ${dir_choice:-} ]] || continue
			kind="${dir_choice%%$'\t'*}"
			rest="$(strip_ansi <<<"${dir_choice#*$'\t'}")"
			[[ $kind == dir ]] || continue
			path="$(awk '{print $NF}' <<<"$rest")"
			[[ -n $path ]] || continue
			focus_or_create_dir "$path" || exit 1
			exit 0
			;;
		ws)
			id="$(awk '{print $NF}' <<<"$rest")"
			[[ -n $id ]] || exit 0
			focus_workspace "$id" || exit 1
			exit 0
			;;
		*)
			exit 0
			;;
		esac
	done
}

# fzf reload / transform entrypoints (must be after function defs)
case "${1:-}" in
--emit-ws)
	list_workspace_rows
	;;
--dd-action)
	dd_transform_action "${2:?}" "${3:?}" "${4:?}" "${5:-}"
	;;
*)
	main "$@"
	;;
esac
