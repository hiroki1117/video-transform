# Video Cut Lambda
resource "aws_lambda_function" "video_cut_submitjob_lambda" {
  filename      = data.archive_file.video_cut_submitjob_batch.output_path
  function_name = "video-cut-submitjob-lambda"
  role          = module.iam_assumable_role_for_video_cut_submitjob_lambda.iam_role_arn
  handler       = "main.lambda_handler"
  source_code_hash = data.archive_file.video_cut_submitjob_batch.output_base64sha256

  runtime = "python3.8"

  environment {
    variables = {
      VIDEO_TRANSFORM_S3BACKET = var.video_transform_s3_backet
      VIDEO_TRANSFORM_JOB_QUEUE = "video-transform-batch-queue"
      VIDEO_TRANSFORM_JOB_DEFINITION = "video-cut-job-definition:2"
    }
  }

}

data "archive_file" "video_cut_submitjob_batch" {
  type        = "zip"
  source_dir  = "./video-cut-lambda"
  output_path = "video-cut-lambda.zip"
}

#Lambdaのロール
module "iam_assumable_role_for_video_cut_submitjob_lambda" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"

  trusted_role_services = [
    "lambda.amazonaws.com"
  ]

  create_role = true

  role_name         = "VideoCutSubmitJobLambdaRole"
  role_requires_mfa = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AWSBatchFullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  ]
}

