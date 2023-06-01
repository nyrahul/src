# Install conjur
```
CONJUR_NAMESPACE=conjur
kubectl create namespace "$CONJUR_NAMESPACE"
DATA_KEY="$(docker run --rm cyberark/conjur data-key generate)"
HELM_RELEASE=conjur
VERSION=2.0.6
helm install \
   -n "$CONJUR_NAMESPACE" \
   --set dataKey="$DATA_KEY" \
   "$HELM_RELEASE" \
   https://github.com/cyberark/conjur-oss-helm-chart/releases/download/v$VERSION/conjur-oss-$VERSION.tgz
```

# Add an account (org)
- exec into the conjur pod
- run
```
conjurctl account create  accuknox | grep API
```

# Install conjur cli

https://github.com/cyberark/conjur-cli-go/releases

# Init conjur cli

you need to add `conjur-conjur-oss` to your hosts file and point it to localhost (if you port forward) or to the lb if exposed via ingress, ...

```
conjur init -s -u https://conjur-conjur-oss:9443 -a accuknox
```

# conjur login

username: admin
password: API token, if you forget it see next section
```
conjur login
```

# retrieve conjur user password (API key)

change accuknox with your org name

```
conjurctl role retrieve-key accuknox:user:admin
```
