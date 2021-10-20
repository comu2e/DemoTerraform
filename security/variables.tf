variable "vpc_id" {
  description = "HTTPアクセス用のセキュリティグループ"
  type        = string
}
variable "app_name" {
  type = string
}
variable "vpc_cidr" {
  type = string
}

variable "private_route_table" {
  type = list(any)
}
variable "private_subnet" {
  type = list(string)
}
