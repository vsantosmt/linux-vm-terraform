variable "suffix" {
  default = "devops"
}

variable "vm_name" {
  default = "AZVM01"
}
variable "location" {
  default = "West Europe"
}
variable "vm_count" {
  description = "Number of AVD machines to deploy"
  default     = 1
}