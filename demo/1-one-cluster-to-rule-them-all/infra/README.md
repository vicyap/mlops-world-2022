## Setup

Install the following tools:

* [awscli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
* [kubectl](https://kubernetes.io/docs/tasks/tools/)
* [helm](https://helm.sh/docs/intro/install/)

Refer to [../README.md] for versions.

## Usage

### Create

To create this infrastructure, you need to run:
```
terraform init
terraform apply -auto-approve
```

**Note**: It can take several minutes (> 15 minutes) to deploy this infrastructure.

**Note**: This will create resources that will cost money.

### Destroy

Because Karpenter manages the state of node resources outside of Terraform,
Karpenter created resources will need to be de-provisioned first before
removing the remaining resources with Terraform.
```
kubectl delete deployment inflate
kubectl delete node -l karpenter.sh/provisioner-name=default
```

Remove the resources created by Terraform
```
terraform destroy -auto-approve
```