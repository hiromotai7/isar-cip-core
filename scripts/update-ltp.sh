#!/bin/bash

REPO_ROOT=$(git rev-parse --show-toplevel)
pushd "${REPO_ROOT}"/recipes-core/ltp > /dev/null || exit

LATEST_VER=$(git ls-remote --refs --tags  https://github.com/linux-test-project/ltp.git | \
	cut --delimiter='/' --fields=3 | \
	sort --version-sort | tail --lines=1)

SHA256FILE="ltp-full-${LATEST_VER}.tar.xz.sha256"
rm -rf "${SHA256FILE}"

wget -q "https://github.com/linux-test-project/ltp/releases/download/${LATEST_VER}/${SHA256FILE}"

SHA256SUM=$(cut -f 1 -d " " "${SHA256FILE}")
RECIPE="ltp-full_${LATEST_VER}.bb"

if [ ! -f "${RECIPE}" ]; then
	git mv ltp-full*.bb "${RECIPE}"

	sed -i 's/\(SRC_URI\[sha256sum\] = "\).*/\1'"${SHA256SUM}"'"'/ "${RECIPE}"
	git add "${RECIPE}"

	git commit -asm "recipes-core: ltp: Update to ${LATEST_VER}"
fi

rm -rf "${SHA256FILE}"

popd > /dev/null || exit
