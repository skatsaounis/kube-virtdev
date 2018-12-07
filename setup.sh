# Setting locale
export LC_ALL='en_US.UTF-8'

# Install prerequisites
apt-get install -y \
  genisoimage qemu-kvm libvirt-bin virtinst

# Create ssh-key
ssh-keygen -t rsa -f ~/.ssh/dummy_key -N ""
ssh_key=$(cat ~/.ssh/dummy_key.pub)
echo $ssh_key

# Create config isos
controller_ip=192.168.42.2
mkdir controller-config
sed 's/\$domain/controller/g' meta-data > controller-config/meta-data
sed 's/\$domain/controller/g' user-data > controller-config/user-data
sed -i "s|\$ssh-key|$ssh_key|g" controller-config/user-data
sed -i "s|\$private-address|$controller_ip|g" controller-config/user-data
genisoimage -o config-controller.iso -V cidata -r -J controller-config/meta-data controller-config/user-data
cp config-controller.iso /var/lib/libvirt/images
#chown qemu:qemu /var/lib/libvirt/images/config-controller.iso

worker0_ip=192.168.42.3
mkdir worker0-config
sed 's/\$domain/worker-0/g' meta-data > worker0-config/meta-data
sed 's/\$domain/worker-0/g' user-data > worker0-config/user-data
sed -i "s|\$ssh-key|$ssh_key|g" worker0-config/user-data
sed -i "s|\$private-address|$worker0_ip|g" worker0-config/user-data
genisoimage -o config-worker0.iso -V cidata -r -J worker0-config/meta-data worker0-config/user-data
cp config-worker0.iso /var/lib/libvirt/images
#chown qemu:qemu /var/lib/libvirt/images/config-worker0.iso

worker1_ip=192.168.42.4
mkdir worker1-config
sed 's/\$domain/worker-1/g' meta-data > worker1-config/meta-data
sed 's/\$domain/worker-1/g' user-data > worker1-config/user-data
sed -i "s|\$ssh-key|$ssh_key|g" worker1-config/user-data
sed -i "s|\$private-address|$worker1_ip|g" worker1-config/user-data
genisoimage -o config-worker1.iso -V cidata -r -J worker1-config/meta-data worker1-config/user-data
cp config-worker1.iso /var/lib/libvirt/images
#chown qemu:qemu /var/lib/libvirt/images/config-worker1.iso

# Download Bionic image
wget -nc https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img

# Create libvirt volumes
cp bionic-server-cloudimg-amd64.img /var/lib/libvirt/images/
#chown qemu:qemu /var/lib/libvirt/images/bionic-server-cloudimg-amd64.img
virsh pool-refresh default
virsh vol-clone --pool default bionic-server-cloudimg-amd64.img controller-vol.img
qemu-img resize /var/lib/libvirt/images/controller-vol.img +40G
virsh vol-clone --pool default bionic-server-cloudimg-amd64.img worker0-vol.img
qemu-img resize /var/lib/libvirt/images/worker0-vol.img +40G
virsh vol-clone --pool default bionic-server-cloudimg-amd64.img worker1-vol.img
qemu-img resize /var/lib/libvirt/images/worker1-vol.img +40G
virsh pool-refresh default

# Create libvirt network
cat <<EOF > internal-net
<network>
  <name>internal-net</name>
  <bridge name="internal-net" stp="on" delay="0"/>
  <ip address="192.168.42.1" netmask="255.255.255.0">
  </ip>
</network>
EOF
virsh net-create internal-net

# Create libvirt Domains
virt-install -n controller --vcpus 4 -r 8192 \
  --network network:default --network bridge=internal-net,model=virtio \
  --disk vol=default/controller-vol.img --import \
  --disk path=/var/lib/libvirt/images/config-controller.iso,device=cdrom \
  --noautoconsole --os-variant=ubuntu16.04

virt-install -n worker-0 --vcpus 4 -r 8192 \
  --network network:default --network bridge=internal-net,model=virtio \
  --disk vol=default/worker0-vol.img --import \
  --disk path=/var/lib/libvirt/images/config-worker0.iso,device=cdrom \
  --noautoconsole --os-variant=ubuntu16.04

virt-install -n worker-1 --vcpus 4 -r 8192 \
  --network network:default --network bridge=internal-net,model=virtio \
  --disk vol=default/worker1-vol.img --import \
  --disk path=/var/lib/libvirt/images/config-worker1.iso,device=cdrom \
  --noautoconsole --os-variant=ubuntu16.04

sleep 10

controller_pub_ip=$(virsh net-dhcp-leases default | grep controller | awk '{print $5}' | cut -f1 -d"/")
echo "controller ip: $controller_pub_ip"
worker0_pub_ip=$(virsh net-dhcp-leases default | grep worker-0 | awk '{print $5}' | cut -f1 -d"/")
echo "worker-0 ip: $worker0_pub_ip"
worker1_pub_ip=$(virsh net-dhcp-leases default | grep worker-1 | awk '{print $5}' | cut -f1 -d"/")
echo "worker-1 ip: $worker1_pub_ip"
