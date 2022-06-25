# Instance type
variable "instance_type" {
  default     = "t3.medium"
  description = "Type of the instance"
  type        = string
}

variable "my_private_ip" {
  default     = "172.31.12.232"
  description = "Cloud9 Private IP"
  type        = string
}

variable "my_public_ip" {
  default     = "44.204.215.205"
  description = "Cloud9 Public IP"
  type        = string
}