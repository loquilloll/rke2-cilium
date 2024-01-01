

vagrant destroy --force && vagrant up
ssh-keygen -R '192.168.201.21' ~/.ssh/known_hosts
scp -i /home/alvins/.vagrant.d/insecure_private_keys/vagrant.key.rsa vagrant@192.168.201.21:.kube/config /tmp/rke2.yaml
kubecm merge -y /tmp/rke2.yaml