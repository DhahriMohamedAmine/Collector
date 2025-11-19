#!/bin/zsh
# set -x

# -----------------------------------------------------------------------------
# Asset Organizer Script
#
# This script scans a source directory for asset files (images, videos, zips),
# parses their file and directory names to extract metadata (market, partner,
# size, etc.), and then renames and copies them into an organized
# destination directory structure based on defined export rules.
#
# It uses macOS 'defaults' to store and retrieve lookup tables for markets,
# identifiers (partners, offers), and export rules.
# -----------------------------------------------------------------------------

#region == Configuration ==

# Domain for macOS 'defaults' storage
readonly SCRIPT_DOMAIN="com.vistaprint.onlinedisplay.assetorganizer"
readonly SCRIPT_VERSION="1.0.1"

# Max parallel processes to run (defaults to physical CPU count or 8)
readonly MAX_PROCESSES=$(sysctl -n hw.perflevel0.physicalcpu 2>/dev/null || echo 8)

# --- User-configurable Paths and Values ---

# The directory to scan for new assets
SOURCE_REVIEW_DIR="/Users/mohamedaminedhahri/Desktop/Code/Collector/REVIEW"

# The base directory where organized assets will be copied
DESTINATION_BASE_DIR='/Users/mohamedaminedhahri/Desktop/Code/Collector/approved'

# The ticket ID to be embedded in new filenames
TICKET_ID='TIX-XXXX'

#endregion

#region == Global Variables (Lookup Tables) ==

# Associative array mapping market aliases (e.g., "USEN", "ENUS", "UK") to a canonical market code (e.g., "GBen")
typeset -A MARKET_LOOKUP
# Associative array mapping group aliases (e.g., "NA", "EU") to a space-separated list of market codes
typeset -A GROUP_LOOKUP

# Associative array mapping identifier types (e.g., "partner", "offer") to a pipe-separated list of regex aliases
typeset -A IDENTIFERS_ALIASES
# Associative array mapping a specific alias (e.g., "you tube") to its canonical name (e.g., "Youtube")
typeset -A IDENTIFERS_NAMES
# Associative array mapping a specific alias (e.g., "you tube") to its folder name (e.g., "03. Youtube")
typeset -A IDENTIFERS_FOLDERS

# Array to store export filters, sorted by specificity (most specific first)
typeset -a EXPORT_FILTERS
# Associative array mapping a filter key (e.g., "partner=Youtube") to a filename template
typeset -A EXPORT_NAME_TEMPLATES
# Associative array mapping a filter key to a folder path template
typeset -A EXPORT_FOLDER_TEMPLATES

#endregion

#region == Database & Lookup Initialization Functions ==

#
# Checks the stored DB version against the script version.
# If versions mismatch, it wipes the old DB to force recreation.
#
function check_and_update_db_version () {
	local stored_version
    stored_version=$(defaults read "$SCRIPT_DOMAIN" DB_VERSION 2>/dev/null)

    if [[ -z "$stored_version" || "$stored_version" < "$SCRIPT_VERSION" ]]; then
        # Clear all settings for this domain if version is old or missing
        defaults delete "$SCRIPT_DOMAIN"
        # Write the new version
        defaults write "$SCRIPT_DOMAIN" DB_VERSION "$SCRIPT_VERSION"
    fi
}

#
# Loads market and group lookup tables from 'defaults'.
# If they don't exist, populates them with default data.
#
function load_market_lookups() {
    # Check if MARKETS data exists; if not, create it
	if ! defaults read "$SCRIPT_DOMAIN" MARKETS &>/dev/null; then
        # Default data: Alias:Countries:Language:Groups
		local default_markets_data='USen:US:EN:ALL NA EN
USes:US:ES:ALL NA
CAen:CA:EN:ALL NA EN
CAfr:CA:FR:ALL NA
AUen:AU:EN:ALL ANZ EN
SGen:SG:EN:ALL ANZ EN
NZen:NZ:EN:ALL ANZ EN
GBen:GB UK:EN:ALL EU EN
IEen:IE:EN:ALL EU EN
FRfr:FR:FR:ALL EU
DEde:DE:DE:ALL EU
ITit:IT:IT:ALL EU
ESes:ES:ES:ALL EU
NLnl:NL:NL:ALL EU
DKda:DK:DA:ALL EU
PTpt:PT:PT:ALL EU
SEsv:SE:SV:ALL EU
NOnb:NO:NB:ALL EU
FIfi:FI:FI:ALL EU
BEfr:BE:FR:ALL EU BE
BEnl:BE:NL:ALL EU BE
CHfr:CH:FR:ALL EU CH
CHde:CH:DE:ALL EU CH
CHit:CH:IT:ALL EU CH
ATde:AT:DE:ALL EU AT
ATit:ATLIT:IT:ALL EU AT'

		while IFS=':' read -r alias countries lang groups; do
            # Write data to macOS defaults
			defaults write "$SCRIPT_DOMAIN" MARKETS -dict-add "$alias" "{ Countries = \"${countries// /, }\"; Languages = \"${lang// /, }\"; Groups = \"${groups// /, }\"; }"
		done <<< "$default_markets_data"
	fi

    # Read the stored market data as JSON
	local current_markets_json
    current_markets_json=$(defaults read "$SCRIPT_DOMAIN" MARKETS | plutil -convert json -o - -)

    # --- Populate ZSH Lookup Tables ---

	for market in $(echo "$current_markets_json" | jq -r 'keys | .[]')
	do
        # Extract data for the current market
		local languages countries groups
        languages=$(jq -r ".$market.Languages" <<< "$current_markets_json") && languages=(${(s:, :)languages})
		countries=$(jq -r ".$market.Countries" <<< "$current_markets_json") && countries=(${(s:, :)countries})
		groups=$(jq -r ".$market.Groups" <<< "$current_markets_json") && groups=(${(s:, :)groups})

        # Create combined aliases like "ENUS", "USEN", and single aliases like "US"
		local market_aliases=(${languages:^^countries} ${countries:^^languages})
		market_aliases=$(perl -pe 's/ /++$c % 2 == 1 ? "" : $& /ge' <<< $market_aliases)
		market_aliases=${market_aliases//GLOBALGLOBAL/GLOBAL}
		market_aliases=(${(s: :)market_aliases})
		market_aliases=($market_aliases $countries)

        # Populate GROUP_LOOKUP
		for group in ${groups[@]}; do
			GROUP_LOOKUP[$group]="${GROUP_LOOKUP[$group]:+$GROUP_LOOKUP[$group] }$market"
		done

        # Populate MARKET_LOOKUP
		for alias in ${market_aliases[@]}; do
            # Only add if alias doesn't already exist (first match wins)
			MARKET_LOOKUP[$alias]="${MARKET_LOOKUP[$alias]:-$market}"
		done
	done
}

#
# Loads identifier lookup tables (partner, offer, etc.) from 'defaults'.
# If they don't exist, populates them with default data.
#
function load_identifier_lookups() {
    # Ensure the base 'identifiers' dictionary exists
	if ! defaults read "$SCRIPT_DOMAIN" 'identifiers' &>/dev/null; then
		defaults write "$SCRIPT_DOMAIN" 'identifiers' -dict "{}"
	fi

	local identifiers_db_json
    identifiers_db_json=$(defaults read "$SCRIPT_DOMAIN" 'identifiers' 2>/dev/null | plutil -convert json -o - -)

    # --- Populate Partners ---
	if ! jq -e '.partners' <<< "$identifiers_db_json" &>/dev/null; then
		local default_partners_data='Linear:01. Linear:linear
CTV:02. CTV:ctv
Youtube:03. Youtube:you[^[:alnum:]]?tube
companionBanner:03. Youtube:companion[^[:alnum:]]?banner
DV360:04. DV360:dv[^[:alnum:]]?360
RTB:05. RTB House:rtb
Pmax:06. PMAX:pmax
inFeed:07. Meta:in[^[:alnum:]]?feed
Story:07. Meta:story
Meta:07. Meta:meta
Reddit:08. Reddit:reddit
Pinterest:09. Pinterest:pinterest
TikTok:10. TikTok:tik[^[:alnum:]]?tok
Discovery:11. Responsive Discovery:discovery
Responsive:11. Responsive Discovery:responsive
HTML:12. HTML:html, html[^[:alnum:]]?5
liveIntent:13. Live Intent:liveintent, live[^[:alnum:]]?intent
Native:14. Native:native
Criteo:15. Criteo:criteo
customerReview:16. Customer Review:customer[^[:alnum:]]?review
Snapchat:17. Snapchat:snap[^[:alnum:]]?chat'

		local partners_db_json=$(echo {} | jq '{}')
		while IFS=':' read -r name folder alias; do
			partners_db_json=$(jq --arg name "$name" --arg folder "$folder" --arg alias "$alias" '. += { ($name): { name: $name, folder: $folder, alias: $alias }}' <<< "$partners_db_json")
		done  <<< "$default_partners_data"

		partners_db_json=$(echo $partners_db_json | plutil -convert xml1 -o - -)
		defaults write "$SCRIPT_DOMAIN" identifiers -dict-add "partner" "$partners_db_json"
	fi

    # --- Populate HTML Publishers ---
	if ! jq -e '.htmlPublisher' <<< "$identifiers_db_json" &>/dev/null; then
		local default_html_publishers_data='theTradeDesk:The Trade Desk:the[^[:alnum:]]?trade[^[:alnum:]]?desk, trade[^[:alnum:]]?desk
campaignManager360:Campaign Manager 360:campaign[^[:alnum:]]?manager[^[:alnum:]]?360, campaign[^[:alnum:]]?manager, manager[^[:alnum:]]?360
pmaxBanner:PMAX Banners:pmax[^[:alnum:]]?banner'

		local html_publishers_db_json=$(echo {} | jq '{}')
		while IFS=':' read -r name folder alias; do
			html_publishers_db_json=$(jq --arg name "$name" --arg folder "$folder" --arg alias "$alias" '. += { ($name): { name: $name, folder: $folder, alias: $alias }}' <<< "$html_publishers_db_json")
		done  <<< "$default_html_publishers_data"

		html_publishers_db_json=$(echo $html_publishers_db_json | plutil -convert xml1 -o - -)
		defaults write "$SCRIPT_DOMAIN" identifiers -dict-add "htmlPublishers" "$html_publishers_db_json"
	fi

    # --- Populate Offers ---
	if ! jq -e '.offer' <<< "$identifiers_db_json" &>/dev/null; then
		local default_offers_data='NCO:New Customer Offer:NCO, new[^[:alnum:]]?customer[^[:alnum:]]?Offer
Offer:Offer:[^[:alnum:]]Offer[^[:alnum:]], [^[:alnum:]]Offer[^[:alnum:]]?[0-9]+[^[:alnum:]]
noOffer:No Offer:[^[:alnum:]]no[^[:alnum:]]?Offer[^[:alnum:]]'

		local offers_db_json=$(echo {} | jq '{}')
		while IFS=':' read -r name folder alias; do
			offers_db_json=$(jq --arg name "$name" --arg folder "$folder" --arg alias "$alias" '. += { ($name): { name: $name, folder: $folder, alias: $alias }}' <<< "$offers_db_json")
		done  <<< "$default_offers_data"

		offers_db_json=$(echo $offers_db_json | plutil -convert xml1 -o - -)
		defaults write "$SCRIPT_DOMAIN" identifiers -dict-add "offer" "$offers_db_json"
	fi

    # --- Populate ZSH Lookup Tables ---
    # Read the complete identifiers DB again (now with defaults)
	identifiers_db_json=$(defaults read "$SCRIPT_DOMAIN" 'identifiers' 2>/dev/null | plutil -convert json -o - -)

    # Use 'eval' to dynamically build ZSH associative arrays from the JSON data
    # IDENTIFIER_ALIASES['partner'] = "linear|ctv|you tube|..."
	eval "$(jq -r 'to_entries[] | .key as $k | [.value[].alias | gsub(", "; "|")] | join("|") as $a | "IDENTIFERS_ALIASES[\($k)]=\"\($a)\""' <<< "$identifiers_db_json")"
	eval "$(jq -r 'to_entries[] | .value[] | .name as $n | (.alias | split(", "))[] | "IDENTIFERS_NAMES[\"\(.)\"]=\"\($n)\""' <<< "$identifiers_db_json")"
	eval "$(jq -r 'to_entries[] | .value[] | .folder as $f | (.alias | split(", "))[] | "IDENTIFERS_FOLDERS[\"\(.)\"]=\"\($f)\""' <<< "$identifiers_db_json")"
}

#
# Loads export rules (name/folder templates) from 'defaults'.
# If they don't exist, populates them with default data.
#
function load_export_lookups() {
    # Ensure the base 'export' dictionary exists
	if ! defaults read "$SCRIPT_DOMAIN" 'export' &>/dev/null; then
		defaults write "$SCRIPT_DOMAIN" 'export' -dict "{}"

        # Default data: Filter:NameTemplate:FolderTemplate
		local default_export_rules_data='DEFAULT:MARKET_TICKET_partner.name_FORMAT_offer.match_SIZE_INDEX:/MARKET/partner.folder/offer.match
partner.name=Responsive:MARKET_TICKET_partner.name_FORMAT_offer.match_SIZE_INDEX:/MARKET/partner.folder/offer.match/SIZE
partner.name=Discovery:MARKET_TICKET_partner.name_FORMAT_offer.match_SIZE_INDEX:/MARKET/partner.folder/offer.match/SIZE
partner.name=Responsive, size=960x1200:MARKET_TICKET_Discovery_FORMAT_offer.match_SIZE_INDEX:/MARKET/partner.folder/offer.match/SIZE
partner.name=Discovery, size=960x1200:MARKET_TICKET_Discovery_FORMAT_offer.match_SIZE_INDEX:/MARKET/partner.folder/offer.match/SIZE
partner.name=companionBanner:MARKET_TICKET_partner.name_FORMAT_offer.match_SIZE_INDEX:/MARKET/partner.folder/offer.match/youtube
partner.name=HTML, FORMAT=Static:MARKET_TICKET_partner.name_FORMAT_offer.match_SIZE_INDEX:/MARKET/partner.folder/offer.match/preview
partner.name=HTML, htmlPublishers:MARKET_TICKET_partner.name_FORMAT_offer.match_SIZE_INDEX:/MARKET/partner.folder/offer.match/htmlPublishers.folder'


		while IFS=':' read -r filter name folder; do
			defaults write "$SCRIPT_DOMAIN" export -dict-add "$filter" "{ name = \"$name\"; folder = \"$folder\"; }"
		done <<< $default_export_rules_data
	fi

	local export_db_json
    export_db_json=$(defaults read "$SCRIPT_DOMAIN" 'export' 2>/dev/null | plutil -convert json -o - -)

    # --- Populate ZSH Lookup Tables ---

    # Get all filter keys
	EXPORT_FILTERS=(${(f)"$(jq -r 'to_entries[] | .key' <<< $export_db_json)"})
    # Sort filters by specificity (most conditions first)
    # This ensures "partner=X, size=Y" is checked before "partner=X"
	EXPORT_FILTERS=("${(@)$(for filter_string in "${EXPORT_FILTERS[@]}"; do
		local conditions=(${(s:,:)filter_string})
		local count=${#conditions[@]}
		echo "$count $filter_string"
	done | sort -nr | cut -d' ' -f2-)}")

    # Populate the name and folder template lookup tables
	eval $(jq -r 'to_entries[] | .key as $k | "EXPORT_NAME_TEMPLATES[\"\($k)\"]=\"\(.value.name)\""' <<< "$export_db_json")
	eval $(jq -r 'to_entries[] | .key as $k | "EXPORT_FOLDER_TEMPLATES[\"\($k)\"]=\"\(.value.folder)\""' <<< "$export_db_json")
}

#endregion

#region == Metadata Parsing Functions ==

#
# Attempts to find market codes from a string (e.g., a filename).
# $1: The string to parse.
#
function get_markets() {
	local path_component="$1"
	typeset -U markets=() # Unique array

    # Clean and uppercase the string
	path_component="${path_component//[^[:alnum:]]/ }"
	path_component=${(U)path_component}
	path_component=(${(s: :)path_component}) # Split into words

	for (( i=1; i<=${#path_component[@]}; i++ )); do
		local current_word="${path_component[$i]}"
		[[ -z "$current_word" ]] && break
		local next_word="${path_component[(( i+1 ))]}"

        # 1. Check if the word is a Group (e.g., "NA")
		[[ -n $GROUP_LOOKUP[$current_word] ]] && markets+=(${(s: :)GROUP_LOOKUP[$current_word]}) && continue
        # 2. Check if the current and next word form a combined alias (e.g., "US EN")
		[[ -n $MARKET_LOOKUP[$current_word$next_word] && -n "$next_word" ]] && markets+=($MARKET_LOOKUP[$current_word$next_word]) && (( i++ )) && continue
        # 3. Check if the current word is a simple alias (e.g., "UK")
		[[ -n $MARKET_LOOKUP[$current_word] ]] && markets+=(${MARKET_LOOKUP[$current_word]}) && continue
		
        # If none matched, stop parsing for markets
		break
	done

	echo "${markets[@]}"
}

#
# Gets the asset format (Static, Video, HTML) based on MIME type.
# $1: The filepath.
#
function get_format() {
	local filepath="$1"
	local mime_type

	mime_type=$(file --brief --mime-type "$filepath")

	case "${mime_type}" in
		image/*) echo "Static" ;;
		video/*) echo "Video" ;;
		application/zip)
            # If it's a zip, check inside for an HTML file
			if unzip -l "$filepath" | grep -iq '\.html$' >/dev/null 2>&1; then
				echo "HTML"
			else
				echo "" # Unknown zip content
			fi
			;;
		*) echo "" ;; # Unknown format
	esac
}

#
# Gets the asset size (e.g., "1920x1080").
# $1: The filepath.
# $2: The format (from get_format).
#
function get_size() {
	local filepath="$1"
	local format="$2"
	local resolution=""

    # 1. Try to find "WIDTHxHEIGHT" in the filename first
	if [[ "${filepath##*/}" =~ ([0-9]+x[0-9]+) ]]; then
		resolution="${match[1]}"
		echo "$resolution"
		return
	fi

    # 2. If it's a Static image, use 'sips' to get dimensions
	if [[ -z "$resolution" && "$format" == 'Static' ]]; then
		local dimensions
        dimensions=$(sips -g pixelWidth -g pixelHeight "$filepath" 2>/dev/null)
		local width=${${dimensions##*pixelWidth: }%%$'\n'*}
		local height=${${dimensions##*pixelHeight: }%%$'\n'*}
		resolution="${width}x${height}"
        # Ensure sips returned valid data
		[[ "$resolution" =~ ^([0-9]+x[0-9]+)$ ]] && echo "$resolution"
		return
	fi

    # 3. Fallback: no size found
	echo ""
}

#endregion

#region == Core Processing Function ==

#
# Parses a single file to find all metadata, determines the
# correct export name and folder, and copies the file.
# $1: The filepath to parse.
#
function parse_file() {
	local filepath="$1"
	local errors=()

    # This array will hold all discovered metadata for the file
	typeset -A asset_metadata
	asset_metadata[NAME]="${filepath##*/}"
	asset_metadata[EXTENSION]="${filepath##*.}"

	asset_metadata[INDEX]=""
	local index_regex='_([0-9]{2})\.'$asset_metadata[EXTENSION]'$'
	if [[ "$asset_metadata[NAME]" =~ $index_regex ]]; then
		asset_metadata[INDEX]="${match[1]}"
	fi

    # Get metadata from file content/properties
	asset_metadata[MARKETS]=""
	asset_metadata[FORMAT]=$(get_format "$filepath")
	asset_metadata[SIZE]=$(get_size "$filepath" "$asset_metadata[FORMAT]")

	setopt nocasematch # Enable case-insensitive matching
	local current_path_level="$filepath"
    # Walk up the directory tree from the file
	while [[ "$current_path_level" != "$HOME" && "$current_path_level" != "/" ]]; do
        # Try to get markets from the current path component (filename or dir name)
        # Only set markets once
		[[ -z $asset_metadata[MARKETS] ]] && asset_metadata[MARKETS]=$(get_markets "${current_path_level##*/}")

        # Check for all other identifiers (partner, offer, etc.)
		for k v in ${(kv)IDENTIFERS_ALIASES}; do
			[[ -n $asset_metadata[$k] ]] && continue
			asset_metadata[$k]=""
			asset_metadata[${k}.name]=""
			asset_metadata[${k}.folder]=""
			asset_metadata[${k}.match]=""
			
			# echo "$k -- $v"
			for alias in ${(s:|:)v}; do
				# echo "$alias"
				if [[ "${current_path_level##*/}" =~ ($alias) ]]; then
					asset_metadata[$k]="$alias"
					asset_metadata[${k}.name]="$IDENTIFERS_NAMES["$alias"]"
					asset_metadata[${k}.folder]="$IDENTIFERS_FOLDERS["$alias"]"
					asset_metadata[${k}.match]="$match[1]"
					break
				fi
			done
		done

        # Stop walking up if all metadata keys have been found
        # Note: This check is a bit loose but acts as an optimization
		[[ ${#${(k)asset_metadata}} == ${#${(v)asset_metadata}} ]] && break
		current_path_level=$(dirname "$current_path_level")
	done
	unsetopt nocasematch


    # --- Validate essential metadata ---
	[[ -z $asset_metadata[MARKETS] ]] && errors+=(MARKETS)
	[[ -z $asset_metadata[partner] ]] && errors+=(PARTNER)
	[[ -z $asset_metadata[FORMAT] ]] && errors+=(FORMAT)
	[[ -z $asset_metadata[SIZE] ]] && errors+=(SIZE)

	if [[ -n $errors ]]; then
		echo "ERR::$filepath::${${errors[*]}// /::}::"
		return 0 # Return success to not stop the loop
	fi

	local asset_metadata_array=$(for k in ${(k)asset_metadata}; do
		[[ -z ${asset_metadata[$k]} ]] && continue
		echo "$k"
		echo "$k=${asset_metadata[$k]}"
	done)
	asset_metadata_array=(${(f)asset_metadata_array})

	local matched_rule="DEFAULT"
	for rule in ${(f)EXPORT_FILTERS[@]}; do
		[[ $rule == "DEFAULT" ]] && continue

		local conditions=(${(s:, :)rule})
		local intersection=( ${asset_metadata_array:*conditions} )

		[[ ${intersection[*]} == ${conditions[*]} ]] && matched_rule="$rule" && break
	done

	#region --- Export File Based on Matched Rule ---
	local name_template="$EXPORT_NAME_TEMPLATES["$matched_rule"]"
	local folder_template="$EXPORT_FOLDER_TEMPLATES["$matched_rule"]"

	# local keys="${${${(k)asset_metadata}// /\n}//./ }"
	# keys=$(print -l ${(on)"${(f)keys}"} | awk '{ print NF, $0 }' | sort -rn | cut -d' ' -f2-)
	# keys=${keys// /.}
	
	for market in ${(s: :)asset_metadata[MARKETS]}; do
		local new_name="${name_template//MARKET/$market}"
		local new_path="${folder_template//MARKET/$market}"
		new_name=${new_name//TICKET/$TICKET_ID}

		for part in ${(s:_:)new_name}; do
			[[ ${(k)asset_metadata} =~ $part ]] || continue
			new_name=${new_name//$part/$asset_metadata[$part]}
		done

		for part in ${(s:/:)new_path}; do
			[[ ${(k)asset_metadata} =~ $part ]] || continue
			new_path=${new_path//$part/$asset_metadata[$part]}
		done

		# for key in ${(f)keys}; do
		# 	new_name=${new_name//$key/$asset_metadata[$key]}
		# 	new_path=${new_path//$key/$asset_metadata[$key]}
		# done

		new_name=${new_name//__/_}
		new_name=${new_name%_}
		new_name=${new_name//HTML_HTML/HTML}
		new_name="${new_name}.$asset_metadata[EXTENSION]"

		new_path="${DESTINATION_BASE_DIR}/${new_path}"
		new_path=${new_path//\/\//\/}
		new_path=${new_path%\/}

		# [[ -f "${new_path}/${new_name}" ]] && echo "WARR::${new_path}/${new_name}::"
		mkdir -p "$new_path"
		cp -f "$filepath" "${new_path}/${new_name}"

		echo "OK::${asset_metadata[NAME]}::${new_path}::${new_name}::"
	done

	# echo
	#endregion
}
#endregion

#region == Main Execution ==

# 1. Initialize DB and load all lookups
# (Output is hidden)
check_and_update_db_version &>/dev/null
load_market_lookups &>/dev/null
load_identifier_lookups &>/dev/null
load_export_lookups &>/dev/null
#endregion

#region == Parallel Processing Loop ==
# 2. Find all files (excluding hidden ones) and process them in parallel
echo "Starting asset organization..."
echo "Source: $SOURCE_REVIEW_DIR"
echo "Destination: $DESTINATION_BASE_DIR"
echo "Ticket: $TICKET_ID"
echo "Max Processes: $MAX_PROCESSES"
echo "---"

process_count=0
# 'find' streams files, 'while read' processes them
# Each 'parse_file' is backgrounded (&)
processing_results=$(while read -r file; do
	parse_file "$file" &
	(( process_count++ ))

    # Wait for processes to finish in batches of MAX_PROCESSES
	if (( process_count % MAX_PROCESSES == 0 )); then
        wait
    fi
done < <(find "$SOURCE_REVIEW_DIR" -type f -not -path '*/.*' -name "*"))

# 3. Wait for any remaining background processes
wait

4. Report results
echo "---"
echo "Processing complete. Total files processed: $process_count"
echo
echo "Files with errors:"
echo "$processing_results" | grep "^ERR" | column -s '::' -t
echo
echo "Warnings:"
echo "$processing_results" | grep "^WARR" | column -s '::' -t
echo
echo "Successfully organized files:"
echo "$processing_results" | grep "^OK" | column -s '::' -t

#endregion

#region == Test Loop ==
# process_count=0
# while read -r file; do
# 	parse_file "$file" &
# 	(( process_count++ ))

#     # Wait for processes to finish in batches of MAX_PROCESSES
# 	if (( process_count % MAX_PROCESSES == 0 )); then
#         wait
#     fi
# done < <(find "$SOURCE_REVIEW_DIR" -type f -not -path '*/.*' -name "*")

# for k v in ${(kv)IDENTIFERS_ALIASES}; do
# 	echo "IDENTIFERS_ALIASES[$k]=${v}"
# done
# echo

# for k v in ${(kv)IDENTIFERS_NAMES}; do
# 	echo "IDENTIFERS_NAMES[$k]=${v}"
# done
# echo

# for k v in ${(kv)IDENTIFERS_FOLDERS}; do
# 	echo "IDENTIFERS_FOLDERS[$k]=${v}"
# done
# echo
#endregion