# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

# Require a recent version of vagrant otherwise some have reported errors 
# setting host names on boxes
Vagrant.require_version ">= 1.7.2"

CONFIG = {
  "box" =>	            ENV['box'] || "generic/ubuntu2304",
  "domain" =>               ENV['CLUSTER_DOMAIN'] || "c1.k8s.work",
  "network_name" =>         ENV['CLUSTER_NETWORK'] || "c1",
  "network_cidr" =>         ENV['CLUSTER_CIDR'] || "192.168.201.0/24",
  "domain_mac_seed" =>      ENV['DOMAIN_MAC_SEED'] || "52:54:30:00",
  "num_cp_nodes" =>         ENV['NUM_CP'] || "1",
  "cp_cores" =>             ENV['CP_CORES'] || "8",
  "cp_memory"  =>           ENV['CP_MEMORY'] || "16384",
  "cp_disk" =>              ENV['CP_DISK'] || "100", 
  "cp_mac" =>               ENV['CP_MAC'] || ":02",
  "num_worker_nodes" =>     ENV['NUM_WORKER'] || "3",
  "worker_cores" =>         ENV['WORKER_CORES'] || "8",
  "worker_memory"  =>       ENV['WORKER_MEMORY'] || "16384",
  "worker_disk" =>          ENV['WORKER_DISK'] || "100", 
  "worker_mac" =>           ENV['WORKER_MAC'] || ":03",
}

hwe_kernel = %{
apt update -qq
apt install -y -qq linux-{image,headers,tools}-generic-hwe-20.04
}

fix_dns = %{
  sudo sed -i -e '/nameservers:/d' -e '/addresses:/d' /etc/netplan/01-netcfg.yaml
  chmod -R 600 /etc/netplan
  sudo netplan generate && sudo netplan apply
  sudo sed -i 's/^[[:alpha:]]/#&/' /etc/systemd/resolved.conf
  sudo systemctl restart systemd-resolved.service
}

server = %{

mkdir -p /etc/rancher/rke2/

echo "
write-kubeconfig-mode: "0644"
tls-san:
  - "cp01.c1.k8s.work"
token: vagrant-rke2
cni: cilium
kube-apiserver-arg:
  - "feature-gates=TopologyAwareHints=true,JobTrackingWithFinalizers=true"
kube-controller-manager-arg:
  - "feature-gates=TopologyAwareHints=true,JobTrackingWithFinalizers=true"
disable-kube-proxy: true
disable:
 - rke2-kube-proxy
" >> /etc/rancher/rke2/config.yaml

mkdir -p /var/lib/rancher/rke2/server/manifests/

echo "
---
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-cilium
  namespace: kube-system
spec:
  valuesContent: |-
    kubeProxyReplacement: true
    k8sServiceHost: cp01.c1.k8s.work
    k8sServicePort: 6443
    hubble:
      enabled: true
      relay:
        enabled: true
      ui:
        enabled: true
    ingressController:
      enabled: true
      loadbalancerMode: dedicated

" >> /var/lib/rancher/rke2/server/manifests/rke2-cilium-config.yaml

curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION=v1.28.2+rke2r1 sh -
systemctl enable --now rke2-server.service

mkdir -p /home/vagrant/.kube
cp /etc/rancher/rke2/rke2.yaml /home/vagrant/.kube/config
sed -i 's/127\.0\.0\.1/192.168.201.21/' /home/vagrant/.kube/config
sed -i 's/default/rke2/' /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config
}

brew = %{
mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
chown -R vagrant ~/homebrew
test -d ~/homebrew && eval "$(~/homebrew/bin/brew shellenv)"
sudo apt-get -qq update
sudo apt-get install build-essential procps curl file git -qqqy -o Dpkg::Progress-Fancy="0" -o APT::Color="0" -o Dpkg::Use-Pty="0"
brew install --quiet kubectl
echo "eval \\"\\$\($\(brew --prefix\)/bin/brew shellenv\)\\"" >> ~/.bashrc
}

agent = %{

mkdir -p /etc/rancher/rke2/

echo "
server: https://cp01.c1.k8s.work:9345
token: vagrant-rke2
" >> /etc/rancher/rke2/config.yaml

curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION=v1.28.2+rke2r1 sh -

systemctl enable --now rke2-agent.service

}

c1_xml = %{
<network xmlns:dnsmasq='http://libvirt.org/schemas/network/dnsmasq/1.0' ipv6='yes'>
  <name>c1</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <domain name='c1.k8s.work'/>
  <dns>
    <host ip='192.168.201.1'>
      <hostname>api-int.c1.k8s.work</hostname>
      <hostname>api.c1.k8s.work</hostname>
    </host>
  </dns>
  <ip address='192.168.201.1' netmask='255.255.255.0' localPtr='yes'>
    <dhcp>
      <range start='192.168.201.2' end='192.168.201.9'/>
      <host mac='52:54:30:00:02:01' name='cp01.c1.k8s.work' ip='192.168.201.21'/>
      <host mac='52:54:30:00:03:01' name='worker01.c1.k8s.work' ip='192.168.201.31'/>
      <host mac='52:54:30:00:03:02' name='worker02.c1.k8s.work' ip='192.168.201.32'/>
      <host mac='52:54:30:00:03:03' name='worker03.c1.k8s.work' ip='192.168.201.33'/>
      <bootp file='pxelinux.0' server='192.168.201.1'/>
    </dhcp>
  </ip>
  <dnsmasq:options>
    <dnsmasq:option value='cname=*.apps.c1.k8s.work,apps.c1.k8s.work,api.c1.k8s.work'/>
    <dnsmasq:option value='auth-zone=c1.k8s.work'/>
    <dnsmasq:option value='auth-server=c1.k8s.work,*'/>
  </dnsmasq:options>
</network>
}


Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.ssh.insert_key = false
  config.vm.box = "#{CONFIG['box']}"
  config.vm.provision "shell", name: "fix_dns", run: "once", inline: fix_dns
#  config.vm.provision "shell", name: "hwe_kernel", run: "once", privileged: true, reboot: true, inline: hwe_kernel
  config.trigger.before :up do |trigger|
    trigger.name = "vmnet"
    trigger.info = "defining management network"
    trigger.ruby do |env|
      require 'libvirt'
      conn = Libvirt::open('qemu:///system')
      begin
        net = conn.define_network_xml(c1_xml)
        net.create
      rescue Libvirt::DefinitionError
        p "network already defined"
      end
      conn.close
      end
    end

  CP = (CONFIG['num_cp_nodes']).to_i
  (1..CP).each do |i|
    vm_name = "cp0#{i}"
    vm_fqdn = "#{vm_name}.#{CONFIG['domain']}"
    vm_cpu = CONFIG['cp_cores']
    vm_cidr = CONFIG['network_cidr']
    vm_memory = CONFIG['cp_memory']
    vm_disk = CONFIG['cp_disk']
    vm_mac = "#{CONFIG['domain_mac_seed']}#{CONFIG['cp_mac']}:0#{i}"
    config.vm.define vm_name do |node|
      node.vm.hostname = "#{vm_fqdn}"
      node.vm.provision "shell", name: "rke2-server", run: "once", privileged: true, inline: server
      node.vm.provision "shell", name: "k9s", run: "once", privileged: false, inline: brew
      node.vm.network "public_network",
        :dev => "bridge0",
        :type => "bridge",
        :ip => "192.168.1.21"
      node.vm.provider :libvirt do |domain|
        domain.cpus = "#{vm_cpu}".to_i
        domain.driver = 'kvm'
        domain.machine_virtual_size = "#{vm_disk}".to_i
        domain.management_network_mac = vm_mac
        domain.management_network_name = CONFIG['network_name']
        domain.management_network_address = CONFIG['network_cidr']
        domain.memory = "#{vm_memory}".to_i
        domain.uri = 'qemu+unix:///system'
      end
    end
  end


  WORKER = (CONFIG['num_worker_nodes']).to_i
  (1..WORKER).each do |i|
    vm_name = "worker0#{i}"
    vm_fqdn = "#{vm_name}.#{CONFIG['domain']}"
    vm_cpu = CONFIG['worker_cores']
    vm_memory = CONFIG['worker_memory']
    vm_disk = CONFIG['worker_disk']
    vm_mac = "#{CONFIG['domain_mac_seed']}#{CONFIG['worker_mac']}:0#{i}"
    config.vm.define vm_name, autostart: true do |node|
      node.vm.hostname = "#{vm_fqdn}"
      node.vm.provision "shell", name: "rke2-agent", run: "once", privileged: true, inline: agent
      node.vm.network "public_network",
        :dev => "bridge0",
        :type => "bridge",
        :ip => "192.168.1.3#{i.to_s}"
      node.vm.provider :libvirt do |domain|
        domain.cpus = "#{vm_cpu}".to_i
        domain.driver = 'kvm'
        domain.machine_virtual_size = "#{vm_disk}".to_i
        domain.management_network_mac = vm_mac
        domain.management_network_name = CONFIG['network_name']
        domain.management_network_address = CONFIG['network_cidr']
        domain.memory = "#{vm_memory}".to_i
        domain.uri = 'qemu+unix:///system'
      end
    end
  end
end