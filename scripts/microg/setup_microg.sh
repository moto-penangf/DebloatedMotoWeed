#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "[❌] Incorrect arguments!"
    echo "     Using: $0 <MOUNT_DIR>"
    exit 1
fi

MOUNT_DIR=$1
PRIV_DIR=${MOUNT_DIR}/priv-app
SYSTEM_DIR=${MOUNT_DIR}/system

microg_dirs=(
    "GmsCore"
    # "GsfProxy"
    "FakeStore" # Companion App
)

set_permissions() {
    sudo chown 0:0 $1
    sudo chmod 0644 $1

    sudo setfattr -n security.selinux -v u:object_r:system_file:s0 $1
}


install_apk() {
    echo "[🔵] Installing ${item}"

    sudo mkdir "${1}/${2}" 
    sudo cp "scripts/microg/files/${2}/${2}.apk" "${1}/${2}/"

    echo "[⚙️] Setting up permissions for ${item}"
    set_permissions "${1}/${2}"
    set_permissions "${1}/${2}/${2}.apk"  
}


install_lib() {
    if [ ! -d "scripts/microg/files/${1}/lib" ]; then
        return
    
    fi

    for lib in $(ls "scripts/microg/files/${1}/lib/arm64-v8a"); do # 64bits libs
        echo "[🔵] Installing ${lib}"
        sudo cp "scripts/microg/files/${1}/lib/arm64-v8a/${lib}" "${SYSTEM_DIR}/lib64/"
        set_permissions "${SYSTEM_DIR}/lib64/${lib}"
    done

    for lib in $(ls "scripts/microg/files/${1}/lib/armeabi-v7a"); do # 32bits libs
        echo "[🔵] Installing ${lib}"
        sudo cp "scripts/microg/files/${1}/lib/armeabi-v7a/${lib}" "${SYSTEM_DIR}/lib/"
        set_permissions "${SYSTEM_DIR}/lib/${lib}"
    done
}


product_stage() {
    sudo rm -rf "${PRIV_DIR}/Phonesky"
    for item in "${microg_dirs[@]}"; do
        if [ -e "${PRIV_DIR}/${item}" ]; then
            echo "[🔴] Removing ${PRIV_DIR}/${item}"
            sudo rm -rf "${PRIV_DIR}/${item}"
        fi

        install_apk "${PRIV_DIR}" "${item}"

    done


    echo "[⚙️] Setting up special permissions for ${item}"
    sudo cp "scripts/microg/files/etc/default-permissions/default-permissions-FakeStore.xml" "${MOUNT_DIR}/etc/default-permissions/default-permissions-FakeStore.xml"
    set_permissions "${MOUNT_DIR}/etc/default-permissions/default-permissions-FakeStore.xml"
    sudo cp "scripts/microg/files/etc/default-permissions/default-permissions-GmsCore.xml" "${MOUNT_DIR}/etc/default-permissions/default-permissions-GmsCore.xml"
    set_permissions "${MOUNT_DIR}/etc/default-permissions/default-permissions-GmsCore.xml"

    sudo cp "scripts/microg/files/etc/permissions/privapp-permissions-FakeStore.xml" "${MOUNT_DIR}/etc/permissions/privapp-permissions-FakeStore.xml"
    set_permissions "${MOUNT_DIR}/etc/permissions/privapp-permissions-FakeStore.xml"
    sudo cp "scripts/microg/files/etc/permissions/privapp-permissions-GmsCore.xml" "${MOUNT_DIR}/etc/permissions/privapp-permissions-GmsCore.xml"
    set_permissions "${MOUNT_DIR}/etc/permissions/privapp-permissions-GmsCore.xml"
    sudo cp "scripts/microg/files/etc/permissions/privapp-permissions-PlayStore.xml" "${MOUNT_DIR}/etc/permissions/privapp-permissions-PlayStore.xml"
    set_permissions "${MOUNT_DIR}/etc/permissions/privapp-permissions-PlayStore.xml"

    sudo cp "scripts/microg/files/etc/sysconfig/google.xml" "${MOUNT_DIR}/etc/sysconfig/google.xml"
    set_permissions "${MOUNT_DIR}/etc/sysconfig/google.xml"
}


system_stage() {

    for item in "${microg_dirs[@]}"; do
        install_lib "${item}"
    done
}

system_ext_stage() {
    sudo rm -rf "${MOUNT_DIR}/priv-app/GoogleServicesFramework"
    install_apk "${PRIV_DIR}" "GoogleServicesFramework"

    echo "[⚙️] Setting up special permissions for GsfProxy"
    sudo cp "scripts/microg/files/privapp-permissions-google-system_ext.xml" "${MOUNT_DIR}/etc/permissions/privapp-permissions-google-system_ext.xml"
    set_permissions "${MOUNT_DIR}/etc/permissions/privapp-permissions-google-system_ext.xml"
}

if [ $2 == "product" ]; then
    product_stage

elif [ $2 == "system" ]; then
    system_stage
elif [ $2 == "system_ext" ]; then
    system_ext_stage
else
    echo "[❌] Incorrect arguments!"
    echo "     Using: $0 <MOUNT_DIR> <product|system|system_ext>"
    exit 1
fi
