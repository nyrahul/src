1. git clone https://github.com/accuknox/infra-misc-scripts
2. cd infra-misc-scripts-main/gcp/gke/network/net1
2. # Ensure that the variables are set properly
3. terraform init && terraform apply
4. cd infra-misc-scripts-main/gcp/gke/mgmt
4. # Ensure that the variables are set properly
5. terraform init && terraform apply
6. # At this point the cluster would be started. Now get the kubeconfig for the cluster.
7. gcloud container clusters get-credentials simple-zonal-private-cluster --zone us-central1-a --project shaped-infusion-402417
8. 
