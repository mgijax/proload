#!/bin/sh
#
#  proload.sh
###########################################################################
#
#  Purpose:
# 	This script creates Protein Ontology vocload and assocload
#       input file and invokes vocload and assocload
#
  Usage=proload.sh
#
#  Env Vars:
#
#      See the configuration file
#
#  Inputs:
#
#      - Common configuration file -
#               /usr/local/mgi/live/mgiconfig/master.config.sh
#      - PRO load configuration file - proload.config
#      - input file - see python script header
#
#
#  Outputs:
#
#      - An archive file
#      - Log files defined by the environment variables ${LOG_PROC},
#        ${LOG_DIAG}, ${LOG_CUR} and ${LOG_VAL}
#      - Input files for vocload and assocload
#      - see vocload and assocload outputs
#      - Records written to the database tables
#      - Exceptions written to standard error
#      - Configuration and initialization errors are written to a log file
#        for the shell script
#
#  Exit Codes:
#
#      0:  Successful completion
#      1:  Fatal error occurred
#      2:  Non-fatal error occurred
#
#  Assumes:  Nothing
#
# History:
#
# sc	12/18/2009 - created
#

cd `dirname $0`
LOG=`pwd`/proload.log
rm -rf ${LOG}

CONFIG_LOAD=../proload.config

#
# verify & source the configuration file
#

if [ ! -r ${CONFIG_LOAD} ]
then
    echo "Cannot read configuration file: ${CONFIG_LOAD}"
    exit 1
fi

. ${CONFIG_LOAD}

#
#  Source the DLA library functions.
#

if [ "${DLAJOBSTREAMFUNC}" != "" ]
then
    if [ -r ${DLAJOBSTREAMFUNC} ]
    then
        . ${DLAJOBSTREAMFUNC}
    else
        echo "Cannot source DLA functions script: ${DLAJOBSTREAMFUNC}" | tee -a ${LOG}
        exit 1
    fi
else
    echo "Environment variable DLAJOBSTREAMFUNC has not been defined." | tee -a ${LOG}
    exit 1
fi

#####################################
#
# Main
#
#####################################

#
# createArchive including OUTPUTDIR, startLog, getConfigEnv
# sets "JOBKEY"
preload ${OUTPUTDIR}

#
# create input files
#
echo 'Running createInputFiles.py' >> ${LOG_DIAG}
${PROLOAD}/bin/createInputFiles.py
STAT=$?
checkStatus ${STAT} "${PROLOAD}/bin/createInputFiles.py"

#
# run the vocabulary load
#
echo "Running vocload to load Protein Ontology" >> ${LOG_DIAG}
${VOCLOAD}/runSimpleFullLoad.sh ${PROLOAD}/vocload.config
STAT=$?
checkStatus ${STAT} "${VOCLOAD}/runSimpleFullLoad.sh ${PROLOAD}/vocload.config"

#
# run association load
#

# set to full path for assocload
CONFIG_LOAD=${PROLOAD}/proload.config

echo "Running Protein Ontology association load" >> ${LOG_DIAG}
${ASSOCLOADER_SH} ${CONFIG_LOAD} ${JOBKEY}
STAT=$?
checkStatus ${STAT} "${ASSOCLOADER_SH} ${CONFIG_LOAD}"

#
# run postload cleanup and email logs
#
shutDown
