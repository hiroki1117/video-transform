variable "video_transform_s3_backet" {
  type    = string
  default = "video-transform-hiroki1117"
}

variable "youtube_dl_endpoint" {
  type    = string
}

variable "vpc_name" {
  type        = string
  default     = "video-transform-vpc"
  description = "Sample Variable"
}

variable "cidr" {
  type    = string
  default = "192.168.0.0/16"
}

variable "azs" {
  type = list(string)

  default = [
    "ap-northeast-1a"
  ]
}

variable "public_subnets" {
  type = list(string)

  default = [
    "192.168.1.0/24"
  ]
}

variable "private_subnets" {
  type = list(string)

  default = [
    "192.168.101.0/24"
  ]
}

variable "spot_bid_percentage" {
  type    = string
  default = "100"
}

variable "instance_types" {
  type    = list(string)
  default = ["m5.large", "m5.xlarge"]
}

variable "instance_settings" {
  type = map

  default = {
    min_vcpus = 0
    max_vcpus = 10
  }
}

variable "video_transform_job_queue_name" {
  type = string
  default = "video-transform-batch-queue"
}

# JobDefinition
 variable "video_cut_job_defination_name" {
   type = string
   default = "video-cut-job-definition"
 }

variable "video_cut_job_log_group_name" {
  type    = string
  default = "/aws/batch/video-cut"
}

 variable "video_multicut_job_defination_name" {
   type = string
   default = "video-multicut-job-definition"
 }

variable "video_multicut_job_log_group_name" {
  type    = string
  default = "/aws/batch/video-multicut"
}