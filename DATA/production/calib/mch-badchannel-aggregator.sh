#!/bin/bash

source common/setenv.sh

# ---------------------------------------------------------------------------------------------------------------------
# Set general arguments
source common/getCommonArgs.sh

PROXY_INSPEC="A:MCH/PDIGITS/0"
CONSUL_ENDPOINT="alio2-cr1-hv-aliecs.cern.ch:8500"

MCH_END_OF_STREAM_ONLY=${MCH_END_OF_STREAM_ONLY:-true}
MCH_CALIBRATOR_MAX_PED=${MCH_CALIBRATOR_MAX_PED:-500.0}
MCH_CALIBRATOR_MAX_NOISE=${MCH_CALIBRATOR_MAX_NOISE:-2.0}
MCH_CALIBRATOR_MIN_STAT=${MCH_CALIBRATOR_MIN_STAT:-100}
MCH_CALIBRATOR_MIN_FRACTION=${MCH_CALIBRATOR_MIN_FRACTION:-0.5}

BADCHANNEL_CONFIG="${ARGS_ALL_CONFIG};MCHBadChannelCalibratorParam.maxPed=${MCH_CALIBRATOR_MAX_PED};MCHBadChannelCalibratorParam.maxNoise=${MCH_CALIBRATOR_MAX_NOISE};MCHBadChannelCalibratorParam.minRequiredNofEntriesPerChannel=${MCH_CALIBRATOR_MIN_STAT};MCHBadChannelCalibratorParam.minRequiredCalibratedFraction=${MCH_CALIBRATOR_MIN_FRACTION};MCHBadChannelCalibratorParam.onlyAtEndOfStream=${MCH_END_OF_STREAM_ONLY}"

WORKFLOW="o2-dpl-raw-proxy $ARGS_ALL --proxy-name mch-badchannel-input-proxy --dataspec \"$PROXY_INSPEC\" --network-interface ib0 --channel-config \"name=mch-badchannel-input-proxy,method=bind,type=pull,rateLogging=0,transport=zeromq\" | "
WORKFLOW+="o2-calibration-mch-badchannel-calib-workflow $ARGS_ALL --configKeyValues \"$BADCHANNEL_CONFIG\" | "
WORKFLOW+="o2-calibration-ccdb-populator-workflow $ARGS_ALL --configKeyValues \"$ARGS_ALL_CONFIG\" --ccdb-path=\"http://o2-ccdb.internal\" --sspec-min 0 --sspec-max 0 | "
WORKFLOW+="o2-calibration-ccdb-populator-workflow $ARGS_ALL --configKeyValues \"$ARGS_ALL_CONFIG\" --ccdb-path=\"http://alio2-cr1-flp199.cern.ch:8083\" --sspec-min 1 --sspec-max 1 --name-extention dcs | "
WORKFLOW+="o2-qc $ARGS_ALL --config consul-json://${CONSUL_ENDPOINT}/o2/components/qc/ANY/any/mch-badchannel | "
WORKFLOW+="o2-dpl-run $ARGS_ALL $GLOBALDPLOPT"

if [ $WORKFLOWMODE == "print" ]; then
  echo Workflow command:
  echo $WORKFLOW | sed "s/| */|\n/g"
else
  # Execute the command we have assembled
  WORKFLOW+=" --$WORKFLOWMODE"
  eval $WORKFLOW
fi
