#!/usr/local/bin/python

##########################################################################
#
# Purpose:
#       From PRO input file create vocload and assocload input file
#
# Usage: createInputFiles.py
# Env Vars:
#	 1. OUTFILE_NAME
#	 2. ASSOC_EXTERNAL_LDB
#	 3. INFILE_NAME_PRO
#	 4. INFILE_NAME_VOC
#	 5. INFILE_NAME (assocload)
#	 6. ANNOTINPUTFILE (annotation load)
#
# Inputs:
#	1. PRO ID to MGI mapping file tab-delimited in following format:
#	   Note that there can be multiple pro ID to marker mappings
#	   So we need to filter out dups for the vocload file
#	    1. PRO ID
#	    2. PRO name
#	    3. MGI ID(s) ';' (semi-colon) delimited
#	2. Configuration (see proload.config, vocload.config)
#
# Outputs:
#	 1. tab delimited file vocload format:
#           1. term
#           2. accession id
#           3. blank
#           4. blank
#           5. blank
#           6. blank
#           7. blank
#           8. blank
#	 2. tab delimited file in assocload format:
#	    line 1 header: "MGI" "Protein Ontology (PRO)"
# 	    1. MGI ID
#           2. PRO ID
#	 3. tab delimited file in annotation load format:
#	    1. term ID
#	    2. marker ID
#	    3. J Number
#	    4. Evidence Code
#	    5. blank
#	    6. blank
#	    7. load user
#	    8. date
#	    9. blank
#	 4. log file
# 
# Exit Codes:
#
#      0:  Successful completion
#      1:  An exception occurred
#
#  Assumes:  Nothing
#
#  Notes:  None
#
###########################################################################

import sys
import os
import mgi_utils
import string

print '%s' % mgi_utils.date()

# PRO logical DB Name
proLDBName = os.environ['ASSOC_EXTERNAL_LDB']
# paths to input and two output files
inFilePath = os.environ['INFILE_NAME_PRO']
vocFilePath = os.environ['INFILE_NAME_VOC']
assocFilePath= os.environ['INFILE_NAME']
annotFilePath = os.environ['ANNOTINPUTFILE']

JNUMBER = os.environ['J_NUMBER']
LOAD_USER_NAME = os.environ['JOBSTREAM']
ANNOT_EVIDENCE_CODE = 'IEA'
CDATE = mgi_utils.date("%m/%d/%Y")

# file descriptors

# input
inFile = ''
# output for vocload
vocFile = ''
# output for assocload
assocFile = ''
# output for annotload
annotFile = ''

#
# Initialize
#

inFile = open(inFilePath, 'r')

vocFile = open(vocFilePath, 'w')

assocFile = open(assocFilePath, 'w')

annotFile = open(annotFilePath, 'w')

# set of IDs written to vocload file
vocIdSet = set([])

#
# Process
#

try: 

    # write out assocload header
    assocFile.write('MGI\t%s\n' % (proLDBName))

    # throw away header line
    header = inFile.readline()

    for line in inFile.readlines():
	(proId, proName, mgiId) = string.split(line, '\t')
	proId = string.strip(proId)
	proName = string.strip(proName)
	mgiId = string.strip(mgiId)
	
	# vocload file
	if proId not in vocIdSet:
	    vocFile.write('%s\n' % '\t'.join(
		[proName, 
		 proId,
		 '',
		 '',
		 '',
		 '',
		 '',
		 ''
		]
	    ))
	vocIdSet.add(proId)

	# association file
	assocFile.write('%s\n' % '\t'.join(
		[mgiId,
		 proId
		]
	))

	# annotation file
	annotFile.write('%s\n' % '\t'.join(
		[proId,
		 mgiId,
		 JNUMBER,
		 ANNOT_EVIDENCE_CODE,
		 '',
		 '',
		 LOAD_USER_NAME,
		 CDATE,
		 ''
		]
	))

finally:

    inFile.close()
    vocFile.close()
    assocFile.close()

print '%s' % mgi_utils.date()
