#videocutジョブ定義
resource "aws_batch_job_definition" "video_transform_job_definition" {
  name = var.job_name
  type = "container"
  container_properties = var.container_properties
}

#videocutジョブのロググループ
resource "aws_cloudwatch_log_group" "video_cut_job_log_group" {
  name = var.job_log_group_name
}

#videocut ECR
resource "aws_ecr_repository" "video_cut_registory" {
  name                 = var.job_ecr_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}