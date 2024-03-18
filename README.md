# DataPlatform

This is a repository for creating a Data Platform on Kubernetes with Open-Source software or Community edition.

Object storage S3 --> Minio : https://min.io/

Database storage --> PostgreSQL : https://www.postgresql.org/

SQL engine --> Trino : https://trino.io/

Table format --> Iceberg : https://iceberg.apache.org/

Metastore for Iceberg --> Hive Metastore Service (HMS) : https://hive.apache.org/

# Table of Contents
1. [General information](#general)
2. [Object storage - Minio](#minio)


## General information<a name="general"></a>

All of this work has been deployed on a development Kubernetes engine (minikube) with a single node.

Minikube 
- Version : v1.32.0
- Configuration
  - container-runtime : docker
  - cpus : 8
  - kubernetes-version : v1.27.11
  - memory : 12288
- Addons
  - default-storageclass
  - ingress
  - storage-provisioner

I use Kubernetes/Docker standard tools to deploy any pods --> kubectl / helm.

I deploy Rancher UI to analyze and supervize my minikube but you can do it with whatever you want.
```shell
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest

kubectl create namespace cattle-system

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.crds.yaml

helm repo add jetstack https://charts.jetstack.io

helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace

helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=myrancher.tpi.com \
  --set replicas=1 \
  --set bootstrapPassword=admin
```
The deployment creates an ingress with hostname `myrancher.tpi.com`. At this moment you can reach this URL for Rancher UI using `minikube tunnel` and add to your host file `127.0.0.1 myrancher.tpi.com`.

At the first connection the bootstrap password will be asked and you will be able to change to another great passwork as you like ;-).

## Object storage - Minio<a name="minio"></a>
