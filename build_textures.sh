#!/bin/sh

# 1 - input image
# 2 - output image
# 3 - percent
function resize_image {
  local IMG_WIDTH=`sips --getProperty pixelWidth $1 | awk '{ print $2 }'`
  local NEW_WIDTH
  let "NEW_WIDTH=( $IMG_WIDTH * $3 ) / 100"
  
  pushd "$(dirname $2)" > /dev/null
  local OUT_DIR=`pwd -P`
  popd > /dev/null
  
  sips "$1" --resampleWidth $NEW_WIDTH --out "$OUT_DIR/$(basename $2)" &> /dev/null
}

# 1 - input dir
# 2 - output dir
# 3 - percent
function resize_sprites {
  INPUT_DIR_BASE="$1"
  OUTPUT_DIR_BASE="$2"
  PERCENT="$3"
  
  COUNTER=0
  
  echo "Resizing sprites from \"$INPUT_DIR_BASE\" to \"${OUTPUT_DIR_BASE}\" (by ${PERCENT}%)..."
  for FILE in `find "${INPUT_DIR_BASE}" -maxdepth 1 -name "*.png" -print -o -name "*.jpg" -print -o -name "*.jpeg" -print`; do resize_image "${INPUT_DIR_BASE}/$(basename ${FILE})" "${OUTPUT_DIR_BASE}/$(basename ${FILE})" ${PERCENT}; let "COUNTER=( COUNTER + 1 )"; done  
  
  echo " done (items: $COUNTER)."
}

function copy_optimized {
  INPUT_DIR_BASE="$1"
  OUTPUT_DIR_BASE="$2"
  
  if [ -d "${INPUT_DIR_BASE}" ]; then
    echo "Copying optimized from \""${INPUT_DIR_BASE}"\" to \""${OUTPUT_DIR_BASE}"\"..."
    COUNTER=0
    
    for FILE in `find "${INPUT_DIR_BASE}" -maxdepth 1 -name "*.png" -print -o -name "*.jpg" -print -o -name "*.jpeg" -print`; do cp "${INPUT_DIR_BASE}/$(basename $FILE)" "${OUTPUT_DIR_BASE}/$(basename $FILE)"; let "COUNTER=( COUNTER + 1 )"; done
    echo " done (items: $COUNTER)."
  fi
}

function remove_images {
  INPUT_DIR_BASE="$1"
  
  if [ -d "${INPUT_DIR_BASE}" ]; then
    echo "Removing images from \""${INPUT_DIR_BASE}"\"..."
    COUNTER=0
    
    for FILE in `find "${INPUT_DIR_BASE}" -maxdepth 1 -name "*.png" -print -o -name "*.jpg" -print -o -name "*.jpeg" -print`; do rm -f "${INPUT_DIR_BASE}/$(basename $FILE)"; let "COUNTER=( COUNTER + 1 )"; done
    echo " done (items: $COUNTER)."
  fi
}

function copy_or_resize_texture {
  INPUT_FILE="$1"
  OPTIMIZED_FILE="$2"
  OUTPUT_FILE="$3"
  PERCENT="$4"
  
  if [ -f "${OPTIMIZED_FILE}" ]; then
    cp "${OPTIMIZED_FILE}" "${OUTPUT_FILE}"
    echo "Copied optimized \"${OPTIMIZED_FILE}\" to \"${OUTPUT_FILE}\""
  else
    resize_image "${INPUT_FILE}" "${OUTPUT_FILE}" ${PERCENT}
    echo "Resized \"${INPUT_FILE}\" to \"${OUTPUT_FILE}\" (${PERCENT}%)" 
  fi
}

SCRIPT_DIR="${BASH_SOURCE[0]}";
if ([ -h "${SCRIPT_DIR}" ]) then
  while([ -h "${SCRIPT_DIR}" ]) do SCRIPT_DIR=`readlink "${SCRIPT_DIR}"`; done
fi
pushd . > /dev/null
cd "`dirname "${SCRIPT_DIR}"`" > /dev/null
SCRIPT_DIR=`pwd`;
popd  > /dev/null

PROJECT_DIR="${SCRIPT_DIR}"
SPRITESHEETGEN_BIN="${PROJECT_DIR}/Tools/bin/spritesheetgen"

BASE_IN_DIR="${PROJECT_DIR}/Resources/Textures.in"
BASE_TEX_DIR="${PROJECT_DIR}/Resources/Textures"

TEXTURE_TO_GEN=$1

if [ ! ${TEXTURE_TO_GEN} ]; then
  echo "Removing old textures..."
  
  COUNTER=0
  
  for FILE in `find "${BASE_TEX_DIR}" -maxdepth 1 -name "*.png" -print -o -name "*.jpg" -print -o -name "*.jpeg" -print -o -name "*.plist" -print`; do rm -f "${BASE_TEX_DIR}/$(basename $FILE)"; let "COUNTER=( COUNTER + 1 )"; done
  echo " done (items: $COUNTER)."
fi

for TEX_DIR in `find "${BASE_IN_DIR}/size-4" -maxdepth 1 -print`; do
  DIR_NAME=$(basename $TEX_DIR)
  if [ ! ${TEXTURE_TO_GEN} -o ${TEXTURE_TO_GEN} == ${DIR_NAME} ]; then
    if [ -d "${BASE_IN_DIR}/size-4/${DIR_NAME}" ]; then
      mkdir -p "${BASE_IN_DIR}/size-1/${DIR_NAME}"
      remove_images "${BASE_IN_DIR}/size-1/${DIR_NAME}"
      resize_sprites "${BASE_IN_DIR}/size-4/${DIR_NAME}" "${BASE_IN_DIR}/size-1/${DIR_NAME}" 25
      copy_optimized "${BASE_IN_DIR}/size-1.optimized/${DIR_NAME}" "${BASE_IN_DIR}/size-1/${DIR_NAME}"
    
      mkdir -p "${BASE_IN_DIR}/size-2/${DIR_NAME}"
      remove_images "${BASE_IN_DIR}/size-2/${DIR_NAME}"
      resize_sprites "${BASE_IN_DIR}/size-4/${DIR_NAME}" "${BASE_IN_DIR}/size-2/${DIR_NAME}" 50
      copy_optimized "${BASE_IN_DIR}/size-2.optimized/${DIR_NAME}" "${BASE_IN_DIR}/size-2/${DIR_NAME}"
    
      ${SPRITESHEETGEN_BIN} "${BASE_IN_DIR}/size-4/${DIR_NAME}" "${BASE_TEX_DIR}" "${DIR_NAME}-4"
      ${SPRITESHEETGEN_BIN} "${BASE_IN_DIR}/size-2/${DIR_NAME}" "${BASE_TEX_DIR}" "${DIR_NAME}-2"
      ${SPRITESHEETGEN_BIN} "${BASE_IN_DIR}/size-1/${DIR_NAME}" "${BASE_TEX_DIR}" "${DIR_NAME}-1"
    fi
  fi
done

for TEX_FILE in `find "${BASE_IN_DIR}/size-4" -maxdepth 1 -name "*.png" -print -o -name "*.jpg" -print -o -name "*.jpeg" -print`; do
  TEX_FILE_NAME=$(basename $TEX_FILE)
  TEX_FILE_NAME_NO_EXT=${TEX_FILE_NAME%.*}
  TEX_FILE_EXT=${TEX_FILE_NAME##*.}
  
  if [ ! ${TEXTURE_TO_GEN} -o ${TEXTURE_TO_GEN} == ${TEX_FILE_NAME_NO_EXT} ]; then
    copy_or_resize_texture "${TEX_FILE}" "${BASE_IN_DIR}/size-2.optimized/${TEX_FILE_NAME}" "${BASE_TEX_DIR}/${TEX_FILE_NAME_NO_EXT}-2.${TEX_FILE_EXT}" 50
    copy_or_resize_texture "${TEX_FILE}" "${BASE_IN_DIR}/size-1.optimized/${TEX_FILE_NAME}" "${BASE_TEX_DIR}/${TEX_FILE_NAME_NO_EXT}-1.${TEX_FILE_EXT}" 25
    cp "${TEX_FILE}" "${BASE_TEX_DIR}/${TEX_FILE_NAME_NO_EXT}-4.${TEX_FILE_EXT}"
    
    echo "Copied \"${TEX_FILE}\" to \"${BASE_TEX_DIR}/${TEX_FILE_NAME_NO_EXT}-4.${TEX_FILE_EXT}\""
  fi
done


