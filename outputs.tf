output "kubernetes_version" {
  value = data.oci_containerengine_cluster_option.cluster_option.0.kubernetes_versions[length(data.oci_containerengine_cluster_option.cluster_option.0.kubernetes_versions) - 1]
}

output "kubeconfig_path_oci" {
  value = local_file.kubeconfigoci.0.filename
}
