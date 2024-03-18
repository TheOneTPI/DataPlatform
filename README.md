# DataPlatform

This is a repository for creating a Data Platform on Kubernetes with Open-Source software or Community edition.

Object storage S3 --> Minio : https://min.io/

Database storage --> PostgreSQL : https://www.postgresql.org/

SQL engine --> Trino : https://trino.io/

Table format --> Iceberg : https://iceberg.apache.org/

Metastore for Iceberg --> Hive Metastore Service (HMS) : https://hive.apache.org/

# Table of Contents
1. [General information](#General-information)
2. [Object storage - Minio](#Object-storage---Minio)
3. [Database PostgreSQL - Test](#Database-PostgreSQL---Test)
4. [Metastore for Iceberg - HMS](#Metastore-for-Iceberg---HMS)
5. [SQL engine - Trino](#SQL-engine---Trino)
6. [Benchmark](#Benchmark)


## General information

All of this work has been deployed on a development Kubernetes engine (minikube) with a single node.

### Minikube
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

### Helm & kubectl

I use Kubernetes/Docker standard tools to deploy any pods --> kubectl / helm.

Helm repository ->
| Repository name | URL |
| --------------- | --- |
| bitnami | https://charts.bitnami.com/bitnami |
| trino | https://trinodb.github.io/charts/ |
| jetstack | https://charts.jetstack.io |
| rancher-latest | https://releases.rancher.com/server-charts/latest |
| minio | https://operator.min.io/ |

### Rancher UI

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

> :memo: At the first connection the bootstrap password will be asked and you will be able to change to another great passwork as you like ;-)

### Create namespace

```shell
kubectl create namespace minio-operator
kubectl create namespace minio-iceberg
kubectl create namespace postgres-test
kubectl create namespace hms
kubectl create namespace trino
```

## Object storage - Minio

I use Minio kubernetes operator to administrate Minio. The `minio_operator_values.yaml` contains only ingress.

### Deploy operator
```shell
helm install -n minio minio-operator minio/operator -f ./minio/minio_operator_values.yaml
```

### Deploy tenant
Then I create a tenant to store buckets.  The `minio_tenant_values.yaml` contains only needed configuration for prototype environment like `volumesPerServer` or `size`, etc...

```shell
helm install -n minio-iceberg minio-tenant minio/tenant -f ./minio/minio_tenant_values.yaml
```

### Deploy ingress
Create ingress to allow accessing the console for operator and also for tenant.
```shell
kubectl apply -f ./minio/ingress_services.yaml
```

### Create buckets & access key in tenant
Create 2 buckets in tenant using the web console.

<img src="/asset/minio_buckets.png" alt="Buckets" style="width:500px;"/>

Create an access key for Trino and HMS.

<img src="/asset/minio_accesskey.png" alt="Access Key" style="width:700px;"/>

## Database PostgreSQL - Test

I create a PostgreSQL instance to store prototype data.

1) Create & deploy a secret for postgres user password
```shell
kubectl apply --namespace postgres-test -f ./postgresql_test/postgresql_test_secret.yaml
```

2) Deploy PostgreSQL instance
```shell
helm install -n postgres-test my-postgres-test oci://registry-1.docker.io/bitnamicharts/postgresql -f ./postgresql_test/values_pg_test.yaml
```

3) Create a node port service.
> :memo: This one can be usefull to browse the instance using DBeaver for example.
```shell
kubectl apply -n postgres-test -f ./postgresql_test/postgresql_test_nodeport.yaml
```
If you want to access the node port in WSL2, you need to create a port forward.
```shell
minikube service -n postgres-test postgresql-test-nodeport
```
> :memo: Note the port number to use it into DBeaver with `localhost`.

## Metastore for Iceberg - HMS

### Create image
For Hive Metastore we need to create the docker image using a dockerfile. The dockerfile contains binaries for HMS and also a copy of `run.sh`. This script uses environment variables and creates configuration for HMS when the image starts.

```shell
# docker build
docker build ./hms/create_image/ -t tpipino/hms:latest

# push to docker hub (replace with your repo)
docker push tpipino/hms:latest
```

### Deploy PostgreSQL instance
HMS needs a storage to kept informations for table schema like columns, statistics, format, etc...
We deploy it like the PostgreSQL test instance.
```shell
# secret
kubectl apply --namespace hms -f ./hms/postgresql_hms_secret.yaml

# deploy
helm install -n hms my-postgres-hms oci://registry-1.docker.io/bitnamicharts/postgresql -f ./hms/values_pg_hms.yaml

# nodeport
kubectl apply -n hms -f ./hms/postgresql_hms_nodeport.yaml
```

### Deploy HMS instance
I create a Helm chart for HMS using the docker image and also add the environment variables to interface HMS with S3 bucket and PostgreSQL into a specific yaml values.

```shell
helm install -n hms my-hms ./hms/hms_helm/ -f ./hms/values_hms.yaml
```

## SQL engine - Trino
The values file `./trino/trino_values.yaml` contains many informations like RAM for worker or JVM (be sure that JVM memory doesn't exceed the Worker/Coordinator memory) and also connections (named catalogs in trino). 

```shell
helm install -n trino my-trino-cluster trino/trino -f ./trino/trino_values.yaml
```

You now can use trino throw DBeaver using the url in `ingress` value.
<img src="/asset/trino_dbeaver.png" alt="Access Key" style="width:300px;"/>

The url can be used in your browser to access the web ui, it's only contains monitoring informations like "workers on", "sql requests failed", "sql requests running", etc...
> :memo: At this point there is no user/passwork for trino webui so you can connect using any user as you want.
<img src="/asset/trino_webui.png" alt="Access Key" style="width:700px;"/>

## Benchmark
