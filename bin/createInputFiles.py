#!/usr/local/bin/python

##########################################################################
#
# Purpose:
#       From PRO input file create vocload and assocload input file
#
# Usage: createInputFiles.py
# Env Vars:
#	 1. OUTFILE_NAME
#
# Inputs:
#	1. PRO ID to MGI mapping file tab-delimited in following format:
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
#	 3. log file
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
import loadlib
import string

print '%s' % mgi_utils.date()

# PRO logical DB Name
proLDBName = os.environ['ASSOC_EXTERNAL_LDB']
# paths to input and two output files
inFilePath = os.environ['INFILE_NAME_PRO']
vocFilePath = os.environ['INFILE_NAME_VOC']
assocFilePath= os.environ['INFILE_NAME']

# file descriptors

# input
inFile = ''
# output for vocload
vocFile = ''
# output for assocload
assocFile = ''

TAB= '\t'
CRT = '\n'
SPACE = ' '

#
# Initialize
#

try:
    inFile = open(inFilePath, 'r')
except:
    exit('Could not open file for reading %s\n' % inFilePath)

try:
    vocFile = open(vocFilePath, 'w')
except:
    exit('Could not open file for writing %s\n' % vocFilePath)

try:
    assocFile = open(assocFilePath, 'w')
except:
    exit('Could not open file for writing %s\n' % assocFilePath)

#
# Process
#

# write out assocload header
assocFile.write('%s%s%s%s' % ('MGI', TAB, proLDBName, CRT))

# throw away header line
header = inFile.readline()

for line in inFile.readlines():
    (proId, proName, mgiId) = string.split(line, TAB)
    proId = string.strip(proId)
    proName = string.strip(proName)
    mgiIds = string.strip(mgiId)
    #mgiId = "MGI:%s" % mgiId
    
    vocFile.write('%s%s%s%s%s%s%s%s%s%s' % (proName, TAB, proId, TAB, TAB, TAB, TAB, TAB, TAB, CRT))
    for m in string.split(mgiIds, ';'):
        mgiId = string.strip(m)
	assocFile.write('%s%s%s%s' % (mgiId, TAB, proId, CRT))
    
#
# Post Process
#

inFile.close()
vocFile.close()
assocFile.close()

print '%s' % mgi_utils.date()
