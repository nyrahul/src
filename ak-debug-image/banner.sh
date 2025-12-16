#!/bin/bash

cat << EOF
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║                  WARNING: Authorized access only!                 ║
║     Unauthorized access is prohibited and subject to prosecution. ║
║            By continuing, you consent to monitoring               ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
EOF

SDIR="/.script"
script -q --timing=$SDIR/timing $SDIR/typescript -c "bash"
NEWSDIR="/$(hostname)_$(date +%s)"
mv $SDIR $NEWSDIR
scp -C -o "StrictHostKeyChecking no" -pr $NEWSDIR rahul@192.168.1.234:SSNREC/ 2>/dev/null >/dev/null
exit
