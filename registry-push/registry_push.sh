#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <new_registry_url>"
    exit 1
fi

NEW_REGISTRY=$1
TAR_LIST="tar_list.txt"
PUSHED_LIST="pushed_list.txt"
NOT_PUSHED_LIST="not_pushed_list.txt"

if [ ! -f "$TAR_LIST" ]; then
    echo "Error: tar_list.txt file not found!"
    exit 1
fi
echo "" > "$PUSHED_LIST"
echo "" > "$NOT_PUSHED_LIST"

while IFS= read -r TAR_FILE; do
    if [ ! -f "$TAR_FILE" ]; then
        echo "Warning: Skipping missing file $TAR_FILE"
        echo "$TAR_FILE" >> "$NOT_PUSHED_LIST"
        continue
    fi

    echo "Loading image from: $TAR_FILE"
    OUTPUT=$(docker image load -i "$TAR_FILE")
    IMAGE_NAME=$(echo "$OUTPUT" | grep 'Loaded image' | awk '{print $3}')

    if [ -z "$IMAGE_NAME" ]; then
        echo "Failed to extract image name from output."
        echo "$TAR_FILE" >> "$NOT_PUSHED_LIST"
        continue
    fi
    NEW_IMAGE_NAME="$NEW_REGISTRY/$IMAGE_NAME"

    echo "Tagging image as: $NEW_IMAGE_NAME"
    docker tag "$IMAGE_NAME" "$NEW_IMAGE_NAME"

    echo "Pushing image: $NEW_IMAGE_NAME"
    if docker push "$NEW_IMAGE_NAME"; then
        echo "$TAR_FILE" >> "$PUSHED_LIST"
        echo "Removing image from local: $NEW_IMAGE_NAME"
        docker rmi "$NEW_IMAGE_NAME"
        echo "Removing image from local: $IMAGE_NAME"
        docker rmi "$IMAGE_NAME"
    else
        echo "Failed to push image: $NEW_IMAGE_NAME"
        echo "$TAR_FILE" >> "$NOT_PUSHED_LIST"
    fi
done < "$TAR_LIST"

echo "Process completed successfully."

