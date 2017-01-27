#########################################################################
# Simple makefile for packaging Roku Simple Video Player example
#
# Makefile Usage:
# > make
# > make install
# > make remove
#
# Important Notes: 
# To use the "install" and "remove" targets to install your
# application directly from the shell, you must do the following:
#
# 1) Make sure that you have the curl command line executable in your path
# 2) Set the variable ROKU_DEV_TARGET in your environment to the IP 
#    address of your Roku box. (e.g. export ROKU_DEV_TARGET=192.168.1.1.
#    Set in your this variable in your shell startup (e.g. .bashrc)
##########################################################################  
APPNAME = Roku-GooglePhotos
APPDEPS = count_functions increment_version
ZIP_EXCLUDE = -x .git\* -x app.mk -x \*.swp -x \*.DS_Store
include ./app.mk

num_functions := $(shell grep -ri --include=*.brs 'end \(function\|sub\)' . | wc -l | tr -d ' ')

.PHONY: count_functions increment_version

count_functions:
	@echo "Counting functions for $(APPNAME), some Rokus limit to 768"
	test $(num_functions) -le 768

increment_version:
        echo "Increment verison: $version_num)"
	echo $(($(version_num) + 1))

screenshot:
	$(CURL) -s -F passwd= -F mysubmit=Screenshot -F "archive=;filename=" -H "Expect:" "http://$(ROKU_DEV_TARGET)/plugin_inspect" > /dev/null
	$(CURL) -s "http://$(ROKU_DEV_TARGET)/pkgs/dev.jpg" > roku_screenshot.jpg

all: $(APPNAME)
