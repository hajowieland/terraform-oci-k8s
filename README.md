# Terraform Kubernetes on Oracle Cloud Infrastructure (OKE)

This repository contains the Terraform module for creating a simple but ready-to-use Kubernetes Cluster on Oracle Container Engine for Kubernetes (OKE).

It uses the latest available Kubernetes version available in the Oracle Cloud Infrastructure region and creates a kubeconfig file at completion.

#### Link to my comprehensive blog post (beginner friendly):
[https://napo.io/posts/terraform-kubernetes-multi-cloud-ack-aks-dok-eks-gke-oke/#oracle-cloud-infrastructure](https://napo.io/posts/terraform-kubernetes-multi-cloud-ack-aks-dok-eks-gke-oke/#oracle-cloud-infrastructure)



<p align="center">
<img alt="Oracle Logo" src="https://upload.wikimedia.org/wikipedia/commons/thumb/5/50/Oracle_logo.svg/320px-Oracle_logo.svg.png">
</p>


- [Terraform Kubernetes on Oracle Cloud](#Terraform-Kubernetes-on-Oracle-Cloud)
  - [Requirements](#Requirements)
  - [Features](#Features)
  - [Notes](#Notes)
  - [Defaults](#Defaults)
  - [Terraform Inputs](#Terraform-Inputs)
  - [Outputs](#Outputs)


## Requirements

You need an [Oracle Cloud](https://cloud.oracle.com/en_US/tryit) account.


## Features

* Always uses latest Kubernetes version available at Oracle Cloud
* **kubeconfig** file generation
* Creates separate node pool for worker nodes
* Allows SSH access from workstation IPv4 address only


## Notes

* `export KUBECONFIG=./kubeconfig_oci` in repo root dir to use the generated kubeconfig file
* The `enable_oracle` variable is used in the [hajowieland/terraform-kubernetes-multi-cloud](https://github.com/hajowieland/terraform-kubernetes-multi-cloud) module
* It can take a few minutes after Terraform finishes until the Kubernetes nodes are available!


## Defaults

See tables at the end for a comprehensive list of inputs and outputs.


* Default region: **eu-frankfurt-1** _(Frankfurt, Germany)_
* Default worker node type: **VM.Standard2.1** _(1x vCPU, 15.0GB memory)_
* Default worker node pool size: **2** (per subnet, by default we only use one subnet)



## Terraform Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| enable_oracle | Enable / Disable Oracle Cloud k8s  | bool | true | yes |
| random_cluster_suffix | Random 6 byte hex suffix for cluster name | string |  | true |
| oci_region | Oracle Cloud region | string | eu-frankfurt-1 | true |
| oci_user_ocid | Oracle Cloud User OCID | string |   | yes |
| oci_tenancy_ocid | Oracle Cloud Tenancy OCID | string |  | yes |
| oci_private_key_path | Path to your OCI private key | string | ~/.oci/oci_api_key.pem | yes |
| oci_public_key_path | Path to your OCI public key | string | ~/.oci/oci_api_key_public.pem | yes |
| oci_fingerprint | OCI public key fingerprint | string |   | yes |
| lbs | Count of 8-bit numbers of LoadBalancer base_cidr_block | number | 10 | yes |
| oci_cidr_block | OCI VCN CIDR block | string | 10.0.0.0/16 | yes |
| oci_subnets | Count of 8-bit numbers of subnets base_cidr_block | number | 2 | yes |
| oci_policy_statements | OCI Policy Statements in policy language | list(string) | "Allow service OKE to manage all-resources in tenancy" | yes |
| oci_cluster_name | Oracle Cloud OKE Kubernetes cluster name | string | k8soci | yes |
| oci_node_pool_name | Oracle Cloud OKE Kubernetes node pool name | string | k8s-nodepool-oci | yes |
| oci_cluster_add_ons_kubernetes_dashboard | Enable the Kubernetes Dashboard | bool | false | yes |
| oci_cluster_add_ons_tiller | Enable Tiller for helm | bool | false | yes |
| oke_node_pool_size | OKE Kubernetes worker node pool quantity per subnet | number | 2 | yes |
| oci_node_pool_node_shape | OCI Kubernetse node pool Shape | string | VM.Standard2.1 | yes |
| oci_subnet_prohibit_public_ip_on_vnic | OCI VCN subnet prohibits assigning public IPs or not | bool | true | yes |
| oci_node_pool_ssh_public_key | SSH public key to add to each node in the node pool | string | ~/.ssh/id_rsa.pub | yes |
| oci_node_pool_node_image_name | OCI Kubernetes node pool image name | string | Oracle-Linux-7.6 | yes | 



## Outputs

| Name | Description |
|------|-------------|
| kubernetes_version | Latest available Kubernetes version on Oracle Cloud |
| kubeconfig_path_oci | generated kubeconfig file name |
