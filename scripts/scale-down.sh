rm replicas.txt

scaleAppToIn () {
   kubectl scale --replicas=$2 deployment/$1 -n $3
}

recordReplicas () {
    replicas=`kubectl get deployment $1 -n $2 -o=jsonpath='{.status.replicas}'`
    echo "$1 has $replicas replicas"
    echo "$1 $2 $replicas" >> replicas.txt
}

echo
echo "Recording current replicas:"
recordReplicas andi admin
for app in reaper valkyrie forklift streisand flair odo
do 
    recordReplicas $app streaming-services
done

echo
echo "Scaling apps down to 0:"
while IFS=" " read -r app namespace replicas remainder
do
    scaleAppToIn $app 0 $namespace
done < "replicas.txt"