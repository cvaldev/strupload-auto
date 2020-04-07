# strupload-auto

This is a simple script that can be used to automatically upload files to Strava when you mount a usb device. It doesn't upload the files directly to Strava because unfortunately that is not possible since you need a registered app to use their API, which is why I made [strupload](https://github.com/cvaldev/strupload). This script makes use of strupload's API to upload your files to Strava.

## How to use

In order to use it you need 3 things:

1. Get an authorization token from [strupload](https://github.com/cvaldev/strupload)
2. Make a config file
3. Start systemd service 
   
### Get an authorization token 

Go to: https://strupload.herokuapp.com/oauth/strava?state=tokenize

Save the token, and move to the next step

### Config file

In the root directory of your script set a file named `config` with these parameters:

```
TOKEN=<YOUR-STRUPLOAD-TOKEN>
ACTIVITIES_PATH=<PATH-TO-ACTIVITIES-IN-YOUR-DEVICE>
```

### Systemd service

Should look something like this:

```
[Unit]
Description= My strupload script trigger
Requires=<YOUR-DEVICE>.mount 
After=<YOUR-DEVICE>.mount 

[Service]
ExecStart=<PATH-TO-YOUR-SCRIPT>

[Install]
WantedBy=<YOUR-DEVICE>.mount
```

You can get `<YOUR-DEVICE>` from 

```
systemctl list-units -t mount
```

Place your file in `/etc/systemd/system/<YOUR-SERVICE>.service`, and then do:

```
sudo systemctl enable <YOUR-SERVICE>.service
```

And you should be set (hopefully...)