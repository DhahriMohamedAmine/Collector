#!/opt/homebrew/bin/bash

# --- MARKET ALIAS LOOKUP ---
get_market_alias() {
	declare -A markets
	declare -A market_lookup

	# Market aliases
	markets["USen"]="US USUS US-US US/US US:US US.US 'US US' ENUS EN-US EN/US EN:US EN.US 'EN US' US_US EN_US US_EN USEN"
	markets["GBen"]="UK UKUK UK-UK UK/UK UK:UK UK.UK 'UK UK' ENUK EN-UK EN/UK EN:UK EN.UK 'EN UK' UK_UK EN_UK UK_EN GB GBGB GB-GB GB/GB GB:GB GB.GB 'GB GB' ENGB EN-GB EN/GB EN:GB EN.GB 'EN GB' GB_GB EN_GB GB_EN GBEN"
	markets["CAen"]="CA CACA CA-CA CA/CA CA:CA CA.CA 'CA CA' ENCA EN-CA EN/CA EN:CA EN.CA 'EN CA' CA_CA EN_CA CA_EN CAEN"
	markets["AUen"]="AU AUAU AU-AU AU/AU AU:AU AU.AU 'AU AU' ENAU EN-AU EN/AU EN:AU EN.AU 'EN AU' AU_AU EN_AU AU_EN AUEN"
	markets["IEen"]="IE IEIE IE-IE IE/IE IE:IE IE.IE 'IE IE' ENIE EN-IE EN/IE EN:IE EN.IE 'EN IE' IE_IE EN_IE IE_EN IEEN"
	markets["SGen"]="SG SGSG SG-SG SG/SG SG:SG SG.SG 'SG SG' ENSG EN-SG EN/SG EN:SG EN.SG 'EN SG' SG_SG EN_SG SG_EN SGEN"
	markets["NZen"]="NZ NZNZ NZ-NZ NZ/NZ NZ:NZ NZ.NZ 'NZ NZ' ENNZ EN-NZ EN/NZ EN:NZ EN.NZ 'EN NZ' NZ_NZ EN_NZ NZ_EN NZEN"
	markets["DEde"]="DE DEDE DE-DE DE/DE DE:DE DE.DE 'DE DE' DE_DE"
	markets["FRfr"]="FR FRFR FR-FR FR/FR FR:FR FR.FR 'FR FR' FR_FR"
	markets["ITit"]="IT ITIT IT-IT IT/IT IT:IT IT.IT 'IT IT' IT_IT"
	markets["ESes"]="ES ESES ES-ES ES/ES ES:ES ES.ES 'ES ES' ES_ES"
	markets["NLnl"]="NL NLNL NL-NL NL/NL NL:NL NL.NL 'NL NL' NL_NL"
	markets["PTpt"]="PT PTPT PT-PT PT/PT PT:PT PT.PT 'PT PT' PT_PT"
	markets["CAfr"]="CAFR CA-FR CA/FR CA:FR CA.FR 'CA FR' FRCA FR-CA FR/CA FR:CA FR.CA 'FR CA' CA_FR FR_CA"
	markets["BEfr"]="BEFR BE-FR BE/FR BE:FR BE.FR 'BE FR' FRBE FR-BE FR/BE FR:BE FR.BE 'FR BE' FR_BE BE_FR"
	markets["BEnl"]="BENL BE-NL BE/NL BE:NL BE.NL 'BE NL' NLBE NL-BE NL/BE NL:BE NL.BE 'NL BE' BE_NL NL_BE"
	markets["CHfr"]="CHFR CH-FR CH/FR CH:FR CH.FR 'CH FR' FRCH FR-CH FR/CH FR:CH FR.CH 'FR CH' CH_FR FR_CH"
	markets["CHde"]="CHDE CH-DE CH/DE CH:DE CH.DE 'CH DE' DECH DE-CH DE/CH DE:CH DE.CH 'DE CH' CH_DE DE_CH"
	markets["CHit"]="CHIT CH-IT CH/IT CH:IT CH.IT ITCH IT-CH IT/CH IT:CH IT.CH 'IT CH' CH_IT IT_CH"
	markets["ATde"]="ATDE AT-DE AT/DE AT:DE AT.DE 'AT DE' DEAT DE-AT DE/AT DE:AT DE.AT 'DE AT' AT_DE DE_AT"
	markets["ATit"]="ATIT AT-IT AT/IT AT:IT AT.IT ITAT IT-AT IT/AT IT:AT IT.AT 'IT IT' AT_IT IT_AT"
	markets["USes"]="USES US-ES US/ES US:ES US.ES 'US ES' ESUS ES-US ES/US ES:US ES.US 'ES US' US_ES ES_US"
	markets["SEsv"]="SE SESE SE-SE SE/SE SE:SE SE.SE 'SE SE' SESV SE-SV SE/SV SE:SV SE.SV 'SE SV' SVSE SV-SE SV/SE SV:SE SV.SE 'SV SE' SE_SE SV_SE SE_SV"
	markets["NOnb"]="NO NONO NO-NO NO/NO NO:NO NO.NO 'NO NO' NONB NO-NB NO/NB NO:NB NO.NB 'NO NB' NBNO NB-NO NB/NO NB:NO NB.NO 'NB NO' NO_NO NB_NO NO_NB"
	markets["DKda"]="DK DKDK DK-DK DK/DK DK:DK DK.DK 'DK DK' DKDA DK-DA DK/DA DK:DA DK.DA 'DA DK' DADK DA-DK DA/DK DA:DK DK.DK 'DA DK' DK_DK DA_DK DK_DA"
	markets["FIfi"]="FI FIFI FI-FI FI/FI FI:FI FI.FI 'FI FI' FIFI FI-FI FI/FI FI:FI FI.FI 'FI FI' FIFI FI-FI FI/FI FI:FI FI.FI 'FI FI' FI_FI"

	# --- BUILD LOOKUP TABLE ---
	for alias in "${!markets[@]}"; do
		read -r -a variants <<<"${markets[$alias]}"
		for variant in "${variants[@]}"; do
			market_lookup["${variant^^}"]="$alias"
		done
	done

	# --- LOOKUP ---
	local input_upper="${1^^}"
	if [[ -v market_lookup["$input_upper"] ]]; then
		echo "${market_lookup["$input_upper"]}"
		return 0
	else
		echo "Unknown"
		return 1
	fi
}

function create_ad_campaign_folders() {

	if [ -z "$1" ]; then
		echo "Error: Please provide a directory path as the first argument."
		echo "Usage: create_ad_campaign_folders /path/to/parent_directory"
		return 1
	fi

	declare -a folders=(
		"01. Linear"
		"02. CTV"
		"03. Youtube"
		"04. DV360"
		"05. RTB House"
		"06. PMAX"
		"07. Meta"
		"08. Reddit"
		"09. Pinterest"
		"10. TikTok"
		"11. Responsive Discovery"
		"12. HTML"
		"13. Live Intent"
		"14. Native"
		"15. Criteo"
		"16. Customer Review"
		"17. Snapchat"
	)
	parent_dir="$1"

	for folder_name in "${folders[@]}"; do
		mkdir -p "$parent_dir/$folder_name"
	done
}

set_label_index() {
	local file="$1"
	local label_index="$2"
	osascript <<EOF >/dev/null 2>&1 &
tell application "Finder"
    set theFinderItem to POSIX file "$file" as alias
    set label index of theFinderItem to $label_index
end tell
EOF
}

get_tags() {
	mdls -raw -name kMDItemUserTags "$1"
}

get_partner() {
	partners=(Pmax Criteo RTB Responsive Pinterest HTML liveIntent Story inFeed companionBanner Meta Discovery)
	for partner in "${partners[@]}"; do
		if [[ "$1" == *"$partner"* ]]; then
			echo "$partner"
			return 0
		fi
	done
	echo "Unknown"
	return 1
}

get_format() {
	extension="$1"

	if [[ "$extension" == "jpg" || "$extension" == "png" || "$extension" == "psd" ]]; then
		echo "Static"
	elif [[ "$extension" == "mp4" ]]; then
		echo "Video"
	else
		echo ""
	fi

}

get_size() {
    file="$1"
	if [[ ! -f "$file" ]]; then
		echo ""
		return
	fi

	width=$(sips -g pixelWidth "$file" 2>/dev/null | awk '/pixelWidth/ {print $2}')
    height=$(sips -g pixelHeight "$file" 2>/dev/null | awk '/pixelHeight/ {print $2}')

	if [[ "$width" =~ ^[0-9]+$ && "$height" =~ ^[0-9]+$ ]]; then
		echo "${width}x${height}"
		return
	fi

	name=$(basename "$file")
	size=$(echo "$name" | grep -oE '[0-9]+x[0-9]+' | head -n 1)

	if [[ "$size" =~ ^[0-9]+x[0-9]+$ ]]; then
		echo "$size"
		return
	fi

	echo ""
}

root="/Users/mohamedaminedhahri/Desktop/Code/Collector/REVIEW"
target="/Users/mohamedaminedhahri/Desktop/Code/Collector/approved"
ticket="GNA-2544"
campaign="Holiday_BAU_Multi"

# << 'COMMENT'
rm -rf "$target"
mkdir -p "$target"

# find "$root" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.mp4" -o -name "*.psd" -o -name "*.gif" -o -name "*.zip" \) | while read -r file; do
find "$root" -type f \( -name "*.zip" \) | while read -r file; do
	# Extract the filename without the extension
	name=$(basename "$file")
	# dir=$(dirname "$file")

	local=$(echo "$name" | grep -oE '^[A-Za-z]+' | tr '[:lower:]' '[:upper:]')
	alias=$(get_market_alias "$local")

	extension="${name##*.}"
	index=$(basename "$file" ".$extension")
	index=$(echo "$index" | grep -oE '_[0-9][0-9]+$' | grep -oE '[0-9][0-9]+$')

	format=$(get_format "$extension")
	partner=$(get_partner "$file")
	size=$(get_size "$file")

	# case "$alias" in
	# AUen|SGen|NZen|USen|CAen|CAfr|USes)
	#     # continue
	#     ;;
	# esac
	set_label_index "$file" 0

	# --- LABEL FILES BASED ON VALIDATION ---
	set_label_index "$file" 0
	if [[ "$alias" == "Unknown" || "$partner" == "Unknown" || $size == "" ]]; then
		error_file=$file
		while [[ "$error_file" != "$root" ]]; do
			set_label_index "$error_file" 2
			error_file=$(dirname "$error_file")
		done
	fi

	create_ad_campaign_folders "$target/$alias"

	case "$partner" in
	Pmax)
		newName="${alias}_${ticket}_${campaign}_${partner}${format:+_$format}_${size}${index:+_$index}.${extension}"
		echo "$newName"

		# Modified section: All Pmax assets now go into a single folder
		mkdir -p "$target/$alias/06. PMAX"
		cp "$file" "$target/$alias/06. PMAX/$newName"

		# Actions for Pmax
		;;
	Criteo)
		newName="${alias}_${ticket}_${campaign}_${partner}${format:+_$format}_${size}${index:+_$index}.${extension}"
		echo "$newName"

		mkdir -p "$target/$alias/15. Criteo/With Offer (Non-Dynamic)"
		cp "$file" "$target/$alias/15. Criteo/With Offer (Non-Dynamic)/$newName"

		# Actions for Criteo
		;;
	RTB)
		newName="${alias}_${ticket}_${campaign}_${partner}${format:+_$format}_${size}${index:+_$index}.${extension}"
		echo "$newName"

		if [[ $extension == "psd" ]]; then
			mkdir -p "$target/$alias/05. RTB House/PSD"
			cp "$file" "$target/$alias/05. RTB House/PSD/$newName"
		else
			mkdir -p "$target/$alias/05. RTB House/Dynamic"
			cp "$file" "$target/$alias/05. RTB House/Dynamic/$newName"
		fi

		# Actions for RTB
		;;
	Responsive | Discovery)
		newName="${alias}_${ticket}_${campaign}_${partner}${format:+_$format}_${size}${index:+_$index}.${extension}"
		echo "$newName"

		if [[ "$size" == "960x1200" ]]; then
			newName="${alias}_${ticket}_${campaign}_Discovery${format:+_$format}_${size}${index:+_$index}.${extension}"

			mkdir -p "$target/$alias/11. Responsive Discovery/$size"
			cp "$file" "$target/$alias/11. Responsive Discovery/$size/$newName"
		else
			mkdir -p "$target/$alias/11. Responsive Discovery/$size"
			cp "$file" "$target/$alias/11. Responsive Discovery/$size/$newName"
		fi
		# Actions for Responsive
		;;
	Pinterest)
		newName="${alias}_${ticket}_${campaign}_${partner}${format:+_$format}_${size}${index:+_$index}.${extension}"
		echo "$newName"

		mkdir -p "$target/$alias/09. Pinterest"
		cp "$file" "$target/$alias/09. Pinterest/$newName"
		# Actions for Pinterest
		;;
	HTML)
		newName="${alias}_${ticket}_${campaign}_${partner}${format:+_$format}_${size}${index:+_$index}.${extension}"
		echo "$newName"

		if [[ $extension == "zip" ]]; then

			if ! unzip -l "$file" | grep -iq '\.html$'; then
				echo "No HTML file inside"
				continue
			fi

			file_lower=${file,,}
			if [[ $file_lower == *trade* && $file_lower == *desk* ]]; then
				mkdir -p "$target/$alias/12. HTML/The Trade Desk"
				cp "$file" "$target/$alias/12. HTML/The Trade Desk/$newName"
			elif [[ ($file_lower == *campaign* || $file_lower == *manager*) && $file_lower == *360* ]]; then
				mkdir -p "$target/$alias/12. HTML/Campaign Manager 360"
				cp "$file" "$target/$alias/12. HTML/Campaign Manager 360/$newName"
			fi

		elif [[ $format == "Static" ]]; then
			mkdir -p "$target/$alias/12. HTML/preview"
			cp "$file" "$target/$alias/12. HTML/preview/$newName"
		fi
		# Actions for HTML
		;;
	liveIntent)
		newName="${alias}_${ticket}_${campaign}_${partner}${format:+_$format}_${size}${index:+_$index}.${extension}"
		echo "$newName"

		mkdir -p "$target/$alias/13. Live Intent"
		cp "$file" "$target/$alias/13. Live Intent/$newName"
		# Actions for liveIntent
		;;
	Story | inFeed)
		newName="${alias}_${ticket}_${campaign}_${partner}${format:+_$format}_${size}${index:+_$index}.${extension}"
		echo "$newName"

		mkdir -p "$target/$alias/07. Meta"
		cp "$file" "$target/$alias/07. Meta/$newName"
		# Actions for Story and inFeed
		;;
	companionBanner)
		newName="${alias}_${ticket}_${campaign}_${partner}${format:+_$format}_${size}${index:+_$index}.${extension}"
		echo "$newName"

		mkdir -p "$target/$alias/03. Youtube/companionBanner"
		cp "$file" "$target/$alias/03. Youtube/companionBanner/$newName"
		# Actions for companionBanner
		;;
	*)
		# Actions for unknown partner
		;;
	esac


done

# COMMENT

find $target -type d -mindepth 1 -maxdepth 1 | while read -r dir; do
	alias=$(basename "$dir")

	for index in {1..6}; do
		index=$(printf "%02d" "$index")

		for size in 1200x1200 1200x628 960x1200; do
			pmax=$(find "$dir" -type f -name "*Pmax*Static*$size*$index*")
			Responsive=$(find "$dir" -type f \( -name "*Responsive*Static*$size*$index*" -o -name "*Discovery*Static*$size*$index*" \))

			if [[ -n $Responsive && -z $pmax ]]; then
				name=$(basename "$Responsive")
				newName=$(echo "$name" | sed -E 's/(Responsive|Discovery)/Pmax/')
				# echo "$name"
				echo "$newName"
				mkdir -p "$target/$alias/06. PMAX"
				cp "$Responsive" "$target/$alias/06. PMAX/$newName"
			fi
		done
	done
done

find "$root/Dynamic" -type f | while read -r file; do
	name=$(basename "$file")
	# dir=$(dirname "$file")

	local=$(echo "$name" | grep -oE '^[A-Za-z]+' | tr '[:lower:]' '[:upper:]')
	alias=$(get_market_alias "$local")

	extension="${name##*.}"
	index=$(basename "$file" ".$extension")
	index=$(echo "$index" | grep -oE '_[0-9][0-9]+$' | grep -oE '[0-9][0-9]+$')

	format=$(get_format "$extension")
	partner=$(get_partner "$file")
	size=$(echo "$name" | grep -oE '[0-9]+x[0-9]+')

	if [[ $format == "Video" ]]; then
		newName="${alias}_${ticket}_${campaign}_Criteo${format:+_$format}_${size}${index:+_$index}.${extension}"

		mkdir -p "$target/$alias/15. Criteo/No Offer (Dynamic)"
		cp "$file" "$target/$alias/15. Criteo/No Offer (Dynamic)/$newName"

		if [[ $size == "1080x1080" ]]; then
			newName="${alias}_${ticket}_${campaign}_Pinterest${format:+_$format}_${size}${index:+_$index}.${extension}"

			mkdir -p "$target/$alias/09. Pinterest/No Offer"
			cp "$file" "$target/$alias/09. Pinterest/No Offer/$newName"
		fi
	elif [[ $format == "Static" && $index == "01" ]]; then
		newName="${alias}_${ticket}_${campaign}_Criteo${format:+_$format}_${size}.${extension}"

		mkdir -p "$target/$alias/15. Criteo/No Offer (Dynamic)"
		cp "$file" "$target/$alias/15. Criteo/No Offer (Dynamic)/$newName"

		if [[ $size == "1080x1080" ]]; then
			newName="${alias}_${ticket}_${campaign}_Pinterest${format:+_$format}_${size}.${extension}"

			mkdir -p "$target/$alias/09. Pinterest/No Offer"
			cp "$file" "$target/$alias/09. Pinterest/No Offer/$newName"
		fi
	fi
done
