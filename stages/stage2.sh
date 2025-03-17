#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "[❌] Incorrect arguments!"
    echo "     Using: $0 <FS> <UNPACKED_DIR>"
    exit 1
fi

smount() {
    IMAGE=$1

    echo "[STAGE 2] ${IMAGE} image modification started"
    sudo mount -t $FS -o loop "${UNPACKED_DIR}/${IMAGE}" ${MNT_DIR}
    echo "[STAGE 2] ${IMAGE} image mounted"
}

FS=$1
UNPACKED_DIR=$2
MNT_DIR="${2}/mnt"

if [ ! -d "$MNT_DIR" ]; then
    mkdir "$MNT_DIR"
    echo "[✔️] Directory $MNT_DIR created"
else
    echo "[✔️] Directory $MNT_DIR already exists"
fi

echo " "
echo "🔴 - Removed"
echo "🟢 - Added"
echo "🔵 - Modified"
echo " "

echo "[STAGE 2] Bloatware remove started"

# system_a.img
smount "system_a.img"

./scripts/remove_bloatware/system.sh $MNT_DIR
./scripts/modify_configs/system.sh $MNT_DIR
./scripts/signature_spoof/signature_spoof.sh $MNT_DIR
./scripts/modify_configs/props.sh $MNT_DIR
./scripts/microg/setup_microg.sh $MNT_DIR system

sudo umount ${MNT_DIR}
echo "[STAGE 2] system_a.img image unmounted"

# product_a.img
smount "product_a.img"

./scripts/remove_bloatware/product.sh $MNT_DIR
./scripts/microg/setup_microg.sh $MNT_DIR product

sudo umount ${MNT_DIR}
echo "[STAGE 2] product_a.img image unmounted"

# system_ext_a.img
smount "system_ext_a.img"

./scripts/modify_configs/system_ext.sh $MNT_DIR
./scripts/remove_bloatware/system_ext.sh $MNT_DIR
./scripts/microg/setup_microg.sh $MNT_DIR system_ext

sudo umount ${MNT_DIR}
echo "[STAGE 2] system_ext_a.img image unmounted"
