#!/bin/sh

#Script for creating web optimized versions of images by Brennan Wilkes

#Dependency check
convert --version 2>/dev/null >/dev/null
[ $? -eq 127 ] && {
	echo "Please install dependency ImageMagick.

	wget https://imagemagick.org/download/ImageMagick.tar.gz
	tar xvzf ImageMagick.tar.gz
	cd ImageMagick-*
	./configure
	sudo make install
	"
	exit 2
};

jpegtran -verbose . 2>/dev/null >/dev/null
[ $? -eq 127 ] && {
	echo "Please install dependency jpegtran.

	wget http://www.ijg.org/files/jpegsrc.v6b.tar.gz
	tar xvzf jpegsrc.v6b.tar.gz
	cd jpeg-*
	./configure
	sudo make install
	"
	exit 2
};



#Set up variables
scale_fact=100
output_file='${fileSTRIPPED}-web.jpg'
saturate=100
output_md=0
quiet_md=0

script_name=$( echo -n "$0" | grep -o '[^/]*$' )

#Usage message
print_err(){
	>&2 echo "usage: "$script_name" [FLAGS] [FILES...]

	-s SCALE_FACTOR - Scale factor to compress images by
		ex. "$script_name" -s 50 - will scale a 1000x1800 image to 500x900
		ex. "$script_name" -s 25 - will scale a 1000x1800 image to 250x450

	-o PATH - write files to an output directory.

	-S SATURATION_FACTOR - Scale image saturation. 100 = 100%, 50 = 50%, 150 = 150%, etc.

	-q - Quiet mode"
}

#Function to check valid arguments
check_args(){
	[ "$#" -lt 1 ] && {
		>&2 echo "invalid Aguments"
		print_err
		exit 1
	};
}

#Agument parsing loop
for arg in $(seq 5); do

	#check arguments
	check_args "$@"

	#Scale argument
	[ "$1" = "-s" ] && {
		shift

		#Check for follow up arguments
		[ "$1" -eq "$1" ] 2>/dev/null &&{
			check_args "$@"

			#set scale factor
			scale_fact="$1"
			shift
			continue
		} || {
			>&2 echo "Invalid scale factor \""$1"\""
			print_err
			exit 1
		}
	};

	#Output directory argument
	[ "$1" = "-o" ] && {
		shift
		[ -d "$1" ] 2>/dev/null &&{
			check_args "$@"

			#set output variables
			output_md=1
			OUTPUTPATH="$1"
			output_file='${OUTPUTPATH}${fileSTRIPPED}.jpg'
			shift
		} || {
			>&2 echo "Invalid Path \""$1"\""
			print_err
			exit 1
		}
	};

	#Saturation argument
	[ "$1" = "-S" ] && {
		shift
		[ "$1" -eq "$1" ] 2>/dev/null &&{
			check_args "$@"

			#Saturation factor
			saturate="$1"
			shift
			continue
		} || {
			>&2 echo "Invalid saturation factor \""$1"\""
			print_err
			exit 1
		}
	};

	#Quiet mode
	[ "$1" = "-q" ] && {
		shift
		quiet_md=1
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
	[ -f "$file" ] && {

		#Strip away file extension
		fileSTRIPPED=$(echo -n "$file" | sed 's/\.[^.]*$//')

		#if custom output directory, strip original path
		[ "$output_md" -eq 1 ] && {
			fileSTRIPPED=$(echo -n "$fileSTRIPPED" | grep -o '[^/]*$')
		}

		#Info
		[ "$quiet_md" -eq 0 ] && {
			eval echo "converting $file to $output_file at $scale_fact% scale and $saturate% saturation"
		}

		#Scale image using ImageMagick
		convert "$file" -resize "$scale_fact%" "$temp_file"

		#saturate image using ImageMagick
		[ "$saturate" -ne 100 ] && {
			convert "$temp_file" -modulate 100,"$saturate",100 "$temp_file"
		}

		#Convert to progressive jpg using jpegtran
		eval jpegtran -copy none -optimize -progressive -outfile "$output_file" "$temp_file"

	#Debug info
	} || {
		[ $quiet_md -eq 0 ] && {
			echo "invalid image \""$file"\". Skipping..."
		}
	};
done

#Delete temp file
rm "$temp_file"
