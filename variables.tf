variable "zookeeper_version" {
  description = "CP Platform Zookeeper container image version"
  type = string
}

variable "zookeeper_client_port" {
  description = "Zookeeper client port"
  type = number
}

variable "zookeeper_count" {
  description = "Number of zookeeper nodes in the cluster"
  type = number
}