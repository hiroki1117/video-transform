terraform {
  required_version = "~> 0.15"
  backend "s3" {
    bucket = "hiroki1117-tf-state"
    key    = "video_transform"
    region = "ap-northeast-1"
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

# VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.cidr

  azs             = var.azs
  private_subnets = var.public_subnets
  public_subnets  = var.private_subnets

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Product = "video-transform"
  }
}

#SG
resource "aws_security_group" "sg" {
  name = "aws_batch_compute_environment_security_group"
  vpc_id = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Product = "video-transform"
  }
}


#Batch
resource "aws_batch_compute_environment" "video_transform_batch" {
  compute_environment_name = "video-transform-batch"

  compute_resources {
    type                = "SPOT"
    spot_iam_fleet_role = module.iam_assumable_role_for_ec2_spot_fleet.iam_role_arn
    bid_percentage      = var.spot_bid_percentage
    subnets             = module.vpc.public_subnets
    security_group_ids  = [aws_security_group.sg.id]
    instance_role       = aws_iam_instance_profile.ecs_instance_profile.arn
    instance_type       = var.instance_types
    min_vcpus           = var.instance_settings["min_vcpus"]
    max_vcpus           = var.instance_settings["max_vcpus"]

    tags = {
      Product = "video-transform"
    }
  }

  service_role = module.iam_assumable_role_for_aws_batch_service.iam_role_arn
  state        = "ENABLED"
  type         = "MANAGED"
  depends_on = [
    module.iam_assumable_role_for_ec2_spot_fleet,
    module.iam_assumable_role_for_aws_batch_service,
    module.iam_assumable_role_for_ecs_instance_role
  ]

  lifecycle {
    create_before_destroy = true
  }
}

#ジョブキューの用意
resource "aws_batch_job_queue" "video_transform_batch_queue" {
  name                 = var.video_cut_job_queue_name
  state                = "ENABLED"
  priority             = 1
  compute_environments = [aws_batch_compute_environment.video_transform_batch.arn]
  lifecycle {
    create_before_destroy = true
  }
}

module "video_cut_job_definition" {
  source = "./modules/batch_job_modules"
  job_name = var.video_cut_job_defination_name
  job_log_group_name = var.video_cut_job_log_group_name
  job_ecr_name = "video-cut"
  container_properties = templatefile("./video_cut_batch_container_definitions.tpl",
    {
      job_role_arn = module.iam_assumable_role_for_video_transform_batchjob.iam_role_arn,
      log_group = var.video_cut_job_log_group_name
    }
  )
}

#videocutジョブ定義
# resource "aws_batch_job_definition" "video_cut_job_definition" {
#   name = "video-cut-job-definition"
#   type = "container"
#   container_properties = templatefile("./video_cut_batch_container_definitions.tpl",
#     {
#       job_role_arn = module.iam_assumable_role_for_video_transform_batchjob.iam_role_arn,
#       log_group = var.video_cut_job_log_group_name
#     }
#   )
# }

#videocutジョブのロググループ
# resource "aws_cloudwatch_log_group" "video_cut_job_log_group" {
#   name = var.video_cut_job_log_group_name
# }

#videocut ECR
# resource "aws_ecr_repository" "video_cut_registory" {
#   name                 = "video-cut"
#   image_tag_mutability = "MUTABLE"

#   image_scanning_configuration {
#     scan_on_push = true
#   }
# }

#AWS Batchサービスロール
module "iam_assumable_role_for_aws_batch_service" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"

  trusted_role_services = [
    "batch.amazonaws.com"
  ]

  create_role = true

  role_name         = "AWSBatchServiceRoleForVideoTransform"
  role_requires_mfa = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
  ]
}

#EC2SpotFleetロール
module "iam_assumable_role_for_ec2_spot_fleet" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"

  trusted_role_services = [
    "spotfleet.amazonaws.com"
  ]

  create_role = true

  role_name         = "AmazonEC2SpotFleetRoleForVideoTransform"
  role_requires_mfa = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
  ]
}

#ECSインスタンスロール
module "iam_assumable_role_for_ecs_instance_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"

  trusted_role_services = [
    "ec2.amazonaws.com"
  ]

  create_role = true

  role_name         = "VideoTransformECSInstanceRole"
  role_requires_mfa = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  ]
}

#インスタンスプロファイル
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "video-transform-profile"
  role = module.iam_assumable_role_for_ecs_instance_role.iam_role_name
}

#ジョブ用のロール
module "iam_assumable_role_for_video_transform_batchjob" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"

  trusted_role_services = [
    "ecs-tasks.amazonaws.com"
  ]

  create_role = true

  role_name         = "VideoTransformJobRole"
  role_requires_mfa = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ]
}

#S3
resource "aws_s3_bucket" "video_transform_bucket" {
  bucket = var.video_transform_s3_backet
  acl    = "private"

  tags = {
    Product = "video-transform"
  }
}