#!/bin/sh

#Script for creating web optimized versions of images by Brennan Wilkes

#Set up variables
SCALEFACT=100
OUTPUTFILE='${fileSTRIPPED}-web.jpg'
SATURATE=100
OUTPUT_MD=0

#Usage message
print_err(){
	>&2 echo "usage: $0 [-s] SCALE_FACTOR [-o] OUTPUT_DIRECTORY [-S] AMT [FILES...]

	-s Scale factor to compress images by
		ex. $0 -s 50 - will scale a 1000x1800 image to 500x900
		ex. $0 -s 25 - will scale a 1000x1800 image to 250x450

	-o Write files to an output directory.

	-S Scale image saturation. 100 = 100%, 50 = 50%, 150 = 150%, etc."
}

#Function to check valid arguments
check_args(){
	[ $# -lt 1 ] && {
		>&2 echo "invalid Aguments - "
		print_err
		exit 1
	};
}

#Agument parsing loop
for arg in $(seq 4); do

	#check arguments
	check_args $@

	#Scale argument
	[ $1 = "-s" ] && {
		shift

		#Check for follow up arguments
		[ $1 -eq $1 ] 2>/dev/null &&{
			check_args $@

			#set scale factor
			SCALEFACT=$1
			shift
			continue
		} || {
			>&2 echo "Invalid scale factor \"$1\" - "
			print_err
			exit 1
		}
	};

	#Output directory argument
	[ $1 = "-o" ] && {
		shift
		[ -d $1 ] 2>/dev/null &&{
			check_args $@

			#set output variables
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

	#Saturation argument
	[ $1 = "-S" ] && {
		shift
		[ $1 -eq $1 ] 2>/dev/null &&{
			check_args $@

			#Saturation factor
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

#Create temp file
temp_file=$( mktemp )

#Rename it to .jpg extension
mv "$temp_file" "${temp_file}.jpg"
temp_file="${temp_file}.jpg"

#Main loop
for file in "$@"; do

	#Ensure that file exists
	[ -f $file ] && {

		#Strip away file extension
		fileSTRIPPED=$(echo -n "$file" | sed 's/\.[^.]*$//')

		#if custom output directory, strip original path
		[ "$OUTPUT_MD" -eq 1 ] &&{
			fileSTRIPPED=$(echo -n "$fileSTRIPPED" | grep -o '[^/]*$')
		}

		#Info
		eval echo "converting $file to $OUTPUTFILE at $SCALEFACT% scale and $SATURATE% saturation"

		#Scale image using ImageMagick
		convert $file -resize "$SCALEFACT%" "$temp_file"

		#Saturate image using ImageMagick
		[ $SATURATE -ne 100 ] && {
			convert "$temp_file" -modulate 100,"$SATURATE",100 "$temp_file"
		}

		#Convert to progressive jpg using jpegtran
		eval jpegtran -copy none -optimize -progressive -outfile "$OUTPUTFILE" "$temp_file"

	#Debug info
	} || {
		echo "invalid image \"$file\". Skipping..."
	};
done

#Delete temp file
rm "$temp_file"
