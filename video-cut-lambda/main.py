import os
import uuid
import boto3
import json
import dataclasses
import datetime
import urllib.request
from urllib.parse import urlparse
from urllib.parse import parse_qs


def lambda_handler(event, context):
    url = event['queryStringParameters']['url']
    ss = event['queryStringParameters']['ss']
    duration = event['queryStringParameters']['d']
    fadeout = event['queryStringParameters'].get('f', 'false')
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


    # 保存先S3パスを生成
    day = datetime.date.today()
    dists3url = f's3://{base_s3_backet}/{day.year}/{day.month}/{day.day}/{str(uuid.uuid4())}.mp4'


    # AWS Batchで動画保存処理
    batch_client = BatchClient()    
    batch_job_id = batch_client.submit_job(url, dists3url, ss, duration, fadeout, youtube_dl_batch_job_id if is_youtube_dl_req else None)["jobId"]
     
    response = {
        "statusCode": 200,
        "body": json.dumps({
            'batch_job_id': batch_job_id,
            's3': dists3url
        }),
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Headers": 'Content-Type',
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": 'OPTIONS,POST,GET'
        }
    }
    return response


class BatchClient:

    def __init__(self):
        self.client = boto3.client("batch")
        self.job_queue = os.environ['VIDEO_TRANSFORM_JOB_QUEUE']
        self.job_definition = os.environ['VIDEO_TRANSFORM_JOB_DEFINITION']
        self.jobname = "videotransform-job-from-lambda"

    def submit_job(self, url, dists3url, ss, duration, fadeout, youtubedl_batch_job_id):

        parameters={
            'inputs3url': url,
            'dists3url': dists3url,
            'ss': ss,
            'duration': duration,
            'fadeout':fadeout 
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
