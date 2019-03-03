#!/bin/bash

# defaults
WIDTH="100"
IMAGE="input.png"
INVERT=0
CONTRAST=0
BROWSER="ie" # only used for HTML
TYPE="html"
EXTRA_PROCESS=''
EXTRA_ARGS=(
  -F 'characters=0'
  -F 'grayscale=2'
)

DISCLAIMER='THIS PROGRAM USES THE ONLINE CONVERTOR AT https://www.text-image.com/convert/pic2.
ALL CREDIT GOES TO THE CREATOR OF THAT SITE.
Network connection is required.

Note that transparent pixels are treates as black. Ensure your image has
a background color. You can use Imagemagick to add a background:
  convert -flatten -background white input.png output.png
'

die() {
  local msg="$1"
  [[ -n "${msg}" ]] && echo "${msg}" >&2
  exit 1
}

usage () {
  cat <<EOF
${DISCLAIMER}

Usage:
  ${BASH_SOURCE[0]} [<options>]"

Options:
  -w     Width of the text image (no. of characters per line). Default is 100.
  -i     Input image to convert. Default is input.png.
  -o     Output text file to write result to. Default is
         'out/{input image name}_outline_W{width}_B{browser}_I{0|1}_C{0|1}.{txt|html}'
  -B     Browser type. Only used for HTML conversion. As a rule of thumb 'ie'
         gives a square to tall aspect ratio, firefox gives a more squashed
         text image. Default is 'ie'.
  -a     Produce an ASCII output instead of HTML. Default is HTML.
  -I     Invert input image colors.
  -C     Extra contrast.
EOF
  exit 0;
}

while [[ $# -gt 0 ]] ; do
  case $1 in
    -w)
      WIDTH="$2"
      shift
      ;;
    -w*)
      WIDTH="${1#-w}"
      ;;
    -i)
      IMAGE="$2"
      shift
      ;;
    -i*)
      IMAGE="${1#-i}"
      ;;
    -o)
      OUTFILE="$2"
      shift
      ;;
    -o*)
      OUTFILE="${1#-o}"
      ;;
    -B)
      BROWSER="$2"
      shift
      ;;
    -B*)
      BROWSER="${1#-B}"
      ;;
    -I)
      INVERT=1
      ;;
    -C)
      CONTRAST=1
      ;;
    -a)
      TYPE="ascii"
      EXTRA_PROCESS='s/<[^>]+>//g; s/[^ ]/0/g; /^ *$/b;'
      EXTRA_ARGS=()
      ;;
    *)
      usage
      ;;
  esac
  shift
done
[[ "${WIDTH}" =~ ^[0-9]+$ && "${BROWSER}" =~ ^[a-zA-Z]+$ ]] || usage
[[ -z ${OUTFILE} ]] &&
  OUTFILE="out/$(basename ${IMAGE%.*})_outline_W${WIDTH}_B${BROWSER}_I${INVERT}_C${CONTRAST}.${TYPE/ascii/txt}"
[[ -f "${IMAGE}" ]] || die "No such file or directory ${IMAGE}. See help (-h)"

echo "${DISCLAIMER}" >&2

if [[ "${OSTYPE}" == "linux-gnu" ]]; then
  SED='sed -r'
else
  SED='gsed -E'
fi

[[ -d $(dirname "${OUTFILE}") ]] || mkdir -p $(dirname "${OUTFILE}") || die "Can't create output directories"
for bin in "${SED%% *}" curl ; do
  which "${bin}" > /dev/null || die "Can't find ${bin} binary in your PATH"
done

echo "Converting to ${TYPE}" >&2
curl -s -F 'image=@'"${IMAGE}"';type=image/png' \
  -F "width=${WIDTH}" \
  -F 'bgcolor=WHITE' \
  -F 'textcolor=BLACK' \
  -F "contrast=${CONTRAST}" \
  -F "invert=${INVERT}" \
  -F "browser=${BROWSER}" \
  "${EXTRA_ARGS[@]}" \
  https://www.text-image.com/convert/pic2${TYPE}.cgi \
    | ${SED} -n '/<!-- IMAGE BEGINS HERE -->/,/<!-- IMAGE ENDS HERE -->/{'"${EXTRA_PROCESS}"'p}' \
    > "${OUTFILE}"

n=$(tr -d '\n ' < "${OUTFILE}" | wc -m | tr -d '\n ')
echo "Saved to ${OUTFILE}."
if [[ "${TYPE}" == "ascii" ]] ; then
  echo "Saved to ${OUTFILE}. There are ${n} characters in the outline:"
  cat "${OUTFILE}"
fi
