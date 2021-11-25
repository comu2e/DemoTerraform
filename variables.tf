variable "app_name" {
  type    = string
  default = "app"
}
variable "azs" {
  type    = list(string)
  default = ["ap-northeast-1a", "ap-northeast-1c"]
}
variable "vpc_cidr" {
  default = "10.10.0.0/16"
}
# PublicSubnets
variable "public_subnet_cidrs" {
  default = ["10.10.0.0/24", "10.10.1.0/24"]
}

# PrivateSubnets
variable "private_subnet_cidrs" {
  default = ["10.10.10.0/24", "10.10.11.0/24"]
}
