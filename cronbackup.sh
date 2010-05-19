#!/bin/bash

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#      Name: CronBackup                                                        #
#   Version: 1.0 Beta ($Id$)  #
#    Author: Jan Erik Zassenhaus (sisko1990@users.sourceforge.net)             #
# Copyright: Copyright (C) 2010 Jan Erik Zassenhaus. All rights reserved.      #
#   License: GNU/GPL, see LICENSE.txt                                          #
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
# This file is part of the CronBackup project.                                 #
#                                                                              #
# CronBackup is free software: you can redistribute it and/or modify           #
# it under the terms of the GNU General Public License v3 as published         #
# by the Free Software Foundation.                                             #
#                                                                              #
# CronBackup is distributed in the hope that it will be useful,                #
# but WITHOUT ANY WARRANTY; without even the implied warranty of               #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the                 #
# GNU General Public License for more details.                                 #
#                                                                              #
# You should have received a copy of the GNU General Public License            #
# along with CronBackup. If not, see: http://www.gnu.org/licenses/.            #
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#


################################ BACKUP SETTINGS ###############################
## Here you can manage some settings for the backup process.                  ##
################################################################################

######################### BACKUP SETTINGS: BACKUP TYPE #########################
## Provide here the backup type you wish.                                     ##
## Available types: "Database", "Files" or "Both"                             ##
################################################################################
BACKUP_TYPE="Files"

###################### BACKUP SETTINGS: DELETE OLD BACKUPS #####################
## Choose when old backup files get deleted by the script.                    ##
## Please note: ALL files stored in the particular backup path will be        ##
##              deleted after the entered time!                               ##
## To disable cleaning, just enter "No".                                      ##
################################################################################
CLEAN="20" # e.g. "20" days or "No"

######################### BACKUP SETTINGS: BACKUP PATH #########################
## Provide here the path to save backups to.                                  ##
## Please note: If the path does not exist the script will try to create it!  ##
################################################################################
BACKUP_PATH="/backup"

######################### BACKUP SETTINGS: ARCHIVE TYPE ########################
## Choose here the type of the backup archive.                                ##
## Please note: You can choose different types, one for the files and         ##
##              another for the database backup.                              ##
## Available types: "Zip", "Tar", "Gzip" or "Bzip2"                           ##
################################################################################
ARCHIVE_TYPE_FILES="Gzip"
ARCHIVE_TYPE_DATABASE="Bzip2"

###################### BACKUP SETTINGS: COMPRESSION LEVEL ######################
## Provide here the level of compression for the archives.                    ##
## Please note: This function is only available for "Zip" and                 ##
##              "Gzip" compression!                                           ##
## Available levels: "1" till "9". To use system default enter "0".           ##
################################################################################
COMPRESS_LEVEL_FILES="5"
COMPRESS_LEVEL_DATABASE="9"

################################################################################


################################### DATABASE ###################################
## Here you can provide your database details.                                ##
## (Required for types: "Database" and "Both")                                ##
################################################################################

################################ DATABASE: DATA ################################
## Provide here all necessary database settings.                              ##
##   1. The database server (database host).                                  ##
##   2. The username to get access to the database.                           ##
##   3. The password to get access to the database.                           ##
##   4. The name of the database. (or "All")                                  ##
##   5. The default storage engine of the database.                           ##
##      ("MyISAM", "InnoDB" or "None")                                        ##
################################################################################
DB_DATA[0]="host1|username1|password1|database1|MyISAM"

# More examples:
#DB_DATA[1]="host2|username2|password2|database2|InnoDB"
#DB_DATA[2]="host3|username3|password3|database3|None"

############################# DATABASE: BACKUP PATH ############################
## Where to save the database backup to.                                      ##
## Please note: The path is located under the entered path in                 ##
##              "BACKUP SETTINGS: BACKUP PATH"!                               ##
##              If the path does not exist the script will try to create it!  ##
################################################################################
BACKUP_PATH_DATABASE="/database"

################################################################################


##################################### FILES ####################################
## Here you can provide your file system details.                             ##
## (Required for types: "Files" and "Both")                                   ##
################################################################################

################################# FILES: SOURCE ################################
## The absolute path which you want a backup from. (Without an opening slash!)##
## Please note: To define more folders, seperate each with a space:           ##
##              "htdocs/f1 htdocs/f2 logs"                                    ##
################################################################################
BACKUP_FILES="htdocs/folder"

############################## FILES: BACKUP PATH ##############################
## Where to save the files backup to.                                         ##
## Please note: The path is located under the entered path in                 ##
##              "BACKUP SETTINGS: BACKUP PATH"!                               ##
##              If the path does not exist the script will try to create it!  ##
################################################################################
BACKUP_PATH_FILES="/files"

################################################################################


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#+++++++++++++++++++++++++++++++++ NO CHANGES! ++++++++++++++++++++++++++++++++#
#++++++++++++++++++++++++ UNLESS YOU KNOW WHAT YOU DO! ++++++++++++++++++++++++#
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#

# Define some programmes
PMYSQLDUMP=$(which mysqldump)
PMYSQL=$(which mysql)
PTAR=$(which tar)
PZIP=$(which zip)
PGZIP=$(which gzip)
PBZIP2=$(which bzip2)


# Functions - START #
## Database backup - START ##
createDatabaseBackup ()
{
  echo "--- DATABASE(S) ---"
  for db in ${DB_DATA[@]}
  do
    # Read out the database information
    HOST=`echo $db | cut -d "|" -f1`
    USERNAME=`echo $db | cut -d "|" -f2`
    PASSWORD=`echo $db | cut -d "|" -f3`
    DATABASE=`echo $db | cut -d "|" -f4`
    ENGINE=`echo $db | cut -d "|" -f5`
    
    # Create directory if it does not exist
    mkdir -p $BACKUP_PATH$BACKUP_PATH_DATABASE
    
    # Go into the path
    cd $BACKUP_PATH$BACKUP_PATH_DATABASE
    
    # Define the options for MySQLDump
    MYISAM="--add-drop-table --add-locks --create-options --disable-keys --extended-insert --lock-tables --quick --compress --set-charset"
    INNODB="--single-transaction --quick --compress --extended-insert"
    NONE="--add-drop-table --create-options --extended-insert --quick --compress --set-charset"
    GENERAL="-h$HOST -u$USERNAME -p$PASSWORD"
    
    # Optimize the database before dumping it
    if [ $DATABASE != "All" ]; then
      echo -e "-> Optimizing of $DATABASE database... \c"
      $PMYSQLDUMP $GENERAL --add-drop-table --no-data $DATABASE | grep ^DROP | sed 's/DROP TABLE IF EXISTS/OPTIMIZE TABLE/g' | $PMYSQL $GENERAL $DATABASE > /dev/null
      echo "OK!"
    fi
    
    # Check which default storage engine we have
    echo -e "-> Create dump of $DATABASE database(s)... \c"
    if [ $ENGINE = "MyISAM" ]; then
      if [ $DATABASE = "All" ]; then
        DATABASE="all_databases"
        $PMYSQLDUMP $MYISAM $GENERAL --all-databases > $DATABASE".sql"
      else
        $PMYSQLDUMP $MYISAM $GENERAL $DATABASE > $DATABASE".sql"
      fi
    elif [ $ENGINE = "InnoDB" ]; then
      if [ $DATABASE = "All" ]; then
        DATABASE="all_databases"
        $PMYSQLDUMP $INNODB $GENERAL --all-databases > $DATABASE".sql"
      else
        $PMYSQLDUMP $INNODB $GENERAL $DATABASE > $DATABASE".sql"
      fi
    else
      if [ $DATABASE = "All" ]; then
        DATABASE="all_databases"
        $PMYSQLDUMP $NONE $GENERAL --all-databases > $DATABASE".sql"
      else
        $PMYSQLDUMP $NONE $GENERAL $DATABASE > $DATABASE".sql"
      fi
    fi
    echo "OK!"
    
    # Set the correct compression level
    if [ $COMPRESS_LEVEL_DATABASE = "0" ]; then
      LEV=""
    else
      LEV="-"$COMPRESS_LEVEL_DATABASE
    fi
    
    # Compress the dump into an archive
    echo -e "-> Create $ARCHIVE_TYPE_DATABASE archive of $DATABASE database(s)... \c"
    if [ $ARCHIVE_TYPE_DATABASE = "Zip" ]; then
      $PZIP -q $(date +%F"_"%H"-"%M)".zip" $DATABASE".sql"
    elif [ $ARCHIVE_TYPE_DATABASE = "Tar" ]; then
      $PTAR -cf $(date +%F"_"%H"-"%M)".tar" $DATABASE".sql"
    elif [ $ARCHIVE_TYPE_DATABASE = "Gzip" ]; then
      $PTAR -cf - $DATABASE".sql" | $PGZIP $LEV > $(date +%F"_"%H"-"%M)".tar.gz"
    elif [ $ARCHIVE_TYPE_DATABASE = "Bzip2" ]; then
      $PTAR -cf - $DATABASE".sql" | $PGZIP $LEV > $(date +%F"_"%H"-"%M)".tar.bz2"
    else
      echo "ERROR!: The database archive type seems wrong!"
    fi
    echo -e "OK!\n"
    
    # Delete the original SQL file
    rm $DATABASE".sql"
    
    # Unset the $LEV var
    unset LEV
  done
}
## Database backup - END ##

## Files backup - START ##
createFilesBackup ()
{
  echo "--- FILE(S) / FOLDER(S) ---"
  
  # Create directory if it does not exist
  mkdir -p $BACKUP_PATH$BACKUP_PATH_FILES
  
  # Go into the root path (for tar)
  cd /
  
  # Set the correct compression level
  if [ $COMPRESS_LEVEL_FILES = "0" ]; then
    LEV=""
  else
    LEV="-"$COMPRESS_LEVEL_FILES
  fi
  
  # Compress the files into an archive
  echo -e "-> Create $ARCHIVE_TYPE_FILES archive of $BACKUP_FILES... \c"
  if [ $ARCHIVE_TYPE_FILES = "Zip" ]; then
    $PZIP -qr $BACKUP_PATH$BACKUP_PATH_FILES"/"$(date +%F"_"%H"-"%M)".zip" $BACKUP_FILES
  elif [ $ARCHIVE_TYPE_FILES = "Tar" ]; then
    $PTAR -cf $BACKUP_PATH$BACKUP_PATH_FILES"/"$(date +%F"_"%H"-"%M)".tar" $BACKUP_FILES
  elif [ $ARCHIVE_TYPE_FILES = "Gzip" ]; then
    $PTAR -cf - $BACKUP_FILES | $PGZIP $LEV > $BACKUP_PATH$BACKUP_PATH_FILES"/"$(date +%F"_"%H"-"%M)".tar.gz"
  elif [ $ARCHIVE_TYPE_FILES = "Bzip2" ]; then
    $PTAR -cf - $BACKUP_FILES | $PGZIP $LEV > $BACKUP_PATH$BACKUP_PATH_FILES"/"$(date +%F"_"%H"-"%M)".tar.bz2"
  else
    echo "ERROR!: The files archive type seems wrong!"
  fi
  echo -e "OK!\n"
}
## Files backup - END ##

## Clean - START ##
clean ()
{
  echo "--- CLEAN ---"
  
  echo -e "-> Removing backups older than $CLEAN day(s)... \c"
  if [ $BACKUP_TYPE != "Files" ]; then
    find $BACKUP_PATH$BACKUP_PATH_DATABASE"/" -mtime +$CLEAN | xargs rm -f
  fi
  find $BACKUP_PATH$BACKUP_PATH_FILES"/" -mtime +$CLEAN | xargs rm -f
  echo -e "OK!\n"
}
## Clean - END ##

## Header - START ##
header ()
{
  echo "########################################################################"
  echo "###      BashCronBackup Copyright (C) 2010 Jan Erik Zassenhaus       ###"
  echo "### This program comes with ABSOLUTELY NO WARRANTY! License: GNU/GPL ###"
  echo -e "########################################################################\n"
}
## Header - END ##
# Functions - END #


# The programme logic and some output - START #
if [ $BACKUP_TYPE = "Both" ]; then
  header
  createDatabaseBackup
  createFilesBackup
  clean
  exit 0
elif [ $BACKUP_TYPE = "Files" ]; then
  header
  createFilesBackup
  clean
  exit 0
elif [ $BACKUP_TYPE = "Database" ]; then
  header
  createDatabaseBackup
  clean
  exit 0
else
  header
  echo "ERROR!: The backup type seems wrong!"
  exit 1
fi
# The programme logic and some output - END #