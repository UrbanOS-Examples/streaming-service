scaleAppToIn () {
   kubectl scale --replicas=$2 deployment/$1 -n $3
}

echo
echo "Scaling apps up to previous replicas:"
while IFS=" " read -r app namespace replicas remainder
do
    scaleAppToIn $app $replicas $namespace
done < "replicas.txt"