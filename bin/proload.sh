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
# There should be a "lastrun" file in the input directory that was created
# the last time the load was run for this input file. If this file exists
# and is more recent than the input file, the load does not need to be run.
#
LASTRUN_FILE=${INPUTDIR}/lastrun
if [ -f ${LASTRUN_FILE} ]
then
    if test ${LASTRUN_FILE} -nt ${INFILE_NAME_PRO}
    then
        echo "Input file has not been updated - skipping load" | tee -a ${LOG_PROC}
	# set STAT for shutdown
	STAT=0
	echo 'shutting down'
        shutDown
	exit 0
    fi
fi

#
# create input files
#
echo 'Running createInputFiles.py' >> ${LOG_DIAG}
${PYTHON} ${PROLOAD}/bin/createInputFiles.py
STAT=$?
checkStatus ${STAT} "${PROLOAD}/bin/createInputFiles.py"

#
# run annotation load delete
#

# make temp blank file for annotload to source
# 	because our values have already been 
#	sourced from proload.config
TMP_FILE=${PROLOAD}/bin/.blank.tmp
touch $TMP_FILE

# TODO(kstone): annotload should be able to run without argument, assuming config values set

# TODO(kstone): annotload should use the ANNOTDATADIR value for generating output
#	not the current working directory

cd $ANNOTDATADIR

# do the delete
ANNOTMODE=delete
export ANNOTMODE
${ANNOTLOAD}/annotload.csh $TMP_FILE
STAT=$?
checkStatus ${STAT} "$ANNOTLOAD/annotload.csh $TMP_FILE"

cd -


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
# run annotation load
#
echo "Running Protein Ontology/Marker annotation load" >> ${LOG_DIAG}

cd $ANNOTDATADIR

# do the add
ANNOTMODE=new
export ANNOTMODE
${ANNOTLOAD}/annotload.csh $TMP_FILE
STAT=$?
checkStatus ${STAT} "$ANNOTLOAD/annotload.csh $TMP_FILE"

rm $TMP_FILE

cd -


#
# Touch the "lastrun" file to note when the load was run.
#
if [ ${STAT} = 0 ]
then
    touch ${LASTRUN_FILE}
fi

#
# run postload cleanup and email logs
#
shutDown
