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

#include "Controllers/ConnectionController.h"
#include "Controllers/ChannelController.h"
#include "Controllers/ContentController.h"
#include "Controllers/TopicInspectorController.h"
#include "Controllers/InputController.h"
#include "Views/ScrollingTextView.h"
#include "Models/Channel.h"
#include "Misc/NSColorAdditions.h"
#include "TalkSoupBundles/TalkSoup.h"
#include "GNUstepOutput.h"

#include <Foundation/NSDictionary.h>
#include <Foundation/NSHost.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSTableView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSTextField.h>

@implementation ConnectionController
- init
{
	id output = _GS_;
	
	return [self initWithIRCInfoDictionary: 
	  [NSDictionary dictionaryWithObjectsAndKeys:
	    [output defaultsObjectForKey: IRCDefaultsNick], 
	      IRCDefaultsNick,
	    [output defaultsObjectForKey: IRCDefaultsRealName],
	      IRCDefaultsRealName,
	    [output defaultsObjectForKey: IRCDefaultsUserName],
	      IRCDefaultsUserName,
	    [output defaultsObjectForKey: IRCDefaultsPassword],
	      IRCDefaultsPassword,
	    nil]];
}
- initWithIRCInfoDictionary: (NSDictionary *)aDict
{
	id typeView;
	
	if (!(self = [super init])) return nil;
	 
	preNick = RETAIN([aDict objectForKey: IRCDefaultsNick]);
	userName = RETAIN([aDict objectForKey: IRCDefaultsUserName]);
	realName = RETAIN([aDict objectForKey: IRCDefaultsRealName]);
	password = RETAIN([aDict objectForKey: IRCDefaultsPassword]);
	
	content = [[ContentController alloc] initWithConnectionController: self];
	[NSBundle loadNibNamed: @"Content" owner: content];
	[content setNickViewString: preNick];
	[[content window] setDelegate: self];
	
	[content setLabel: S2AS(_l(@"Unconnected")) 
	  forViewWithName: ContentConsoleName];
	[[content window] setTitle: _l(@"Unconnected")];
	
	typeView = [content typeView];

	nameToChannelData = [NSMutableDictionary new];
	
	fieldEditor = [KeyTextView new];
	[fieldEditor setFieldEditor: YES];
	[fieldEditor setKeyTarget: self];
	[fieldEditor setKeyAction: @selector(keyPressed:sender:)];
	[fieldEditor setFont: [NSFont userFontOfSize: 12.0]];
	[fieldEditor setUsesFontPanel: NO];
	
	inputController = [[InputController alloc] initWithConnectionController: self];
	
	[typeView setTarget: inputController];
	[typeView setAction: @selector(enterPressed:)];
	[typeView abortEditing];
	[typeView setFont: [NSFont userFontOfSize: 12.0]];
	[typeView setAllowsEditingTextAttributes: NO];
	
	[[content window] makeFirstResponder: typeView];
	
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
	RELEASE(fieldEditor);
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
	  forViewWithName: ContentConsoleName];
	[[content window] setTitle: [NSString stringWithFormat: 
	  _l(@"Connecting to %@"), typedHost]];
	
	registered = NO;
	
	return self;
}
- updateTopicInspector
{
	id topic;
	id data;
	id current;
	
	topic = [_GS_ topicInspectorController];
		
	if ((data = [nameToChannelData objectForKey: 
	  GNUstepOutputLowercase(current = [content currentViewName])]))
	{
		[topic setTopic: [data topic] inChannel: current
		  setBy: [data topicAuthor] onDate: [data topicDate]
		  forConnectionController: self];
	}
	else
	{
		[topic setTopic: nil inChannel: nil
		  setBy: nil onDate: nil
		  forConnectionController: nil];
	}
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
- (InputController *)inputController
{
	return inputController;
}
- (id)connection
{
	return connection;
}
- (ContentController *)contentController
{
	return content;
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
	id view = [content controllerForViewWithName: channel];
	id object = [view tableView];
		
	[object setDataSource: nil];
	[object setTarget: nil];
		
	[nameToChannelData removeObjectForKey: channel];
	[content setLabel: BuildAttributedString(@"(", channel, @")", nil)
	  forViewWithName: channel];

	return self;
}
- (KeyTextView *)fieldEditor
{
	return fieldEditor;
}
@end
