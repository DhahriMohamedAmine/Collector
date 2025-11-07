#!/bin/zsh

#region Global Variables
VERSION="1.0.0"
DOMAIN="com.vistaprint.asset_sorter"
MARKETS=""
typeset -A MARKET_GROUPS

function create_market_lookups() {
	local markets
	markets="GLOBAL:GLOBAL
USEN:ALL NA EN
CAEN:ALL NA EN
USES:ALL NA
CAFR:ALL NA
AUEN:ALL ANZ EN
SGEN:ALL ANZ EN
NZEN:ALL ANZ EN
GBEN:ALL EU EN
IEEN:ALL EU EN
DEDE:ALL EU
FRFR:ALL EU
ITIT:ALL EU
ESES:ALL EU
NLNL:ALL EU
PTPT:ALL EU
BEFR:ALL EU BE
BENL:ALL EU BE
CHFR:ALL EU CH
CHDE:ALL EU CH
CHIT:ALL EU CH
ATDE:ALL EU AT
ATIT:ALL EU AT
SESV:ALL EU
NONB:ALL EU
DKDA:ALL EU
FIFI:ALL EU"

	while read -r line; do
		market="${line%:*}"
		market="${market:0:2}${(L)market:2:2}"
		market="${market//GLob/GLOBAL}"

		groups="${line#*:}"
		groups=("${(s/ /)groups}")
		for group in "${groups[@]}"; do
			MARKET_GROUPS[$group]="${MARKET_GROUPS[$group]:-":"}${market}:"
		done
	done <<< $markets

	MARKETS=":$(awk -F ':' '{print $1}' <<< "$markets" | tr '\n' ':')"
}

#region
function get_markets() {
	local name=$1
	local market
	while [[ "$name" =~ (^[A-Za-z]{2})([^0-9a-zA-Z]?)([A-Za-z]{2})([^0-9a-zA-Z]|$) || "$name" =~ (^[A-Za-z]{2,4}|^GLOBAL)([^0-9a-zA-Z]|$) ]]; do
		to_replace="${match[*]}"
		# to_replace="${to_replace// /}"
		name=$(echo "$name" | tr -d "$to_replace")

		found="${to_replace[*]}"
		found="${found//[^a-zA-Z]/}"
		found="${(U)found}"
		found="${found//UK/GB}"

		if [[ -n "${MARKET_GROUPS[$found]}" ]]; then
			local="${MARKET_GROUPS[$found]//:/ }"
			local="${local% }"
			local="${local# }"

			market="$market $local"
			continue
		fi

		if [[ "${#found}" == 2 ]]; then
			EN_markets="${MARKET_GROUPS[EN]}"
			if [[ "$EN_markets" == *"$found"EN* ]]; then
				found="${found}EN"
			else
				found="${found}${found}"
			fi
		fi

		if [[ "$MARKETS" =~ (:)($found)(:) || "$MARKETS" =~ (:)(${found:2:2}${found:0:2})(:) ]]; then
			local="${match[2]}"
			local="${local:0:2}${(L)local:2:2}"

			market="$market $local"
		fi

	done

	echo "$market"
}


#region

create_market_lookups

test_names_list=$(
	cat <<'EOF'
US_simple.jpg
DEde_asset_for.png
EN-GB-photo.gif
ITIT_logo.svg
ca_banner.PDF
NA_sales_report.doc
ALL_markets_logo.svg
US_and_CA_promo.jpg
EU/document.pdf
NA/Canada/untitled.jpg
UK/folder/GB_image.jpg
US/folder/image_for_GB.jpg
Final-CA-Release.zip
New-Version-UK-Final.psd
image_for_RU.png
vacation_photo.mov
final_image_v3.jpg
archive.zip
CA_FR_presentation.ppt
US_espan.jpg
GLOBAL_foundem.jpg
popop_GLOBAL.klo
BE_assets.zip
FR_DE_EU_ass.kop
EOF
)


while IFS= read -r name; do
	market=$(get_markets "$name") && echo "$name --------->> $market"
done <<<"$test_names_list"