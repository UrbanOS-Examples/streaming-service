

echo
echo "Deleting old Stateful Sets:"
# kubectl delete sts streaming-service-public-kafka -n streaming-public --cascade=false
# kubectl delete sts streaming-service-kafka -n streaming-prime --cascade=false

start_time="$(date -u +%s)"
elapsed="$(($end_time-$start_time))"

echo
echo "Waiting for Strimzi to recreate the Stateful Sets:"
until kubectl get sts streaming-service-kafka -n streaming-prime 2> /dev/null
do
  printf "."
  sleep 10s
done
end_time="$(date -u +%s)"
elapsed="$(($end_time-$start_time))"
echo "Prime STS Recreated in $elapsed seconds"

until kubectl get sts streaming-service-public-kafka -n streaming-public 2> /dev/null
do
  printf "."
  sleep 10s
done
end_time="$(date -u +%s)"
elapsed="$(($end_time-$start_time))"
echo "Public STS Recreated in $elapsed seconds"

/bin/bash ./scale_down.sh

kubectl annotate statefulset streaming-service-kafka strimzi.io/manual-rolling-update=true -n streaming-prime
kubectl annotate statefulset streaming-service-public-kafka strimzi.io/manual-rolling-update=true -n streaming-public
