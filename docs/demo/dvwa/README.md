# DVWA

DVWA installation [here](https://github.com/cytopia/docker-dvwa#kubernetes).

### allow.yaml

KubeArmor policy to allow specific operations for dvwa web app i.e., allow apache2, ping, dash.


### deny-shadow.yaml

Deny access to /etc/shadow for all processes.

### dvwa-upload.php

PHP code for remote command injection.
