#!/bin/sh

if [ "$1" != "install" ] ; then
	cat <<EOS
This script will build TalkSoup.app for OS X.

There are a few requirements:
    TalkSoup and netclasses should -=not=- be installed in any way, shape, or
    form on your machine.

    You need to have netclasses unpacked into ../netclasses This script needs
    to be ran from the root of the TalkSoup repository, so your directory
    structure would be something like:
    
        andy somedir/TalkSoup $ ls ../
        netclasses TalkSoup
        
        andy somedir/TalkSoup $ Misc/setup_osx.sh install

    You must have gnustep-make correctly installed and already loaded into the
    environment.

    And of course, you need all the tools you would normally use to install
    TalkSoup.

    When you want to really run this script run with "install" argument as
    shown above
EOS
	exit 1
fi

PWD="`pwd`"
if ! [ -e Misc/setup_osx.sh ]; then
	echo "I don't think you read the instructions, you dolt..."
	echo "Just run $0 and RTFM ;)"
	exit 1
fi

trap "exit 1" ERR
echo "Cleaning up"
sleep 1
rm -fr build || true
rm -fr TalkSoup.app || true
mkdir build
make distclean
make -C ../netclasses distclean || true

echo "Compiling netclasses"
sleep 1

# First we make netclasses correctly...
(
	trap "exit 1" ERR
	cd ../netclasses ;
	./configure
	cd Source
	make debug=yes \
	  LIB_LINK_INSTALL_NAME="@executable_path/../Frameworks/netclasses.framework/netclasses"
	mv netclasses.framework ../../TalkSoup/TalkSoupBundles
)
# Then TalkSoupBundles
(
	trap "exit 1" ERR
	cd TalkSoupBundles
	make debug=yes \
	  LIB_LINK_INSTALL_NAME="@executable_path/../Frameworks/TalkSoupBundles.framework/TalkSoupBundles"
)

make debug=yes

echo "Installing TalkSoup into build/"
mkdir -p build/Library/Application\ Support/TalkSoup/{OutFilters,InFilters,Input,Output}
make debug=yes install GNUSTEP_INSTALLATION_DIR="$PWD"/build 
rm -fr build/Library/Frameworks

echo "Moving in the plugins..."
mv build/Library/Application\ Support/TalkSoup/* build/Applications/TalkSoup.debug/Contents/Resources
mkdir build/Applications/TalkSoup.debug/Contents/Frameworks

echo "Taking care of frameworks"
tar -C TalkSoupBundles -cf - TalkSoupBundles.framework netclasses.framework | \
tar -C build/Applications/TalkSoup.debug/Contents/Frameworks -xf -

mv build/Applications/TalkSoup.debug TalkSoup.app
rm -fr build

echo "TalkSoup.app is done"
	
exit 0
