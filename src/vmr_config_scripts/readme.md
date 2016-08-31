# VMR Configuration Scripts
Configures a VMR into a state where it is ready to be assigned to a Cloud Foundry Service Broker service plan.

## Usage
To configure a VMR :

    ./rs-config-vmr-for-maas --cli-username <admin-user> [--cli-authkey <ssh_id_key>] [--cli-password <password>] plan=(shared|dedicated) portSeed=<startingPort> fileUserPass=<fileUser> adminPass=<fileUserPass>
    Description:

        admin-user: The message router's cli admin user with global access
        ssh_id_key: An SSH id private key
        password: The message router's admin user password.  Not needed when ssh_id_key is provided.
        portSeed: The starting port of the port range assigned to the VMR's service.  Recommended: 7000
        fileUser: The username of the user to create for file transfer.  The script creates this user for subsequent file transfers, such as server certificate and Trusted CA Certificates.
        fileUserPass: The password to give the file user created by this script.