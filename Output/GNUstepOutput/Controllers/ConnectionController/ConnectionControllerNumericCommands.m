/***************************************************************************
                                ConnectionControllerNumericCommands.m
                          -------------------
    begin                : Tue May 20 19:00:06 CDT 2003
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
#include "Controllers/ContentController.h"
#include "Controllers/ChannelController.h"
#include "Models/Channel.h"
#include "TalkSoupBundles/TalkSoup.h"
#include "GNUstepOutput.h"

#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>
#include <Foundation/NSAttributedString.h>
#include <AppKit/NSTableView.h>

@implementation ConnectionController (NumericCommands)
// RPL_TOPIC
- numericHandler332: (NSArray *)arguments
{
	id channel = [arguments objectAtIndex: 0];
	id topic = [arguments objectAtIndex: 1];
	id data = [nameToChannelData objectForKey: 
	  GNUstepOutputLowercase([channel string])];
	
	[content putMessage: 
	  BuildAttributedFormat(_l(@"Topic for %@ is \"%@\""), channel, topic) 
	  in: channel];
	
	[data setTopic: [topic string]];
	[data setTopicAuthor: @""];
	[data setTopicDate: @""];
	
	[self updateTopicInspector];
	
	return self;
}
// RPL_TOPIC (extension???)
- numericHandler333: (NSArray *)arguments
{
	id channel = [arguments objectAtIndex: 0];
	id who = [arguments objectAtIndex: 1];
	NSDictionary *attrib;
	id date = [arguments objectAtIndex: 2];
	id data = [nameToChannelData objectForKey:
	  GNUstepOutputLowercase([channel string])];
	
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
	
	[self updateTopicInspector];
	
	return self;
}
// RPL_NAMREPLY
- numericHandler353: (NSArray *)arguments
{
	id channel = [nameToChannelData objectForKey: 
	  GNUstepOutputLowercase([[arguments objectAtIndex: 1] string])];
	  
	if (!channel)
	{
		return nil;
	}

	[channel addServerUserList: [[arguments objectAtIndex: 2]
	 string]];

	return self;
}
// RPL_ENDOFNAMES
- numericHandler366: (NSArray *)arguments
{
	id name = GNUstepOutputLowercase([[arguments objectAtIndex: 0] string]);
	id cont = [content controllerForViewWithName: name];
	id channel = [nameToChannelData objectForKey: name];

	if (!channel)
	{
		return nil;
	}

	[channel endServerUserList];

	[[cont tableView] reloadData]; 

	return self;
}
@end


