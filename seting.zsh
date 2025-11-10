#!/bin/zsh

readonly SCRIPT_DOMAIN="com.vistaprint.onlinedisplay.assetorganizer"
typeset -A IDENTIFERS_ALIASES
typeset -A IDENTIFERS_NAMES
typeset -A IDENTIFERS_FOLDERS

DB="$(defaults read "$SCRIPT_DOMAIN" identifiers 2>/dev/null | plutil -convert json -o - -)"

eval "$(jq -r 'to_entries[] | .key as $k | [.value[].alias | gsub(", "; "|")] | join("|") as $a | "IDENTIFERS_ALIASES[\($k)]=\"\($a)\""' <<< "$DB")"
eval "$(jq -r 'to_entries[] | .value[] | .name as $n | (.alias | split(", "))[] | "IDENTIFERS_NAMES[\"\(.)\"]=\"\($n)\""' <<< "$DB")"
eval "$(jq -r 'to_entries[] | .value[] | .folder as $f | (.alias | split(", "))[] | "IDENTIFERS_FOLDERS[\"\(.)\"]=\"\($f)\""' <<< "$DB")"

for k v in ${(kv)IDENTIFERS_ALIASES}; do
	echo "IDENTIFERS_ALIASES[$k]=${v}"
done
echo

for k v in ${(kv)IDENTIFERS_NAMES}; do
	echo "IDENTIFERS_NAMES[$k]=${v}"
done
echo

for k v in ${(kv)IDENTIFERS_FOLDERS}; do
	echo "IDENTIFERS_FOLDERS[$k]=${v}"
done
echo

mm="meta"
echo $IDENTIFERS_FOLDERS["$mm"]