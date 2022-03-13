#!/bin/bash
set -e # exit when any command fails
source ./fuse_test.sh

# /////////////////////////////////////////////////////////////////
function InstallS3Backer() {
    sudo apt install -y s3backer
    sudo sh -c 'echo user_allow_other >> /etc/fuse.conf'
}

# /////////////////////////////////////////////////////////////////
function MountBackend() {

    # Explanation:
    #   Linux loop back mount
    #   s3backer <---> remote S3 storage

    # do `s3backer --help`` for all options
    OVERALL_SIZE=1T                                                   # overall size, you should known in advance
    BLOCK_SIZE_MB=4                                                   # single block size
    NUM_BLOCK_TO_CACHE=$(( ${RAM_CACHE_SIZE_MB} / ${BLOCK_SIZE_MB} )) # number of blocks to cache
    NUM_THREADS=64          
                                              # number of threads
    # where to cache/store block informations
    BLOCK_CACHE_FILE=${CACHE_DIR}/blocks   

    # directory that sync with S3 (note: it's a virtual directory)
    BACKEND_DIR=${CACHE_DIR}/backend_dir
    
    mkdir -p ${BACKEND_DIR}
    s3backer --accessId=${AWS_ACCESS_KEY_ID} \
             --accessKey=${AWS_SECRET_ACCESS_KEY} \
             --blockCacheFile=${BLOCK_CACHE_FILE} \
             --blockSize=${BLOCK_SIZE_MB}M \
             --size=${OVERALL_SIZE} \
             --region=${AWS_DEFAULT_REGION} \
             --blockCacheSize=${NUM_BLOCK_TO_CACHE} \
             --blockCacheThreads=${NUM_THREADS} \
             -o default_permissions,allow_other \
             -o uid=$UID \
             ${BUCKET_NAME} \
             ${BACKEND_DIR}  
    
    mount | grep ${CACHE_DIR}
}

# /////////////////////////////////////////////////////////////////
function UMountBackend() {
    umount ${BACKEND_DIR}
}

# /////////////////////////////////////////////////////////////////
function MountLoopBack() {
    mount -o loop \
          -o discard \
          -o default_permissions,allow_other \
          -o uid=$UID \
          ${BACKEND_DIR}/file \
          ${TEST_DIR}
}

# /////////////////////////////////////////////////////////////////
function UMountLoopBack() {
    umount ${TEST_DIR}
}

# /////////////////////////////////////////////////////////////////
function CreateBackend()  {
    MountBackend 
    mkfs.ext4 -E nodiscard -F ${BACKEND_DIR}/file
    UMountBackend
}

# /////////////////////////////////////////////////////////////////
function FuseUp(){
    echo "FuseUp (s3backer)..."
    MountBackend
    MountLoopBack
    mount | grep ${TEST_DIR}
    echo "FuseUp (s3backer) done"
}

# /////////////////////////////////////////////////////////////////
function FuseDown() {
    # overriding since I need to umount two file system
    echo "FuseDown (s3backer)..."
    CHECK TEST_DIR
    CHECK CACHE_DIR
    UMountLoopBack
    UMountBackend
    umount ${TEST_DIR} 
    umount ${BACKEND_DIR}
    rm -Rf ${CACHE_DIR}/* 
    rm -Rf ${TEST_DIR}/*
    echo "FuseDown (s3backer) done"
}

BUCKET_NAME=nsdf-fuse-s3backer
InitFuseTest 
InstallS3Backer
CreateBucket
CreateBackend
RunFuseTest  
RemoveBucket 
TerminateFuseTest 


