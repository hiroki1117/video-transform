# /bin/sh

CONCAT_S3PATH=${1:-error}
DIST_VIDEO_S3PATH=${2:-error}
CONCAT_FILE="concattemp.txt"

echo $CONCAT_S3PATH
echo $DIST_VIDEO_S3PATH

# S3ビデオリストをダウンロード
aws s3 cp "${CONCAT_S3PATH}" .

# S3から対象ビデオ一覧(s3path)をダウンロード
while read line
do
  aws s3 cp "${line}" .
  TMP=`basename $line`
  echo "file $TMP" >> $CONCAT_FILE
done < `basename $CONCAT_S3PATH`

# ビデオをマージ
ffmpeg -f concat -i "${CONCAT_FILE}" merged.mp4

# S3へ保存
aws s3 cp merged.mp4 "${DIST_VIDEO_S3PATH}"



