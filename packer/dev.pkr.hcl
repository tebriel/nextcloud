source "azure-arm" "dev-box" {
  subscription_id     = "8d7d1594-ccc4-4018-9cae-3a23c5519eff"

  managed_image_name = "nextcloudDev-${formatdate("YYYY-MM-DD'T'hhmmssZ", timestamp())}"
  managed_image_resource_group_name = "nextcloud"

  os_type         = "Linux"
  image_publisher = "canonical"
  image_offer     = "0001-com-ubuntu-server-focal"
  image_sku       = "20_04-lts-gen2"

  location = "East US 2"
  vm_size  = "Standard_D2s_v3"
}


build {
  sources = ["sources.azure-arm.dev-box"]

  provisioner "file" {
    source = "./scripts/letsencrypt.sh"
    destination = "/tmp/letsencrypt.sh"
  }

  provisioner "shell" {
    scripts = [
      "./scripts/nextcloud.sh",
    ]
  }

  post-processor "manifest" {
    output = "manifest.json"
    strip_path = true
  }
}

