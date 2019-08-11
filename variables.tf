variable "enable_oracle" {
  description = "Enable / Disable Oracle (e.g. `1`)"
  type        = bool
  default     = true
}

variable "random_cluster_suffix" {
  description = "Random 6 byte hex suffix for cluster name"
  type        = string
  default     = ""
}

variable "oci_region" {
  description = "OCI Region to use (e.g. `eu-frankfurt-1` => Frankfurt)"
  type        = string
  default     = "eu-frankfurt-1"
}

variable "oci_user_ocid" {
  description = "OCI User OCID"
  type        = string
}

variable "oci_tenancy_ocid" {
  description = "OCI Tenancy OCID"
  type        = string
}

variable "oci_private_key_path" {
  description = "OCI private key path (e.g. `~/.oci/oci_api_key.pem`)"
  type        = string
  default     = "~/.oci/oci_api_key.pem"
}

variable "oci_public_key_path" {
  description = "OCI public key path (e.g. `~/.oci/oci_api_key_public.pem`)"
  type        = string
  default     = "~/.oci/oci_api_key_public.pem"
}

variable "oci_fingerprint" {
  description = "OCI SSH public key fingerprint"
  type        = string
}

# OCI VCN
variable "lbs" {
  description = "Count of 8-bit numbers of LoadBalancer base_cidr_block"
  type        = number
  default     = 10
}

variable "oci_cidr_block" {
  description = "OCI VCN CIDR block (e.g. `10.0.23.0/16`)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "oci_subnets" {
  description = "Count of 8-bit numbers of subnets base_cidr_block"
  type        = number
  default     = 2
}

variable "oci_policy_statements" {
  description = "OCI Policy Statements in policy language"
  type        = list(string)
  default     = ["Allow service OKE to manage all-resources in tenancy"]
}

# OKE
variable "oci_cluster_name" {
  description = "OCI OKE Kubernetes cluster name (e.g. `k8soci`)"
  type        = string
  default     = "k8soci"
}

variable "oci_node_pool_name" {
  description = "OCI Kubernetes node pool name (e.g. `k8s-nodepool-oci`)"
  type        = string
  default     = "k8s-nodepool-oci"
}

variable "oke_node_pool_size" {
  description = "OKE Kubernetes worker node pool quantity per subnet (e.g. `2`)"
  type        = number
  default     = 2
}

variable "oci_node_pool_node_shape" {
  description = "OCI Kubernetes node pool Shape (e.g. `VM.Standard2.1` => 1vCPU, 15GB RAM)"
  type        = string
  default     = "VM.Standard2.1"
}

variable "oci_node_pool_node_image_name" {
  description = "OCI Kubernetes node pool image name (e.g. `Oracle-Linux-7.6`)"
  type        = string
  default     = "Oracle-Linux-7.6"
}

variable "oci_node_pool_ssh_public_key" {
  description = "SSH public key to add to each node in the node pool (e.g. `~/.ssh/id_rsa.pub`)"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "oci_cluster_add_ons_kubernetes_dashboard" {
  description = "Enable Kubernetes Dashboard (e.g. `false`)"
  type        = bool
  default     = false
}

variable "oci_cluster_add_ons_tiller" {
  description = "Enable Tiller for helm (e.g. `false`)"
  type        = bool
  default     = false
}

variable "oci_subnet_prohibit_public_ip_on_vnic" {
  description = "OCI VCN subnet prohibits assigning public IPs or not (e.g. `false`)"
  type        = bool
  default     = true
}

//variable "oci_cluster_kube_config_expiration" { default = 2592000 }
//variable "oci_cluster_kube_config_token_version" { default = "1.0.0" }
