if [[ "$@" == "--hard" ]]; then
    virsh destroy --domain master
    virsh undefine master
    virsh destroy --domain node
    virsh undefine node
    rm /var/lib/libvirt/images/master-vol.img
    rm /var/lib/libvirt/images/node-vol.img

    virsh net-destroy internal-net
    rm internal-net

    rm ~/.ssh/dummy_key*

    rm /var/lib/libvirt/images/bionic-server-cloudimg-amd64.img

    rm /var/lib/libvirt/images/config-master.iso
    rm /var/lib/libvirt/images/config-node.iso
fi

rm -rf master-config
rm -rf node-config
rm *.iso
