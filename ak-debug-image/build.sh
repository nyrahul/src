#!/bin/bash

TAG=1.6
IMGNAME=ak-debug-image
DOCKUSER=nyrahul

echo "Building [$IMGNAME:$TAG] ..."
docker buildx build -t $IMGNAME:$TAG --load .
docker tag $IMGNAME:$TAG $DOCKUSER/$IMGNAME:$TAG
echo "Pushing [$IMGNAME:$TAG] ..."
docker push $DOCKUSER/$IMGNAME:$TAG
