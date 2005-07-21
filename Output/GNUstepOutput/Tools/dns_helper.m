/***************************************************************************
                             dns_helper.m 
                          -------------------
    begin                : Wed Jun  8 20:55:48 CDT 2005
    copyright            : (C) 2005 by Andrew Ruder
    email                : aeruder@ksu.edu
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

/* This is a simple tool that handles the problem of doing dns lookups
 * without having to lock up the main application.
 */

#import <TalkSoupBundles/TalkSoup.h>

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSHost.h>
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSDistributedNotificationCenter.h>

#include <signal.h>

int main(int argc, char **argv, char **env)
{
	CREATE_AUTORELEASE_POOL(apr);
	NSString *notname, *regname, *address, *reverse, *hostname;
	NSHost *aHost, *aHost2;

	signal(SIGPIPE, SIG_IGN);
	if (argc < 3) 
		return 1;

	regname = [NSString stringWithCString: argv[1]];
	notname = [NSString stringWithCString: argv[2]];
	hostname = [NSString stringWithCString: argv[3]];

	NSLog(@"Performing DNS lookup for %@", hostname);
	aHost = [NSHost hostWithName: hostname];
	address = [aHost address];
	reverse = nil;
	if (address)
	{
		aHost2 = [NSHost hostWithAddress: address];
		reverse = [aHost2 name];
	}

	NSLog(@"DNS Lookup: host: %@ addr: %@ reverse: %@: ", hostname, address, reverse);
	[(NSDistributedNotificationCenter *)[NSDistributedNotificationCenter defaultCenter]
	  postNotificationName: notname
	  object: regname
	  userInfo: [NSDictionary dictionaryWithObjectsAndKeys: 
	    hostname, @"Hostname",
	    address, @"Address",
	    reverse, @"Reverse",
	    nil]
	  deliverImmediately: YES];

	RELEASE(apr);
	return 0;
}
