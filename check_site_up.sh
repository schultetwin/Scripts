#!/bin/bash
# By Mark Schulte (schultetwin@gmail.com)
# Sends an email to an email address if an http request of a domain does
# not return 200.
#
# Currently only supports http and not https. If you require an www in front
# of the domain, then please enter that in your first argument. Do not
# add the http:// in front of the domain


if [ $# != 2 ]
then
  echo "Need to specify site to check and email address to send to\n"
  echo "Should be $0 site.com email@example.come"
  exit 4
fi

response=$(curl --write-out %{http_code} --silent --output /dev/null http://$1)

if [[ ${response} != 200 ]] ; then
  /bin/mail -s "$1 down1" $2 << EOF
  Please check $1, the site is not responding with an code of 200.
EOF
fi

