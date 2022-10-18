Creates a Fortigate and pushes configuration to the new VM then creates two servers and configures them as a web server.  It will also create a load balancer to distribute traffic between the two servers.  

To add a user in Azure to run this plan you can run the command below.

az ad sp create-for-rbac --name "SPForTerraformCLI"  --role "Contributor" --scopes="/subscriptions/subscription id"