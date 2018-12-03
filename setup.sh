# Install prerequisites
apt-get install -y \
  genisoimage qemu-kvm libvirt-bin virtinst

# Create ssh-key
ssh-keygen -t rsa -f ~/.ssh/dummy_key -N ""
ssh_key=$(cat ~/.ssh/dummy_key.pub)
echo $ssh_key

# Create config isos
master_ip=192.168.42.2
mkdir master-config
sed 's/\$domain/master/g' meta-data > master-config/meta-data
sed 's/\$domain/master/g' user-data > master-config/user-data
sed -i "s|\$ssh-key|$ssh_key|g" master-config/user-data
sed -i "s|\$private-address|$master_ip|g" master-config/user-data
genisoimage -o config-master.iso -V cidata -r -J master-config/meta-data master-config/user-data
cp config-master.iso /var/lib/libvirt/images
chown qemu:qemu /var/lib/libvirt/images/config-master.iso

node_ip=192.168.42.3
mkdir node-config
sed 's/\$domain/node/g' meta-data > node-config/meta-data
sed 's/\$domain/node/g' user-data > node-config/user-data
sed -i "s|\$ssh-key|$ssh_key|g" node-config/user-data
sed -i "s|\$private-address|$node_ip|g" node-config/user-data
genisoimage -o config-node.iso -V cidata -r -J node-config/meta-data node-config/user-data
cp config-node.iso /var/lib/libvirt/images
chown qemu:qemu /var/lib/libvirt/images/config-node.iso

# Download Bionic image
wget -nc https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img

# Create libvirt volumes
cp bionic-server-cloudimg-amd64.img /var/lib/libvirt/images/
chown qemu:qemu /var/lib/libvirt/images/bionic-server-cloudimg-amd64.img
virsh pool-refresh default
virsh vol-clone --pool default bionic-server-cloudimg-amd64.img master-vol.img
virsh vol-clone --pool default bionic-server-cloudimg-amd64.img node-vol.img
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
virt-install -n master --vcpus 4 -r 8192 \
  --network network:default --network bridge=internal-net,model=virtio \
  --disk vol=default/master-vol.img --import \
  --disk path=/var/lib/libvirt/images/config-master.iso,device=cdrom \
  --noautoconsole --os-variant=ubuntu16.04

virt-install -n node --vcpus 4 -r 8192 \
  --network network:default --network bridge=internal-net,model=virtio \
  --disk vol=default/node-vol.img --import \
  --disk path=/var/lib/libvirt/images/config-node.iso,device=cdrom \
  --noautoconsole --os-variant=ubuntu16.04
