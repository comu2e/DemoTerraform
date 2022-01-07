variable "app_name" {
  description = "Application Name"
  type        = string
}
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "http_sg" {
  description = "HTTP access security group"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet ids."
  type        = list(string)
}

variable "port" {
  description = "ALB incoming Port"
  type        = number
}
