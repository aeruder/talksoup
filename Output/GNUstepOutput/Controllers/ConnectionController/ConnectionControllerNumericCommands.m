/***************************************************************************
                                ConnectionControllerNumericCommands.m
                          -------------------
    begin                : Tue May 20 19:00:06 CDT 2003
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
#import "Controllers/ContentControllers/ContentController.h"
#import "Controllers/ContentControllers/StandardChannelController.h"
#import "Models/Channel.h"
#import <TalkSoupBundles/TalkSoup.h>
#import "GNUstepOutput.h"

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSCalendarDate.h>
#import <Foundation/NSNotification.h>
#import <AppKit/NSTableView.h>

@implementation ConnectionController (NumericCommands)
// RPL_TOPIC
- numericHandler332: (NSArray *)arguments
{
	id channel = [arguments objectAtIndex: 0];
	id topic = [arguments objectAtIndex: 1];
	id lowername = GNUstepOutputLowercase([channel string], connection);
	id data = [nameToChannelData objectForKey: lowername];
	id view = [content viewControllerForName: lowername];
	
	[content putMessage: 
	  BuildAttributedFormat(_l(@"Topic for %@ is \"%@\""), channel, topic) 
	  in: channel];
	
	[data setTopic: [topic string]];
	[data setTopicAuthor: @""];
	[data setTopicDate: @""];
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName: ConnectionControllerUpdatedTopicNotification
	 object: view 
	 userInfo: [NSDictionary dictionaryWithObjectsAndKeys: 
	  content, @"Content",
	  data, @"Channel",
	  nil]];

	return self;
}
// RPL_TOPIC (extension???)
- numericHandler333: (NSArray *)arguments
{
	id channel = [arguments objectAtIndex: 0];
	id who = [arguments objectAtIndex: 1];
	NSDictionary *attrib;
	id date = [arguments objectAtIndex: 2];
	id lowername = GNUstepOutputLowercase([channel string], connection);
	id data;
	id view;

	data = [nameToChannelData objectForKey: lowername];
	view = [content viewControllerForName: lowername];
	
	attrib = [date attributesAtIndex: 0 effectiveRange: 0];
	date = [[NSDate dateWithTimeIntervalSince1970: [[date string] doubleValue]] 
	   descriptionWithCalendarFormat: @"%a %b %e %H:%M:%S"
	   timeZone: nil locale: nil];
	date = AUTORELEASE([[NSAttributedString alloc] initWithString: date
	  attributes: attrib]);
	
	[content putMessage: 
	  BuildAttributedFormat(_l(@"Topic for %@ set by %@ at %@"),
	  channel, who, date) in: channel];
		
	[data setTopicAuthor: [who string]];
	[data setTopicDate: [date string]];

	[[NSNotificationCenter defaultCenter]
	 postNotificationName: ConnectionControllerUpdatedTopicNotification
	 object: view 
	 userInfo: [NSDictionary dictionaryWithObjectsAndKeys: 
	  content, @"Content",
	  data, @"Channel",
	  nil]];
	
	return self;
}
// RPL_NAMREPLY
- numericHandler353: (NSArray *)arguments
{
	id channel = [nameToChannelData objectForKey: 
	  GNUstepOutputLowercase([[arguments objectAtIndex: 1] string], connection)];
	  
	if (!channel)
	{
		return ContentConsoleName;
	}

	[channel addServerUserList: [[arguments objectAtIndex: 2]
	 string]];

	return self;
}
// RPL_ENDOFNAMES
- numericHandler366: (NSArray *)arguments
{
	id name = GNUstepOutputLowercase([[arguments objectAtIndex: 0] string], connection);
	id cont = [content viewControllerForName: name];
	id channel = [nameToChannelData objectForKey: name];

	if (!channel)
	{
		return ContentConsoleName;
	}

	[channel endServerUserList];

	[cont refreshFromChannelSource];

	return self;
}
- numericHandler301: (NSArray *)arguments
{
	return nil;
}
- numericHandler305: (NSArray *)arguments
{
	return nil;
}
- numericHandler306: (NSArray *)arguments
{
	return nil;
}
- numericHandler401: (NSArray *)arguments
{
	return nil;
}
- numericHandler403: (NSArray *)arguments
{
	return nil;
}
- numericHandler404: (NSArray *)arguments
{
	return nil;
}
- numericHandler442: (NSArray *)argments
{
	return nil;
}
- numericHandler432: (NSArray *)arguments
{
	return nil;
}
- numericHandler433: (NSArray *)arguments
{
	return nil;
}
@end


