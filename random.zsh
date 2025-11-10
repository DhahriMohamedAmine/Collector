#!/bin/zsh

typeset -A EXPORT_NAME_TEMPLATES
typeset -A EXPORT_FOLDER_TEMPLATES

readonly SCRIPT_DOMAIN="com.vistaprint.onlinedisplay.assetorganizer"
export_db_json=$(defaults read "$SCRIPT_DOMAIN" export 2>/dev/null | plutil -convert json -o - -)

jq -r 'to_entries[] | .key' <<< "$export_db_json"

eval $(jq -r 'to_entries[] | .key as $k | "EXPORT_NAME_TEMPLATES[\"\($k)\"]=\"\(.value.name)\""' <<< "$export_db_json")
eval $(jq -r 'to_entries[] | .key as $k | "EXPORT_FOLDER_TEMPLATES[\"\($k)\"]=\"\(.value.folder)\""' <<< "$export_db_json")

for k v in ${(kv)EXPORT_NAME_TEMPLATES}; do
	echo "EXPORT_NAME_TEMPLATES[$k]=${v}"
done
echo
for k v in ${(kv)EXPORT_FOLDER_TEMPLATES}; do
	echo "EXPORT_FOLDER_TEMPLATES[$k]=${v}"
done
echo