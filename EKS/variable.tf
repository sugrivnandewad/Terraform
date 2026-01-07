variable "subnet_ids" {
  description = "List of subnet IDs (public + private) for the EKS cluster vpc_config.subnet_ids"
  type        = list(string)
  default     = []
}
