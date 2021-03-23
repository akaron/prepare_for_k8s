# purpose

Prepare the iso file `ubuntu-18.04.5-live-server-amd64.iso` for installation of kubeadm,
kubectl, and kubelet. The result environment should be ready to run `kubeadm init` to
start or join a cluster.

Assume the node is fresh, only network is configured and an account is configured. Near
the end of script, you may need to change the name `kai` to the account name in your
system.

Tested in VMs in VMware.


# Good practice for machines in VMWare

In VMware, after successfully run this script, make a template (NOT snapshot).  This is
because the updates and processes may take more than 10 minutes.  Next time, just create a
VM out of the template, then change the network configurations.
