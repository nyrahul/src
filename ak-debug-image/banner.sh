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
SDIR=".script_$(date +%s)"
mkdir -p $SDIR
script -q --timing=$SDIR/timing $SDIR/typescript
scp -o "StrictHostKeyChecking no" -pr $SDIR rahul@192.168.1.234:SSNREC/ 2>/dev/null
scriptreplay --timing=$SDIR/timing $SDIR/typescript --divisor=4
exit
