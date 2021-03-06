#!/bin/bash
. /pipeline/docker-run/markers.sh
. /pipeline/shared/duplicati.sh

function update_version_files() {
	echo "${RELEASE_NAME}" > "${DUPLICATI_ROOT}/Duplicati/License/VersionTag.txt"
	echo "${releasetype}" > "${DUPLICATI_ROOT}/Duplicati/Library/AutoUpdater/AutoUpdateBuildChannel.txt"
	UPDATE_MANIFEST_URLS="https://updates.duplicati.com/${releasetype}/latest.manifest;https://alt.updates.duplicati.com/${releasetype}/latest.manifest"
	echo "${UPDATE_MANIFEST_URLS}" > "${DUPLICATI_ROOT}/Duplicati/Library/AutoUpdater/AutoUpdateURL.txt"
	cp "${DUPLICATI_ROOT}/Updates/release_key.txt"  "${DUPLICATI_ROOT}/Duplicati/Library/AutoUpdater/AutoUpdateSignKey.txt"
}

function generate_package () {
	UPDATE_ZIP_URLS="https://updates.duplicati.com/${releasetype}/${RELEASE_FILE_NAME}.zip;https://alt.updates.duplicati.com/${releasetype}/${RELEASE_FILE_NAME}.zip"

	mkdir -p "${UPDATE_TARGET}"

	auto_update_options="\
  --input=\"${UPDATE_SOURCE}\" --output=\"${UPDATE_TARGET}\"  \
	--manifest=${DUPLICATI_ROOT}/Updates/${releasetype}.manifest --changeinfo=\"${RELEASE_CHANGEINFO}\" \
	--displayname=\"${RELEASE_NAME}\" \
	--remoteurls=\"${UPDATE_ZIP_URLS}\" --version=\"${releaseversion}\" --allow-new-key=true \
	--keyfile-password=\"${signingkeyfilepassword}\" \
	--keyfile=\"${signingkeyfile}\" \
	"
	mono "${DUPLICATI_ROOT}/BuildTools/AutoUpdateBuilder/bin/Release/AutoUpdateBuilder.exe" $auto_update_options

	mv "${UPDATE_TARGET}/package.zip" "${UPDATE_TARGET}/latest.zip"
	mv "${UPDATE_TARGET}/autoupdate.manifest" "${UPDATE_TARGET}/latest.manifest"
	cp "${UPDATE_TARGET}/latest.zip" "${UPDATE_TARGET}/${RELEASE_FILE_NAME}.zip"
	cp "${UPDATE_TARGET}/latest.manifest" "${UPDATE_TARGET}/${RELEASE_FILE_NAME}.manifest"
}

function prepare_update_source_folder () {
	mkdir -p "${UPDATE_SOURCE}"

	cp -R "${DUPLICATI_ROOT}/Duplicati/GUI/Duplicati.GUI.TrayIcon/bin/Release/"* "${UPDATE_SOURCE}"
	cp -R "${DUPLICATI_ROOT}Duplicati/Server/webroot" "${UPDATE_SOURCE}"

	# We copy some files for alphavss manually as they are not picked up by xbuild
	mkdir -p "${UPDATE_SOURCE}/alphavss"
	for FN in "${DUPLICATI_ROOT}/Duplicati/Library/Snapshots/bin/Release/"AlphaVSS.*.dll; do
		cp "${FN}" "${UPDATE_SOURCE}/alphavss/"
	done

	# Fix for some support libraries not being picked up
	for BACKEND in "${DUPLICATI_ROOT}/Duplicati/Library/Backend/"*; do
		if [ -d "${BACKEND}/bin/Release/" ]; then
			cp "${BACKEND}/bin/Release/"*.dll "${UPDATE_SOURCE}"
		fi
	done

	# Install the assembly redirects for all Duplicati .exe files
	find "${UPDATE_SOURCE}" -maxdepth 1 -type f -name Duplicati.*.exe -exec cp ${DUPLICATI_ROOT}/Installer/AssemblyRedirects.xml {}.config \;

	# Clean some unwanted build files
	for FILE in "control_dir" "Duplicati-server.sqlite" "Duplicati.debug.log" "updates"; do
		if [ -e "${UPDATE_SOURCE}/${FILE}" ]; then rm -rf "${UPDATE_SOURCE}/${FILE}"; fi
	done

	# Clean the localization spam from Azure
	for FILE in "de" "es" "fr" "it" "ja" "ko" "ru" "zh-Hans" "zh-Hant"; do
		if [ -e "${UPDATE_SOURCE}/${FILE}" ]; then rm -rf "${UPDATE_SOURCE}/${FILE}"; fi
	done

	# Clean debug files, if any
	rm -rf "${UPDATE_SOURCE}/"*.mdb "${UPDATE_SOURCE}/"*.pdb "${UPDATE_SOURCE}/"*.xml
}

travis_mark_begin "BUILDING ZIP"
update_version_files
prepare_update_source_folder
generate_package
travis_mark_end "BUILDING ZIP"
