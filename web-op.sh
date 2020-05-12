#!/bin/sh

errMessage="Use format:\nweb-op [-s] SCALE_FACTOR [-o] OUTPUT_DIRECTORY [FILES...]"
SCALEFACT=100
OUTPUTFILE='${fileSTRIPPED}-op.jpg'
SATURATE=0

check_args(){
	[ $# -lt 1 ] && {
		echo -n "invalid Aguments - "
		echo $errMessage
		exit 1
	};
}

for arg in $(seq 4); do

	check_args $@

	[ $1 = "-s" ] && {
		shift
		[ $1 -eq $1 ] 2>/dev/null &&{
			check_args $@
			SCALEFACT=$1
			shift
			continue
		} || {
			echo -n "Invalid scale factor \"$1\" - "
			echo $errMessage
			exit 1
		}
	};

	[ $1 = "-o" ] && {
		shift
		[ -d $1 ] 2>/dev/null &&{
			check_args $@
			OUTPUTPATH=$1
			OUTPUTFILE='${OUTPUTPATH}${fileSTRIPPED}.jpg'
			shift
		} || {
			echo -n "Invalid Path \"$1\" - "
			echo $errMessage
			exit 1
		}
	};

	[ $1 = "-u" ] && {
		shift
		SATURATE=1
	}

done

temp_file=$( mktemp )
mv "$temp_file" "${temp_file}.jpg"
temp_file="${temp_file}.jpg"


for file in "$@"; do

	[ -f $file ] && {
		fileSTRIPPED=$(echo -n "$file" | cut -d'.' -f1)
		eval echo "converting $file to $OUTPUTFILE at $SCALEFACT% scale"
		convert $file -resize "$SCALEFACT%" "$temp_file"
		[ $SATURATE -eq 1 ] && {
			convert "$temp_file" -modulate 100,125,100 "$temp_file"
		}
		eval jpegtran -copy none -optimize -progressive -outfile "$OUTPUTFILE" "$temp_file"
	} || {
		echo "invalid image \"$file\". Skipping..."
	};
done

rm "$temp_file"
