#! /usr/bin/env bash
command=$1
remotePath=$2
shift 2
args=()
for c in "$@"; do if [ -f "${c}" ]; then args+=("${remotePath}${c}"); else args+=("${c}"); fi; done

sshpass -e ssh -l ${REMOTE_user} ${REMOTE_machine} powershell -File - <<EOF \
    | sed 's+\\+/+g' \
    | sed "s+${remotePath}++g"
cd '${remotePath}'
& '${command}' ${args[@]}
EOF
exit $?
