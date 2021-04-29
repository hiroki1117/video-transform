#!/bin/sh

# main.sh inputs3url dists3url ss duration fadeout

TARGET_VIDEO_S3PATH=${1:-error}
DIST_VIDEO_S3PATH=${2:-error}
SS=${3:-0}
DURATION=${4:-10}
FADEOUT=${5:-false}

echo $TARGET_VIDEO_S3PATH
echo $DIST_VIDEO_S3PATH
echo $SS
echo $DURATION
echo $FADEOUT

# 対象のビデオをダウンロード
aws s3 cp "${TARGET_VIDEO_S3PATH}" .
DL_FILENAME=`find . | grep mp4`
TRIM_FILENAME="trimtemp.mp4"

# 動画のトリミング
ffmpeg -ss "${SS}" -i ${DL_FILENAME} -t "${DURATION}" -vcodec libx264 "${TRIM_FILENAME}"

FADE_FILENAME
# フェードアウト処理
if [ $FADEOUT = "true" ]; then
    FADE_FILENAME="fadetemp.mp4"
    ffmpeg -i "${TRIM_FILENAME}" -vf "fade=d=1.2,reverse,fade=d=1.2,reverse" -af "afade=t=in:st=0:d=2,areverse,afade=t=in:st=0:d=2,areverse" -vcodec libx264 "${FADE_FILENAME}"
fi

LAST_FINENAME=${FADE_FILENAME-${TRIM_FILENAME}}

# S3へ保存
aws s3 cp "${LAST_FINENAME}" "${DIST_VIDEO_S3PATH}"
