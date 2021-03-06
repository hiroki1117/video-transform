
{
  "jobDefinitionName": "video-cut-job-definition",
  "image": "103933412310.dkr.ecr.ap-northeast-1.amazonaws.com/video-cut:v1",
  "executionRoleArn": "arn:aws:iam::103933412310:role/ecsTaskExecutionRole",
  "jobRoleArn": "${job_role_arn}",
  "logConfiguration": {
    "logDriver": "awslogs",
    "options": {
      "awslogs-region": "ap-northeast-1",
      "awslogs-stream-prefix": "video-cut-job",
      "awslogs-group": "${log_group}"
    },
    "secretOptions": []
  },
  "memory": 512,
  "vcpus": 1,
  "command" : ["bash","main.sh", "Ref::inputs3url", "Ref::dists3url", "Ref::ss", "Ref::duration", "Ref::fadeout"],
  "type": "container",
  "environment": [],
  "mountPoints": [],
  "resourceRequirements": [],
  "secrets": [],
  "ulimits": [],
  "volumes": [],
  "parameters": [],
  "tags": {}
}
