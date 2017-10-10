# DH-3TierApp
DH 3Tier App OVA
This OVA based on Photon 2.0
https://bintray.com/vmware/photon/download_file?file_path=2.0%2FRC%2Fova%2Fphoton-custom-hw11-2.0-31bb961.ova

There are 4 VMs. 2 Web + 1 App + 1 DB

Photon OS :

chage -M -1 root
vi /etc/hostname
tdnf install iputils
systemctl start docker
systemctl enable docker



