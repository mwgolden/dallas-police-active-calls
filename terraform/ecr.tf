resource "aws_ecr_repository" "dpd_active_calls_api" {
    name = "com.wgolden.dpd-active-calls-api"
    image_tag_mutability = "MUTABLE"
    image_scanning_configuration {
      scan_on_push = true
    }
}

resource "null_resource" "docker_push" {
    depends_on = [ aws_ecr_repository.dpd_active_calls_api ]
    provisioner "local-exec" {
      command = <<EOT
        aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(aws ecr describe-repositories --repository-names com.wgolden.dpd-active-calls-api --region us-east-1 --query 'repositories[0].repositoryUri' --output text)
        docker build -t dpd-active-calls-api-server ../api
        docker tag dpd-active-calls-api-server:latest $(aws ecr describe-repositories --repository-names com.wgolden.dpd-active-calls-api --region us-east-1 --query 'repositories[0].repositoryUri' --output text):latest
        docker push $(aws ecr describe-repositories --repository-names com.wgolden.dpd-active-calls-api --region us-east-1 --query 'repositories[0].repositoryUri' --output text):latest
      EOT
    }
}