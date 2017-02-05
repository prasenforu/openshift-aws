# openshift-aws



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

for node in {ose-master,ose-hub,ose-node1}; do
echo "Installing Docker on $node" && \
ssh $node "sudo yum -y install docker"
ssh $node "systemctl enable docker"
ssh $node "systemctl start docker"
done 

# 4. Configure the Docker registry on the master host to allow insecure (no-certificate) connections to the Docker registries in all hosts. (Run in all host)

sed -i "s/OPTIONS.*/OPTIONS='--selinux-enabled --insecure-registry 172.30.0.0\/16'/" /etc/sysconfig/docker

# 5. install openshift utility package

yum -y install atomic-openshift-utils

# 6. start installer

atomic-openshift-installer install
