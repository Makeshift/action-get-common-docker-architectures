#!/bin/bash

: "${IMAGES:?IMAGES environment variable must be set}"
PRUNE_MISSING_IMAGES="${PRUNE_MISSING_IMAGES:-true}"
DEFAULT_ARCHITECTURES="${DEFAULT_ARCHITECTURES:-linux/amd64}"
DEBUG="${DEBUG:-false}"
INPUT_DELIMITER="${INPUT_DELIMITER:-,}"
OUTPUT_DELIMITER="${OUTPUT_DELIMITER:-,}"

# Handle newlines in output delimiter
OUTPUT_DELIMITER=$(echo "${OUTPUT_DELIMITER}" | sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g')

function debug() {
  if [[ "${DEBUG}" == "true" ]]; then
    echo "DEBUG: $*"
  fi
}

function echoInputs() {
  echo "IMAGES: ${IMAGES}"
  echo "PRUNE_MISSING_IMAGES: ${PRUNE_MISSING_IMAGES}"
  echo "DEFAULT_ARCHITECTURES: ${DEFAULT_ARCHITECTURES}"
  echo "DEBUG: ${DEBUG}"
  echo "INPUT_DELIMITER: ${INPUT_DELIMITER}"
  echo "OUTPUT_DELIMITER: ${OUTPUT_DELIMITER}"
}

[ "$DEBUG" == "true" ] && echoInputs && set -x

set +e
tmpdir=$(mktemp -d)
echo "Temp dir: $tmpdir"
curl -sL https://github.com/regclient/regclient/releases/latest/download/regctl-linux-amd64 >"${tmpdir}"/regctl
chmod 755 "${tmpdir}"/regctl
count=0
# Get list of architectures from each image
IFS="$INPUT_DELIMITER"
for line in $IMAGES; do
  ARCHITECTURES=$("${tmpdir}"/regctl manifest get "${line}" | /bin/grep -i "Platform:" | awk '{print $2}')
  if [ $? != 0 ] || [ -z "$ARCHITECTURES" ]; then
    echo "No architectures found in manifest for image ${line}, inspecting image instead..."
    ARCHITECTURES=$("${tmpdir}"/regctl image inspect "${line}" | jq -r '.os + "/" + .architecture')
    if [ $? != 0 ] || [ -z "$ARCHITECTURES" ]; then
      if [[ "$PRUNE_MISSING_IMAGES" == "true" ]]; then
        echo "No architectures found in image for image $line and PRUNE_MISSING_IMAGES is enabled, ignoring this image..."
        unset ARCHITECTURES
      else
        echo "No architectures found in image for image $line and PRUNE_MISSING_IMAGES is disabled, using default architectures..."
        # No, bad shellcheck, bash replace is dumb
        # shellcheck disable=SC2001
        ARCHITECTURES=$(echo "$DEFAULT_ARCHITECTURES" | sed 's/'"$IFS"'/\n/g')
      fi
    fi
  fi
  # If architectures isn't set, we can assume PRUNE_MISSING_IMAGES is enabled and we should skip this image
  if [ -n "$ARCHITECTURES" ]; then
    echo "Architectures for image $line: $(echo "$ARCHITECTURES" | paste -s -d, -)"
    echo "$ARCHITECTURES" >"${tmpdir}"/architectures-${count}.txt
    count=$((count + 1))
  fi
done
unset IFS
# Sort each file
for file in "${tmpdir}"/architectures-*.txt; do
  sort -u "${file}" >"${file}.tmp" && mv "${file}.tmp" "${file}"
done
debug "Sorted architectures: $(tail "${tmpdir}"/architectures-*.txt)"
# Find common lines between all lists
comm -12 "${tmpdir}"/architectures-0.txt "${tmpdir}"/architectures-1.txt >"${tmpdir}"/architectures-common.txt
for ((i = 2; i < count; i++)); do
  comm -12 "${tmpdir}"/architectures-common.txt "${tmpdir}"/architectures-"${i}".txt >"${tmpdir}"/architectures-common.txt.tmp &&
    mv "${tmpdir}"/architectures-common.txt.tmp "${tmpdir}"/architectures-common.txt
  debug "Comparing $count: $(cat "${tmpdir}"/architectures-common.txt)"
done
# Output common architectures
# what the fuck is this arcane sed syntax it took me like 30 minutes to find it why the fuck does 's/\n/,/g' not work
COMMON_ARCHITECTURES=$(sed ':a;N;$!ba;s/\n/'"${OUTPUT_DELIMITER}"'/g' <"${tmpdir}"/architectures-common.txt)
echo "Common architectures between all images: ${COMMON_ARCHITECTURES}"
echo "::set-output name=architectures::${COMMON_ARCHITECTURES}"
# Clean up
[ "$DEBUG" != "true" ] && rm -rf "${tmpdir}"
exit 0
