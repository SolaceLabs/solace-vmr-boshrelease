Files within the deployments directory are used for testing the Bosh release directly by developers (IE. without
going through Pivotal's Operation Manager)

cleanup.sh -- helps cleanup a recent deployment to bosh lite (deletes deployment, release, orphaned disks) , also delete build.sh produced artifacts.

To test with a local http test server (test-http-server), you need to set these values in the deployment manifest:
    broker_user: 'test_user-1212'
    broker_password: 'test_password-2323'
    broker_hostname: '10.254.50.4'
