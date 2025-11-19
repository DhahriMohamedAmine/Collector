#!/bin/zsh

root="/Users/mohamedaminedhahri/Desktop/work/GNA-2544"
target="/Users/mohamedaminedhahri/Desktop/work/GNA-2544/atoms"

rm -rf $target/*

find $root -type f -name "*Pmax*1200x1200*.jpg" -not -name "*BG*" | while read -r file; do
	name=${file##*/}
	local=${name%%_*}

	extension=${name##*_}
	extension=${extension%%.*} && oldExtn=$extension
	extension=${extension:1:1}
	extension=$(( extension + 2 ))
	extension="0$extension"

		case $local in
		(USen|CAen|CAfr|USes))
			region=NA
			;;
		(AUen|SGen|NZen))
			region=ANZ
			;;
		*)
			region=EU
			;;
	esac

	[[ $region == EU && $extension =~ (04|05) ]] && local=Global
	[[ $region == EU && $extension =~ (08) ]] && extension=01
	[[ $region == EU && $extension =~ (06) ]] && extension=10
	[[ $region == EU && $extension =~ (07) ]] && extension=11

	[[ $region == ANZ && $extension =~ (04) ]] && local=Global && extension=06
	[[ $region == ANZ && $extension =~ (05) ]] && local=Global
	[[ $region == ANZ && $extension =~ (07) ]] && local=Global && extension=07
	[[ $region == ANZ && $extension =~ (08) ]] && extension=01
	[[ $region == ANZ && $extension =~ (06) ]] && extension=10

	[[ $region == NA && $extension =~ (06) ]] && local=Global
	[[ $region == NA && $extension =~ (05) ]] && local=Global && extension=08
	[[ $region == NA && $extension =~ (08) ]] && local=Global && extension=09
	[[ $region == NA && $extension =~ (07) ]] && extension=01
	[[ $region == NA && $extension =~ (04) ]] && extension=12

	newName="${local}_Multi_Lifestyle_1200x1200_${extension}.jpg"
	echo $local
	$(mkdir -p "$target" && cp "$file" ""$target"/$newName") &
done

# find $target -type f  -name "*.jpg" | while read -r file; do
# 	name=${file##*/}
# 	local=${name%%_*}
# 	extension=${name##*_} && extension=${extension%%.*}

# 	case $local in
# 		(USen|CAen|CAfr|USes))
# 			region=NA
# 			;;
# 		(AUen|SGen|NZen))
# 			region=ANZ
# 			;;
# 		*)
# 			region=EU
# 			;;
# 	esac

# 	if [[ $extension == "07" && $region == "NA" ]] || [[ $extension == "08" && ! $region == "NA" ]]; then
# 		mv "$file" "${file:h}/${local}_Multi_Lifestyle_1200x1200_01.jpg"
# 	fi

# done
