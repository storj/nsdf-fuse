aws configure set default.s3.max_concurrent_requests 10
if [[ -z "${AWS_ACCESS_KEY_ID}" ]]; then
    echo missing export AWS_ACCESS_KEY_ID
    exit 1
fi
if [[ -z "${AWS_SECRET_ACCESS_KEY}" ]]; then
    echo missing export AWS_SECRET_ACCESS_KEY
    exit 1
fi
export AWS_DEFAULT_REGION_REGION=us-east-1
export AWS_S3_ENDPOINT_URL=https://gateway.storjshare.io

for target in goofys geesefs rclone s3backer s3fs s3ql # objectivefs juicefs
do
    echo -------------------------------
    echo ---- $target
    echo -------------------------------

    export TARGET=$target
    export OUTPUT_FILE=$target.txt
    ./nsdf-fuse install
    ./nsdf-fuse clean-all
    ./nsdf-fuse create-bucket
    ./nsdf-fuse simple-benchmark
done

