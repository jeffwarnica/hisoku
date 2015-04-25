#! /bin/bash



if [ -z "$1" ]
then
	echo "Must supply a project name";
	exit 1
fi

if [ -z "$2" ]
then 
	echo "Must supply a url";
	exit 1
fi

APACHECONF="/etc/apache2/sites-available/$1.conf";
echo $APACHECONF
mkdir /var/www/$1
mkdir /var/www/$1/$1.git
mkdir /var/www/$1/serve
git init --bare /var/www/$1/$1.git

POSTRECEIVE="/var/www/$1/$1.git/hooks/post-recieve"
touch $POSTRECEIVE


#This part based on post-receive by Fritz Thomas
echo "#!/bin/bash" > $POSTRECEIVE
echo "DEPLOY_BRANCH=\"master\"" >> $POSTRECEIVE
echo "DEPLOY_ROOT=\"/var/www/$1/serve\"" >> $POSTRECEIVE

echo "echo \"HISOKU v0.1a\"" >> $POSTRECEIVE
echo "export GIT_DIR=\"$(cd $(dirname $(dirname $0));pwd)\"" >> $POSTRECEIVE
echo "export PROJECT_NAME=\"${GIT_DIR##*/}\"" >> $POSTRECEIVE
echo "export DEPLOY_TO=\"${DEPLOY_ROOT}/\"" >> $POSTRECEIVE
echo "export GIT_WORK_TREE=\"${DEPLOY_TO}\"" >> $POSTRECEIVE

echo "while read oldrev newrev refname" >> $POSTRECEIVE
echo "do" >> $POSTRECEIVE
 
echo "branch=$(git rev-parse --symbolic --abbrev-ref $refname)" >> $POSTRECEIVE
 
echo "if [ \"${DEPLOY_BRANCH}\" == \"$branch\" ]; then" >> $POSTRECEIVE
echo "echo \"Deploying ${PROJECT_NAME}: ${DEPLOY_BRANCH}\"" >> $POSTRECEIVE
echo "git checkout -f \"${DEPLOY_BRANCH}\"" >> $POSTRECEIVE
echo "git reset --hard HEAD" >> $POSTRECEIVE

echo "fi" >> $POSTRECEIVE
echo "else" >> $POSTRECEIVE
echo "echo \"ERROR! Not deploying ${PROJECT_NAME}: ${branch}\"" >> $POSTRECEIVE
echo "fi" >> $POSTRECEIVE
echo "done" >> $POSTRECEIVE
echo "exit 0" >> $POSTRECEIVE

touch $APACHECONF
echo "<VirtualHost *:80>" > $APACHECONF
echo "ServerName $2" >>  $APACHECONF
echo "ServerAdmin webmaster@$2" >> $APACHECONF
echo "DocumentRoot /var/www/$1/serve" >> $APACHECONF
echo "ErrorLog ${APACHE_LOG_DIR}/$1_error.log" >> $APACHECONF
echo "CustomLog ${APACHE_LOG_DIR}/$1_access.log combined" >>  $APACHECONF
echo "</VirtualHost>" >>  $APACHECONF


a2ensite $1.conf
service apache2 restart

echo "Done!"
echo "git add remote ssh://$HOSTNAME/var/www/$1/$1.git"
