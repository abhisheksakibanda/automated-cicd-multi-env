output "pipeline_name" {
  value = aws_codepipeline.cicd_pipeline.name
}

output "artifact_bucket_arn" {
  value = aws_s3_bucket.artifact_bucket.arn
}
