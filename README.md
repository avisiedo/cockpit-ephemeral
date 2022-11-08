# cockpit ephemeral deployer

This tiny repository try to deploy cockpit for console.dot
into the ephemeral environment.

When deploying into ephemeral environmnet using crc-bonfire
it uses clowder operator, which create the secret with the
same name as the clowdapp resource (for instance `cockpit`)
which contains several configuration for the resources
requested into the clowdapp resource (such as the redis
service).
