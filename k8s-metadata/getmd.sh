#!/bin/bash

# Traverse Metadata URL for AWS

MDURL="http://169.254.169.254/latest/meta-data/"
baseURL=$MDURL

traverse()
{
	for key in `curl -s $baseURL`; do
		echo "--- $key ---"
	done
}

traverse
