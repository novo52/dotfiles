#!/bin/sh
# Render palette.tsv for one terminal. Output goes to stdout.
#
#   generate.sh dconf        gnome-terminal / any dconf-based VTE terminal
#   generate.sh wt           a Windows Terminal colour scheme, as JSON
#   generate.sh lua-table    the Lua table literal in nvim/lua/config/palette.lua
#   generate.sh apply-dconf  write the palette into a gnome-terminal profile
#
# POSIX sh and awk only, so this runs anywhere the bootstrap does.

set -eu

dir=$(dirname "$0")
tsv="$dir/palette.tsv"

[ -r "$tsv" ] || { echo "generate.sh: cannot read $tsv" >&2; exit 1; }

# slot -> hex, for slots 0-15 in order, then fg and bg.
ansi() { awk -F'\t' '$1 ~ /^[0-9]+$/ { print $3 }' "$tsv"; }
slot() { awk -F'\t' -v s="$1" '$1 == s { print $3 }' "$tsv"; }

case "${1:-}" in
dconf)
	printf "palette="
	printf "["
	ansi | awk '{ printf "%s'\''%s'\''", (NR>1 ? ", " : ""), $0 }'
	printf "]\n"
	printf "foreground-color='%s'\n" "$(slot fg)"
	printf "background-color='%s'\n" "$(slot bg)"
	printf "use-theme-colors=false\n"
	;;
wt)
	printf '{\n'
	printf '  "name": "chloe-tango",\n'
	printf '  "background": "%s",\n' "$(slot bg)"
	printf '  "foreground": "%s",\n' "$(slot fg)"
	printf '  "cursorColor": "%s",\n' "$(slot fg)"
	printf '  "selectionBackground": "%s",\n' "$(slot 8)"
	# Windows Terminal names slot 5 "purple", not "magenta".
	i=0
	for name in black red green yellow blue purple cyan white \
	            brightBlack brightRed brightGreen brightYellow \
	            brightBlue brightPurple brightCyan brightWhite; do
		printf '  "%s": "%s"' "$name" "$(slot $i)"
		[ "$i" -eq 15 ] && printf '\n' || printf ',\n'
		i=$((i + 1))
	done
	printf '}\n'
	;;
lua-table)
	roles=$(awk -F'\t' '$1 ~ /^[0-9]+$/ { gsub(/_/, " ", $2); print $1 " " $2 }' "$tsv")
	printf 'local ansi = {\n'
	echo "$roles" | while read -r idx role; do
		printf "  '%s', -- %s %s\n" "$(slot "$idx")" "$idx" "$role"
	done
	printf '}\n'
	;;
apply-dconf)
	profile=${2:-}
	[ -n "$profile" ] || {
		echo "usage: generate.sh apply-dconf <profile-uuid>" >&2
		echo "list them with: dconf read /org/gnome/terminal/legacy/profiles:/list" >&2
		exit 1
	}
	base="/org/gnome/terminal/legacy/profiles:/:$profile"
	list=$(ansi | awk '{ printf "%s'\''%s'\''", (NR>1 ? ", " : ""), $0 }')
	dconf write "$base/palette" "[$list]"
	dconf write "$base/foreground-color" "'$(slot fg)'"
	dconf write "$base/background-color" "'$(slot bg)'"
	dconf write "$base/use-theme-colors" "false"
	echo "applied to $profile" >&2
	;;
*)
	sed -n '2,10p' "$0" >&2
	exit 1
	;;
esac
