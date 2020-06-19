#/bin/bash
# Author: KoopaKiller / github.com/MrKoopaKiller
#subscription=$1
projectName="$1"
deploymentName="$2" #TO-DO: Get it from environment variables
imageName="$3"
subscription="projects/${projectName}/subscriptions/nginx"

## Getting msg from Pub/Sub
MSG=$(gcloud pubsub subscriptions pull ${subscription}  --format=json)
## Identifying keys,values
ACKID=$(echo ${MSG} | jq '.[].ackId' | tr -d '"')
DATA=$(echo ${MSG} | jq '.[].message.data' | \
  tr -d '"' | \
  base64 -d)
ACTION=$(echo ${DATA} | jq '.action' | tr -d '"')
DIGEST=$(echo ${DATA} | jq '.digest' | tr -d '"')
TAG=$(echo ${DATA} | jq '.tag' | tr -d '"')

## debug:
#echo $MSG | jq

tagFilter() {
 if [ $(echo ${TAG} | awk -F'/' '{print $3}' | cut -d':' -f1 ) != "${imageName}" ]; then #TODO: Improve this terrible command :(
   echo "The imageName not match: $TAG" 2>&1 && exit 0
 fi
 updateImage
}

updateImage() {
  if [ $ACTION == "INSERT" ]; then
    kubectl set image deployment/${deploymentName} ${imageName}=${TAG} --record
    if [ $? == '0' ]; then
      echo 'done!'
        ackMsg
    else
      echo "ERROR: Unable to update deployment" 2>&1
    fi
  fi
}

ackMsg() {
 gcloud alpha pubsub subscriptions ack ${subscription} --ack-ids=${ACKID}
 if [ $? != '0' ]; then
   echo "ERROR: Unable to ACK, ackid: ${ACKID}, DATE: $(date)" 2>&1
 fi
}

tagFilter
