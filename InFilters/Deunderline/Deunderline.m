/***************************************************************************
                              Deunderline.m
                          -------------------
    begin                : Sat May 10 18:58:30 CDT 2003
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

#import "Deunderline.h"
#import <TalkSoupBundles/TalkSoup.h>

#import <Foundation/NSAttributedString.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSRange.h>

static NSAttributedString *deul(id a)
{
	a = AUTORELEASE([[NSMutableAttributedString alloc] initWithAttributedString: a]);
	[a removeAttribute: IRCUnderline range: NSMakeRange(0, [a length])];
	
	return a;
}

@implementation Deunderline
- (NSAttributedString *)pluginDescription
{
	return BuildAttributedString([NSNull null], IRCBold, IRCBoldValue,
	 _l(@"Author: "), @"Andrew Ruder\n\n",
	 [NSNull null], IRCBold, IRCBoldValue,
	 _l(@"Description: "), _l(@"Removes underline from incoming messages."),
	 @"\n\n",
	 _l(@"Copyright (C) 2005 by Andrew Ruder"),
	 nil);
}
- CTCPReplyReceived: (NSAttributedString *)aCTCP
   withArgument: (NSAttributedString *)argument 
   to: (NSAttributedString *)receiver
   from: (NSAttributedString *)aPerson 
   onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ CTCPReplyReceived: aCTCP withArgument: deul(argument)
	  to: receiver from: aPerson onConnection: connection withNickname: aNick
	  sender: self];
	return self;
}
- wallopsReceived: (NSAttributedString *)message 
   from: (NSAttributedString *)sender 
   onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ wallopsReceived: deul(message) from: sender onConnection: connection
	  withNickname: aNick sender: self];
	return self;
}
- channelParted: (NSAttributedString *)channel 
   withMessage: (NSAttributedString *)aMessage
   from: (NSAttributedString *)parter onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ channelParted: channel withMessage: deul(aMessage)
	  from: parter onConnection: connection withNickname: aNick sender: self];
	return self;
}
- quitIRCWithMessage: (NSAttributedString *)aMessage 
   from: (NSAttributedString *)quitter onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ quitIRCWithMessage: deul(aMessage)
	  from: quitter onConnection: connection withNickname: aNick
	  sender: self];
	return self;
}
- topicChangedTo: (NSAttributedString *)aTopic in: (NSAttributedString *)channel
   from: (NSAttributedString *)aPerson onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ topicChangedTo: deul(aTopic) in: channel from: aPerson onConnection: connection
	  withNickname: aNick sender: self];
	return self;
}
- messageReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ messageReceived: deul(aMessage) to: to
	  from: sender onConnection: connection withNickname: aNick
	  sender: self];
	return self;
}
- noticeReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ noticeReceived: aMessage to: to from: sender onConnection: connection
	  withNickname: aNick sender: self];
	return self;
}
- actionReceived: (NSAttributedString *)anAction to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ actionReceived: deul(anAction) to: to from: sender onConnection: connection
	  withNickname: aNick sender: self];
	return self;
}
@end

