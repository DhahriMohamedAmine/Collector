#!/bin/zsh

#region
typeset -gx VERSION="1.0.1"
typeset -gx DOMAIN="com.vistaprint.asset_sorter"

typeset -gxA MARKET_ALIASES
typeset -gxA MARKET_GROUPS
typeset -gx MARKET_REGEX

typeset -gxA PARTNER_LOOKUP
typeset -gxA PARTNER_FOLDER_LOOKUP
typeset -gx PARTNER_REGEX
typeset -gxaU PARTNER_FOLDERS

typeset -gx ROOT_DIR="/Users/mohamedaminedhahri/Desktop/Code/Collector/REVIEW"
typeset -gx TARGET_DIR="$HOME/Documents/FINAL"
typeset -gx TICKET_ID="TICKET-XXXX"
typeset -gx MAX_PROCS=8

#region
function create_market_lookups() {
	if defaults read "$DOMAIN.$VERSION" &>/dev/null; then
		local serialized_aliases
		local serialized_groups
		local serialized_regex

		serialized_aliases=$(defaults read "$DOMAIN.$VERSION" "MARKET_ALIASES" &>/dev/null)
		serialized_groups=$(defaults read "$DOMAIN.$VERSION" "MARKET_GROUPS" &>/dev/null)
		serialized_regex=$(defaults read "$DOMAIN.$VERSION" "MARKET_REGEX" &>/dev/null)

		if [[ "$serialized_aliases" == typeset* && "$serialized_groups" == typeset* && "$serialized_regex" == typeset* ]]; then
			eval "$serialized_aliases"
			eval "$serialized_groups"
			eval "$serialized_regex"

			return 0
		fi
	fi

    local markets=$(
        cat <<EOF
GLOBAL::::GLOBAL
USen::NA::EN::US USUS US-US US/US US.US ENUS EN-US EN/US EN.US US_US EN_US US_EN USEN
USes::NA::EN::USES US-ES US/ES US.ES ESUS ES-US ES/US ES.US US_ES ES_US
CAen::NA::CA CACA CA-CA CA/CA CA.CA ENCA EN-CA EN/CA EN.CA CA_CA EN_CA CA_EN CAEN
CAfr::NA::CAFR CA-FR CA/FR CA.FR FRCA FR-CA FR/CA FR.CA CA_FR FR_CA
AUen::ANZ::EN::AU AUAU AU-AU AU/AU AU.AU ENAU EN-AU EN/AU EN.AU AU_AU EN_AU AU_EN AUEN
SGen::ANZ::EN::SG SGSG SG-SG SG/SG SG.SG ENSG EN-SG EN/SG EN.SG SG_SG EN_SG SG_EN SGEN
NZen::ANZ::EN::NZ NZNZ NZ-NZ NZ/NZ NZ.NZ ENNZ EN-NZ EN/NZ EN.NZ NZ_NZ EN_NZ NZ_EN NZEN
GBen::EU::EN::UK UKUK UK-UK UK/UK UK.UK ENUK EN--UK EN/UK EN.UK UK_UK EN_UK UK_EN GB GBGB GB-GB GB/GB GB.GB ENGB EN-GB EN/GB EN.GB GB_GB EN_GB GB_EN GBEN
IEen::EU::EN::IE IEIE IE-IE IE/IE IE.IE ENIE EN-IE EN/IE EN.IE IE_IE EN_IE IE_EN IEEN
DEde::EU::DE DEDE DE-DE DE/DE DE.DE DE_DE
FRfr::EU::FR FRFR FR-FR FR/FR FR.FR FR_FR
ITit::EU::IT ITIT IT-IT IT/IT IT.IT IT_IT
ESes::EU::ES ESES ES-ES ES/ES ES.ES ES_ES
NLnl::EU::NL NLNL NL-NL NL/NL NL.NL NL_NL
PTpt::EU::PT PTPT PT-PT PT/PT PT.PT PT_PT
BEfr::EU::BE::BEFR BE-FR BE/FR BE.FR FRBE FR-BE FR/BE FR.BE FR_BE BE_FR
BEnl::EU::BE::BENL BE-NL BE/NL BE.NL NLBE NL-BE NL/BE NL.BE BE_NL NL_BE
CHfr::EU::CH::CHFR CH-FR CH/FR CH.FR FRCH FR-CH FR/CH FR.CH CH_FR FR_CH
CHde::EU::CH::CHDE CH-DE CH/DE CH.DE DECH DE-CH DE/CH DE.CH CH_DE DE_CH
CHit::EU::CH::CHIT CH-IT CH/IT CH.IT ITCH IT-CH IT/CH IT.CH CH_IT IT_CH
ATde::EU::ATDE AT-DE AT/DE AT.DE DEAT DE-AT DE/AT DE.AT AT_DE DE_AT
ATit::EU::ATIT AT-IT AT/IT AT.IT ITAT IT-AT IT/IT IT.AT AT_IT IT_AT
SEsv::EU::SE SESE SE-SE SE/SE SE.SE SESV SE-SV SE/SV SE.SV SVSE SV-SE SV/SE SV.SE SE_SE SV_SE SE_SV
NOnb::EU::NO NONO NO-NO NO/NO NO.NO NONB NO-NB NO/NB NO.NB NBNO NB-NO NB/NO NB.NO NO_NO NB_NO NO_NB
DKda::EU::DK DKDK DK-DK DK/DK DK.DK DKDA DK-DA DK/DA DK.DA DADK DA-DK DA/DK DK.DK DK_DK DA_DK DK_DA
FIfi::EU::FI FIFI FI-FI FI/FI FI.FI FI-FI FI/FI FI.FI FI-FI FI/FI FI.FI FI_FI
EOF
    )

	local market
	local alias
	local group
	local line
	
    while read -r line; do
        market="${line%%::*}"
        [[ -z "$market" ]] && continue

        alias="${line##*::}"
		if [[ -n "$alias" ]]; then
			for a in ${(s: :)alias}; do
				MARKET_ALIASES[$a]="$market"
				MARKET_REGEX="${MARKET_REGEX:+$MARKET_REGEX|}$a"
			done
		fi

        group="${line%::*}"
        group="${group#*::}"
        group="${group//::/ }"
		if [[ -n "$group" ]]; then
			for g in ${(s: :)group}; do
				MARKET_GROUPS[$g]="${MARKET_GROUPS[$g]:+${MARKET_GROUPS[$g]} }$market"
				MARKET_REGEX="${MARKET_REGEX:+$MARKET_REGEX|}$g"
			done
		fi
    done <<< "$markets"

	typeset -U market_regex
	market_regex=(${(s:|:)MARKET_REGEX})
	MARKET_REGEX="${(j:|:)market_regex}"

	local serialized_aliases
	local serialized_groups
	local serialized_regex

	serialized_aliases=$(typeset -p MARKET_ALIASES)
	serialized_groups=$(typeset -p MARKET_GROUPS)
	serialized_regex=$(typeset -p MARKET_REGEX)

	defaults write "$DOMAIN.$VERSION" "MARKET_ALIASES" -string "$serialized_aliases"
	defaults write "$DOMAIN.$VERSION" "MARKET_GROUPS" -string "$serialized_groups"
	defaults write "$DOMAIN.$VERSION" "MARKET_REGEX" -string "$serialized_regex"
}

function create_partner_lookups() {
	if defaults read "$DOMAIN.$VERSION" &>/dev/null; then
		local serialized_partner_lookup
		local serialized_partner_folder_lookup
		local serialized_partner_regex
		local serialized_partner_folders

		serialized_partner_lookup=$(defaults read "$DOMAIN.$VERSION" "PARTNER_LOOKUP")
		serialized_partner_folder_lookup=$(defaults read "$DOMAIN.$VERSION" "PARTNER_FOLDER_LOOKUP")
		serialized_partner_regex=$(defaults read "$DOMAIN.$VERSION" "PARTNER_REGEX")
		serialized_partner_folders=$(defaults read "$DOMAIN.$VERSION" "PARTNER_FOLDERS")

		if [[ "$serialized_partner_lookup" == typeset* && "$serialized_partner_folder_lookup" == typeset* && "$serialized_partner_regex" == typeset* && "$serialized_partner_folders" == typeset* ]]; then
			eval "$serialized_partner_lookup"
			eval "$serialized_partner_folder_lookup"
			eval "$serialized_partner_regex"
			eval "$serialized_partner_folders"

			return
		fi
	fi

	local partners=$(
	cat <<EOF
Linear::01. Linear::
CTV::02. CTV::
Youtube::03. Youtube::YOUTUBE
companionBanner::03. Youtube::COMPANIONBANNER:COMPANION BANNER
DV360::04. DV360::
RTB::05. RTB House::RTB
Pmax::06. PMAX::PMAX
inFeed::07. Meta::INFEED:IN-FEED:IN FEED
Story::07. Meta::STORY
Meta::07. Meta::META
Reddit::08. Reddit::REDDIT
Pinterest::09. Pinterest::PINTEREST
TikTok::10. TikTok::TIKTOK
Discovery::11. Responsive Discovery::DISCOVERY
Responsive::11. Responsive Discovery::RESPONSIVE
HTML::12. HTML::HTML:HTML5
liveIntent::13. Live Intent::LIVEINTENT:LIVE INTENT:LIVE-INTENT:LIVE_INTENT:LIVEINTENT
Native::14. Native::NATIVE
Criteo::15. Criteo::CRITEO
customerReview::16. Customer Review::CUSTOMERREVIEW:CUSTOMER REVIEW:CUSTOMER_REVIEW:CUSTOMER-REVIEW
Snapchat::17. Snapchat::SNAPCHAT:SNAP CHAT:SNAP-CHAT:SNAP_CHAT
EOF
)
	local partner
	local folder
	local aliases
	local alias
	while read -r line; do
		partner="${line%%::*}"

		folder="${line#*::}"
		folder="${folder%::*}"
		PARTNER_FOLDERS+=("$folder")
		PARTNER_FOLDER_LOOKUP[$partner]="$folder"

		aliases="${line##*::}"
		[[ -z "$aliases" ]] && continue

		for alias in ${(s/:/)aliases}; do
			PARTNER_LOOKUP[$alias]=$partner
			PARTNER_REGEX="${PARTNER_REGEX:+$PARTNER_REGEX|}$alias"
		done
	done <<< "$partners"

	local serialized_partner_lookup
	local serialized_partner_folder_lookup
	local serialized_partner_regex
	local serialized_partner_folders

	serialized_partner_lookup=$(typeset -p PARTNER_LOOKUP)
	serialized_partner_folder_lookup=$(typeset -p PARTNER_FOLDER_LOOKUP)
	serialized_partner_regex=$(typeset -p PARTNER_REGEX)
	serialized_partner_folders=$(typeset -p PARTNER_FOLDERS)

	defaults write "$DOMAIN.$VERSION" "PARTNER_LOOKUP" -string "$serialized_partner_lookup"
	defaults write "$DOMAIN.$VERSION" "PARTNER_FOLDER_LOOKUP" -string "$serialized_partner_folder_lookup"
	defaults write "$DOMAIN.$VERSION" "PARTNER_REGEX" -string "$serialized_partner_regex"
	defaults write "$DOMAIN.$VERSION" "PARTNER_FOLDERS" -string "$serialized_partner_folders"
}

function create_partner_folders() {
	local target_path="$1"
	local partner

	[[ -z "$target_path" || -z "$PARTNER_FOLDERS" ]] && return 1

	for partner in "${PARTNER_FOLDERS[@]}"; do
		mkdir -p "$target_path/$partner"
	done
}

function get_target_directory() {
	local target
	target=$(pbpaste)

	if [[ -d "$target" ]]; then
		TARGET_DIR="$target"
		defaults write "$DOMAIN.$VERSION" TARGET_DIR -string "$TARGET_DIR"
		return
	fi

	if target=$(defaults read "$DOMAIN.$VERSION" TARGET_DIR); then
		TARGET_DIR="$target"
		return
	fi

	TARGET_DIR="$HOME/Documents/FINAL"
}

#region
function extract_markets(){
	local base_name=$1
	local markets
	local name
	local found

	[[ -z "$base_name" ]] && { echo ""; return 1; }

	# Convert name to uppercase for case-insensitive matching.
	name="${(U)base_name}"
	# Greedily match market codes/groups at the start of the string.
	while [[ "$name" =~ ^($MARKET_REGEX)([^0-9A-Z]) ]]; do
		matched_prefix="${match[1]}${match[2]}"
		found="${match[1]}"

		# Check if the found code is a group (e.g., "NA") and expand it.
		market="$MARKET_GROUPS[$found]"
		if [[ -n "$market" ]]; then
			markets="${markets:+$markets }$market"
			name="${name#"$matched_prefix"}"
			continue
		fi

		# Check if the found code is a specific alias (e.g., "USEN").
		market="$MARKET_ALIASES[$found]"
		markets="${markets:+$markets }$market"
		name="${name#"$matched_prefix"}"
	done

	# De-duplicate and format the final list of markets.
	markets=$(echo "$markets" | tr ' ' '\n' | sort -u | tr '\n' ' ')
	markets="${markets% }" # Trim trailing space
	
	[[ -n "$markets" ]] && echo "$markets" || return 1
}

function get_markets () {
	local file_path=$1
	local root_path=$2
	local current_name
	local markets

	[[ -z "$file_path" ]] && return 1
	[[ -n "$root_path" ]] && file_path="${file_path#$root_path}"

	# Loop upwards through the path until markets are found or the path is consumed.
	while [[ -z "$markets" && -n "$file_path" ]]; do
		current_name="${file_path##*/}"
		markets=$(extract_markets "$current_name")
		file_path="${file_path%/*}"
	done

	[[ -n "$markets" ]] && echo "$markets" || return 1
}

function get_size() {
	local file="$1"
	local dimensions
	local width
	local height
	local resolution

	# Use `sips` for image files.
	dimensions=$(sips -g pixelWidth -g pixelHeight "$file" 2>/dev/null)
	width=$(echo "$dimensions" | awk '/pixelWidth/ {print $2}')
	height=$(echo "$dimensions" | awk '/pixelHeight/ {print $2}')
	resolution="${width}x${height}"

	# If `sips` fails, try to find dimensions like "1920x1080" in the filename.
	if [[ $resolution == '<nil>x<nil>' || -z "$resolution" ]]; then
		resolution=$(grep -oE '[0-9]+x[0-9]+' <<< "${file##*/}" )
	fi

	[[ -n "$resolution" ]] && echo "$resolution" || return 1
}

function get_format() {
	local file="$1"
	local file_type

	file_type=$(file --brief --mime-type "$file")

	case "${file_type}" in
		image/*) echo "Static" ;;
		video/*) echo "Video" ;;
		application/zip)
			# For zip files, check if an HTML file exists inside.
			if unzip -l "$file" | grep -iq '\.html$' >/dev/null 2>&1; then
				echo "HTML"
			else
				return 1
			fi
			;;
		*) return 1 ;;
	esac
}

function get_partner() {
	local file="$1"
	local partner

	if [[ "${(U)file}" =~ .*($PARTNER_REGEX) ]]; then
		partner="${match[1]}"
		partner="$PARTNER_LOOKUP[$partner]"

		if [[ "${(U)file}" == *PMAX*HTML* || "${(U)file}" == *HTML*PMAX* ]]; then
			partner="$PARTNER_LOOKUP[HTML]"
		fi

		echo "$partner"
		return 0
	else
		return 1
	fi
}


function parse_file () {
	local file="$1"
	if [[ -z "$file" || ! -f "$file" ]]; then
		echo "ERR::${file}::Invalid or missing file"
		return 1
	fi

	local errors
	local partner_folder
	local newPath

	local name
	local extension
	local index

	local markets
	local size
	local format
	local partner

	errors=()
	partner_folder=""
	
	name="${file##*/}"
	extension="${name##*.}"
	# Try to find a 2-digit index at the end of the filename, e.g., "_01.jpg".
	index="" && [[ "${file##*/}" =~ _([0-9]{2})\.[^.]+$ ]] && index="${match[1]}"

	# Sequentially call the extraction functions. If any fail, append an error code.
	markets=$(get_markets "$file" "$ROOT_DIR") || errors+=("Market")
	size=$(get_size "$file") || errors+=("Size")
	format=$(get_format "$file") || errors+=("Format")
	partner=$(get_partner "$file") || errors+=("Partner")

	# If any errors occurred, report them and exit.
	if [[ -n "${errors[*]}" ]]; then
		echo "ERR::${file}::${errors[*]}"
		return 1
	fi

	# For each market identified, generate a new proposed file path and name.
	for market in ${(s: :)markets}; do
		# Construct the standard new name.
		newName="${market}_${TICKET_ID}_${partner}_${format}_${size}${index:+_$index}.$extension"
		newName="${newName//HTML_HTML/HTML}" # Cleanup potential duplication.

		# Get the target folder name from the partner lookup.
		partner_folder="$PARTNER_FOLDER_LOOKUP[$partner]"
		
		# Apply custom logic for specific partners to determine the final path.
		case "$partner" in
			"Discovery"|"Responsive")
				# Differentiate between Discovery and Responsive based on size.
				if [[ "$size" == "960x1200" ]]; then
					newName="${market}_${TICKET_ID}_Discovery_${format}_${size}${index:+_$index}.$extension"
				else
					newName="${market}_${TICKET_ID}_Responsive_${format}_${size}${index:+_$index}.$extension"
				fi
				newPath="$TARGET_DIR/$market/$partner_folder/$size"
				;;
			"HTML")
				# Special handling for HTML assets based on format and keywords.
				if [[ "$format" == 'Static' ]]; then
					newPath="$TARGET_DIR/$market/$partner_folder/preview"
				elif [[ "${(U)file}" == *TRADE*DESK* ]]; then
					newPath="$TARGET_DIR/$market/$partner_folder/The Trade Desk"
				elif [[ "${(U)file}" == *CAMPAIGN*MANAGER* ]]; then
					newPath="$TARGET_DIR/$market/$partner_folder/CAMPAIGN MANAGER 360"
				else
					newPath="$TARGET_DIR/$market/$partner_folder"
				fi
				;;
			*)
				# Default path for all other partners.
				newPath="$TARGET_DIR/$market/$partner_folder"
				;;
		esac

		# if [[ -d "$TARGET_DIR/$market" ]]; then
		# 	create_partner_folders "$TARGET_DIR/$market"
		# fi

		mkdir -p "$newPath"
		cp "$file" "$newPath/$newName"
	done
}


#region
create_market_lookups  &>/dev/null
create_partner_lookups  &>/dev/null
get_target_directory &>/dev/null
MAX_PROCS=$(sysctl -n hw.perflevel0.physicalcpu)
rm -rf "$TARGET_DIR"/*

serialized_lookups=$(typeset -p VERSION DOMAIN MARKET_ALIASES MARKET_GROUPS MARKET_REGEX PARTNER_LOOKUP PARTNER_FOLDER_LOOKUP PARTNER_REGEX PARTNER_FOLDERS ROOT_DIR TARGET_DIR TICKET_ID MAX_PROCS)
serialized_functions=$(typeset -f create_market_lookups create_partner_lookups create_partner_folders extract_markets get_markets get_size get_format get_partner parse_file)
export serialized_functions serialized_lookups

results=$(find -E "$ROOT_DIR" -type f -regex '.*\.(jpg|png|jpeg|psd|gif|mp4|zip)$' -print0 | \
	xargs -0 -n 1 -P "$MAX_PROCS" zsh -c '
	file="$1"

	eval "$serialized_lookups"
	eval "$serialized_functions"

	parse_file "$file"
	' _)


for final_folder in $TARGET_DIR/*; do
	[[ ! -d "$final_folder" ]] && continue

	create_partner_folders "$final_folder" &
done
