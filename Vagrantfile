require 'yaml'

BOX_IMAGE = "bento/centos-7"

if File.exist?('config.yml')
  CONFIG = YAML.load_file('config.yml')
else
  CONFIG = YAML.load_file('config.yml.default')
end


Vagrant.configure("2") do |config|
  config.vm.box = BOX_IMAGE
  config.vm.provision "shell", path: "provision.sh"

  CONFIG["machines"].each do |machine_config|
    config.vm.define machine_config["name"] do |n|
      n.vm.hostname = machine_config["name"]

      n.vm.network "private_network", ip: machine_config["private_ip"]
      n.vm.network "forwarded_port", id: "ssh", guest: 22, host: machine_config["ssh_forward_port"]

      n.vm.provider "virtualbox" do |vb|
        vb.cpus = machine_config["cpus"]
        vb.memory = machine_config["memory_mb"]

        if machine_config.has_key?("external_disks")
          machine_config["external_disks"].each_with_index do |disk_config, num|
            disk_path = "./#{machine_config["name"]}_disk#{num+1}.vdi"
            if not File.exist?(disk_path)
              vb.customize ["createvdi", "--filename", disk_path, "--size", disk_config["size_mb"]]
            end
            vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', num+1, '--device', 0, '--type', 'hdd', '--medium', disk_path]
          end
        end
      end
    end
  end
end
