#You can provide Date value if need to know when its created and what is happening
variable "tagNameDate" {
  default = ""
}

# VPC Variables
variable "cidr_blocks" {
  default = ["0.0.0.0/0"]
}


variable "public_subnet_cidr_blocks" {
  description = "CIDR blocks for public subnets"
  default     = ["10.0.0.0/26", "10.0.0.64/26"] # Adjust as needed
}