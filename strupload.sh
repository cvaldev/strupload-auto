#!/bin/bash

# You can use this script to keep your devices sync'd with Strava via strupload's API.
# It is supposed to be used along side a systemd service.
# When the device is mounted it will check the ACTIVITIES_PATH for new files since the last time the service ran, it then attaches them to a curl request.
# It expects a config file in the root dir of this script with your TOKEN and ACTIVITIES_PATH

# Where to send the files
UPLOAD_URL="https://strupload.herokuapp.com/api/upload"

# Name of the systemd service
service="strupload.service" 

service_status=`echo systemctl status $service`
service_path=`$service_status | awk 'NR==2 { gsub(/\(|;/,"",$3); print $3 }'`

# Make sure sytemd service is running
service_enabled=`$service_status | awk 'NR==2 { gsub(";","",$4); print $4 }'`
if [[ -z $service_status || $service_enabled != "enabled" ]]
then
    echo "ERROR: service error - service status: $service_status"
    exit 1
fi

# Load up config (Expected to be on the root dir of this script as config)
config=`sed -En 's/ExecStart=(.*)\/[a-z]*.sh/\1\/config/ip' $service_path`
if [[ -z $config ]]
then 
    echo "ERROR: Couldn't load $config"
    exit 1
fi
source $config

function getFiles {   
    # Get the date we last ran the service and successfully uploaded
    local last_update=`journalctl --output-fields="MESSAGE" -o verbose -r -u $service | egrep -B 1 "uploads" |awk 'NR==1 {print $2,$3}'`
    local last_update_date=`date "+%Y%m%d%H%M%S" --date="$last_update"`
    
    # Check files at ACTIVITIES_PATH to see if there are any new files
    local files=`ls -t $ACTIVITIES_PATH`
    for file in $files
    do
        local path="$ACTIVITIES_PATH/$file"
        local date=`ls -l --time-style="+%Y%m%d%H%M%S" $path | awk '{print $6}'`

        if [[ -n $date && $date > $last_update_date ]]
        then
        # Add to list
            set -- $@ $path
        elif [[ -n $date ]]
        then
        # Stop if files are older than the latest update date
            break
        fi
    done
    echo $@
}

files_to_upload=$(getFiles)
if [[ -n $files_to_upload ]]
then
    # Attach all the files to the form body
    form_body=`tr " " "\n"  <<< $files_to_upload | sed -E 's/^(.*)/-F file=@\1/g' | tr "\n" " "`

    # Upload the files
    echo `curl $form_body -H "Authorization: Bearer $TOKEN" $UPLOAD_URL`
fi


exit 0