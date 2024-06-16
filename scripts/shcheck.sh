#!/usr/bin/env bash

# Copyright 2017-present Open Networking Foundation
#
# SPDX-License-Identifier: Apache-2.0

# shcheck.sh - check shell scripts with shellcheck

set +e -u -o pipefail
fail_shellcheck=0

# verify that we have shellcheck-lint installed
command -v shellcheck  >/dev/null 2>&1 || { echo "shellcheck not found, please install it" >&2; exit 1; }

# when not running under Jenkins, use current dir as workspace
WORKSPACE=${WORKSPACE:-.}

echo "=> Linting shell script with $(shellcheck --version)"

while IFS= read -r -d '' sf
do
  echo "==> CHECKING: ${sf}"
  shellcheck "${sf}"
  rc=$?
  if [[ $rc != 0 ]]; then
    echo "==> LINTING FAIL: ${sf}"
    fail_shellcheck=1
  fi
done < <(find "${WORKSPACE}" \( -name "*.sh" -o -name "*.bash" \) -print0)

exit ${fail_shellcheck}

