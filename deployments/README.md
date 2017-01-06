
To support testing a bosh release directly by developers.

Requires a [bosh-lite] (https://github.com/cloudfoundry/bosh-lite) 
- Assumes installation with default networking options. 
- Scripts need to be able to target bosh: bosh target 192.168.50.4 lite

- The files in [templates](./templates/) are used to generate a bosh deployment manifest.yml
--  These files are processed with the help of the [runit.sh](./runit.sh) script.
- Files within the [static_samples](./static_samples) directory can be used directly.

- Both the [templates](./templates) and the [static_samples](./static_samples) contain parameters that assume you have installed the [Solace Service Broker](../../solace-service-broker) in a locally accessible [PCF Dev](https://pivotal.io/pcf-dev)
-- To test with a local [test http server](../../test-http-server), you need to set these values in the deployment manifest:
---    broker_user: 'test_user-1212'
---    broker_password: 'test_password-2323'
---    broker_hostname: '10.254.50.4'

Development helper scripts:

- prepareBosh.sh
-- prepares bosh-lite to access the solace bosh release, adds docker-bosh, stemcell

- runit.sh   
-- prepare bosh if not done already, adds docker-bosh, stemcell
-- Prepares a bosh deployment manifest.yml
-- Will exit if the VMR was already deployed to bosh
-- Does a build of the solace-vmr bosh release
-- uploads the release to bosh
-- deploys the release according to the generated manifest.yml

- cleanup.sh 
-- Cleanup from bosh lite deployment
--- Deletes a recent deployment to bosh lite 
--- Deletes the release
--- Deletes orphaned disks
-- Deletes build.sh and bosh release produced artifacts (Releases, Blobs, Caches, ... )

