#!/bin/bash

cd /usr/lib/plexmediaserver

CLUSTERPLEX_PLEX_VERSION=$(strings "Plex Media Server" | grep -P '^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)-[0-9a-f]{9}')
CLUSTERPLEX_PLEX_CODECS_VERSION=$(strings "Plex Media Server" | grep -P '^[0-9a-f]{7}-[0-9]{4}$' -m1)
CLUSTERPLEX_PLEX_EAE_VERSION=$(printf "eae-`strings "Plex Media Server" | grep -P '^EasyAudioEncoder-eae-[0-9a-f]{7}-$' | cut -d- -f3`-42")

echo "CLUSTERPLEX_PLEX_VERSION => '${CLUSTERPLEX_PLEX_VERSION}'"
echo "CLUSTERPLEX_PLEX_CODECS_VERSION => '${CLUSTERPLEX_PLEX_CODECS_VERSION}'"
echo "CLUSTERPLEX_PLEX_EAE_VERSION => '${CLUSTERPLEX_PLEX_EAE_VERSION}'"
echo "PLEX_ARCH => '${PLEX_ARCH}'"

CLUSTERPLEX_PLEX_CODEC_ARCH="${PLEX_ARCH}"

case "${PLEX_ARCH}" in
  amd64)
    CLUSTERPLEX_PLEX_CODEC_ARCH="linux-x86_64-standard"
    ;;
  armhf)
    CLUSTERPLEX_PLEX_CODEC_ARCH="linux-armv7hf_neon-standard"
    ;;
esac

echo "CLUSTERPLEX_PLEX_CODEC_ARCH => ${CLUSTERPLEX_PLEX_CODEC_ARCH}"

CODEC_PATH="/codecs/${CLUSTERPLEX_PLEX_CODECS_VERSION}-${CLUSTERPLEX_PLEX_CODEC_ARCH}"
echo "Codec location => ${CODEC_PATH}"

mkdir -p ${CODEC_PATH}
cd ${CODEC_PATH}

#original list: libhevc_decoder libh264_decoder libdca_decoder libac3_decoder libmp3_decoder libaac_decoder libaac_encoder libmpeg4_decoder libmpeg2video_decoder liblibmp3lame_encoder liblibx264_encoder; do
cat /app/codecs.txt | while read line 
do
  codec=${line//[$'\t\r\n']}
  echo "Processing codec ${codec}..."
  if [ -f "${codec}.so" ]; then
    echo "Codec ${codec}.so already exists. Skipping"
  else 
    echo "Codec ${codec}.so does not exist. Downloading..."
    wget https://downloads.plex.tv/codecs/${CLUSTERPLEX_PLEX_CODECS_VERSION}/${CLUSTERPLEX_PLEX_CODEC_ARCH}/${codec}.so
  fi
done

export FFMPEG_EXTERNAL_LIBS="/codecs/${CLUSTERPLEX_PLEX_CODECS_VERSION}-${CLUSTERPLEX_PLEX_CODEC_ARCH}/"

cd /app

node worker.js
