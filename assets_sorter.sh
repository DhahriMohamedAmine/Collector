#!/opt/homebrew/bin/bash

# Global Variables
VERSION="1.0.0"
DOMAIN="com.vistaprint.asset_sorter"

# shellcheck disable=SC2120
function create_market_lookup() {
	if defaults read "$DOMAIN.markets.$VERSION" &>/dev/null; then
		return
	fi

	markets=$(
		cat <<"EOF"
GLOBAL==GLOBAL
USen=NA=US USUS US-US US/US US:US US.US 'US US' ENUS EN-US EN/US EN:US EN.US 'EN US' US_US EN_US US_EN USEN
CAen=NA=CA CACA CA-CA CA/CA CA:CA CA.CA 'CA CA' ENCA EN-CA EN/CA EN:CA EN.CA 'EN CA' CA_CA EN_CA CA_EN CAEN
AUen=ANZ=AU AUAU AU-AU AU/AU AU:AU AU.AU 'AU AU' ENAU EN-AU EN/AU EN:AU EN.AU 'EN AU' AU_AU EN_AU AU_EN AUEN
SGen=ANZ=SG SGSG SG-SG SG/SG SG:SG SG.SG 'SG SG' ENSG EN-SG EN/SG EN:SG EN.SG 'EN SG' SG_SG EN_SG SG_EN SGEN
NZen=ANZ=NZ NZNZ NZ-NZ NZ/NZ NZ:NZ NZ.NZ 'NZ NZ' ENNZ EN-NZ EN/NZ EN:NZ EN.NZ 'EN NZ' NZ_NZ EN_NZ NZ_EN NZEN
GBen=EU=UK UKUK UK-UK UK/UK UK:UK UK.UK 'UK UK' ENUK EN-UK EN/UK EN:UK EN.UK 'EN UK' 'UK EN' UK_UK EN_UK UK_EN GB GBGB GB-GB GB/GB GB:GB GB.GB 'GB GB' ENGB EN-GB EN/GB EN:GB EN.GB 'EN GB' 'GB EN' GB_GB EN_GB GB_EN GBEN
IEen=EU=IE IEIE IE-IE IE/IE IE:IE IE.IE 'IE IE' ENIE EN-IE EN/IE EN:IE EN.IE 'EN IE' IE_IE EN_IE IE_EN IEEN
DEde=EU=DE DEDE DE-DE DE/DE DE:DE DE.DE 'DE DE' DE_DE
FRfr=EU=FR FRFR FR-FR FR/FR FR:FR FR.FR 'FR FR' FR_FR
ITit=EU=IT ITIT IT-IT IT/IT IT:IT IT.IT 'IT IT' IT_IT
ESes=EU=ES ESES ES-ES ES/ES ES:ES ES.ES 'ES ES' ES_ES
NLnl=EU=NL NLNL NL-NL NL/NL NL:NL NL.NL 'NL NL' NL_NL
PTpt=EU=PT PTPT PT-PT PT/PT PT:PT PT.PT 'PT PT' PT_PT
CAfr=EU=CAFR CA-FR CA/FR CA:FR CA.FR 'CA FR' FRCA FR-CA FR/CA FR:CA FR.CA 'FR CA' CA_FR FR_CA
BEfr=EU=BEFR BE-FR BE/FR BE:FR BE.FR 'BE FR' FRBE FR-BE FR/BE FR:BE FR.BE 'FR BE' FR_BE BE_FR
BEnl=EU=BENL BE-NL BE/NL BE:NL BE.NL 'BE NL' NLBE NL-BE NL/BE NL:BE NL.BE 'NL BE' BE_NL NL_BE
CHfr=EU=CHFR CH-FR CH/FR CH:FR CH.FR 'CH FR' FRCH FR-CH FR/CH FR:CH FR.CH 'FR CH' CH_FR FR_CH
CHde=EU=CHDE CH-DE CH/DE CH:DE CH.DE 'CH DE' DECH DE-CH DE/CH DE:CH DE.CH 'DE CH' CH_DE DE_CH
CHit=EU=CHIT CH-IT CH/IT CH:IT CH.IT ITCH IT-CH IT/CH IT:CH IT.CH 'IT CH' CH_IT IT_CH
ATde=EU=ATDE AT-DE AT/DE AT:DE AT.DE 'AT DE' DEAT DE-AT DE/AT DE:AT DE.AT 'DE AT' AT_DE DE_AT
ATit=EU=ATIT AT-IT AT/IT AT:IT AT.IT ITAT IT-AT IT/AT IT:AT IT.AT 'IT IT' AT_IT IT_AT
USes=EU=USES US-ES US/ES US:ES US.ES 'US ES' ESUS ES-US ES/US ES:US ES.US 'ES US' US_ES ES_US
SEsv=EU=SE SESE SE-SE SE/SE SE:SE SE.SE 'SE SE' SESV SE-SV SE/SV SE:SV SE.SV 'SE SV' SVSE SV-SE SV/SE SV:SE SV.SE 'SV SE' SE_SE SV_SE SE_SV
NOnb=EU=NO NONO NO-NO NO/NO NO:NO NO.NO 'NO NO' NONB NO-NB NO/NB NO:NB NO.NB 'NO NB' NBNO NB-NO NB/NO NB:NO NB.NO 'NB NO' NO_NO NB_NO NO_NB
DKda=EU=DK DKDK DK-DK DK/DK DK:DK DK.DK 'DK DK' DKDA DK-DA DK/DA DK:DA DK.DA 'DA DK' DADK DA-DK DA/DK DA:DK DK.DK 'DA DK' DK_DK DA_DK DK_DA
FIfi=EU=FI FIFI FI-FI FI/FI FI:FI FI.FI 'FI FI' FIFI FI-FI FI/FI FI:FI FI.FI 'FI FI' FIFI FI-FI FI/FI FI:FI FI.FI 'FI FI' FI_FI
EOF
	)

	market_regex="ALL|NA|ANZ|EU"
	while IFS='=' read -r market _ aliases; do
		OLD_IFS="$IFS"
		IFS=' '
		eval "set -- $aliases"
		for alias in "$@"; do
			alias="${alias#\'}"
			alias="${alias#\"}"
			alias="${alias%\'}"
			alias="${alias%\"}"
			market_regex="${market_regex:+$market_regex|}$alias"
			defaults write "$DOMAIN.markets.$VERSION" "$alias" -string "$market"
		done
		IFS="$OLD_IFS"
	done <<<"$markets"

	defaults write "$DOMAIN.markets.$VERSION" NA -string "$(echo "$markets" | awk -F '=' '/NA/ {print $1}' | tr '\n' ' ')"
	defaults write "$DOMAIN.markets.$VERSION" EU -string "$(echo "$markets" | awk -F '=' '/EU/ {print $1}' | tr '\n' ' ')"
	defaults write "$DOMAIN.markets.$VERSION" ANZ -string "$(echo "$markets" | awk -F '=' '/ANZ/ {print $1}' | tr '\n' ' ')"
	defaults write "$DOMAIN.markets.$VERSION" ALL -string "$(echo "$markets" | awk -F '=' '!/GLOBAL/ {print $1}' | tr '\n' ' ')"

	defaults write "$DOMAIN.markets.$VERSION" "MARKET_REGEX" -string "$market_regex"
}

function extract_markets() {
	local string="$1"
	local markets
	local regex
	local market
	string=$(echo "$string" | tr '[:lower:]' '[:upper:]')

	regex=$(defaults read "com.vistaprint.asset_sorter.markets.1.0.0" "MARKET_REGEX" 2>/dev/null)
	regex="^($regex)([^a-z0-9A-Z]|$)"

	while [[ "$string" =~ $regex ]]; do
		market="${BASH_REMATCH[1]}"
		market=$(defaults read "com.vistaprint.asset_sorter.markets.1.0.0" "$market")
		markets="${markets:+$markets }$market"

		if [[ $market == ALL ]]; then
			break
		fi

		string=${string#*"${BASH_REMATCH[0]}"}
		string=${string#[^a-zA-Z0-9]}
	done

	markets=$(echo "$markets" | awk '!seen[$0]++' RS=' ' ORS=' ' | tr '\n' ' ' | sed 's/[[:space:]]*$//')
	echo "$markets"
}

function get_market() {
	local file="$1"
	local root_dir="$2"
	local markets

	markets=$(extract_markets "$(basename "$file")")

	if [[ -n "$markets" ]]; then
		echo "$markets"
		return 0
	fi

	if [[ -n "$root_dir" ]]; then
		local current_dir
		current_dir=$(dirname "$file")

		while [[ "$current_dir" != "$root_dir" && "$current_dir" != "/" ]]; do
			markets=$(extract_markets "$(basename "$current_dir")")
			if [[ -n "$markets" ]]; then
				echo "$markets"
				return 0
			fi

			current_dir=$(dirname "$current_dir")
		done
	fi

	echo ''
	return 1
}

function update_errors() {
	local domain="$1"
	local backlog="$2"
	local errors
	local errors_backlog

	errors=$(defaults read "$domain" 2>/dev/null)
	errors_backlog=$(defaults read "$backlog" 2>/dev/null)

	#clear error tags on old files/folders
	if [[ -n "$errors" ]]; then
		error_files=$(echo "$errors" |
			sed '1d;$d' |
			tr -s ' ' |
			sed 's/^[[:space:]]*//g' |
			awk '/=/ {gsub(/"/, "|")} 1' |
			awk '!/;/ && !/=/ { gsub(/[^,]+/, "\"&\"")} 1' |
			tr -d '\n' |
			sed 's/=/:/g' |
			sed 's/;/,/g' |
			sed 's/,/, /g' |
			sed 's/(/{/g' |
			sed 's/)/}/g')
		error_files="${error_files%, *}"
		error_files="{ $error_files }"
		echo "error_files: "
		echo "$error_files"

		osascript <<EOF
use framework "Foundation"
use scripting additions

-- Example record: paths as keys, tag lists as values
set errorTagList to $error_files

-- Convert to NSDictionary for iteration
set dict to current application's NSDictionary's dictionaryWithDictionary:errorTagList
set allKeys to dict's allKeys()

repeat with k in allKeys
	set pathString to k as text
	set tagList to (dict's objectForKey:k) as list
	log "Path: " & pathString & " - Removing tags: " & (tagList as text)
	my removeTags:tagList forPath:pathString
end repeat

on removeTags:tagList forPath:p
	set u to current application's |NSURL|'s fileURLWithPath:p
	set {theResult, theTags} to u's getResourceValue:(reference) forKey:(current application's NSURLTagNamesKey) |error|:(missing value)
	
	if theTags is not missing value then
		set tagArray to (current application's NSMutableArray's arrayWithArray:theTags)
		
		-- Remove each specified tag
		repeat with t in tagList
			(tagArray's removeObject:t)
		end repeat
		
		-- Apply updated list (can be empty)
		u's setResourceValue:tagArray forKey:(current application's NSURLTagNamesKey) |error|:(missing value)
	end if
end removeTags:forPath:
EOF

		defaults delete "$domain"
	fi

	# tag new files/fodlers with new errors
	if [[ -n "$errors_backlog" ]]; then
		errors_files_backlog=$(echo "$errors_backlog" |
			sed '1d;$d' |
			tr -s ' ' |
			sed 's/^[[:space:]]*//g' |
			awk '/=/ {gsub(/"/, "|")} 1' |
			awk '!/;/ && !/=/ { gsub(/[^,]+/, "\"&\"")} 1' |
			tr -d '\n' |
			sed 's/=/:/g' |
			sed 's/;/,/g' |
			sed 's/,/, /g' |
			sed 's/(/{/g' |
			sed 's/)/}/g')
		errors_files_backlog="${errors_files_backlog%, *}"
		errors_files_backlog="{ $errors_files_backlog }"

		osascript <<EOF
use framework "Foundation"
use scripting additions

-- convert bash variable to AppleScript record
set errorTagList to $errors_files_backlog

-- call main logic
my processTags:errorTagList

on processTags:errorTagList
	set dict to current application's NSDictionary's dictionaryWithDictionary:errorTagList
	set allKeys to dict's allKeys()
	
	repeat with k in allKeys
		set pathString to k as text
		set tagList to (dict's objectForKey:k) as list
		--log "Path: " & pathString & " Tags: " & (tagList as text)
		my addTags:tagList forPath:pathString
	end repeat
end processTags:

on addTags:tagList forPath:p
	set u to current application's |NSURL|'s fileURLWithPath:p
	set {theResult, theTags} to u's getResourceValue:(reference) forKey:(current application's NSURLTagNamesKey) |error|:(missing value)
	
	if theTags is not missing value then
		set tagList to (theTags as list) & tagList
		set tagList to (current application's NSOrderedSet's orderedSetWithArray:tagList)'s allObjects()
	end if
	
	u's setResourceValue:tagList forKey:(current application's NSURLTagNamesKey) |error|:(missing value)
end addTags:forPath:
EOF

		defaults read "$backlog" >/tmp/error_backlog.plist
		# cat /tmp/error_backlog.plist
		defaults import "$domain" /tmp/error_backlog.plist

		rm /tmp/error_backlog.plist
		defaults delete "$backlog"
	fi

}

function tag_file() {
	if [[ -z "$1" || -z "$2" ]]; then
		return 1
	fi

	local path="$1"
	local tag="$2"
	local root_dir="$3"
	local current_dir
	local existing_tags

	# Only add if not already tagged with same value
	existing_tags=$(defaults read "$DOMAIN.error_files.backlog.$VERSION" "$path" 2>/dev/null | grep -o "$tag" || true)
	if [[ -z "$existing_tags" ]]; then
		defaults write "$DOMAIN.error_files.backlog.$VERSION" "$path" -array-add "$tag"
	fi

	if [[ -n "$root_dir" ]]; then
		current_dir=$(dirname "$path")
		while [[ "$current_dir" != "$root_dir" && "$current_dir" != "/" ]]; do
			existing_tags=$(defaults read "$DOMAIN.error_files.backlog.$VERSION" "$current_dir" 2>/dev/null | grep -o "$tag" || true)
			if [[ -z "$existing_tags" ]]; then
				defaults write "$DOMAIN.error_files.backlog.$VERSION" "$current_dir" -array-add "$tag"
			fi
			current_dir=$(dirname "$current_dir")
		done

		existing_tags=$(defaults read "$DOMAIN.error_files.backlog.$VERSION" "$root_dir" 2>/dev/null | grep -o "$tag" || true)
		if [[ -z "$existing_tags" ]]; then
			defaults write "$DOMAIN.error_files.backlog.$VERSION" "$root_dir" -array-add "$tag"
		fi
	fi
}

root="/Users/mohamedaminedhahri/Desktop/Code/Collector/REVIEW"

# defaults delete "$DOMAIN.markets.$VERSION"
create_market_lookup

find "$root" -type f ! -name "*DS_Store*" | while read -r file; do
	markets=$(get_market "$file" "$root")
	echo "File: $(basename "$file") - Markets: $markets"
	if [[ -z "$markets" ]]; then
		tag_file "$file" "Red" "$root"
	fi
done

update_errors "$DOMAIN.error_files.$VERSION" "$DOMAIN.error_files.backlog.$VERSION"
