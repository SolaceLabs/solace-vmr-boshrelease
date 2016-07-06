# VMR Configuration Bosh Release
This bosh release configures a set of Virtual Message Routers (VMR) so they can then be assigned to a Solace
Service Broker's Service Plan.

## Usage
Typically used by Operation Manager.  However, to use it directly with Bosh-Lite:

    Edit deployments/solace-vmr-warden-deployment.yml:

        find 'dedicated_vmr_list', and change the list to match the VMRs you want to be dedicated.
        find 'shared_vmr_list', and change the list to match the VMRs you want to be shared.
        upload the release to Bosh Director
        Set deployments/solace-vmr-warden-deployment.yml as the deployment manifest
        deploy the release
        run the config_vmr errand