function check_kind_exists {
# $1 cluster name
CLUSTER_NAME=$1
if kind get clusters | grep -q "${CLUSTER_NAME}"; then
  echo "{\"exists\": \"true\"}"
else
  echo "{\"exists\": \"false\"}"
fi
}
check_kind_exists $1
