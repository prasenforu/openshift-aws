# Openshift-aws



# Run it from DNS server

for node in {ose-master,ose-hub,ose-node1}; do
echo "Deploy SSH Key on $node" && \
scp -i prasen.pem /root/.ssh/id_rsa.pub ec2-user@$node:/home/ec2-user/.ssh/id_rsa.pub_root
ssh ec2-user@$node -i prasen.pem "sudo mv /home/ec2-user/.ssh/id_rsa.pub_root /root/.ssh/authorized_keys"
ssh ec2-user@$node -i prasen.pem "sudo chown root:root /root/.ssh/authorized_keys"
ssh ec2-user@$node -i prasen.pem "sudo chmod 600 /root/.ssh/authorized_keys"
ssh ec2-user@$node -i prasen.pem "sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config"
ssh ec2-user@$node -i prasen.pem "sudo sed -i \"s/$PasswordAuthentication no/$PasswordAuthentication yes/g\" /etc/ssh/sshd_config"
ssh ec2-user@$node -i prasen.pem "sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config"
ssh ec2-user@$node -i prasen.pem "sudo service sshd restart"
done

# Install Openshift 3.3

# 1. First Install "bash-completion" & the following tools and utilities on the master host

ssh ose-master "yum -y install wget git net-tools bind-utils iptables-services bridge-utils pythonvirtualenv gcc bash-completion"

# 2. Run yum update on the master and all the nodes:

for node in {ose-master,ose-hub,ose-node1}; do
echo "Running yum update on $node" && \
ssh $node "yum -y update"
ssh $node "yum -y wget git net-tools bind-utils"
done

# 3. Install docker in all hosts.

# 3. Install docker in all hosts.

for node in {ose-master,ose-hub,ose-node1}; do
echo "Installing Docker on $node" && \
ssh $node "sudo yum -y install docker"
ssh $node "chcon -t docker_exec_t /usr/bin/docker*"
ssh $node "chcon -Rt svirt_sandbox_file_t /var/lib"
ssh $node "chcon -Rt svirt_sandbox_file_t /var/db"
ssh $node "systemctl enable docker"
ssh $node "systemctl start docker"
done 

## Note: Above chcon is required if host OS is RHEL 7.3 nd onwards.

# 4. Configure the Docker registry on the master host to allow insecure (no-certificate) connections to the Docker registries in all hosts. (Run in all host)

sed -i "s/OPTIONS.*/OPTIONS='--selinux-enabled --insecure-registry 172.30.0.0\/16'/" /etc/sysconfig/docker

# 5. Install openshift utility package

yum -y install atomic-openshift-utils

# 6. Start installer

atomic-openshift-installer install

And follow the steps.

# 7. After Sucessfull Installation follow below steps

1.
   oc get nodes
   oc get nodes --show-labels

2.
   oc label node ose-hub.cloud-cafe.in region="infra" zone="infranodes" --overwrite
   oc label node ose-node1.cloud-cafe.in region="primary" zone="east" --overwrite
   oc label node ose-master.cloud-cafe.in region="primary" zone="west" --overwrite

3. 
   oc get nodes
   oc get nodes --show-labels

4.
   cp /etc/origin/master/master-config.yaml /etc/origin/master/master-config.yaml.original

5. Edit /etc/origin/master/master-config.yaml and Set defaultNodeSelector as follows.
   defaultNodeSelector: "region=primary"

   systemctl restart atomic-openshift-master
   systemctl status atomic-openshift-master

6. Execute below command and In annotations section, add the this line "openshift.io/node-selector: region=infra" in the default namespace object:
   oc edit namespace default

then check

   oc get namespace default -o yaml

7. Set Process logs
   journalctl -f -u atomic-openshift-master
   journalctl -f -u atomic-openshift-node

8. Authentication: By default authentication is set to deny all.

   yum install -y httpd-tools

   htpasswd -c /etc/origin/master/users.htpasswd admin
   htpasswd /etc/origin/master/users.htpasswd testuser
   htpasswd /etc/origin/master/users.htpasswd pkar

9. Edit /etc/origin/master/master-config.yaml as follows

identityProviders:
 - name: my_htpasswd_provider
 challenge: true
 login: true
 mappingMethod: claim
 provider:
 apiVersion: v1
 kind: HTPasswdPasswordIdentityProvider
 file: /etc/origin/master/users.htpasswd

10. Create Registry and Router

 echo '{"kind":"ServiceAccount","apiVersion":"v1","metadata":{"name":"registry"}}' | oc create -n default -f -
 oadm policy add-cluster-role-to-user cluster-admin admin
 oadm policy add-scc-to-user privileged system:serviceaccount:default:registry

 systemctl restart atomic-openshift-master
 systemctl status atomic-openshift-master
 oadm registry --create --credentials=/etc/origin/master/openshift-registry.kubeconfig --service-account=registry --selector='region=infra'

 oadm router router --replicas=1 --selector='region=infra' --credentials='/etc/origin/master/openshift-router.kubeconfig' --service-account=router --stats-password=<password>

11. Check status
  
  oc get pods
  oc get all
