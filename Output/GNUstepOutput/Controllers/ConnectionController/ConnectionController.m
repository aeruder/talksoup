/***************************************************************************
                                ConnectionController.m
                          -------------------
    begin                : Sun Mar 30 21:53:38 CST 2003
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

#import "Controllers/ConnectionController.h"
#import "Controllers/Preferences/PreferencesController.h"
#import "Controllers/ContentControllers/StandardChannelController.h"
#import "Controllers/ContentControllers/Tab/TabContentController.h"
#import "Controllers/ContentControllers/Tab/TabMasterController.h"
#import "Controllers/ContentControllers/ContentController.h"
#import "Controllers/TopicInspectorController.h"
#import "Controllers/InputController.h"
#import "Views/ScrollingTextView.h"
#import "Models/Channel.h"
#import "Misc/NSColorAdditions.h"
#import "GNUstepOutput.h"

#import <TalkSoupBundles/TalkSoup.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSHost.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSFont.h>
#import <Foundation/NSEnumerator.h>

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
	NSTextView *fieldEditor;
	
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
		content = [[TabContentController alloc] initWithConnectionController: self];
	}
	else
	{
		content = RETAIN(aContent);
	}

	[content setNickname: preNick];
	
	[content setLabel: S2AS(_l(@"Unconnected")) 
	  forName: ContentConsoleName];
	[content setTitle: _l(@"Unconnected")];
	
	fieldEditor = [KeyTextView new];
	[fieldEditor setFieldEditor: YES];
	[content setFieldEditor: fieldEditor];

	nameToChannelData = [NSMutableDictionary new];
	
	[_GS_ addConnectionController: self];
	
	return self;
}
- (void)dealloc
{
	RELEASE(typedHost);
	RELEASE(preNick);
	RELEASE(userName);
	RELEASE(password);
	RELEASE(realName);
	RELEASE(inputController);
	RELEASE(connection);
	RELEASE(content);
	RELEASE(tabCompletion);
	RELEASE(nameToChannelData);
	
	[super dealloc];
}
- connectToServer: (NSString *)aName onPort: (int)aPort
{
	NSHost *aHost = [NSHost hostWithName: aName];
	NSString *ident = [NSString stringWithFormat: @"%p", self];
	
	RELEASE(typedHost);
	typedHost = RETAIN(aName);
	typedPort = aPort;
	
	if (!aHost)
	{
		[self systemMessage: BuildAttributedString(_l(@"Host not found: "),
		  aName, nil) onConnection: nil];
		return self;
	}
	
	if (connection)
	{
		[[_TS_ pluginForInput] closeConnection: connection];
	}
	
	[_GS_ waitingForConnection: ident
	  onConnectionController: self];
	  
	[[_TS_ pluginForInput] initiateConnectionToHost: aHost onPort: aPort
	  withTimeout: 30 withNickname: preNick 
	  withUserName: userName withRealName: realName 
	  withPassword: password 
	  withIdentification: ident];
	
	[content setLabel: S2AS(_l(@"Connecting")) 
	  forName: ContentConsoleName];
	[content setTitle: [NSString stringWithFormat: 
	  _l(@"Connecting to %@"), typedHost]];
	
	registered = NO;
	
	return self;
}
- (Channel *)dataForChannelWithName: (NSString *)aName
{
	return [nameToChannelData objectForKey: GNUstepOutputLowercase(aName)];
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
- (id)connection
{
	return connection;
}
- (id <ContentController>)contentController
{
	return content;
}
- (InputController *)inputController
{
	return inputController;
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
	id view = [content controllerForName: channel];
	
	[view detachChannelSource];
		
	[nameToChannelData removeObjectForKey: channel];
	[content setLabel: BuildAttributedString(@"(", channel, @")", nil)
	  forName: channel];

	return self;
}
@end
