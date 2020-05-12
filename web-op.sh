#!/bin/sh

SCALEFACT=100
OUTPUTFILE='${fileSTRIPPED}-web.jpg'
SATURATE=100
OUTPUT_MD=0

print_err(){
	>&2 echo "usage: $0 [-s] SCALE_FACTOR [-o] OUTPUT_DIRECTORY [-S] AMT [FILES...]

	-s Scale factor to compress images by
		ex. $0 -s 50 - will scale a 1000x1800 image to 500x900
		ex. $0 -s 25 - will scale a 1000x1800 image to 250x450

	-o Write files to an output directory.

	-S Scale image saturation. 100 = 100%, 50 = 50%, 150 = 150%, etc."
}

check_args(){
	[ $# -lt 1 ] && {
		>&2 echo "invalid Aguments - "
		print_err
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
			>&2 echo "Invalid scale factor \"$1\" - "
			print_err
			exit 1
		}
	};

	[ $1 = "-o" ] && {
		shift
		[ -d $1 ] 2>/dev/null &&{
			check_args $@
			OUTPUT_MD=1
			OUTPUTPATH=$1
			OUTPUTFILE='${OUTPUTPATH}${fileSTRIPPED}.jpg'
			shift
		} || {
			>&2 echo "Invalid Path \"$1\" - "
			print_err
			exit 1
		}
	};

	[ $1 = "-u" ] && {
		shift
		[ $1 -eq $1 ] 2>/dev/null &&{
			check_args $@
			SATURATE=$1
			shift
			continue
		} || {
			>&2 echo "Invalid saturation factor \"$1\" - "
			print_err
			exit 1
		}
	};

done

temp_file=$( mktemp )
mv "$temp_file" "${temp_file}.jpg"
temp_file="${temp_file}.jpg"


for file in "$@"; do

	[ -f $file ] && {
		fileSTRIPPED=$(echo -n "$file" | sed 's/\.[^.]*$//')
		[ "$OUTPUT_MD" -eq 1 ] &&{
			fileSTRIPPED=$(echo -n "$fileSTRIPPED" | grep -o '[^/]*$')
		}


		eval echo "converting $file to $OUTPUTFILE at $SCALEFACT% scale"
		convert $file -resize "$SCALEFACT%" "$temp_file"
		[ $SATURATE -ne 100 ] && {
			convert "$temp_file" -modulate 100,"$SATURATE",100 "$temp_file"
		}
		eval jpegtran -copy none -optimize -progressive -outfile "$OUTPUTFILE" "$temp_file"
	} || {
		echo "invalid image \"$file\". Skipping..."
	};
done

rm "$temp_file"
