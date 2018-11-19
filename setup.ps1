
Param([string]$clustername = "zchallenge")
Param([string]$clusterresourcegroup = "zchallengerg")
Param([string]$clusterresourcegrouplocation = "uksouth")
Param([string]$k8sversion = "1.11.3")
Param([string]$clusterstorageaccountname = "zchallengestr93k1")
Param([string]$sshkey = "nicks ssh key")


Write-Output  "Creating Challenge K8S Cluster"
Write-Output  "Azure CLI version"
az --version
Write-Output  "kubectl version"
kubectl version
Write-Output  "helm version"
helm version
az group create --name $clusterresourcegroup --location $clusterresourcegrouplocation
az aks create --resource-group $clusterresourcegroup --name $clustername --node-count 2 --kubernetes-version $k8sversion --ssh-key-value $sshkey
az aks get-credentials --resource-group $clusterresourcegroup --name $clustername
kubectl get nodes
az aks list | Select-String -Pattern('enableRbac')

$noderesourcegroup = az aks show -g $clusterresourcegroup -n $clustername | ConvertFrom-Json | Select-Object nodeResourceGroup 
Write-Output  "node resource group is $noderesourcegroup.nodeResourceGroup"

az storage account create --resource-group $noderesourcegroup.nodeResourceGroup --name $clusterstorageaccountname --sku Standard_LRS -o table
Write-Output "dashboard and rbac"
kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
Write-Output "helm and rbac"
kubectl apply -f cluster-admin.yaml
kubectl create serviceaccount -n kube-system tiller
kubectl create clusterrolebinding tiller-binding --clusterrole=cluster-admin --serviceaccount kube-system:tiller
Write-Output "storage and rbac"
kubectl apply -f stor-rbac.yaml
# helm init
Write-Output "Helm init....."
helm init --service-account tiller
Write-Output "sleeping 120....."
Start-Sleep 120
Write-Output "Helm teller ?....."
kubectl get pods --namespace kube-system | Select-String -Pattern('tiller')
Write-Output "Helm install mongo ....."
helm install --name mongo stable/mongodb --set usePassword=false --version 3.0.1
Write-Output "Helm install rabbitmq ....."
helm install --name rabbit --set rabbitmq.username=nicksadmin,rabbitmq.password=nicksadminpassword stable/rabbitmq --version 1.1.8
kubectl get deployments
kubectl get statefulsets
kubectl apply -f part1-yamls/capture-order-deployment.yaml
kubectl apply -f part1-yamls/capture-order-service.yaml
Write-Output "sleeping 120....."
Start-Sleep 120
kubectl get services
kubectl apply -f part2-yamls/storageclass.yaml
kubectl get storageclass
kubectl apply -f part2-yamls/persistentvolume.yaml
kubectl get persistentvolumeclaim
kubectl apply -f part2-yamls/fulfillorder-deployment.yaml
kubectl get deployment
kubectl apply -f part2-yamls/fulfillorder-service.yaml
kubectl get services
kubectl apply -f part2-yamls/eventlistener-deployment.yaml
kubectl get deployment
Write-Output "Exiting setup....."