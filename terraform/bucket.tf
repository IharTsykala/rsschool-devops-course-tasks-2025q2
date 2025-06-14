# resource "aws_s3_bucket" "tf_state" {
#   bucket        = "terraform-states-ihar-tsykala-2025q2"
#   force_destroy = true
#
#   versioning {
#     enabled = true
#   }
#
#   tags = {
#     Project = "DevOpsCourse"
#     Owner   = "devops-user"
#   }
# }
