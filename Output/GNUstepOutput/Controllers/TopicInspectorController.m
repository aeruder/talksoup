/***************************************************************************
                                TopicInspectorController.m
                          -------------------
    begin                : Thu May  8 22:40:13 CDT 2003
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

#include "Controllers/TopicInspectorController.h"
#include "Controllers/ConnectionController.h"
#include "GNUstepOutput.h"
#include "Views/KeyTextView.h"

#include <AppKit/NSView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSTextContainer.h>
#include <Foundation/NSString.h>

@implementation TopicInspectorController
- (void)awakeFromNib
{
	id temp = nothingView;
	nothingView = RETAIN([temp contentView]);
	AUTORELEASE(temp);
	contentView = RETAIN([window contentView]);

	[window setContentView: nothingView];
	
	[topicText setHorizontallyResizable: NO];
	[topicText setVerticallyResizable: YES];
	[topicText setMinSize: NSMakeSize(0, 0)];
	[topicText setMaxSize: NSMakeSize(1e7, 1e7)];
	[[topicText textContainer] setContainerSize:
	  NSMakeSize([topicText frame].size.width, 1e7)];
	[[topicText textContainer] setWidthTracksTextView: YES];
	[topicText setTextContainerInset: NSMakeSize(2, 0)];
	[topicText setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
}
- (void)dealloc
{
	RELEASE(nothingView);
	RELEASE(contentView);
	RELEASE(window);
	RELEASE(dateField);
	RELEASE(authorField);
	RELEASE(channelField);
	RELEASE(topicText);
	RELEASE(connection);

	[super dealloc];
}	
- setTopic: (NSString *)aTopic inChannel: (NSString *)aChannel
   setBy: (NSString *)author onDate: (NSString *)date
   forConnectionController: (ConnectionController *)aConnection
{
	DESTROY(connection);
	if ([aChannel length] == 0)
	{
		[window setContentView: nothingView];
	}
	else
	{
		[channelField setStringValue: aChannel];
		[dateField setStringValue: date];
		[authorField setStringValue: author];
		[topicText setString: aTopic];
		[window setContentView: contentView];
		connection = RETAIN(aConnection);
	}
	return self;
}
- (NSView *)contentView
{
	return contentView;
}
- (NSView *)nothingView
{
	return nothingView;
}
- (NSWindow *)window
{
	return window;
}
- (NSTextField *)dateField
{
	return dateField;
}
- (NSTextField *)authorField
{
	return authorField;
}
- (NSTextField *)channelField
{
	return channelField;
}
- (KeyTextView *)topicText
{
	return topicText;
}
- (ConnectionController *)connectionController
{
	return connection;
}
@end

