## Setup

Install the following tools:

* [awscli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
* [kubectl](https://kubernetes.io/docs/tasks/tools/)
* [helm](https://helm.sh/docs/intro/install/)

## Versions

* awscli - 2.7.4
* kubectl - 1.22
* kuberay - 0.2.0
* helm - 3.9.0
* karpenter - 0.10.1
* kubernetes - 1.22
* python - 3.8
* ray - 1.21.1
* terraform - 1.2.1

## Usage

### Create

To create this infrastructure, you need to run:
```
terraform init
terraform apply -auto-approve
```

**Note**: It can take several minutes (> 15 minutes) to deploy this infrastructure.

**Note**: This will create resources that will cost money.

### Configure Kubeconfig

```
aws eks --region us-east-1 update-kubeconfig --name mlops-world-22-demo
kubectl config set-context --current --namespace=karpenter
```

Run:

```
kubectl get po
```

You should see something like:
```
NAME                            READY   STATUS    RESTARTS   AGE
karpenter-6df4bc5d97-n9v9p      2/2     Running   0          26h
ray-operator-8445c997c8-lm8dj   1/1     Running   0          23h
ray-ray-head-type-nkdxm         1/1     Running   0          23h
ray-ray-worker-type-6kqwl       1/1     Running   0          8m11s
ray-ray-worker-type-96smc       1/1     Running   0          8m32s
```

### Connect

```
kubectl -n karpenter port-forward service/ray-ray-head 10001:10001
```

### Destroy

Because Karpenter manages the state of node resources outside of Terraform,
Karpenter created resources will need to be de-provisioned first before
removing the remaining resources with Terraform.
```
kubectl patch rayclusters/ray -p '{"metadata":{"finalizers":[]}}' --type=merge
helm uninstall ray
helm uninstall karpenter
kubectl delete po -n karpenter -l ray-cluster-name=ray
kubectl delete node -n karpenter -l karpenter.sh/provisioner-name=cpu-on-demand,karpenter.sh/provisioner-name=cpu-spot,karpenter.sh/provisioner-name=gpu
```
If deleting nodes hang, you can terminate the instances directly with:
```
aws --region us-east-1 ec2 describe-instances --filters Name=tag:karpenter.sh/discovery,Values=mlops-world-22-demo --query 'Reservations[*].Instances[*].InstanceId' --output text | xargs aws --region us-east-1 ec2 terminate-instances --instance-ids
```

Remove the resources created by Terraform
```
terraform destroy -auto-approve
```

## Demo

### Setup Watch

Setup some `watch` terminals to view the system in action.

Watch pods -- as Ray receives resource requests, it will create worker pods to
serve those requests.
```
watch kubectl get po -n karpenter
```

Watch nodes -- when Ray creates pending pods, Karpenter will find just the
right instance types for those pods.
```
watch kubectl get no -L node.kubernetes.io/instance-type,karpenter.sh/capacity-type
```

Watch Karpenter's logs -- we can view when Karpenter decides to create nodes
and when it decides to delete nodes. As Ray scales down, it will remove its
worker pods. As nodes become empty and idle, Karpenter will delete them.
```
kubectl logs -f -l app.kubernetes.io/name=karpenter -c controller
```

### Run Demo

Install `requirements.txt`.
```
pip install -r requirements.txt
```

Run the demo script:
```
python ray_demo.py
```

### Expected Behavior
