set -Eueo pipefail
set -o errtrace # inherits trap on ERR in function and subshell

trap 'traperror $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]:-})' ERR
trap 'trapexit $? $LINENO' EXIT

function trapexit() {
  echo "$(date) $(hostname) $0: EXIT on line $2 (exit status $1)"
}

function traperror () {
    local err=$1 # error status
    local line=$2 # LINENO
    local linecallfunc=$3
    local command="$4"
    local funcstack="$5"
    echo "$(date) $(hostname) $0: ERROR '$command' failed at line $line - exited with status: $err"

    if [ "$funcstack" != "::" ]; then
      echo -n "$(date) $(hostname) $0: DEBUG Error in ${funcstack} "
      if [ "$linecallfunc" != "" ]; then
        echo "called at line $linecallfunc"
      else
        echo
      fi
    fi
    echo "'$command' failed at line $line - exited with status: $err"
}



aws configure set default.s3.max_concurrent_requests 10
now=$( date '+%F_%H:%M:%S' )
export PATH=$PATH:$(pwd)

# loop through the different fuse providers
for target in goofys geesefs s3ql rclone s3backer s3fs
do
    # install the provider
    export TARGET=$target

    nsdf-fuse install
    nsdf-fuse up

    # loop through the different services with the current fuse provider
    for service in *.creds; do

        export OUTPUT_FILE=$now-$service-$target.txt

        echo ---------------------------------------------------
        echo ---------------------------------------------------
        echo ---------------------------------------------------
        echo ---- $service - $target
        echo ---------------------------------------------------
        echo ---------------------------------------------------
        echo ---------------------------------------------------

        # load service keys, regions, and endpoint from files
        source $service

        # sanity check that we have config keys
        if [[ -z "${AWS_ACCESS_KEY_ID}" ]]; then
            echo missing export AWS_ACCESS_KEY_ID
            exit 1
        fi
        if [[ -z "${AWS_SECRET_ACCESS_KEY}" ]]; then
            echo missing export AWS_SECRET_ACCESS_KEY
            exit 1
        fi

        nsdf-fuse clean-all
        nsdf-fuse create-bucket
        nsdf-fuse simple-benchmark
        nsdf-fuse clean-all
    done

    # clean up the provider
    nsdf-fuse down
    nsdf-fuse uninstall
    nsdf-fuse update-os
done