#!/bin/bash

# ------------------------------------------------------------------------
# Copyright 2018 WSO2, Inc. (http://wso2.com)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License
# ------------------------------------------------------------------------

ECHO=`which echo`
KUBECTL=`which kubectl`

# methods
function echoBold () {
    ${ECHO} $'\e[1m'"${1}"$'\e[0m'
}

# persistent storage
echoBold 'Deleting persistent volume and volume claim...'
${KUBECTL} delete -f ../is/identity-server-volume-claims.yaml
${KUBECTL} delete -f ../volumes/persistent-volumes.yaml

# WSO2 Identity Server
echoBold 'Deleting WSO2 Identity Server deployment...'
${KUBECTL} delete -f ../is/identity-server-service.yaml
${KUBECTL} delete -f ../is/identity-server-deployment.yaml
sleep 1m

# MySQL
echoBold 'Deleting the MySQL deployment...'
${KUBECTL} delete -f ../extras/rdbms/mysql/mysql-service.yaml
${KUBECTL} delete -f ../extras/rdbms/mysql/mysql-deployment.yaml
${KUBECTL} delete -f ../extras/rdbms/mysql/mysql-persistent-volume-claim.yaml
${KUBECTL} delete -f ../extras/rdbms/volumes/persistent-volumes.yaml
sleep 1s

echoBold 'Deleting Metrics Server...'
${KUBECTL} delete -f ../autoscaling/metrics-server/deploy/1.8+

echoBold 'Deleting Autoscale...'
${KUBECTL} delete -f ../autoscaling/hpa/hpa.yaml
sleep 1s

# delete the created Kubernetes Namespace
echoBold 'Deleting Namesapce'
${KUBECTL} delete namespace wso2

# Undeployment Monitoring 
# Prometheus and Grafana

# switch the context to monitoring namespace
echoBold 'Set Default Namespace'
${KUBECTL} config set-context $(kubectl config current-context) --namespace=monitoring

echoBold 'Delete the Monitoring...'
${KUBECTL} delete -f ../autoscaling/prometheus/prometheus-deployment.yaml
sleep 1s

echoBold 'Delete the Monitoring Services...'
${KUBECTL} delete -f ../autoscaling/prometheus/prometheus-service.yaml

echoBold 'Deleting Monitoring Config and RBAC...'
${KUBECTL} delete -f ../autoscaling/prometheus/prometheus-configuration.yaml
${KUBECTL} delete -f ../autoscaling/prometheus/prometheus-rbac.yaml
sleep 1s

echoBold 'Deleting Monitoring Namespace ...'
${KUBECTL} delete namespace monitoring
sleep 1s

# switch the context to  'default' namespace
${KUBECTL} config set-context $(${KUBECTL} config current-context) --namespace=default

echoBold 'Finished'