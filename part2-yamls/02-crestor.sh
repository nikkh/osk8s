# must be in the MC- resource group - standard storage as files doesn't support premium (yet)
cl="aks0"
rgs=`az group list -o table | grep MC_ | grep $cl | awk '{print $1}'`
az storage account create --resource-group $rgs --name strteam1aks1 --sku Standard_LRS
