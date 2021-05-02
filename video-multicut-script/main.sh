#!/bin/sh

# main.sh inputs3url instructions3urldists3url

# 引数(指示書の一行, オリジナルの動画ファイル名)
function trim_and_upload () {
    local ARR=(${1//,/ })
    local TRIM_DIST_S3PATH=${ARR[0]}
    local SS=${ARR[1]}
    local DURATION=${ARR[2]}
    local DL_LOCAL_FILE=$2
    # echo $TRIM_DIST_S3PATH
    # echo $SS
    # echo $DURATION

    local TMP_FILE_NAME=`basename $TRIM_DIST_S3PATH`

    # 動画のトリミング
    ffmpeg -ss "${SS}" -i ${DL_LOCAL_FILE} -t "${DURATION}" "${TMP_FILE_NAME}" &
    wait $!

    # s3へアップロード
    aws s3 cp "${TMP_FILE_NAME}" "${TRIM_DIST_S3PATH}"
    echo $TRIM_DIST_S3PATH
    echo $TMP_FILE_NAME
}

TARGET_VIDEO_S3PATH=${1:-error}
INSTRUCTION_S3PATH=${2:-error}
echo $TARGET_VIDEO_S3PATH
echo $INSTRUCTION_S3PATH

# 対象のビデオをダウンロード
aws s3 cp "${TARGET_VIDEO_S3PATH}" .
DL_FILENAME=`find . | grep mp4`

# trimリストをS3からダウンロード
aws s3 cp "${INSTRUCTION_S3PATH}" .
INSTRUCTION_FILE=`basename $INSTRUCTION_S3PATH`

exec < $INSTRUCTION_FILE
while read line
do
    # 一行ずつトリム処理する
    trim_and_upload $line `basename $DL_FILENAME`
done



