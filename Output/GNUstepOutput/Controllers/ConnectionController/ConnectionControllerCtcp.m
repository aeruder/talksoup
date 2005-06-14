/***************************************************************************
                                ConnectionControllerCtcp.m
                          -------------------
    begin                : Tue May 20 18:38:20 CDT 2003
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
 
#import "Controllers/ConnectionController.h"
#import <TalkSoupBundles/TalkSoup.h>
#import "Controllers/ContentControllers/ContentController.h"
#import "GNUstepOutput.h"

#import <Foundation/NSAttributedString.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSBundle.h>

#include <sys/time.h>
#include <time.h>

@implementation ConnectionController (CTCP)
- CTCPReplyPING: (NSAttributedString *)argument from: (NSAttributedString *)aPerson
{
	NSString *now;
	NSString *then;
	NSString *results;
	struct timeval tv = {0, 0};
	int sec;
	int microsec;
	NSLog(@"Tessssting");
	if (gettimeofday(&tv, NULL) == -1)
	{
		[content putMessage: S2AS(_l(@"gettimeofday() failed"))
		  in: ContentConsoleName];
		return nil;
	}
	
	now = [NSString stringWithFormat: @"%u.%u", 
	  (unsigned)tv.tv_sec, (unsigned)(tv.tv_usec / 1000)];
	then = [argument string];

	if ([then isEqualToString: now])
	{
		sec = 0;
		microsec = 0;
	}
	else
	{
		id a1, a2;
		a1 = [now componentsSeparatedByString: @"."];
		a2 = [then componentsSeparatedByString: @"."];

		if ([a1 count] < 2 || [a2 count] < 2) return nil;

		now = [a1 objectAtIndex: 0];
		then = [a2 objectAtIndex: 0];
	
		results = [now commonPrefixWithString: then options: 0];
		
		if ([results length] == [now length] && 
		  [results length] == [then length])
		{
			sec = 0;
		}
		else
		{
			if ([now length] == [results length])
			{
				now = @"";
			}
			else
			{
				now = [now substringFromIndex: [results length]];
			}

			if ([then length] == [results length])
			{
				then = @"";
			}
			else
			{
				then = [then substringFromIndex: [results length]];
			}
			
			sec = [now intValue] - [then intValue];
		}
		
		microsec = [[a1 objectAtIndex: 1] intValue] - 
		  [[a2 objectAtIndex: 1] intValue];

		if (microsec < 0)
		{
			sec -= 1;
			microsec = 0 - microsec;
		}
	}

	[content putMessage: BuildAttributedFormat(_l(@"CTCP PING reply from %@: %@ seconds"),
	  [IRCUserComponents(aPerson) objectAtIndex: 0], 
	  [NSString stringWithFormat: @"%u.%03u", sec, microsec])
	  in: nil];

	return self;
}
- CTCPRequestPING: (NSAttributedString *)argument from: (NSAttributedString *)aPerson
{
	[_TS_ sendCTCPReply: S2AS(@"PING") withArgument: argument to: 
	  [IRCUserComponents(aPerson) objectAtIndex: 0] onConnection: connection
	  withNickname: S2AS([connection nick])
	  sender: _GS_]; 
	  
	[content putMessage: 
	  BuildAttributedFormat(@"Received a CTCP PING from %@", 
	  [IRCUserComponents(aPerson) objectAtIndex: 0]) in: ContentConsoleName];
	
	return self;
}
- CTCPRequestVERSION: (NSAttributedString *)query from: (NSAttributedString *)aPerson
{
	[_TS_ sendCTCPReply: S2AS(@"VERSION") withArgument:
	  BuildAttributedFormat(@"TalkSoup.app %@", 
	    [[[NSBundle mainBundle] infoDictionary] objectForKey: @"ApplicationRelease"])
	  to: [IRCUserComponents(aPerson) objectAtIndex: 0] 
	  onConnection: connection 
	  withNickname: S2AS([connection nick])
	  sender: _GS_];

	return nil;
}
- CTCPRequestCLIENTINFO: (NSAttributedString *)query from: (NSAttributedString *)aPerson
{
	[_TS_ sendCTCPReply: S2AS(@"CLIENTINFO") withArgument:
	  BuildAttributedString(_l(@"TalkSoup can be obtained from: "),
	    @"http://aeruder.gnustep.us ", nil)
	  to: [IRCUserComponents(aPerson) objectAtIndex: 0]
	  onConnection: connection 
	  withNickname: S2AS([connection nick])
	  sender: _GS_];

	return ContentConsoleName;
}
- CTCPRequestXYZZY: (NSAttributedString *)query from: (NSAttributedString *)aPerson
{
	[_TS_ sendCTCPReply: S2AS(@"XYZZY") withArgument:
	  S2AS(@"Nothing happened.") 
	  to: [IRCUserComponents(aPerson) objectAtIndex: 0]
	  onConnection: connection 
	  withNickname: S2AS([connection nick])
	  sender: _GS_];
	
	return ContentConsoleName;
}
- CTCPRequestRFM: (NSAttributedString *)query from: (NSAttributedString *)aPerson
{
	[_TS_ sendCTCPReply: S2AS(@"RFM") withArgument: S2AS(@"Problems? Blame RFM")
	  to: [IRCUserComponents(aPerson) objectAtIndex: 0]
	  onConnection: connection 
	  withNickname: S2AS([connection nick])
	  sender: _GS_];
	
	return ContentConsoleName;
}
@end
