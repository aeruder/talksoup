/***************************************************************************
                                ConnectionController.m
                          -------------------
    begin                : Sun Mar 30 21:53:38 CST 2003
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
#import "Controllers/Preferences/PreferencesController.h"
#import "Controllers/Preferences/GeneralPreferencesController.h"
#import "Controllers/ContentControllers/StandardChannelController.h"
#import "Controllers/ContentControllers/Tab/TabContentController.h"
#import "Controllers/ContentControllers/Tab/TabMasterController.h"
#import "Controllers/ContentControllers/ContentController.h"
#import "Controllers/TopicInspectorController.h"
#import "Controllers/InputController.h"
#import "Views/ScrollingTextView.h"
#import "Models/Channel.h"
#import "Misc/HelperExecutor.h"
#import "Misc/LookedUpHost.h"
#import "Misc/NSColorAdditions.h"
#import "GNUstepOutput.h"

#import <TalkSoupBundles/TalkSoup.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSHost.h>
#import <Foundation/NSNotification.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSFont.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSString.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDistributedNotificationCenter.h>

NSString *ConnectionControllerUpdatedTopicNotification = @"ConnectionControllerUpdatedTopicNotification";

@interface ConnectionController (PrivateMethods)
- (void)dnsLookup: (NSNotification *)aNotification;
- (void)connectToHost: (NSHost *)aHost;
@end

NSString *DNSLookupNotification = @"DNSLookupNotification";
static NSString *dns_helper = @"dns_helper";

@implementation ConnectionController
- init
{
	return [self initWithIRCInfoDictionary: nil
	  withContentController: nil];
}
- initWithIRCInfoDictionary: (NSDictionary *)aDict
{
	return [self initWithIRCInfoDictionary: aDict 
	  withContentController: nil];
} 	 
- initWithIRCInfoDictionary: (NSDictionary *)aDict 
   withContentController: (id <ContentController>)aContent
{
	NSString *aIdentifier;

	if (!(self = [super init])) return nil;

	if (!aDict)
	{
	  aDict = [NSDictionary dictionaryWithObjectsAndKeys:
	    [_PREFS_ preferenceForKey: IRCDefaultsNick], 
	      IRCDefaultsNick,
	    [_PREFS_ preferenceForKey: IRCDefaultsRealName],
	      IRCDefaultsRealName,
	    [_PREFS_ preferenceForKey: IRCDefaultsUserName],
	      IRCDefaultsUserName,
	    [_PREFS_ preferenceForKey: IRCDefaultsPassword],
	      IRCDefaultsPassword,
	    nil];
	}
		
	preNick = RETAIN([aDict objectForKey: IRCDefaultsNick]);
	userName = RETAIN([aDict objectForKey: IRCDefaultsUserName]);
	realName = RETAIN([aDict objectForKey: IRCDefaultsRealName]);
	password = RETAIN([aDict objectForKey: IRCDefaultsPassword]);
	
	if (!aContent)
	{
		// FIXME
		// This needs to use the correct content controller
		// which is probably stored in defaults.
		// Also needs to handle the possibility of putting
		// them into an existing master controller
		content = [TabContentController new];
	}
	else
	{
		// Does this even make sense???
		content = RETAIN(aContent);
	}
	[content setConnectionController: self];
	[content addViewControllerOfType: ContentControllerQueryType 
	  withName: ContentConsoleName 
	  withLabel: AUTORELEASE([NSAttributedString new])
	  inMasterController: nil];

	[content setNickname: preNick];
	
	[content setLabel: S2AS(_l(@"Unconnected")) 
	  forName: ContentConsoleName];
	[content setTitle: _l(@"Unconnected") 
	  forViewController: [content viewControllerForName: ContentConsoleName]];

	nameToChannelData = [NSMutableDictionary new];
	
	[_GS_ addConnectionController: self];

	[content bringNameToFront: ContentConsoleName];

	aIdentifier = [NSString stringWithFormat: @"%p%@%ld",
	  self, self, rand()];
	helper = [[HelperExecutor alloc] initWithHelperName: dns_helper 
	  identifier: aIdentifier];

	[(NSDistributedNotificationCenter *)[NSDistributedNotificationCenter defaultCenter] 
	  addObserver: self
	  selector: @selector(dnsLookup:)
	  name: DNSLookupNotification 
	  object: aIdentifier 
	  suspensionBehavior: NSNotificationSuspensionBehaviorDeliverImmediately];
	
	return self;
}
- (void)dealloc
{
	[(NSDistributedNotificationCenter *)[NSDistributedNotificationCenter defaultCenter]
	  removeObserver: self];
	RELEASE(helper);
	RELEASE(typedHost);
	RELEASE(preNick);
	RELEASE(userName);
	RELEASE(password);
	RELEASE(realName);
	RELEASE(connection);
	RELEASE(content);
	RELEASE(tabCompletion);
	RELEASE(nameToChannelData);
	
	[super dealloc];
}
- connectToServer: (NSString *)aName onPort: (int)aPort
{
	registered = NO;

	[_GS_ notWaitingForConnectionOnConnectionController: self];
	if (connection)
	{
		[[_TS_ pluginForInput] closeConnection: connection];
	}
	
	[self systemMessage: BuildAttributedFormat(_l(@"Looking up %@"),
	  aName) onConnection: nil];
	
	ASSIGN(typedHost, aName);
	typedPort = aPort;

	[helper runWithArguments: [NSArray arrayWithObjects: 
	  DNSLookupNotification, typedHost, nil]];

	return self;
}
- (Channel *)dataForChannelWithName: (NSString *)aName
{
	return [nameToChannelData objectForKey: GNUstepOutputLowercase(aName, connection)];
}
- setNick: (NSString *)aString
{
	if (preNick != aString)
	{
		RELEASE(preNick);
		preNick = RETAIN(aString);
	}
	
	return self;
}
- (NSString *)nick
{
	return preNick;
}
- setRealName: (NSString *)aString
{
	if (realName != aString)
	{
		RELEASE(realName);
		realName = RETAIN(aString);
	}
	
	return self;
}
- (NSString *)realName
{
	return realName;
}
- setUserName: (NSString *)aString
{
	if (userName != aString)
	{
		RELEASE(userName);
		userName = RETAIN(aString);
	}
	
	return self;
}
- (NSString *)userName
{
	return userName;
}
- setPassword: (NSString *)aString
{
	if (aString != password)
	{
		RELEASE(password);
		password = RETAIN(aString);
	}
	
	return self;
}
- (NSString *)password
{
	return password;
}
- (NSString *)serverString
{
	return server;
}
- (id)connection
{
	return connection;
}
- (id <ContentController>)contentController
{
	return content;
}
- (void)setContentController: (id <ContentController>)aController
{
	ASSIGN(content, aController);
	if (!content)
	{
		[helper cleanup];
		AUTORELEASE(RETAIN(self));
		[_GS_ removeConnectionController: self];
		if (connection) {
			id msg = 
			  [_PREFS_ preferenceForKey: GNUstepOutputDefaultQuitMessage];

			[_TS_ quitWithMessage: S2AS(msg) onConnection: connection
			  withNickname: S2AS([connection nick]) sender: _GS_];
			[[_TS_ pluginForInput] closeConnection: connection];
		}
	}
}
- (NSArray *)channelsWithUser: (NSString *)user
{
	NSEnumerator *iter;
	id object;
	NSMutableArray *a = AUTORELEASE([NSMutableArray new]);
	
	iter = [[nameToChannelData allValues] objectEnumerator];
	while ((object = [iter nextObject]))
	{
		if ([object containsUser: user])
		{
			[a addObject: [object identifier]];
		}
	}
	
	return a;
}
- leaveChannel: (NSString *)channel
{
	id view = [content viewControllerForName: channel];
	
	[view detachChannelSource];
		
	[nameToChannelData removeObjectForKey: channel];
	[content setLabel: BuildAttributedString(@"(", channel, @")", nil)
	  forName: channel];

	return self;
}
@end

@implementation ConnectionController (PrivateMethods)
/* Called by dns_helper 
 */
- (void)dnsLookup: (NSNotification *)aNotification
{
	NSHost *realHost = nil;
	id userInfo = [aNotification userInfo];
	id aHost = [userInfo objectForKey: @"Hostname"];
	id aAddress = [userInfo objectForKey: @"Address"];
	id aReverse = [userInfo objectForKey: @"Reverse"];

	if (!aHost || ![aHost isEqualToString: typedHost])
		return;

	aReverse = AUTORELEASE([aReverse copy]);
	if (!aReverse) aReverse = typedHost;

	if (aAddress && aReverse)
		realHost = [NSHost hostWithName: aReverse 
		  address: AUTORELEASE([aAddress copy])];

	if (!realHost)
	{
		[self systemMessage: BuildAttributedFormat(_l(@"%@ not found"),
		  typedHost) onConnection: nil];
		return;
	}

	[self connectToHost: realHost];
}
- (void)connectToHost: (NSHost *)aHost
{
	NSString *ident = [NSString stringWithFormat: @"%p", self];
	
	[_GS_ waitingForConnection: ident
	  onConnectionController: self];
	  
	[[_TS_ pluginForInput] initiateConnectionToHost: aHost onPort: typedPort 
	  withTimeout: 30 withNickname: preNick 
	  withUserName: userName withRealName: realName 
	  withPassword: password 
	  withIdentification: ident];
	
	[content setLabel: S2AS(_l(@"Connecting")) 
	  forName: ContentConsoleName];
	[content setTitle: [NSString stringWithFormat: 
	  _l(@"Connecting to %@"), typedHost]
	  forViewController: [content viewControllerForName: ContentConsoleName]];
}
@end
