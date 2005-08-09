/***************************************************************************
                              PrivateBeep.m
                          -------------------
    begin                : Tue Aug  9 00:54:55 CDT 2005
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

#import "PrivateBeep.h"
#import <TalkSoupBundles/TalkSoup.h>

#import <Foundation/NSAttributedString.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSNotification.h>
#import <AppKit/NSGraphics.h>

@interface PrivateBeep (PrivateMethods)
- (void)messageReceived: (NSNotification *)aNotification;
@end

@implementation PrivateBeep (PrivateMethods)
- (void)messageReceived: (NSNotification *)aNotification
{
	NSBeep();
}
@end

@implementation PrivateBeep
- (NSAttributedString *)pluginDescription
{
	return BuildAttributedString([NSNull null], IRCBold, IRCBoldValue,
	 _l(@"Author: "), @"Andrew Ruder\n\n",
	 [NSNull null], IRCBold, IRCBoldValue,
	 _l(@"Description: "), _l(@"This bundle will beep when someone "
	 @"uses your name in a channel or sends you a private message.  This "
	 @"bundle works off of a service provided by the Highlighting bundle. For"
	 @"this reason, you must have the Highlighting bundle for this bundle to "
	 @"take effect."),
	 @"\n\n",
	 _l(@"Copyright (C) 2005 by Andrew Ruder"),
	 nil);
}
- pluginActivated
{
	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(messageReceived:)
	  name: @"TalkSoupHighlightingNotification" 
	  object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(messageReceived:)
	  name: @"TalkSoupPrivateMessageNotification" 
	  object: nil];
	return self;
}
- pluginDeactivated
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	return self;
}
@end

