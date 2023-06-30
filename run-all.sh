aws configure set default.s3.max_concurrent_requests 10

for target in goofys geesefs rclone s3backer s3fs s3ql # objectivefs juicefs
do
    echo $value
    export TARGET=$target
    export OUTPUT_FILE=$target.txt
    nsdf-install
    nsdf-fuse clean-all && nsdf-fuse create-bucket && nsdf-fuse simple-benchmark
done

