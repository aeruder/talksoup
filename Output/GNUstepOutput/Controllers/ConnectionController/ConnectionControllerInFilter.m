/***************************************************************************
                                ConnectionControllerInFilter.m
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


#import "Controllers/ConnectionController.h"
#import "Controllers/ContentControllers/ContentController.h"
#import "Controllers/Preferences/ColorPreferencesController.h"
#import <TalkSoupBundles/TalkSoup.h>
#import "GNUstepOutput.h"
#import "Models/Channel.h"
#import "Controllers/ContentControllers/StandardChannelController.h"
#import "Misc/NSAttributedStringAdditions.h"

#import <Foundation/NSEnumerator.h>
#import <Foundation/NSString.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNull.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSTableView.h>

#define MARK [NSNull null]

@implementation ConnectionController (InFilter)
- newConnection: (id)aConnection withNickname: (NSAttributedString *)aNick
   sender: aPlugin
{
	if (connection)
	{
		[[_TS_ pluginForInput] closeConnection: connection];
	}
	connection = RETAIN(aConnection);
	
	return self;
}
- lostConnection: (id)aConnection withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	NSEnumerator *iter;
	id object;

	iter = [[NSArray arrayWithArray: [nameToChannelData allKeys]] objectEnumerator];

	while ((object = [iter nextObject]))
	{
		[self leaveChannel: object];
	}
	
	[self systemMessage: S2AS(_l(@"Disconnected")) onConnection: aConnection];
	
	[content setLabel: S2AS(_l(@"Unconnected")) 
	  forName: ContentConsoleName];
	[content setTitle: _l(@"Unconnected")];
	
	RELEASE(preNick);
	preNick = RETAIN([aConnection nick]);
	
	DESTROY(connection);	
	return self;
}
- controlObject: (id)aObject onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	/* This stuff needs a big fat FIXME
	id process;
	if (![aObject isKindOfClass: [NSDictionary class]]) return self;
	
	process = [aObject objectForKey: @"Process"];

	if (!process) return self;

	if ([process isEqualToString: @"HighlightTab"])
	{
		id col, name, prior;

		name = [aObject objectForKey: @"TabName"];
		col = [aObject objectForKey: @"TabColor"];
		prior = [aObject objectForKey: @"TabPriority"];

		if (!name || !col) return self;

		[content highlightTabWithName: name withColor: col withPriority: 
		  (prior) ? YES : NO];
	}
	else if ([process isEqualToString: @"LabelTab"])
	{
		id name, label;
		
		name = [aObject objectForKey: @"TabName"];
		label = [aObject objectForKey: @"TabLabel"];

		if (!name || !label) return self;
		
		[content setLabel: label forViewWithName: name];
	}
	else if ([process isEqualToString: @"OpenTab"])
	{
		id name, label;

		name = [aObject objectForKey: @"TabName"];
		label = [aObject objectForKey: @"TabLabel"];

		if (!name || !label) return self;

		if (![content isQueryName: name])
		{
			[content addQueryWithName: name withLabel: label];
		}
	}
	else if ([process isEqualToString: @"CloseTab"])
	{
		id name;

		name = [aObject objectForKey: @"TabName"];

		if (!name) return self;

		if ([content isQueryName: name])
		{
			[content closeViewWithName: name];
		}
	}
	
	*/
	return self;
}
- registeredWithServerOnConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[content setNickname: [aConnection nick]];
	return self;
}
- couldNotRegister: (NSAttributedString *)reason onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	NSLog(@"Couldn't register: %@", [reason string]);
	return self;
}
- CTCPRequestReceived: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)argument 
   to: (NSAttributedString *)receiver
   from: (NSAttributedString *)aPerson onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	SEL sid = NSSelectorFromString([NSString stringWithFormat: 
	   @"CTCPRequest%@:from:", [[aCTCP string] uppercaseString]]);
	id str;
	id where;
	
	where = ContentConsoleName;
	
	if (sid && [self respondsToSelector: sid])
	{
		where = [self performSelector: sid withObject: argument
		 withObject: aPerson];
	}
	
	if (where == self) return self;
	
	if ([argument length])
	{
		str = BuildAttributedFormat(_l(@"Received a CTCP '%@ %@' from %@"), 
		  aCTCP, argument, [IRCUserComponents(aPerson) objectAtIndex: 0]);
	}
	else
	{
		str = BuildAttributedFormat(_l(@"Received a CTCP %@ from %@"),
		  aCTCP, [IRCUserComponents(aPerson) objectAtIndex: 0]);
	}
	
	[content putMessage: str in: where];
	
	return self;
}
- CTCPReplyReceived: (NSAttributedString *)aCTCP
   withArgument: (NSAttributedString *)argument 
   to: (NSAttributedString *)receiver 
	from: (NSAttributedString *)aPerson 
   onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	SEL sid = NSSelectorFromString([NSString stringWithFormat: 
	   @"CTCPReply%@:from:", [[aCTCP string] uppercaseString]]);
	id str;
	id where = nil;
	
	if (sid && [self respondsToSelector: sid])
	{
		where = [self performSelector: sid withObject: argument
		 withObject: aPerson];
	}

	if (where == self) return self;
	
	if ([argument length])
	{
		str = BuildAttributedString(
		  MARK, TypeOfColor, GNUstepOutputOtherBracketColor, @"-",
		  [IRCUserComponents(aPerson) objectAtIndex: 0], 
		  MARK, TypeOfColor, GNUstepOutputOtherBracketColor, @"-",
		  @" ", aCTCP, @" ", argument, nil);
	}
	else
	{
		str = BuildAttributedString(MARK, TypeOfColor, 
		  GNUstepOutputOtherBracketColor, @"-",
		  [IRCUserComponents(aPerson) objectAtIndex: 0], 
		  MARK, TypeOfColor, GNUstepOutputOtherBracketColor, @"-",
		  @" ", aCTCP, nil);
	}

	[content putMessage: str in: where];

	return self;
}
- errorReceived: (NSAttributedString *)anError onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[self systemMessage: BuildAttributedFormat(_l(@"Error: %@"), anError)
	  onConnection: nil];
	
	return self;
}
- wallopsReceived: (NSAttributedString *)message 
   from: (NSAttributedString *)sender 
   onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[content putMessage: BuildAttributedFormat(_l(@"Wallops(%@): %@"),
	  sender, message) in: ContentConsoleName];
	  
	return self;
}
- userKicked: (NSAttributedString *)aPerson 
   outOf: (NSAttributedString *)aChannel 
   for: (NSAttributedString *)reason from: (NSAttributedString *)kicker 
   onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id name = [IRCUserComponents(kicker) objectAtIndex: 0];
	id lowChan = GNUstepOutputLowercase([aChannel string]);
	id view = [content viewControllerForName: lowChan];

	if (GNUstepOutputCompare([aPerson string], [connection nick]))
	{
		[self leaveChannel: lowChan];
	}
	else
	{
		[[nameToChannelData objectForKey: lowChan] removeUser: [aPerson string]];
		[view refreshFromChannelSource];
	}
	
	[content putMessage: 
	  BuildAttributedFormat(_l(@"%@ was kicked from %@ by %@ (%@)"), aPerson,
	  aChannel, name, reason) 
	  in: [aChannel string]];
	return self;
}
- invitedTo: (NSAttributedString *)aChannel from: (NSAttributedString *)inviter 
   onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id name = [IRCUserComponents(inviter) objectAtIndex: 0];
	
	[content putMessage: 
	  BuildAttributedFormat(_l(@"You have been invited to %@ by %@"), 
	  aChannel, name)
	  in: nil];
	return self;
}
- modeChanged: (NSAttributedString *)aMode on: (NSAttributedString *)anObject 
   withParams: (NSArray *)paramList from: (NSAttributedString *)aPerson 
   onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	Channel *chan;
	unichar m;
	BOOL add = YES;
	int argindex = 0;
	id mode = [aMode string];
	int modeindex;
	int modelen = [mode length];
	int argcnt = [paramList count];
	id who = [IRCUserComponents(aPerson) objectAtIndex: 0];
	
	id params;
	NSEnumerator *iter;
	id object = nil;
	
	iter = [paramList objectEnumerator];
	params = AUTORELEASE([NSMutableAttributedString new]);
	
	while ((object = [iter nextObject]))
	{
		[params appendAttributedString: S2AS(@" ")];
		[params appendAttributedString: object];
	}
		
	chan = [nameToChannelData objectForKey: 
	  GNUstepOutputLowercase([anObject string])];

	for (modeindex = 0; modeindex < modelen; modeindex++)
	{
		m = [mode characterAtIndex: modeindex];
		switch (m)
		{
			case '+':
				add = YES;
				continue;
			case '-':
				add = NO;
				continue;
			default:
				break;
		}
				
		if (chan)
		{
			switch (m)
			{
				case 'o':
					if (argindex < argcnt)
					{
						id user;
						user = [chan userWithName: 
						  [[paramList objectAtIndex: argindex] string]];
						[user setOperator: add];
						[(id <ContentControllerChannelController>)
						 [content viewControllerForName: [anObject string]] 
						   refreshFromChannelSource];
						argindex++;
					}
					break;
				case 'v':
					if (argindex < argcnt)
					{
						id user;
						user = [chan userWithName: 
						  [[paramList objectAtIndex: argindex] string]];
						[user setVoice: add];
						[(id <ContentControllerChannelController>)
						 [content viewControllerForName: [anObject string]] 
						   refreshFromChannelSource];
						argindex++;
					}
					break;
				default:
					break;
			}
		}
	}
	
	[content putMessage: 
	  BuildAttributedFormat(_l(@"%@ sets mode %@ %@%@"), who, aMode, anObject,
	  params) in: [anObject string]];
	
	return self;
}
- numericCommandReceived: (NSAttributedString *)command 
   withParams: (NSArray *)paramList from: (NSAttributedString *)sender 
   onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{	
	SEL sel = NSSelectorFromString([NSString stringWithFormat: 
	  @"numericHandler%@:", [command string]]);
	NSMutableAttributedString *a = 
	  AUTORELEASE([[NSMutableAttributedString alloc] initWithString: @""]);
	NSEnumerator *iter;
	id object;
	id where;
	
	if ([connection connected] && !registered)
	{
		object = [IRCUserComponents(sender) objectAtIndex: 0];
		[content setLabel: object
		 forName: ContentConsoleName];
		[content setTitle: [object string]];
		registered = YES;
	}
	
	iter = [paramList objectEnumerator];
	while ((object = [iter nextObject]))
	{
		[a appendAttributedString: object];
		[a appendAttributedString: S2AS(@" ")];
	}
	
	where = ContentConsoleName;
	
	if (sel && [self respondsToSelector: sel])
	{
		where = [self performSelector: sel withObject: paramList];
	}

	if (where != self)
	{
		[content putMessage: a in: where];
	}
	
	return self;
}
- nickChangedTo: (NSAttributedString *)newName 
   from: (NSAttributedString *)aPerson 
   onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	NSEnumerator *iter;
	id object;
	id array;
	NSAttributedString *oldName = [IRCUserComponents(aPerson) objectAtIndex: 0];
	
	if (GNUstepOutputCompare([newName string], [connection nick]))
	{
		[self setNick: [newName string]];
		[content setNickname: [newName string]];
	}
	
	array = [self channelsWithUser: [oldName string]];
	iter = [array objectEnumerator];
	while ((object = [iter nextObject]))
	{
		[[nameToChannelData objectForKey: 
		  GNUstepOutputLowercase(object)] userRenamed: [oldName string] 
		  to: [newName string]];
		[(id <ContentControllerChannelController>)
		  [content viewControllerForName: object] refreshFromChannelSource];
	}
	
	[content putMessage: BuildAttributedFormat(
	  _l(@"%@ is now known as %@"), oldName, newName)
	  in: array];
	  
	if ([content viewControllerForName: [oldName string]])
	{
		[content renameViewControllerWithName: [oldName string] to: [newName string]];
		[content setLabel: S2AS([newName string]) 
		  forName: [newName string]];
	}
	  
	return self;
}
- channelJoined: (NSAttributedString *)channel 
   from: (NSAttributedString *)joiner 
   onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id name = [channel string];
	id array = IRCUserComponents(joiner);
	id lowName = GNUstepOutputLowercase(name);

	if (GNUstepOutputCompare([[array objectAtIndex: 0] string], [aConnection nick]))
	{
		id x;

		[content addViewControllerOfType: ContentControllerChannelType withName: name
		  withLabel: channel inMasterController: [content primaryMasterController]];
		[content bringNameToFront: name];
		[nameToChannelData setObject: x = AUTORELEASE([[Channel alloc] 
		  initWithIdentifier: lowName]) forKey: lowName];
				
		[(id <ContentControllerChannelController>)
		 [content viewControllerForName: lowName] attachChannelSource: x];
	}
	else
	{
		[[nameToChannelData objectForKey: lowName] addUser: 
		  [[array objectAtIndex: 0] string]];
		[(id <ContentControllerChannelController>)
		  [content viewControllerForName: lowName] refreshFromChannelSource];
	}
	
	[content putMessage: BuildAttributedFormat(_l(@"%@ (%@) has joined %@"),
	  [array objectAtIndex: 0], [array objectAtIndex: 1], channel) in: name];
	
	return self;
}
- channelParted: (NSAttributedString *)channel 
   withMessage: (NSAttributedString *)aMessage
   from: (NSAttributedString *)parter onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id name = [IRCUserComponents(parter) objectAtIndex: 0];
	id lowChan = GNUstepOutputLowercase([channel string]);
	id view = [content viewControllerForName: lowChan];

	if (GNUstepOutputCompare([name string], [connection nick]))
	{
		[self leaveChannel: lowChan];
	}
	else
	{
		[[nameToChannelData objectForKey: lowChan] removeUser: [name string]];
		[view refreshFromChannelSource];
	}
	
	if (view)
	{
		[content putMessage: BuildAttributedFormat(_l(@"%@ has left %@ (%@)"), 
		  name, channel, aMessage) in: lowChan];
	}
	
	return self;
}
- quitIRCWithMessage: (NSAttributedString *)aMessage 
   from: (NSAttributedString *)quitter onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id name = [IRCUserComponents(quitter) objectAtIndex: 0];
	id array = [self channelsWithUser: [name string]];
	NSEnumerator *iter;
	id object;
	
	iter = [array objectEnumerator];
	while ((object = [iter nextObject]))
	{
		id low = GNUstepOutputLowercase(object);
		[[nameToChannelData objectForKey: low] 
		  removeUser: [name string]];
		[(id <ContentControllerChannelController>)
		  [content viewControllerForName: low] refreshFromChannelSource];
	}
	
	[content putMessage:
	  BuildAttributedFormat(_l(@"%@ has quit IRC (%@)"), name, aMessage)
	  in: array];
		
	return self;
}
- topicChangedTo: (NSAttributedString *)aTopic in: (NSAttributedString *)channel
   from: (NSAttributedString *)aPerson onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[content putMessage:
	  BuildAttributedFormat(_l(@"%@ changed the topic in %@ to '%@'"),
	   [IRCUserComponents(aPerson) objectAtIndex: 0], channel, aTopic)
	  in: [channel string]];
	
	return self;
}
- messageReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id who = [IRCUserComponents(sender) objectAtIndex: 0];
	id whos = [who string];
	id where;
	id string;
	id privstring;
	id pubstring;
	
	privstring = BuildAttributedString(
	  MARK, TypeOfColor, GNUstepOutputOtherBracketColor, @"*",
	  MARK, TypeOfColor, GNUstepOutputOtherBracketColor, who, 
	  MARK, TypeOfColor, GNUstepOutputOtherBracketColor, @"*",
	  @" ", aMessage, nil);
	pubstring = BuildAttributedString(
	  MARK, TypeOfColor, GNUstepOutputOtherBracketColor, @"<", who, 
	  MARK, TypeOfColor, GNUstepOutputOtherBracketColor, @">",
	  @" ", aMessage, nil);
	
	string = pubstring;
	
	if (GNUstepOutputCompare([to string], [connection nick]))
	{
		if (![content viewControllerForName: where = whos])
		{
			where = nil;
			string = privstring;
		}
	}
	else
	{
		if (![content viewControllerForName: where = [to string]])
		{
			where = nil;
			string = privstring;
		}
	}
	
	[content putMessage: string in: where];
	
	return self;
}
- noticeReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[self messageReceived: aMessage to: to from: sender onConnection: aConnection
	  withNickname: aNick
	  sender: aPlugin];
	return self;
}
- actionReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id who = [IRCUserComponents(sender) objectAtIndex: 0];
	id whos = [who string];
	id where;
	NSString *prefix = @"*";
	
	if (GNUstepOutputCompare([to string], [connection nick]))
	{
		if (![content viewControllerForName: where = whos])
		{
			where = nil;
			prefix = @"***";
		}
	}
	else
	{
		if (![content viewControllerForName: where = [to string]])
		{
			where = nil;
			prefix = @"***";
		}
	}
	
	[content putMessage: BuildAttributedString(
	  MARK, TypeOfColor, GNUstepOutputOtherBracketColor,
	  prefix, @" ", who, @" ", aMessage, nil) in: where];
	
	return self;
}
- pingReceivedWithArgument: (NSAttributedString *)arg 
   from: (NSAttributedString *)sender onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ sendPongWithArgument: arg onConnection: aConnection
	  withNickname: aNick
	  sender: _GS_];

	return self;
}
- pongReceivedWithArgument: (NSAttributedString *)arg 
   from: (NSAttributedString *)sender onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	return self;
}
- newNickNeededWhileRegisteringOnConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	return self;
}
- consoleMessage: (NSAttributedString *)arg onConnection: (id)connection
{
	[content putMessage: arg in: ContentConsoleName];
	return self;
}
- systemMessage: (NSAttributedString *)arg onConnection: (id)connection
{
	[content putMessageInAll: arg];
	return self;
}	
- showMessage: (NSAttributedString *)arg onConnection: (id)connection
{
	[content putMessage: arg in: nil];
	return self;
}
@end

#undef FCAN
#undef MARK
