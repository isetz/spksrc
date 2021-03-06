#!/bin/sh

# Package
PACKAGE="transmission"
DNAME="Transmission"

# Others
INSTALL_DIR="/usr/local/${PACKAGE}"
PATH="${INSTALL_DIR}/bin:/usr/local/bin:/bin:/usr/bin:/usr/syno/bin"
RUNAS="transmission"
CFG_FILE="${INSTALL_DIR}/var/settings.json"
TMP_DIR="${SYNOPKG_PKGDEST}/../../@tmp"


preinst ()
{
    # Installation wizard requirements
    if [ "${SYNOPKG_PKG_STATUS}" != "UPGRADE" ] && [ ! -d "${wizard_download_dir}" ]; then
        exit 1
    fi

    exit 0
}

postinst ()
{
    # Link
    ln -s ${SYNOPKG_PKGDEST} ${INSTALL_DIR}

    # Install busybox stuff
    ${INSTALL_DIR}/bin/busybox --install ${INSTALL_DIR}/bin

    # Create user
    adduser -h ${INSTALL_DIR}/var -g "${DNAME} User" -G users -s /bin/sh -S -D ${RUNAS}

    # Edit the configuration according to the wizzard
    sed -i -e "s|@download_dir@|${wizard_download_dir}|g" ${CFG_FILE}
    if [ -d "${wizard_watch_dir}" ]; then
        sed -i -e "s|@watch_dir_enabled@|true|g" ${CFG_FILE}
        sed -i -e "s|@watch_dir@|${wizard_watch_dir}|g" ${CFG_FILE}
    else
        sed -i -e "s|@watch_dir_enabled@|false|g" ${CFG_FILE}
        sed -i -e "/@watch_dir@/d" ${CFG_FILE}
    fi

    # Correct the files ownership
    chown -R ${RUNAS}:root ${SYNOPKG_PKGDEST}

    exit 0
}

preuninst ()
{
    # Remove the user (if not upgrading)
    if [ "${SYNOPKG_PKG_STATUS}" != "UPGRADE" ]; then
        deluser ${RUNAS}
    fi

    exit 0
}

postuninst ()
{
    # Remove link
    rm -f ${INSTALL_DIR}

    exit 0
}

preupgrade ()
{
    # Save some stuff
    rm -fr ${TMP_DIR}/${PACKAGE}
    mkdir -p ${TMP_DIR}/${PACKAGE}
    mv ${INSTALL_DIR}/var ${TMP_DIR}/${PACKAGE}/

    exit 0
}

postupgrade ()
{
    # Restore some stuff
    rm -fr ${INSTALL_DIR}/var
    mv ${TMP_DIR}/${PACKAGE}/var ${INSTALL_DIR}/
    rm -fr ${TMP_DIR}/${PACKAGE}

    exit 0
}

