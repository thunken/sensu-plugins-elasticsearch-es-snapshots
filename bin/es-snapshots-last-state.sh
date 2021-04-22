#!/bin/bash

while getopts ":h:p:r:" opt; do
  case $opt in
    a) ES_HOST="$OPTARG"
    ;;
    p) ES_PORT="$OPTARG"
    ;;
    r) ES_REPOSITORY="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

ES_HOST=${ES_HOST:-localhost}
ES_PORT=${ES_PORT:-9200}
ES_REPOSITORY=${ES_REPOSITORY:-es_repository}

STATUS_CODE_TMP_FILE="status_code.tmp"
STATUS_CODE=$(curl -o ${STATUS_CODE_TMP_FILE} -L -s -w "%{http_code}" "${ES_HOST}:${ES_PORT}/_cat/snapshots/${ES_REPOSITORY}?format=JSON&h=id,start_epoch,end_epoch,status,reason&s=start_epoch&pretty")
if [ ${STATUS_CODE} != "200" ]; then
  echo "Can't get snapshot state. Reason:"
  cat ${STATUS_CODE_TMP_FILE}
  exit 2;
fi
rm ${STATUS_CODE_TMP_FILE}

SNAPSHOTS=$(curl -s -X GET "${ES_HOST}:${ES_PORT}/_cat/snapshots/${ES_REPOSITORY}?format=JSON&h=id,start_epoch,end_epoch,status,reason&s=start_epoch&pretty")
if [ $? != 0 ]; then
    echo ${SNAPSHOTS}
    exit 2;
fi

if ! command -v jq &> /dev/null
then
    echo "jq tool could not be found. Please install it: https://stedolan.github.io/jq/download/"
    exit 0;
fi

LATEST_SNAPSHOT=$(echo ${SNAPSHOTS} | jq .[-1])
LATEST_SNAPSHOT_ID=$(echo ${LATEST_SNAPSHOT} | jq .id)

LATEST_SNAPSHOT_STATUS=$(echo ${LATEST_SNAPSHOT} | jq .status)
LATEST_SNAPSHOT_STATUS="${LATEST_SNAPSHOT_STATUS%\"}"
LATEST_SNAPSHOT_STATUS="${LATEST_SNAPSHOT_STATUS#\"}"

case ${LATEST_SNAPSHOT_STATUS} in

  "SUCCESS" | "IN_PROGRESS")
    echo "Latest snapshot ${LATEST_SNAPSHOT_ID} success"
    exit 0;
    ;;

  "FAILED" | "INCOMPATIBLE" | "PARTIAL")
    echo "Latest snapshot ${LATEST_SNAPSHOT_ID} failed"
    echo ${LATEST_SNAPSHOT}
    exit 2;
    ;;

  *)
    echo "Unknown state"
    exit 1;
    ;;
esac