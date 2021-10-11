Vagrant.configure("2") do |config|
  config.vm.box = "bento/centos-7"
  
  CPUS = 4
  MEMORY_MB = 1024
  SHARED_DISK_MB = 1 * 1024

  NODE1_IP = "192.168.222.91"
  NODE1_SSH_PORT = 22291
  NODE2_IP = "192.168.222.92"
  NODE2_SSH_PORT = 22292

  config.vm.define "node1" do |n|
    n.vm.hostname = "node1"
    disk_path = "./node1_disk.vdi"

    n.vm.network "private_network", ip: NODE1_IP
    n.vm.network "forwarded_port", id: "ssh", guest: 22, host: NODE1_SSH_PORT

    n.vm.provider "virtualbox" do |v|
      v.cpus = CPUS
      v.memory = MEMORY_MB

      if not File.exist?(disk_path)
        v.customize ["createvdi", "--filename", disk_path, "--size", SHARED_DISK_MB]
      end
      v.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', disk_path]
    end
  end


  config.vm.define "node2" do |n|
    n.vm.hostname = "node2"
    disk_path = "./node2_disk.vdi"
    
    n.vm.network "private_network", ip: NODE2_IP
    n.vm.network "forwarded_port", id: "ssh", guest: 22, host: NODE2_SSH_PORT

    n.vm.provider "virtualbox" do |v|
      v.cpus = CPUS
      v.memory = MEMORY_MB

      if not File.exist?(disk_path)
        v.customize ["createvdi", "--filename", disk_path, "--size", SHARED_DISK_MB]
      end
      v.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', disk_path]
    end
  end

  config.vm.provision "shell", path: "provision.sh"

end