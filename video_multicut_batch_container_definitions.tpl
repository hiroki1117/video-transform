
{
  "jobDefinitionName": "video-cut-job-definition",
  "image": "103933412310.dkr.ecr.ap-northeast-1.amazonaws.com/video-multi-cut:v2",
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
  "command" : ["bash","main.sh", "Ref::inputs3url", "Ref::instruction3url"],
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
