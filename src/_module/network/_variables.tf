
variable "app_name" {
  description = "Application Name"
  type        = string
}
variable "vpc_cidr" {
  description = "VPC CIDR blocks"
  type        = string
}
variable "public_subnet_cidrs" {
  description = "Public Subnet CIDR blocks"
  type        = list(string)
}
variable "private_subnet_cidrs" {
  description = "Public Subnet CIDR blocks"
  type        = list(string)
}
variable "azs" {
  description = "Availability zones"
  type        = list(string)
}
