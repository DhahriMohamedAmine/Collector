#!/bin/zsh
# set -x

#region
DOMAIN="com.vistaprint.onlinedisplay.assetorganizer"
VERSION="1.0.1"
MAX_PROCS=$(sysctl -n hw.perflevel0.physicalcpu 2>/dev/null || echo 8)

typeset -A MARKET_LOOKUP
typeset -A GROUP_LOOKUP

typeset -A IDENTIFERS
typeset -A IDENTIFERS_NAMES
typeset -A IDENTIFERS_FOLDERS

typeset -a EXPORT_FILTERS 
typeset -A EXPORT_NAME
typeset -A EXPORT_FOLDER

INPUT_DIRS=("/Users/mohamedaminedhahri/Desktop/Code/Collector/testFiles")
TICKET='TIX-XXXX'
DEST='/Users/mohamedaminedhahri/Desktop/Code/Collector/approved'

#region
function version_check () {
	local stored_version
    stored_version=$(defaults read "$DOMAIN" DB_VERSION)

    if [[ -z "$stored_version" || "$stored_version" < "$VERSION" ]]
	then
        defaults delete "$DOMAIN"
        defaults write "$DOMAIN" DB_VERSION "$VERSION"
    fi
}

function create_markets_lookup() {
	if ! defaults read "$DOMAIN" MARKETS
	then
		default_markets_DB='USen:US:EN:ALL NA EN
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
ATit:AT:IT:ALL EU AT'

		while IFS=':' read -r alias Countries lang groups
		do
			defaults write "$DOMAIN" MARKETS -dict-add "$alias" "{ Countries = \"${Countries// /, }\"; Languages = \"${lang// /, }\"; Groups = \"${groups// /, }\"; }"
		done <<< "$default_markets_DB"
	fi

	current_markets=$(defaults read "$DOMAIN" MARKETS | plutil -convert json -o - -)

	groups_regex=($(echo "$current_markets" | jq -r 'to_entries | .[] | .value.Groups | split(", ") | .[]'))
	groups_regex=(${(u)groups_regex})
	groups_regex="${(j:|:)groups_regex}"

	for market in $(echo "$current_markets" | jq -r 'keys | .[]')
	do
		Languages=$(jq -r ".$market.Languages" <<< "$current_markets") && Languages=(${(s:, :)Languages})
		Countries=$(jq -r ".$market.Countries" <<< "$current_markets") && Countries=(${(s:, :)Countries})
		Groups=$(jq -r ".$market.Groups" <<< "$current_markets") && Groups=(${(s:, :)Groups})

		market_aliases=(${Languages:^^Countries} ${Countries:^^Languages})
		market_aliases=$(perl -pe 's/ /++$c % 2 == 1 ? "" : $& /ge' <<< $market_aliases)
		market_aliases=${market_aliases//GLOBALGLOBAL/GLOBAL}
		market_aliases=(${(s: :)market_aliases})
		market_aliases=($market_aliases $Countries)

		for group in ${Groups[@]}
		do
			GROUP_LOOKUP[$group]="${GROUP_LOOKUP[$group]:+$GROUP_LOOKUP[$group] }$market"
		done

		for alias in ${market_aliases[@]}
		do
			MARKET_LOOKUP[$alias]="${MARKET_LOOKUP[$alias]:-$market}"
		done
	done
}

function create_identifiers_lookup() {
	if ! defaults read "$DOMAIN" 'identifiers' &>/dev/null
	then
		defaults write "$DOMAIN" 'identifiers' &>/dev/null
	fi

	local DB=$(defaults read "$DOMAIN" 'identifiers' 2>/dev/null | plutil -convert json -o - -)

	if ! jq -e '.partners' <<< "$DB" &>/dev/null
	then

		local default_partners_DB='Linear:01. Linear:linear
CTV:02. CTV:ctv
Youtube:03. Youtube:you tube
companionBanner:03. Youtube:companion banner
DV360:04. DV360:dv 360
RTB:05. RTB House:rtb
Pmax:06. PMAX:pmax
inFeed:07. Meta:in feed
Story:07. Meta:story
Meta:07. Meta:meta
Reddit:08. Reddit:reddit
Pinterest:09. Pinterest:pinterest
TikTok:10. TikTok:tik tok
Discovery:11. Responsive Discovery:discovery
Responsive:11. Responsive Discovery:responsive
HTML:12. HTML:html, html 5
liveIntent:13. Live Intent:liveintent, live intent
Native:14. Native:native
Criteo:15. Criteo:criteo
customerReview:16. Customer Review:customer review
Snapchat:17. Snapchat:snap chat'

		local partners_DB=$(echo {} | jq '{}')
		while IFS=':' read -r name folder alias
		do
			partners_DB=$(jq --arg name "$name" --arg folder "$folder" --arg alias "$alias" '. += { ($name): { name: $name, folder: $folder, alias: $alias }}' <<< "$partners_DB")
		done  <<< "$default_partners_DB"

		partners_DB=$(echo $partners_DB | plutil -convert xml1 -o - -)
		defaults write "$DOMAIN" identifiers -dict-add "partner" "$partners_DB"
	fi

	if ! jq -e '.htmlPublisher' <<< "$DB" &>/dev/null
	then

		local default_HTML_Publishers_DB='theTradeDesk:The Trade Desk:the trade desk, trade desk
campaignManager360:Campaign Manager 360:campaign manager 360, campaign manager, manager 360
pmaxBanner:PMAX Banners:pmax banner'

		local html_publishers_DB=$(echo {} | jq '{}')
		while IFS=':' read -r name folder alias
		do
			html_publishers_DB=$(jq --arg name "$name" --arg folder "$folder" --arg alias "$alias" '. += { ($name): { name: $name, folder: $folder, alias: $alias }}' <<< "$html_publishers_DB")
		done  <<< "$default_HTML_Publishers_DB"

		html_publishers_DB=$(echo $html_publishers_DB | plutil -convert xml1 -o - -)
		defaults write "$DOMAIN" identifiers -dict-add "htmlPublishers" "$html_publishers_DB"
	fi

	if ! jq -e '.offer' <<< "$DB" &>/dev/null
	then
		local default_offers_DB='NCO:NCO:NCO, newcustomerOffer, new customer Offer
Offer:Offer:Offer, Offer[0-9]+, Offer [0-9]+
noOffer:noOffer:noOffer, no Offer'

		local offers_DB=$(echo {} | jq '{}')
		while IFS=':' read -r name folder alias
		do
			offers_DB=$(jq --arg name "$name" --arg folder "$folder" --arg alias "$alias" '. += { ($name): { name: $name, folder: $folder, alias: $alias }}' <<< "$offers_DB")
		done  <<< "$default_offers_DB"

		offers_DB=$(echo $offers_DB | plutil -convert xml1 -o - -)
		defaults write "$DOMAIN" identifiers -dict-add "offer" "$offers_DB"
	fi

	DB=$(defaults read "$DOMAIN" 'identifiers' 2>/dev/null | plutil -convert json -o - -)
	eval $(jq -r 'to_entries[] | "IDENTIFERS[\(.key|@json)]=" + ([.value[].alias | gsub(", "; "|")] | join("|") | @sh)' <<< "$DB")
	eval $(jq -r 'to_entries[] | .value[] | .name as $n | (.alias | split(", "))[] | "IDENTIFERS_NAMES[\(.|@json)]=\($n|@sh)"' <<< "$DB")
	eval $(jq -r 'to_entries[] | .value[] | .folder as $f | (.alias | split(", "))[] | "IDENTIFERS_FOLDERS[\(.|@json)]=\($f|@sh)"' <<< "$DB")
}

function create_export_lookup() {
	if ! defaults read "$DOMAIN" 'export' &>/dev/null
	then
		# echo notFOund
		defaults write "$DOMAIN" 'export' &>/dev/null


		local default_export='DEFAULT:MARKET_TICKET_PARTNER_FORMAT_SIZE_INDEX:/MARKET/PARTNER
partner=Responsive:MARKET_TICKET_PARTNER_FORMAT_SIZE_INDEX:/MARKET/PARTNER/SIZE
partner=Discovery:MARKET_TICKET_PARTNER_FORMAT_SIZE_INDEX:/MARKET/PARTNER/SIZE
partner=Responsive, size=960x1200:MARKET_TICKET_Discovery_FORMAT_SIZE_INDEX:/MARKET/PARTNER/SIZE
partner=Discovery, size=960x1200:MARKET_TICKET_Discovery_FORMAT_SIZE_INDEX:/MARKET/PARTNER/SIZE
partner=companionBanner:MARKET_TICKET_PARTNER_FORMAT_SIZE_INDEX:/MARKET/PARTNER/youtube'

		while IFS=':' read -r filter name folder
		do
			defaults write "$DOMAIN" export -dict-add "$filter" "{ name = "$name"; folder = "$folder"; }"
		done <<< $default_export
	fi

	local DB=$(defaults read "$DOMAIN" 'export' 2>/dev/null | plutil -convert json -o - -)

	EXPORT_FILTERS=(${(f)"$(jq -r 'to_entries[] | .key' <<< $DB)"})
	EXPORT_FILTERS=("${(@)$(for s in "${EXPORT_FILTERS[@]}"; do
		words=(${(s:,:)s})
		count=${#words[@]}
		echo "$count $s"
	done | sort -nr | cut -d' ' -f2-)}")

	eval $(jq -r 'to_entries[] | .key as $k | "EXPORT_NAME[\($k|@sh)]=\(.value.name|@sh)"' <<< "$DB")
	eval $(jq -r 'to_entries[] | .key as $k | "EXPORT_FOLDER[\($k|@sh)]=\(.value.folder|@sh)"' <<< "$DB")
}

#region
function get_markets() {
	local name="$1"
	typeset -U markets=()

	name="${name//[^[:alnum:]]/ }"
	name=${(U)name}
	name=(${(s: :)name})

	for (( i=1; i<=${#name[@]}; i++ ))
	do
		local curr="${name[$i]}"
		[[ -z "$curr" ]] && break
		local next="${name[(( i+1 ))]}"

		[[ -n $GROUP_LOOKUP[$curr] ]] && markets+=(${(s: :)GROUP_LOOKUP[$curr]}) && continue
		[[ -n $MARKET_LOOKUP[$curr$next] && -n "$next" ]] && markets+=($MARKET_LOOKUP[$curr$next]) && (( i++ )) && continue
		[[ -n $MARKET_LOOKUP[$curr] ]] && markets+=(${MARKET_LOOKUP[$curr]}) && continue
		
		break
	done

	echo "${markets[@]}"
}

function get_format() {
	local file="$1"
	local mime_type

	mime_type=$(file --brief --mime-type "$file")

	case "${mime_type}" in
		image/*) echo "Static" ;;
		video/*) echo "Video" ;;
		application/zip)
			if unzip -l "$file" | grep -iq '\.html$' >/dev/null 2>&1; then
				echo "HTML"
			else
				echo ""
			fi
			;;
		*) echo "" ;;
	esac
}

function get_size() {
	local file="$1"
	local format="$2"
	local resolution

	if [[ "${file##*/}" =~ ([0-9]+x[0-9]+) ]]; then
		resolution="${match[1]}"
		echo "$resolution"
		return
	fi

	if [[ -z "$resolution" && "$format" == 'Static' ]]; then
		local dimensions=$(sips -g pixelWidth -g pixelHeight "$file" 2>/dev/null)
		local width=${${dimensions##*pixelWidth: }%%$'\n'*}
		local height=${${dimensions##*pixelHeight: }%%$'\n'*}
		resolution="${width}x${height}"
		[[ "$resolution" =~ ^([0-9]+x[0-9]+)$ ]] && echo "$resolution"
		return
	fi

	echo ""
}

function parse_file() {
	local file="$1"
	local errors=()

	typeset -A file_identifiers
	file_identifiers[NAME]="${file##*/}"
	file_identifiers[EXTENSION]="${file##*.}"

	file_identifiers[MARKETS]=""
	file_identifiers[FORMAT]=$(get_format "$file")
	file_identifiers[SIZE]=$(get_size "$file" "$file_identifiers[FORMAT]")

	setopt nocasematch
	local curr_file="$file"
	while [[ "$curr_file" != "$HOME" ]]
	do
		[[ -z $file_identifiers[MARKETS] ]] && file_identifiers[MARKETS]=$(get_markets "${curr_file##*/}")

		for k in ${(k)IDENTIFERS}; do
			for al in ${(s:|:)IDENTIFERS[$k]}; do
				if [[ "${curr_file##*/}" =~ .*(${al// /[^[:alnum:]]?}) ]]; then
					local key=${k//\"/}
					key=${(U)key}
					file_identifiers[$key]=$al
					break
				fi
			done
		done

		[[ ${#${(k)file_identifiers}} == ${#${(v)file_identifiers}} ]] && break
		curr_file=$(dirname "$curr_file")
	done
	unsetopt nocasematch

	[[ "${file##*/}" =~ '_([0-9]{2})\.' ]] && file_identifiers[INDEX]="${match[1]}" || file_identifiers[INDEX]=""

	[[ -z $file_identifiers[MARKETS] ]] && errors+=(MARKETS)
	[[ -z $file_identifiers[PARTNER] ]] && errors+=(PARTNER)
	[[ -z $file_identifiers[FORMAT] ]] && errors+=(FORMAT)
	[[ -z $file_identifiers[SIZE] ]] && errors+=(SIZE)
	[[ -n $errors ]] && echo "ERR::$file::${errors[*]}" && return 0

	function filter_check() {
		local filter="$1"
		local condition

		for condition in ${(s:, :)filter}; do
			local key=${condition%%=*}
			key=${(U)key}
			local value="" && [[ $condition == *=* ]] && value=${condition##*=}

			local identifier="$file_identifiers[$key]"
			[[ $key =~ (SIZE|NAME|MARKET|FORMAT|INDEX|EXTENSION) ]] || identifier="$IDENTIFERS_NAMES["$identifier"]"

			identifier="${(U)identifier}"
			value="${(U)value}"
			
			if ! [[ ( "$identifier" =~ "$value" && -n "$value" ) || ( -z "$value" && -n "$identifier" ) ]]; then
				return 1
			fi
		done

		return 0
	}

	selected_filter='DEFAULT'
	for filter in ${(f)${EXPORT_FILTERS[@]}}; do
		[[ $filter == 'DEFAULT' ]] && continue

		if filter_check "$filter"
		then
			selected_filter="$filter"
			break
		fi
	done

	selected_filter="'${selected_filter}'"
	local nameTemplate=${EXPORT_NAME[$selected_filter]}
	local folderTemplate=${EXPORT_FOLDER[$selected_filter]}

	for market in ${(s: :)file_identifiers[MARKETS]}
	do
		local newName=$nameTemplate
		newName=${newName//_/}
		newName=${newName//MARKET/${market}_}
		newName=${newName//TICKET/${TICKET}_}

		local newFolder=$folderTemplate
		newFolder=${newFolder//MARKET/$market}
		newFolder=${newFolder//TICKET/$TICKET}

		for k v in ${(kv)file_identifiers}
		do
			[[ $k == MARKET ]] && continue

			if [[ $k =~ (SIZE|NAME|MARKET|FORMAT|INDEX|EXTENSION) ]]
			then
				newName=${newName//$k/${v:+_$v}}
				newFolder=${newFolder//$k/$v}
			else
				local identifier_name=$IDENTIFERS_NAMES["$v"]
				local identifier_folder=$IDENTIFERS_FOLDERS["$v"]

				newName=${newName//$k/${identifier_name:+_${identifier_name}}}
				newFolder=${newFolder//$k/$identifier_folder}
			fi
		done

		newName=${newName//__/_}
		newName="${newName}.${file_identifiers[EXTENSION]}"
		newFolder="$DEST/$newFolder"

		mkdir -p "$newFolder"
		cp "$file" "$newFolder/$newName"

		echo "OK::${file##*/}::${newFolder}::${newName}"
	done
}
#region
version_check &>/dev/null
create_markets_lookup &>/dev/null
create_identifiers_lookup &>/dev/null
create_export_lookup &>/dev/null

#region
count=0
results=$(while read -r file
do
	parse_file "$file" &
	(( count++ ))

	if (( count % MAX_PROCS == 0 )); then
        wait
    fi
done < <(find "/Users/mohamedaminedhahri/Desktop/Code/Collector/REVIEW" -type f -not -path '*/.*'))

echo "$results" #| column -s '::' -t
echo
echo "$results" | grep "ERR" | column -s '::' -t

wait
echo "count: $count"