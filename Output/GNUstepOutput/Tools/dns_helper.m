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
#import <Foundation/NSConnection.h>
#import <Foundation/NSDistantObject.h>
#import <Foundation/NSProxy.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSHost.h>
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDebug.h>

#include <signal.h>

@protocol SomeBogusProtocoldns_helper
- (void)dnsLookupCallback: (NSString *)ip_address forHost: (NSString *)aHost
  withReverse: (NSString *)aReverse;
@end

int main(int argc, char **argv, char **env)
{
	CREATE_AUTORELEASE_POOL(apr);
	NSString *regname, *address, *reverse, *hostname;
	id connection;
	NSHost *aHost, *aHost2;

	signal(SIGPIPE, SIG_IGN);
	if (argc < 2) 
		return 1;

	regname = [NSString stringWithCString: argv[1]];

	connection = [[NSConnection rootProxyForConnectionWithRegisteredName: 
	  regname host: nil] retain];

	hostname = [NSString stringWithCString: argv[2]];

	if (!connection)
	{
		NSLog(@"Can't lookup %@, got connection: %@", connection);
		RELEASE(connection);
		return 5;
	}
	aHost = [NSHost hostWithName: hostname];
	address = [aHost address];
	reverse = nil;
	if (address)
	{
		aHost2 = [NSHost hostWithAddress: address];
		reverse = [aHost2 name];
	}

	[connection dnsLookupCallback: address forHost: hostname withReverse: reverse];

	RELEASE(connection);
	RELEASE(apr);
	return 0;
}
