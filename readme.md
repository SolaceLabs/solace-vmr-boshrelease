# Solace VMR Bosh Release

A BOSH release for the Solace Virtual Message Router (VMR).

## Components

| Component      | Description |
| --- | --- |
| containers     | Create the VMR Container |
| prepare_vmr    | Loads the VMR Docker images in the target host's docker registry |
| vmr_agent      | Configures the VMR into its initial state after creation |

## How to build

### Prerequisites 

Before building the Bosh Release you will need the VMR Docker images.  These docker images will be provided to you by
Solace.

### Build Procedure

Follow these steps in order to build a Bosh Release for the Solace VMR:

```
git clone https://github.com/SolaceDev/solace-vmr-boshrelease.git
cd solace-vmr-boshrelease
# Copy the docker image provided by solace into the vmr_images directory
cp /path/to/vmr-image/soltr-7.2.0.20-vmr-community-docker.tar.gz vmr_images/
./prepare.sh
./build.sh
```

Bosh will have created a tarball that contains the Bosh Release with the VMR packaged within.

## Deployment on Bosh-List 

Assuming that you already have a Bosh-Lite Vagrant VM up and running at IP 192.168.50.4, you can follow this procedure
to build, and deploy the Bosh Release for you :

```
git clone https://github.com/SolaceDev/solace-vmr-boshrelease.git
cd solace-vmr-boshrelease
# Copy the docker image provided by solace into the vmr_images directory
cp /path/to/vmr-image/soltr-7.2.0.20-vmr-community-docker.tar.gz vmr_images/
./prepare.sh
cd deployments
./runit.sh
```

At this point you will have a VMR instance up and running in Bosh-Lite with this IP : 10.244.0.3

This IP is not routables from the Vagrant host by default.  You can easily make it routable :
 
On Mac OS host :
```
sudo route add 10.244.0.0/28 192.168.50.4
```

On Windows Host :
```
route ADD 10.244.0.0 MASK 255.255.255.240 192.168.50.4
```

Then you will be able to use the VMR from the Vagrant Host.  For example, to access the VMR CLI interface, ssh to
admin@10.244.0.3 over port 2222, IE:
```
ssh -p 2222 admin@10.244.0.3
The authenticity of host '[10.244.0.3]:2222 ([10.244.0.3]:2222)' can't be established.
ECDSA key fingerprint is SHA256:hIUrMmLF5tE6VJbeaPA19bHhgwL8Nrs7xgw3+BP1tRU.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '[10.244.0.3]:2222' (ECDSA) to the list of known hosts.
Solace - Virtual Message Router (VMR)
Password:

System Software. SolOS-TR Version 7.2ha.0.260

Virtual Message Router (Message Routing Node)

Copyright 2004-2016 Solace Corporation. All rights reserved.

This is the Community Edition of the Solace VMR. To purchase the
full Enterprise Edition of this product, please contact Solace at:
http://dev.solace.com/contact-us/

b8ffcd5e-6353-4505-a538-f8fd3c8b95f5> en
b8ffcd5e-6353-4505-a538-f8fd3c8b95f5# show message-vpn *

Management Message VPN:
Message-VPN                      Local       # Unique Subscriptions  # Local
                                 Status      Local   Remote    Total   Conns
-------------------------------- -------- -------- -------- -------- -------
default                          Down            0        0        0       0
v001                             Up              5        0        5       1
```


## Deployment Manifest Explanation

The deployment manifest needs to provide the following :
* A reference to [docker boshrelease|https://github.com/cloudfoundry-community/docker-boshrelease] (At least v28)
* Must provide one static IP address to each VMR job instance.
* Must provide at least 20Gig of persistent disk size to each VMR job instance.
* Must provide the containers properties required to create the container (See deployments templates).
  * Part of the containers poperties is a Dockerfile which also defines the inital passwords for the admin, support and root users.  It is important that those passwords are changed from their default values.
* Must provide the following properties :

| Property      | Optional | Description |
| --- | --- | --- |
| starting_port   | No | The VMR will listen on a range of ports starting from this port number. |
| admin_user      | No | The username of the admin user.  Must be 'admin' in the current version. |
| admin_password  | No | The initial password that was chosen for the VMR.  Must match the admin password set in the Dockerfile (See containers properties) |
| semp_port       | No | The Port the VMR will use to listen for SEMP requests (administrative operations) |
| ssh_port        | No | The Port the VMR will listen onto for direct ssh access to the VMR's CLI |
| cert_pem        | Yes | Base64 string of a DER encoded server certificate to install on the VMR |
| private_key_pem | Yes | Base64 string of a DER encoded private key that matches the server certificate in cert_pem |
