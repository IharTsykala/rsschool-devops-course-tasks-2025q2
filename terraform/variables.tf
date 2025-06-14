variable "region" {
  type    = string
  default = "us-east-1"
}

variable "bucket_name" {
  default = "terraform-states-ihar-tsykala-2025q2"
}

variable "role_name" {
  default = "GithubActionsRole"
}

variable "oidc_provider" {
  default = "arn:aws:iam::141706873519:oidc-provider/token.actions.githubusercontent.com"
}

variable "repository" {
  default = "repo:IharTsykala/rsschool-devops-course-tasks-2025q2:ref:refs/heads/main"
}
