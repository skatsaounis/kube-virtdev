if [[ "$@" == "--hard" ]]; then
    virsh destroy --domain controller
    virsh undefine controller
    virsh destroy --domain worker-0
    virsh undefine worker-0
    virsh destroy --domain worker-1
    virsh undefine worker-1
    rm /var/lib/libvirt/images/controller-vol.img
    rm /var/lib/libvirt/images/worker0-vol.img
    rm /var/lib/libvirt/images/worker1-vol.img

    virsh net-destroy internal-net
    rm internal-net

    rm ~/.ssh/dummy_key*

    rm /var/lib/libvirt/images/bionic-server-cloudimg-amd64.img

    rm /var/lib/libvirt/images/config-controller.iso
    rm /var/lib/libvirt/images/config-worker0.iso
    rm /var/lib/libvirt/images/config-worker1.iso
fi

rm -rf controller-config
rm -rf worker0-config
rm -rf worker1-config
rm *.iso
