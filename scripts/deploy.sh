set -e

ECHO=`which echo`
KUBECTL=`which kubectl`

# methods
function echoBold () {
    ${ECHO} -e $'\e[1m'"${1}"$'\e[0m'
}

function usage () {
    echoBold "This script automates the installation of WSO2 Identity Server Kubernetes resources\n"
    echoBold "Allowed arguments:\n"
    echoBold "-h | --help"
    echoBold "--wu | --wso2-username\t\tYour WSO2 username"
    echoBold "--wp | --wso2-password\t\tYour WSO2 password"
    echoBold "--cap | --cluster-admin-password\tKubernetes cluster admin password\n\n"
}

WSO2_SUBSCRIPTION_USERNAME='fabio@wso2.com'
WSO2_SUBSCRIPTION_PASSWORD='WSaf0302*'
ADMIN_PASSWORD='admin'

# capture named arguments
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`

    case ${PARAM} in
        -h | --help)
            usage
            exit 1
            ;;
        --wu | --wso2-username)
            WSO2_SUBSCRIPTION_USERNAME=${VALUE}
            ;;
        --wp | --wso2-password)
            WSO2_SUBSCRIPTION_PASSWORD=${VALUE}
            ;;
        --cap | --cluster-admin-password)
            ADMIN_PASSWORD=${VALUE}
            ;;
        *)
            echoBold "ERROR: unknown parameter \"${PARAM}\""
            usage
            exit 1
            ;;
    esac
    shift
done

#prerequisite generic deployment 
#the command is required for all deployments for docker for mac
# <<<< Attention >>>> 
# The default configuration watches Ingress object from all the namespaces. 
# To change this behavior use the flag --watch-namespace to limit the scope to a particular namespace.
${KUBECTL} apply -f ../ingress-nginx/mandatory.yaml

# create a service
${KUBECTL} apply -f ../ingress-nginx/cloud-generic.yaml

# create a new Kubernetes Namespace
${KUBECTL} create namespace wso2

# create a new service account in 'wso2' Kubernetes Namespace
${KUBECTL} create serviceaccount wso2svc-account -n wso2

# switch the context to new 'wso2' namespace
${KUBECTL} config set-context $(${KUBECTL} config current-context) --namespace=wso2

# create a Kubernetes Secret for passing WSO2 Private Docker Registry credentials
${KUBECTL} create secret docker-registry wso2creds --docker-server=docker.wso2.com --docker-username=${WSO2_SUBSCRIPTION_USERNAME} --docker-password=${WSO2_SUBSCRIPTION_PASSWORD} --docker-email=${WSO2_SUBSCRIPTION_USERNAME}

# create Kubernetes Role and Role Binding necessary for the Kubernetes API requests made from Kubernetes membership scheme
${KUBECTL} create --username=admin --password=${ADMIN_PASSWORD} -f ../rbac/rbac.yaml

# create Kubernetes ConfigMaps
echoBold 'Creating Kubernetes ConfigMaps...'
${KUBECTL} create configmap identity-server-conf --from-file=../confs/
${KUBECTL} create configmap identity-server-conf-axis2 --from-file=../confs/axis2/
${KUBECTL} create configmap identity-server-conf-datasources --from-file=../confs/datasources/
${KUBECTL} create configmap identity-server-conf-identity --from-file=../confs/identity/
${KUBECTL} create configmap mysql-dbscripts --from-file=../extras/confs/rdbms/mysql/dbscripts/
#${KUBECTL} create configmap identity-server-conf-event-publishers --from-file=../confs/is/deployment/server/eventpublishers/
${KUBECTL} create configmap identity-server-conf-tomcat --from-file=../confs/tomcat/

echoBold 'Deploying the Kubernetes Services...'
${KUBECTL} create -f ../extras/rdbms/mysql/mysql-service.yaml
${KUBECTL} create -f ../is/identity-server-service.yaml
sleep 10s

# deploying WSO2 product databases using MySQL RDBMS
echoBold 'Deploying WSO2 Identity Server Databases using MySQL...'
${KUBECTL} create -f ../extras/rdbms/mysql/mysql-deployment.yaml
sleep 10s

# persistent storage
echoBold 'Creating persistent volumes and volume claims...'
${KUBECTL} create -f ../is/identity-server-volume-claims.yaml
${KUBECTL} create -f ../volumes/persistent-volumes.yaml
${KUBECTL} create -f ../extras/rdbms/mysql/mysql-persistent-volume-claim.yaml
${KUBECTL} create -f ../extras/rdbms/volumes/persistent-volumes.yaml
sleep 10s

# WSO2 Identity Server
echoBold 'Deploying WSO2 Identity Server...'
${KUBECTL} create -f ../is/identity-server-deployment.yaml
sleep 30s

#create Kubernetes Ingress resources
echoBold 'Deploying Kubernetes Ingresses...'
${KUBECTL} create -f ../ingresses/identity-server-ingress.yaml
#sleep 20s

echoBold 'Creating Metrics Server...'
${KUBECTL} create -f ../autoscaling/metrics-server/deploy/1.8+

echoBold 'Creating autoscale...'
${KUBECTL} create -f ../autoscaling/hpa/hpa.yaml
#${KUBECTL} autoscale deployment wso2is-deployment --cpu-percent=50 --min=1 --max=10

echoBold 'Creating K*S Dashboard...'
${KUBECTL} create -f ../dashboard/kubernetes-dashboard.yaml
#${KUBECTL} autoscale deployment wso2is-deployment --cpu-percent=50 --min=1 --max=10



# Deployment Monitoring 
# Prometheus and Grafana
# <<<< Attention >>>> 
# create a new Kubernetes Namespace
echoBold 'Criando Monitoring Namespace ...'
${KUBECTL} create namespace monitoring

# switch the context to new 'monitoring' namespace
${KUBECTL} config set-context $(${KUBECTL} config current-context) --namespace=monitoring

echoBold 'Creating Monitoring Config and RBAC...'
${KUBECTL} create -f ../autoscaling/prometheus/prometheus-configuration.yaml
${KUBECTL} create -f ../autoscaling/prometheus/prometheus-rbac.yaml
sleep 1s

echoBold 'Creating the Monitoring Services...'
${KUBECTL} create -f ../autoscaling/prometheus/prometheus-service.yaml
sleep 3s

echoBold 'Deploying the Monitoring...'
${KUBECTL} create -f ../autoscaling/prometheus/prometheus-deployment.yaml
sleep 1s

echoBold 'Creating Grafana Secret...'
${KUBECTL} create -f ../autoscaling/grafana/grafana-secret.yaml 

echoBold 'Deploying Grafana ...'
${KUBECTL} create -f ../autoscaling/grafana/grafana-service.yaml
${KUBECTL} create -f ../autoscaling/grafana/grafana-controller.yaml 

# switch the context to new 'wso2' namespace
${KUBECTL} config set-context $(${KUBECTL} config current-context) --namespace=wso2

echoBold 'Finished'