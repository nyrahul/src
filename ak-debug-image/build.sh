#!/bin/bash

TAG=1.0
IMGNAME=ak-debug-image
DOCKUSER=nyrahul

docker buildx build -t $IMGNAME:$TAG --load .
docker tag $IMGNAME:$TAG $DOCKUSER/$IMGNAME:$TAG
docker push $DOCKUSER/$IMGNAME:$TAG
