/***************************************************************************
                                ConnectionControllerCtcp.m
                          -------------------
    begin                : Tue May 20 18:38:20 CDT 2003
    copyright            : (C) 2003 by Andy Ruder
    email                : aeruder@yahoo.com
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
 
#include "Controllers/ConnectionController.h"
#include "TalkSoupBundles/TalkSoup.h"
#include "Controllers/ContentController.h"
#include "GNUstepOutput.h"

#include <Foundation/NSAttributedString.h>
#include <Foundation/NSNull.h>

@implementation ConnectionController (CTCP)
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
	  BuildAttributedString(@"TalkSoup can be obtained from: "
	    @"http://linuks.mine.nu/andy/ "
		 @"http://www.freshmeat.net/talksoup/ or "
		 @"http://andyruder.tripod.com", nil)
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
