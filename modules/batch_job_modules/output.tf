output "job_revision" {
    value = aws_batch_job_definition.video_transform_job_definition.revision
}