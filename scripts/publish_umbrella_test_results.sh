#!/bin/bash
# uncomment to debug the script
#set -x
# copy the script below into your app code repo (e.g. ./scripts/publish_umbrella_test_results.sh.sh) and 'source' it from your pipeline job
#    source ./scripts/publish_umbrella_test_results.sh.sh
# alternatively, you can source it from online script:
#    source <(curl -sSL "https://raw.githubusercontent.com/open-toolchain/commons/master/scripts/publish_umbrella_test_results.sh.sh")
# ------------------
# source: https://raw.githubusercontent.com/open-toolchain/commons/master/scripts/publish_umbrella_test_results.sh.sh

# This script does upload current test results for all components in an given umbrella chart which would be updated from respective CI pipelines (see also https://raw.githubusercontent.com/open-toolchain/commons/master/scripts/check_umbrella_gate.sh)

echo "Build environment variables:"
echo "BUILD_NUMBER=${BUILD_NUMBER}"
echo "CHART_PATH=${CHART_PATH}"
echo "FILE_LOCATION=${FILE_LOCATION}"
echo "TEST_TYPE=${TEST_TYPE}"

# copy latest version of each component insights config
if [[ ! -d ./insights ]]; then
  echo "Cannot find Insights config information in /insights folder"
  exit 1
fi

# Install DRA CLI
export PATH=/opt/IBM/node-v4.2/bin:$PATH
npm install -g grunt-idra3

ls ./insights/*
for INSIGHT_CONFIG in $( ls -v ${CHART_PATH}/insights); do
  echo -e "Checking gate for component: ${INSIGHT_CONFIG}"
  source ${CHART_PATH}/insights/${INSIGHT_CONFIG}
  echo -e "LOGICAL_APP_NAME: ${LOGICAL_APP_NAME}"
  echo -e "BUILD_PREFIX: ${BUILD_PREFIX}"
  echo -e "PIPELINE_STAGE_INPUT_REV: ${PIPELINE_STAGE_INPUT_REV}"
  # publish the results for all components
  idra --publishtestresult --filelocation=${FILE_LOCATION} --type=${TEST_TYPE}

  # get the process exit code
  RESULT=$?  
  if [[ ${RESULT} != 0 ]]; then
      exit ${RESULT}
  fi
done

exit 0