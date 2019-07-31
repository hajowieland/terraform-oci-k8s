provider "oci" {
  alias            = "oci"
  version          = ">=3.28"
  tenancy_ocid     = var.oci_tenancy_ocid
  user_ocid        = var.oci_user_ocid
  fingerprint      = var.oci_fingerprint
  private_key_path = var.oci_private_key_path
  public_key_path  = var.oci_public_key_path
  region           = var.oci_region
}