#!/bin/bash

source common/setenv.sh

source common/getCommonArgs.sh

PROXY_INSPEC="A:MCH/RAWDATA;B:FLP/DISTSUBTIMEFRAME/0"
CONSUL_ENDPOINT="alio2-cr1-hv-aliecs.cern.ch:8500"

WORKFLOW="o2-dpl-raw-proxy ${ARGS_ALL} --dataspec \"$PROXY_INSPEC\" --channel-config \"name=readout-proxy,type=pull,method=connect,address=ipc://@$INRAWCHANNAME,transport=shmem,rateLogging=0\" | "
WORKFLOW+="o2-mch-raw-to-digits-workflow ${ARGS_ALL} --pipeline mch-data-decoder:12 --configKeyValues \"${ARGS_ALL_CONFIG};MCHCoDecParam.sampaBcOffset=31;HBFUtils.nHBFPerTF=128\" --time-reco-mode bcreset | "

WORKFLOW+="o2-datasampling-standalone ${ARGS_ALL} --config json://$O2DPG_ROOT/DATA/testing/detectors/MCH/datasampling.json | "

WORKFLOW+="o2-mch-digits-filtering-workflow ${ARGS_ALL} --input-digits-data-description \"S-DIGITS\" --input-digitrofs-data-description \"S-DIGITROFS\" --disable-mc true | "
WORKFLOW+="o2-mch-digits-to-timeclusters-workflow ${ARGS_ALL} --only-trackable --input-digits-data-description \"F-DIGITS\" --input-digitrofs-data-description \"F-DIGITROFS\" --mch-debug | "
WORKFLOW+="o2-mch-digits-to-preclusters-workflow ${ARGS_ALL} --check-no-leftover-digits off | "

WORKFLOW+="o2-mch-preclusters-to-clusters-original-workflow ${ARGS_ALL} --configKeyValues \"${ARGS_ALL_CONFIG};MCHClustering.defaultClusterResolution=0.4;MCHClustering.lowestPadCharge=100.\" | "
WORKFLOW+="o2-mch-clusters-transformer-workflow ${ARGS_ALL} --configKeyValues \"${ARGS_ALL_CONFIG}\" | "
WORKFLOW+="o2-mch-clusters-to-tracks-workflow ${ARGS_ALL} --configKeyValues \"${ARGS_ALL_CONFIG};MCHTracking.chamberResolutionX=0.1;MCHTracking.chamberResolutionY=0.1;MCHTracking.sigmaCutForTracking=3.;MCHTracking.sigmaCutForImprovement=3.\" | "

#WORKFLOW+="o2-qc $ARGS_ALL --config consul-json://${CONSUL_ENDPOINT}/o2/components/qc/ANY/any/mch-qcmn-epn-digits-expert-direct | "

WORKFLOW+="o2-dpl-run $ARGS_ALL $GLOBALDPLOPT"


if [ $WORKFLOWMODE == "print" ]; then
  echo Workflow command:
  echo $WORKFLOW | sed "s/| */|\n/g"
else
  # Execute the command we have assembled
  WORKFLOW+=" --$WORKFLOWMODE"
  eval $WORKFLOW
fi