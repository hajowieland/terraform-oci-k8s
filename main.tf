resource "random_id" "cluster_name" {
  count       = var.enable_oracle ? 1 : 0
  byte_length = 6
}

resource "random_id" "username" {
  count       = var.enable_oracle ? 1 : 0
  byte_length = 14
}

resource "random_id" "password" {
  count       = var.enable_oracle ? 1 : 0
  byte_length = 18
}

## Get your workstation external IPv4 address:
data "http" "workstation-external-ip" {
  count = var.enable_oracle ? 1 : 0
  url   = "http://ipv4.icanhazip.com"
}

locals {
  count                     = var.enable_oracle ? 1 : 0
  workstation-external-cidr = "${chomp(data.http.workstation-external-ip.0.body)}/32"
}

/**
 * Get the avaialbility domains for this tennancy.
 * Using any compartment id in this tennancy should also work just as well. 
 */
data "oci_identity_availability_domains" "ads" {
  count          = var.enable_oracle ? 1 : 0
  compartment_id = var.oci_tenancy_ocid
}

data "oci_containerengine_cluster_option" "cluster_option" {
  count = var.enable_oracle ? 1 : 0
  #Required
  cluster_option_id = "all"
}

# Create random id
resource "random_id" "vnc_dns_randid" {
  count       = var.enable_oracle ? 1 : 0
  byte_length = 1
}

# Identity Policy
resource "oci_identity_policy" "test_policy" {
  count = var.enable_oracle ? 1 : 0

  compartment_id = var.oci_tenancy_ocid
  description    = "Allow OKE to manage all resources"
  name           = "k8spolicy"
  statements     = var.oci_policy_statements

  freeform_tags = { "Project" = "K8s" }
  #version_date = "${var.policy_version_date}"
}

# VCN
/*
 * Create a VCN. 
 * A DNS label with the name of the cluster is attached to the VCN.
 * The creation of the vcn also creates the default route table, security list, and dhcp options.
 */
resource "oci_core_vcn" "oke-vcn" {
  count          = var.enable_oracle ? 1 : 0
  cidr_block     = var.oci_cidr_block
  compartment_id = var.oci_tenancy_ocid

  display_name  = "${var.oci_cluster_name}_vcn"
  dns_label     = "${var.oci_cluster_name}vcn${random_id.vnc_dns_randid.0.dec}"
  freeform_tags = { "Project" = "k8s" }
}

/*
 * An internet gateway is created in the relevant compartment attached to the created VCN. 
 */
resource "oci_core_internet_gateway" "oke-igw" {
  count          = var.enable_oracle ? 1 : 0
  compartment_id = var.oci_tenancy_ocid
  display_name   = "${var.oci_cluster_name}-igw"
  vcn_id         = oci_core_vcn.oke-vcn.0.id
}

/*
 * Configures the default route table that was created when the VCN was created.
 * The default route is pointed to the internet gateway that was created. 
 */
resource "oci_core_default_route_table" "oke-default-rt" {
  count                      = var.enable_oracle ? 1 : 0
  manage_default_resource_id = oci_core_vcn.oke-vcn.0.default_route_table_id
  display_name               = "${var.oci_cluster_name}-default-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.oke-igw[0].id
  }
}

/*
 * Configures the default dhcp options object that was created along with the VCN.
 */
resource "oci_core_default_dhcp_options" "oke-default-dhcp-options" {
  count                      = var.enable_oracle ? 1 : 0
  manage_default_resource_id = oci_core_vcn.oke-vcn.0.default_dhcp_options_id
  display_name               = "${var.oci_cluster_name}-default-dhcp-options"

  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }
}

/*
 * Configures the default security list.
 */
resource "oci_core_default_security_list" "oke-default-security-list" {
  count                      = var.enable_oracle ? 1 : 0
  manage_default_resource_id = oci_core_vcn.oke-vcn.0.default_security_list_id
  display_name               = "${var.oci_cluster_name}-default-security-list"

  // allow outbound tcp traffic on all ports
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  // allow inbound ssh traffic
  ingress_security_rules {
    protocol  = "6" // tcp
    source    = local.workstation-external-cidr
    stateless = false

    tcp_options {
      min = 22
      max = 22
    }
  }

  // allow inbound icmp traffic of a specific type
  ingress_security_rules {
    protocol = 1
    source   = "0.0.0.0/0"

    icmp_options {
      type = 3
      code = 4
    }
  }
}

/*
 * Security list for the worker subnets.
 *  - Stateless ingress/egress rule-pairs for the worker subnets. this lets traffic between the worker
 *    nodes flow freely. Stateless rule.
 *  - Contains a stateful rule to allow traffic to the internet - like for pulling docker images from 
 *    DockerHub
 *  - Conatins two ingress rules to allow SSH traffic from OCI Cluster service.
 */
resource "oci_core_security_list" "oke-worker-security-list" {
  count          = var.enable_oracle ? var.oci_subnets : 0
  compartment_id = var.oci_tenancy_ocid
  display_name   = "${var.oci_cluster_name}-Workers-SecList"
  vcn_id         = oci_core_vcn.oke-vcn.0.id

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6" // outbound TCP to the internet
    stateless   = false
  }

  egress_security_rules {
    destination = cidrsubnet(var.oci_cidr_block, 8, count.index)
    protocol    = "all"
    stateless   = true
  }

  ingress_security_rules {
    # Intra VCN traffic - this lets the 3 subnets in teh 3 ADs tak to each other without restriction.
    # These are stateless, so they need to be accompanied by stateless egress rules.
    stateless = true

    protocol = "all"
    source   = cidrsubnet(var.oci_cidr_block, 8, count.index)
  }

  ingress_security_rules {
    # ICMP 
    protocol = 1
    source   = "0.0.0.0/0"

    icmp_options {
      type = 3
      code = 4
    }
  }
  ingress_security_rules {
    # OCI Cluster service
    protocol  = "6" // tcp
    source    = "130.35.0.0/16"
    stateless = false

    tcp_options {
      min = 22
      max = 22
    }
  }
  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "138.1.0.0/17"
    stateless = false

    tcp_options {
      min = 22
      max = 22
    }
  }
  # NodePort ingress rules
  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "0.0.0.0/0"
    stateless = true

    tcp_options {
      min = 30000
      max = 32767
    }
  }
  # SSH Stateful ingress rules
  ingress_security_rules {
    protocol  = "6" // tcp
    source    = local.workstation-external-cidr
    stateless = false

    tcp_options {
      min = 22
      max = 22
    }
  }
}

/*
 * Security list for the loadbalancer subnets.
 * - Allows all TCP traffic in/out.
 */
resource "oci_core_security_list" "oke-lb-security-list" {
  count          = var.enable_oracle ? 1 : 0
  compartment_id = var.oci_tenancy_ocid
  display_name   = "${var.oci_cluster_name}-LoadBalancers-SecList"
  vcn_id         = oci_core_vcn.oke-vcn.0.id

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"
    stateless   = true
  }
  ingress_security_rules {
    protocol  = "6"
    source    = "0.0.0.0/0"
    stateless = true
  }
}

resource "oci_core_subnet" "oke-subnet-worker" {
  count               = var.enable_oracle ? var.oci_subnets : 0
  availability_domain = lookup(data.oci_identity_availability_domains.ads.0.availability_domains[0], "name")
  #cidr_block          = "${var.oci_vcn_cidr_prefix}.10.0/24"
  cidr_block        = cidrsubnet(var.oci_cidr_block, 8, var.oci_subnets + count.index)
  display_name      = "${var.oci_cluster_name}-WorkerSubnet${count.index}"
  dns_label         = "workers${count.index}"
  compartment_id    = var.oci_tenancy_ocid
  vcn_id            = oci_core_vcn.oke-vcn.0.id
  security_list_ids = [
    oci_core_security_list.oke-worker-security-list[0].id]
  route_table_id    = oci_core_vcn.oke-vcn.0.default_route_table_id
  dhcp_options_id   = oci_core_vcn.oke-vcn.0.default_dhcp_options_id
}

resource "oci_core_subnet" "oke-subnet-loadbalancer" {
  count               = var.enable_oracle ? 2 : 0
  availability_domain = lookup(data.oci_identity_availability_domains.ads.0.availability_domains[0], "name")
  #cidr_block          = "${var.oci_vcn_cidr_prefix}.20.0/24"
  cidr_block        = cidrsubnet(var.oci_cidr_block, 8, var.lbs + count.index)
  display_name      = "${var.oci_cluster_name}-LB-Subnet${count.index}"
  dns_label         = "lb${count.index}"
  compartment_id    = var.oci_tenancy_ocid
  vcn_id            = oci_core_vcn.oke-vcn.0.id
  security_list_ids = [
    oci_core_security_list.oke-lb-security-list[0].id]
  route_table_id    = oci_core_vcn.oke-vcn.0.default_route_table_id
  dhcp_options_id   = oci_core_vcn.oke-vcn.0.default_dhcp_options_id
}

# Container Engine for Kubernetes cluster
resource "oci_containerengine_cluster" "oke" {
  count = var.enable_oracle ? 1 : 0

  compartment_id     = var.oci_tenancy_ocid
  kubernetes_version = data.oci_containerengine_cluster_option.cluster_option[count.index].kubernetes_versions[length(data.oci_containerengine_cluster_option.cluster_option[count.index].kubernetes_versions) - 1]
  name               = "${var.oci_cluster_name}-${random_id.cluster_name[count.index].hex}"
  vcn_id             = oci_core_vcn.oke-vcn.0.id

  options {
    service_lb_subnet_ids = [
      for subnet in oci_core_subnet.oke-subnet-loadbalancer.*.id :
      subnet
    ]
    add_ons {
      is_kubernetes_dashboard_enabled = var.oci_cluster_add_ons_kubernetes_dashboard
      is_tiller_enabled               = var.oci_cluster_add_ons_tiller
    }
  }
}

# Container Engine for Kubernetes Node Pool
resource "oci_containerengine_node_pool" "oke_node_pool" {
  count = var.enable_oracle ? 1 : 0

  cluster_id         = oci_containerengine_cluster.oke.0.id
  compartment_id     = var.oci_tenancy_ocid
  kubernetes_version = data.oci_containerengine_cluster_option.cluster_option[count.index].kubernetes_versions[length(data.oci_containerengine_cluster_option.cluster_option[count.index].kubernetes_versions) - 1]
  name               = var.oci_node_pool_name
  node_image_name    = var.oci_node_pool_node_image_name
  node_shape         = var.oci_node_pool_node_shape
  subnet_ids         = oci_core_subnet.oke-subnet-worker[*].id

  #Optional
  #node_image_name = "${var.node_pool_node_image_name}"
  #initial_node_labels {

  #Optional
  #key = "${var.node_pool_initial_node_labels_key}"
  #value = "${var.node_pool_initial_node_labels_value}"
  #}
  #node_metadata = "${var.oci_node_pool_node_metadata}"
  quantity_per_subnet = var.oke_node_pool_size
  #ssh_public_key = "${file(var.oci_node_pool_ssh_public_key)}"

}

data "oci_containerengine_cluster_kube_config" "kube_config" {
  count = var.enable_oracle ? 1 : 0

  cluster_id = oci_containerengine_cluster.oke.0.id
}

resource "local_file" "kubeconfigoci" {
  count = var.enable_oracle ? 1 : 0

  content  = data.oci_containerengine_cluster_kube_config.kube_config.0.content
  filename = "${path.module}/kubeconfig_oci"
}

###
# Workaround to destroy cleanly with Terraform
# Otherwise terraform destroy does not complete
###


#data "oci_containerengine_node_pool" "oke_node_pool" {
#    node_pool_id = "${oci_containerengine_node_pool.oke_node_pool.id}"
#}

#data "oci_core_instance" "test_instance" {
#    instance_id = "${data.oci_core_instance.oke_node_pool.node.0.id}"
#}

#data "oci_core_vnic_attachments" "test_vnic_attachments" {
#    compartment_id = var.oci_tenancy_ocid
#
#    instance_id = "${data.oci_core_instance.test_instance.id}"
#}
