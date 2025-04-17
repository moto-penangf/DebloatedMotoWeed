#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "[❌] Incorrect arguments!"
    echo "     Using: $0 <MOUNT_DIR>"
    exit 1
fi

MOUNT_DIR=$1
SYSTEM_DIR="${MOUNT_DIR}/system_a/system"
PRODUCT_DIR="${MOUNT_DIR}/product_a"
SYSTEM_EXT_DIR="${MOUNT_DIR}/system_ext_a"

set_permissions() {
    sudo chown 0:0 $1
    sudo chmod 0644 $1

    sudo setfattr -n security.selinux -v u:object_r:system_file:s0 $1
}


install_apk() {
    echo "[🔵] Installing ${item} to ${2}/${3} in ${1}"

    sudo rm -rf "${MOUNT_DIR}/${1}/${2}/${3}"
    sudo mkdir "${MOUNT_DIR}/${1}/${2}/${3}"
    sudo cp "scripts/microg/files/${3}/${3}.apk" "${MOUNT_DIR}/${1}/${2}/${3}/"

    echo "[⚙️] Setting up permissions for ${item}"
    set_permissions "${MOUNT_DIR}/${1}/${2}/${3}"
    set_permissions "${MOUNT_DIR}/${1}/${2}/${3}/${3}.apk"
    install_lib "${3}"
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

    # for lib in $(ls "scripts/microg/files/${1}/lib/armeabi-v7a"); do # 32bits libs
    #     echo "[🔵] Installing ${lib}"
    #     sudo cp "scripts/microg/files/${1}/lib/armeabi-v7a/${lib}" "${SYSTEM_DIR}/lib/"
    #     set_permissions "${SYSTEM_DIR}/lib/${lib}"
    # done
}

# Install the apks
install_apk "product_a" "priv-app" "GmsCore"
# install_apk "product_a" "priv-app" "PhoneSky" // Companion app to replace playstore, not needed for now
install_apk "system_ext_a" "priv-app" "GoogleServicesFramework"


# Setup google maps framework jar
sudo cp "scripts/microg/files/framework/com.google.android.maps.jar" "${SYSTEM_DIR}/framework/com.google.android.maps.jar"
set_permissions "${SYSTEM_DIR}/framework/com.google.android.maps.jar"
sudo cp "scripts/microg/files/permissions/com.google.android.maps.xml" "${SYSTEM_DIR}/etc/permissions/com.google.android.maps.xml"
set_permissions "${SYSTEM_DIR}/etc/permissions/com.google.android.maps.xml"

sudo cp "scripts/microg/files/sysconfig/google.xml" "${SYSTEM_EXT_DIR}/etc/sysconfig/google.xml"
set_permissions "${SYSTEM_EXT_DIR}/etc/sysconfig/google.xml"
sudo cp "scripts/microg/files/permissions/privapp-permissions-GmsCore.xml" "${SYSTEM_EXT_DIR}/etc/permissions/privapp-permissions-GmsCore.xml"
set_permissions "${SYSTEM_EXT_DIR}/etc/permissions/privapp-permissions-GmsCore.xml"
sudo cp "scripts/microg/files/default-permissions/default-permissions-GmsCore.xml" "${SYSTEM_EXT_DIR}/etc/default-permissions/default-permissions-GmsCore.xml"
set_permissions "${SYSTEM_EXT_DIR}/etc/default-permissions/default-permissions-GmsCore.xml"

sudo cp "scripts/microg/files/etc/microg.xml" "${SYSTEM_EXT_DIR}/etc/microg.xml"
set_permissions "${SYSTEM_EXT_DIR}/etc/microg.xml"

sudo rm -rf "{SYSTEM_EXT_DIR}/priv-app/MtkSettingsProvider"
sudo cp -R "scrips/microg/files/MtkSettingsProvider" "{SYSTEM_EXT_DIR}/priv-app/"
sudo chown -R 0:0 "{SYSTEM_EXT_DIR}/priv-app/MtkSettingsProvider"
sudo chmod -R 0644 "{SYSTEM_EXT_DIR}/priv-app/MtkSettingsProvider"
sudo chcon -R "u:object_r:system_file:s0" "{SYSTEM_EXT_DIR}/priv-app/MtkSettingsProvider"

echo "[✅] Installation complete!"
