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
kubectl create namespace security-dataplatform
kubectl create namespace data-gov
```

## Object storage - Minio

I use Minio kubernetes operator to administrate Minio. The `minio_operator_values.yaml` contains only ingress.

### Add repo to helm
```shell
helm repo add minio-operator https://operator.min.io
```

### Deploy operator
```shell
helm install -n minio-operator minio-operator minio/operator -f ./minio/minio_operator_values.yaml
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

> :memo: If you have an error "schema failed" then you have to create on the "public" schema in postgresql all table from the version 4.0.0 for HIVE. Follow this link for the SQL : https://github.com/apache/hive/blob/master/standalone-metastore/metastore-server/src/main/sql/postgres/hive-schema-4.0.0.postgres.sql#L12C1-L12C38


## Security with Keycloak and Openldap

## OpenLdap
I create a Helm chart for OpenLdap using the docker image of bitnami.

```shell
helm install -n security-dataplatform my-openldap ./openldap/openldap_helm/ -f ./openldap/values_openldap.yaml
```

## Keycloak
Keycloak is an identity manager but we need to interface it with a LDAP because some tools that we use in the Open Dataplatform is not compatible AD or OpenID Connect or other protocol.
Install it with :

```shell
helm install -n security-dataplatform my-keycloak oci://registry-1.docker.io/bitnamicharts/keycloak -f ./keycloak/values_keycloak
```

And configure it with a new realm and link it to the LDAP. You can also change some configuration like I do :
- add a smtp for registration mail
- add password policies for strong password
- ...

## SQL engine - Trino
The values file `./trino/trino_values.yaml` contains many informations like RAM for worker or JVM (be sure that JVM memory doesn't exceed the Worker/Coordinator memory) and also connections (named catalogs in trino). 

```shell
# add repo
helm repo add trino https://trinodb.github.io/charts

# secret
kubectl apply --namespace trino -f ./trino/trino_secret.yaml

kubectl create secret tls -n trino my-trino-tls-secret --key ca.key --cert ca.crt

# deploy
helm install -n trino my-trino-cluster trino/trino -f ./trino/trino_values.yaml
```

You now can use trino throw DBeaver using the url in `ingress` value.

<img src="/asset/trino_dbeaver.png" alt="Access Key" style="width:300px;"/>

The url can be used in your browser to access the web ui, it's only contains monitoring informations like "workers on", "sql requests failed", "sql requests running", etc...
> :memo: At this point there is no user/passwork for trino webui so you can connect using any user as you want.

<img src="/asset/trino_webui.png" alt="Access Key" style="width:800px;"/>

## Benchmark
Trino comes with some usefull tools to benchmark the solution "tpcds" https://www.tpc.org/tpcds/ . We use it to store same data into PostgreSQL and S3 with Iceberg. And then we perform some SQL request on PostgreSQL directly, on PostgreSQL using Trino and on Iceberg using Trino

Results :

| Request ID | Summary | PostgreSQL | PostgreSQL over Trino | Iceberg over Trino |
| ---------- | ------- | ---------- | --------------------- | ----------------- |
| 001 | Agregate 150M rows of sales by year | 2 min 25s | 1 min 38s | 4s |


## Apache ranger

Install prerequisites for Apache Ranger (PostgreSQL & Opensearch)
```shell

# POSTGRESQL
# secret
kubectl apply --namespace security-dataplatform -f ./ranger/postgresql_ranger_secret.yaml
# deploy
helm install -n security-dataplatform my-postgres-ranger oci://registry-1.docker.io/bitnamicharts/postgresql -f ./ranger/values_pg_ranger.yaml

#OPENSEARCH
helm install -n security-dataplatform opensearch opensearch/opensearch -f ./ranger/values_opensearch.yaml

```

Build the docker image for Apache Ranger
```shell
# docker build
docker build ./ranger/create_image/ -t tpipino/ranger-admin:2.5.0-SNAPSHOT


kubectl create secret generic -n security-dataplatform ranger-secret --from-file=./ranger/install_prop/ranger/install.properties
kubectl create secret generic -n security-dataplatform ranger-usersync-secret --from-file=./ranger/install_prop/ranger_usersync/install.properties

helm install -n security-dataplatform my-ranger ./ranger/ranger_helm/ -f ./ranger/values_ranger.yaml

kubectl exec -it -n security-dataplatform apache-ranger-admin-59d55855c-zdjtq -- /bin/bash



```

## Data Governance with Open-Metadata


```shell
# add repo
helm repo add open-metadata https://helm.open-metadata.org/

# secret
kubectl apply --namespace data-gov -f ./openmeta/openmeta_secret.yaml

# deploy postgresql metadata for openmeta & airflow
helm install -n data-gov my-postgres-openmeta oci://registry-1.docker.io/bitnamicharts/postgresql -f ./openmeta/values_pg_openmeta.yaml

# deploy dependancies for openmeta (opensearch & airflow)
helm install -n data-gov openmetadata-dependencies open-metadata/openmetadata-dependencies -f ./openmeta/values_dep_openmetadata.yaml

# deploy
helm install -n data-gov openmetadata open-metadata/openmetadata -f ./openmeta/values_openmetadata.yaml




helm repo add opendatadiscovery https://opendatadiscovery.github.io/charts

# secret
kubectl apply --namespace data-gov -f ./opendatadiscovery/odd_secret.yaml
kubectl create secret tls -n data-gov my-odd-tls-secret --key ca.key --cert ca.crt

helm install -n data-gov my-postgres-odd oci://registry-1.docker.io/bitnamicharts/postgresql -f ./opendatadiscovery/values_pg_odd.yaml

helm install -n data-gov my-odd-platform opendatadiscovery/odd-platform -f ./opendatadiscovery/values_odd_platform.yaml

helm install -n data-gov my-odd-collector opendatadiscovery/odd-collector -f ./opendatadiscovery/values_odd_collector.yaml


kubectl create secret -n data-gov generic mysql-secrets --from-literal=mysql-root-password=datahub --from-literal=mysql-password=datahub
kubectl create secret -n data-gov generic neo4j-secrets --from-literal=neo4j-password=datahub --from-literal=NEO4J_AUTH=neo4j/datahub

helm repo add datahub https://helm.datahubproject.io/

helm install -n data-gov prerequisites datahub/datahub-prerequisites
helm install -n data-gov datahub datahub/datahub


```