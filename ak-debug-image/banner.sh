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
mkdir -p .script
script -q --timing=.script/timing .script/typescript && ls .script
ls .script
exit
