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

    # URLのチェック
    # youtubeであればyoutube-dlの後にバッチの依存性など
    day = datetime.date.today()
    dists3url = f's3://{base_s3_backet}/{day.year}/{day.month}/{day.day}/{str(uuid.uuid4())}.mp4'

    # AWS Batchで動画保存処理
    batch_client = BatchClient()    
    batch_job_id = batch_client.submit_job(url, dists3url, ss, duration, fadeout)["jobId"]
     
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

    def submit_job(self, url, dists3url, ss, duration, fadeout):

        parameters={
            'inputs3url': url,
            'dists3url': dists3url,
            'ss': ss,
            'duration': duration,
            'fadeout':fadeout 
        }

        return self.client.submit_job(
            jobName=self.jobname,
            jobQueue=self.job_queue,
            jobDefinition=self.job_definition,
            parameters=parameters
        )
