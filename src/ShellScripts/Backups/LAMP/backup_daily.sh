#!/bin/sh

# Daily backups go into a dated directory
DATE=`date +%Y-%m-%d`
BACKUPBASEDIR="/home/backup"
BACKUPDIR=$BACKUPBASEDIR"/daily/"$DATE
mkdir -p $BACKUPDIR

# MySQL databases...
MYSQLDIR=$BACKUPDIR"/mysql"
mkdir -p $MYSQLDIR
USER="root"
PASS="mypassword"

# MySQL Database Full Backups
DBSFULL='
feeds
media
mydns
mysql
system
'

# Site contents
SITESBASEDIR="/home/sites"


for DB in $DBSFULL; do
	echo "DB: [$DB]";
	DBFILE=$MYSQLDIR"/db_"$DB"_"$DATE".sql"
	if [ -f $DBFILE ]
	then
		echo "Already have "$DBFILE
	else
		mysqldump -u $USER -p$PASS $DB > $DBFILE
		gzip $DBFILE
	fi
done

# MySQL Database Schema-only Backups
DBSSCHEMA='
phpsession
'

for DB in $DBSSCHEMA; do
	echo "DB: [$DB]";
	DBFILE=$MYSQLDIR"/db_"$DB"_"$DATE".sql"
	if [ -f $DBFILE ]
	then
		echo "Already have "$DBFILE
	else
		mysqldump -u $USER -p$PASS $DB > $DBFILE
		gzip $DBFILE
	fi
done


# Sites
SITESDIR=$BACKUPDIR"/sites"
mkdir -p $SITESDIR

SITES=`ls -1 /home/sites`
for SITE in $SITES; do
	echo "SITE: [$SITE]";
	SITEFILE=$SITESDIR"/site_"$SITE".tgz"
	if [ -f $SITEFILE ]
	then
		echo "Already have "$SITEFILE
	else
		tar -czf $SITEFILE --directory $SITESBASEDIR --exclude-from $BACKUPBASEDIR/exclusions.txt $SITE
	fi
done

# Capture weeklies
DOW=`date +%u`
if [ $DOW -eq 1 ]
then
	WEEKLYDIR=$BACKUPBASEDIR"/weekly/"$DATE
	cp -Rf $BACKUPDIR $WEEKLYDIR
fi

# Capture monthlies
DOM=`date +%d`
if [ $DOM -eq 01 ]
then
	MONTHLYDIR=$BACKUPBASEDIR"/monthly/"$DATE
	cp -Rf $BACKUPDIR $MONTHLYDIR
fi


# Clean up old rotating backups

# We're not doing hourlies, but if we did they would look like this:
#find $BACKUPBASEDIR/hourly -mindepth -mtime +1 -exec /bin/rm -Rf {} \;

# We'll keep 14 dailies
find $BACKUPBASEDIR/daily -mindepth 1 -mtime +14 -exec /bin/rm -Rf {} \;

# we'll keep 8 weeklies (8*7 days = 56)
find $BACKPBASEDIR/weekly -mindepth 1 -mtime +56 -exec /bin/rm -Rf {} \;

# we'll keep 4 monthlies (4*31 days = 124)
find $BACKUPBASEDIR/monthly -mindepth 1 -mtime +124 -exec /bin/rm -Rf {} \;

