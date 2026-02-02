To install it for the first time on a mac, do the following

sudo mkdir -p "/Library/Application Support/FinkTelecomServices/frameworks"
sudo chown  -R $USER  "/Library/Application Support/FinkTelecomServices"

this makes sure you can build and install the framework as your local user you use for development

also /usr/local/lib, /usr/local/include should be existing and writable by $USER

you should install the packages from the dependencies folder if you want zeromq and/or SSL support

then run 
	./configure	
once

after this you can build normally with xcode and the framework will get installed to /Library/Application Support/FinkTelecomServices/frameworks


