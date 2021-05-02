import os
import uuid
import boto3
import json
import tempfile
import datetime
import urllib.request
from urllib.parse import urlparse
from urllib.parse import parse_qs



# trim=30,60&trim=120,20...
def lambda_handler(event, context):
    url = event['queryStringParameters']['url']
    trim_array = event['multiValueQueryStringParameters']['trim']
    base_s3_backet = os.environ['VIDEO_TRANSFORM_S3BACKET']
    youtube_dl_endpoint = os.environ['YOUTUBE_DL_ENDPOINT']

    # URLのチェック
    # youtubeであればyoutube-dlの後にバッチの依存性など
    o = urlparse(url)
    is_youtube_dl_req = o.scheme != "s3"
    if is_youtube_dl_req:
        req = urllib.request.Request(youtube_dl_endpoint + url)
        with urllib.request.urlopen(req) as res:
            o = json.load(res)
            print(o)
            # DL後のS3エンドポイントを代入
            url = o['s3']
            youtube_dl_batch_job_id = o['batch_job_id']
    
    # s3へ指示書をアップロード
    instruction_s3_path, trim_result_s3_path_array = create_instruction_s3(trim_array, base_s3_backet)

    # AWS Batchで動画保存処理
    batch_client = BatchClient()
    batch_job_id = batch_client.submit_job(url, instruction_s3_path, youtube_dl_batch_job_id if is_youtube_dl_req else None)["jobId"]
    
    response = {
        "statusCode": 200,
        "body": json.dumps({
            'batch_job_id': batch_job_id,
            's3': trim_result_s3_path_array
        }),
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Headers": 'Content-Type',
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": 'OPTIONS,POST,GET'
        }
    }
    return response

# S3のファイルパスを作成
def generate_s3_path(base_s3_backet):
    # 保存先S3パスを生成
    day = datetime.date.today()
    return dists3url = f's3://{base_s3_backet}/{day.year}/{day.month}/{day.day}/{str(uuid.uuid4())}.mp4'

# S3へバッチ指示書をアップロード
# 形式
# trimアップロード先path,ss,d
def create_instruction_s3(trim_array, s3backet):
    s3 = boto3.resource('s3')
    bucket = s3.Bucket(s3backet)
    result_s3_path = []

    tf = tempfile.NamedTemporaryFile()
    for e in trim_array:
        ss, d = e.split(",")
        s3path = generate_s3_path(s3backet)
        b = bytes(s3path + "," + ss + "," + "d" + "\n", encoding='utf-8', errors='replace'))
        tf.write(b)
        result_s3_path.append(s3path)
    tf.flush()

    instruction_file_s3_path = generate_s3_path(s3backet)
    bucket.upload_file(tf.name, instruction_file_s3_path)
    return (instruction_file_s3_path, result_s3_path)


class BatchClient:

    def __init__(self):
        self.client = boto3.client("batch")
        self.job_queue = os.environ['VIDEO_TRANSFORM_JOB_QUEUE']
        self.job_definition = os.environ['VIDEO_TRANSFORM_JOB_DEFINITION']
        self.jobname = "videotransform-job-from-lambda"

    def submit_job(self, url, instruction_file_s3_path, youtubedl_batch_job_id):

        parameters={
            'inputs3url': url,
            'instruction3url': instruction_file_s3_path
        }

        dependsOn=[
            {
                'jobId': youtubedl_batch_job_id,
                'type': 'N_TO_N'
            }
        ]

        return self.client.submit_job(
            jobName=self.jobname,
            jobQueue=self.job_queue,
            jobDefinition=self.job_definition,
            parameters=parameters,
            dependsOn=[] if not youtubedl_batch_job_id else dependsOn
        )
