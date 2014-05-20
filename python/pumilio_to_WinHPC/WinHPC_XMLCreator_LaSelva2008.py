#!/usr/bin/python
# ---------------------------------------------------------------------------
# ClipRasters.py
# Created on: 2010-11-18 10:17:24.00000
#   (generated by ArcGIS/ModelBuilder)
# Description: 
# This script clips all rasters in a folder based on a polygon feature, and exports the slipped rasters to ASCII files.
# Written by Jarrod Doucette, FORS 208, 195 Marsteller Ave. Purdue University
# Edited by Luis J. Villanueva to get the data from Pumilio (http://ljvillanueva.github.io/pumilio)
# ---------------------------------------------------------------------------

#New version needed to specify max cores in the job, while keeping tasks at 1

##########################################################
# VARIABLES
##########################################################


#Pumilio database settings
db_hostname=''
db_database=''
db_username=''
db_password=''

#Name to give this job
NameToUse=''

#Domain and username: DOMAIN\username
ClusterUsername=''

RArguments='\\\\server\\WinHPC\\script.R ' + str(i) + ' ' + '\\\\pumilio_server\\pumilio_dir\\sounds\\sounds\\' + str(ColID) + '\\' + OriginalFilename + '"'

#number of max cores to use
MaxCores=24

# Import modules
import sys, os, MySQLdb

#Call the script giving two arguments: from and to SoundID, useful for large archives
fromID=sys.argv[1]
toID=sys.argv[2]



##########################################################
# FUNCTIONS
##########################################################


#Get a file to process from MySQL
def getfile(SoundID):
	try:
		con = MySQLdb.connect(host=db_hostname, user=db_username, passwd=db_password, db=db_database)
	except MySQLdb.Error, e:
		print "Database Error %d: %s" % (e.args[0], e.args[1])
		print "\n Could not connect to the database! leaving the program..."
		sys.exit (1)
	cursor = con.cursor()
	query = "SELECT ColID, DirID, OriginalFilename FROM Sounds WHERE SoundID = " + str(SoundID) + " AND SoundStatus=0"
	cursor.execute (query)
	row = cursor.fetchone ()
	cursor.close ()
	con.close ()
	return row

def checkfiles(fromID,toID):
	try:
		con = MySQLdb.connect(host=db_hostname, user=db_username, passwd=db_password, db=db_database)
	except MySQLdb.Error, e:
		print "Database Error %d: %s" % (e.args[0], e.args[1])
		print "\n Could not connect to the database! leaving the program..."
		sys.exit (1)
	cursor = con.cursor()
	query = "SELECT COUNT(*) FROM Sounds WHERE SoundID >= " + str(fromID) + " AND SoundID <= " + str(toID) + " AND SoundStatus=0"
	cursor.execute (query)
	row1 = cursor.fetchone ()
	cursor.close ()
	con.close ()
	return row1



##########################################################
# RUN
##########################################################

checkfiles = checkfiles(fromID,toID)[0]

if checkfiles == 0:
	print "No files in the range " + str(fromID) + " to " + str(toID)
	sys.exit (0)
else:
	print "There are " + str(checkfiles) + " files in that range\n"
	#Variable to hold xml file name 
	xmlFileName = NameToUse + "_" + str(fromID) + ".xml"
	#Create and open xml file
	xmlFile = open (xmlFileName, "w")

	#Add text that is the same for entire state

	xmlFile.write('<?xml version="1.0" encoding="utf-8"?>')
	xmlFile.write('<Job Version="3.000" Id="' + NameToUse + str(fromID) + '" Name="' + NameToUse + "_" + str(fromID) + '_' + str(toID) + '" UnitType="Core" ErrorCode="0" ErrorParams="" State="Configuring" PreviousState="Configuring" JobType="Batch" Priority="Lowest" IsBackfill="false" NextTaskNiceID="2" HasGrown="false" HasShrunk="false" OrderBy="" RequestCancel="None" RequeueCount="0" AutoRequeueCount="0" FailureReason="None" PendingReason="None" AutoCalculateMax="false" AutoCalculateMin="false" MinCores="1" MaxCores="' + str(MaxCores) + '" ParentJobId="0" ChildJobId="0" NumberOfCalls="0" NumberOfOutstandingCalls="0" CallDuration="0" CallsPerSecond="0" ProjectId="2" JobTemplateId="1" OwnerId="2" ClientSourceId="2" Project="' + Project + '" JobTemplate="Default" DefaultTaskGroupId="53" Owner="' + ClusterUsername + '"  ClientSource="HpcJobManager" xmlns="http://schemas.microsoft.com/HPCS2008R2/scheduler/">\n')
	xmlFile.write('    <Dependencies/>\n')
	xmlFile.write('    <Tasks>\n')



	for i in range(int(fromID), int(toID) + 1):

		row = getfile(i)
		if row==None:
			continue
		elif len(row)==3:
			ColID, DirID, OriginalFilename = row
	
			xmlFile.write('        <Task Version="3.000" Id="' + NameToUse + "_" + str(i) + '" ErrorCode="0" ErrorParams="" State="Configuring" PreviousState="Configuring" ParentJobId="51" RequestCancel="None" Closed="false" RequeueCount="0" AutoRequeueCount="0" FailureReason="None" PendingReason="None" InstanceId="0" RecordId="30" Name="' + Project + '_'+ str(i) + '" NiceId="1" CommandLine="&quot;C:\\Program Files\\R\\R-2.14.1\\bin\\x64\\Rscript.exe&quot; --vanilla ' + script_to_use + ' ' + str(i) + ' ' + '\\\\share\\sounds\\sounds\\' + str(ColID) + '\\' + str(DirID) + '\\' + OriginalFilename + '" MinCores="1" MaxCores="1" HasCustomProps="false" IsParametric="false" GroupId="53" ParentJobState="Configuring" UnitType="Core" ParametricRunningCount="0" ParametricCanceledCount="0" ParametricFailedCount="0" ParametricQueuedCount="0" />\n')
		            
	#Close MySQL

	xmlFile.write('\n    </Tasks>\n')
	xmlFile.write('</Job>\n')
	xmlFile.close()

