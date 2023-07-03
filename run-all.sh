aws configure set default.s3.max_concurrent_requests 10
export now=$( date '+%F_%H:%M:%S' )

# loop through the different fuse providers
for target in goofys geesefs rclone s3backer s3fs s3ql # objectivefs juicefs
do
    # install the provider
    ./nsdf-fuse install

    for service in *.creds; do

        # load service keys, regions, and endpoint from files
        source $service

        # sanity check that we have keys
        if [[ -z "${AWS_ACCESS_KEY_ID}" ]]; then
            echo missing export AWS_ACCESS_KEY_ID
            exit 1
        fi
        if [[ -z "${AWS_SECRET_ACCESS_KEY}" ]]; then
            echo missing export AWS_SECRET_ACCESS_KEY
            exit 1
        fi


        echo ---------------------------------------------------
        echo ---- $service - $target 
        echo ---------------------------------------------------

        export TARGET=$target
        export OUTPUT_FILE=$now-$service-$target.txt

        ./nsdf-fuse clean-all
        ./nsdf-fuse create-bucket
        ./nsdf-fuse simple-benchmark
        ./nsdf-fuse clean-all
    done

    # clean up the provider
    ./nsdf-fuse uninstall
    ./nsdf-fuse update-os
done