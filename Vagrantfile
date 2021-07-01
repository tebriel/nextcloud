Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.provision :ansible do |ansible|
    ansible.playbook = "provisioning/nextcloud.yml"
  end
  # config.vm.provision :file, source: "./scripts/letsencrypt.sh", destination: "/tmp/letsencrypt.sh"
  # config.vm.provision :shell, path: "./packer/scripts/nextcloud.sh"
  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "forwarded_port", guest: 443, host: 9443
end
