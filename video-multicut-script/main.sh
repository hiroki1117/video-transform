#!/bin/sh

# main.sh inputs3url instructions3urldists3url

# 引数(指示書の一行, オリジナルの動画ファイル名)
function trim_and_upload () {
    ARR=(${1//,/ })
    TRIM_DIST_S3PATH=${ARR[0]}
    SS=${ARR[1]}
    DURATION=${ARR[2]}
    DL_LOCAL_FILE=$2
    echo $TRIM_DIST_S3PATH
    echo $SS
    echo $D

    TMP_FILE_NAME=`basename $TRIM_DIST_S3PATH`

    # 動画のトリミング
    ffmpeg -ss "${SS}" -i ${DL_LOCAL_FILE} -t "${DURATION}" "${TMP_FILE_NAME}"

    # s3へアップロード
    aws s3 cp "${TMP_FILE_NAME}" "${TRIM_DIST_S3PATH}"
}

TARGET_VIDEO_S3PATH=${1:-error}
INSTRUCTION_S3PATH=${2:-error}

# 対象のビデオをダウンロード
aws s3 cp "${TARGET_VIDEO_S3PATH}" .
DL_FILENAME=`find . | grep mp4`

# trimリストをS3からダウンロード
aws s3 cp "${INSTRUCTION_S3PATH}" .

while read line
do
    # 一行ずつトリム処理する
    trim_and_upload $line `basename $DL_FILENAME`
done < `basename $INSTRUCTION_S3PATH`



