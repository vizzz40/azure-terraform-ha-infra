variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "project"
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "northitaly"
}

variable "vnet_address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefix" {
  description = "Address prefix for Subnet A"
  type        = list(string)
  default     = ["10.0.0.0/20"]
}