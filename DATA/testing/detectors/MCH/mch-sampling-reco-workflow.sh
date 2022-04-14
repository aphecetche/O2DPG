#!/bin/bash

source common/setenv.sh

# ---------------------------------------------------------------------------------------------------------------------
# Set general arguments
ARGS_ALL="--session default --severity $SEVERITY --shm-segment-size $SHMSIZE $ARGS_ALL_EXTRA"
ARGS_ALL+=" --infologger-severity $INFOLOGGER_SEVERITY"
ARGS_ALL+=" --monitoring-backend influxdb-unix:///tmp/telegraf.sock --resources-monitoring 60"
if [ $SHMTHROW == 0 ]; then
  ARGS_ALL+=" --shm-throw-bad-alloc 0"
fi
if [ $NORATELOG == 1 ]; then
  ARGS_ALL+=" --fairmq-rate-logging 0"
fi
ARGS_ALL_CONFIG="NameConf.mDirGRP=$FILEWORKDIR;NameConf.mDirGeom=$FILEWORKDIR;NameConf.mDirCollContext=$FILEWORKDIR;NameConf.mDirMatLUT=$FILEWORKDIR;keyval.input_dir=$FILEWORKDIR;keyval.output_dir=/dev/null;$ALL_EXTRA_CONFIG"

PROXY_INSPEC="A:MCH/RAWDATA;B:FLP/DISTSUBTIMEFRAME/0"
CONSUL_ENDPOINT="alio2-cr1-hv-aliecs.cern.ch:8500"

WORKFLOW="o2-dpl-raw-proxy ${ARGS_ALL} --dataspec \"$PROXY_INSPEC\" --channel-config \"name=readout-proxy,type=pull,method=connect,address=ipc://@$INRAWCHANNAME,transport=shmem,rateLogging=0\" | "
WORKFLOW+="o2-mch-raw-to-digits-workflow ${ARGS_ALL} --pipeline mch-data-decoder:4 --configKeyValues \"MCHCoDecParam.sampaBcOffset=31;HBFUtils.nHBFPerTF=128\" --time-reco-mode bcreset | "

WORKFLOW+="o2-datasampling-standalone ${ARGS_ALL} --config json://$O2DPG_ROOT/DATA/testing/detectors/MCH/datasampling.json | "

WORKFLOW+="o2-mch-digits-filtering-workflow ${ARGS_ALL} --input-digits-data-description \"S-DIGITS\" --input-digitrofs-data-description \"S-DIGITROFS\" --disable-mc true | "

WORKFLOW+="o2-mch-digits-to-timeclusters-workflow ${ARGS_ALL} --input-digits-data-description \"F-DIGITS\" --input-digitrofs-data-description \"F-DIGITROFS\" --mch-debug | "

WORKFLOW+="o2-mch-digits-to-preclusters-workflow ${ARGS_ALL} --check-no-leftover-digits off | "

WORKFLOW+="o2-qc $ARGS_ALL --config consul-json://${CONSUL_ENDPOINT}/o2/components/qc/ANY/any/mch-qcmn-epn-digits-expert-direct | "

WORKFLOW+="o2-dpl-run $ARGS_ALL $GLOBALDPLOPT"


if [ $WORKFLOWMODE == "print" ]; then
  echo Workflow command:
  echo $WORKFLOW | sed "s/| */|\n/g"
else
  # Execute the command we have assembled
  WORKFLOW+=" --$WORKFLOWMODE"
  eval $WORKFLOW
fi