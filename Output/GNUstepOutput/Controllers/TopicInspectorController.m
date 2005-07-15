/***************************************************************************
                                TopicInspectorController.m
                          -------------------
    begin                : Thu May  8 22:40:13 CDT 2003
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

#import "Controllers/TopicInspectorController.h"
#import "Controllers/ConnectionController.h"
#import "GNUstepOutput.h"
#import "Views/KeyTextView.h"
#import "Models/Channel.h"

#import <AppKit/NSView.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSTextView.h>
#import <AppKit/NSClipView.h>
#import <AppKit/NSTextContainer.h>
#import <AppKit/NSScrollView.h>
#import <Foundation/NSString.h>
#import <Foundation/NSNotification.h>
#import <AppKit/NSEvent.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSText.h>

@interface TopicInspectorController (PrivateMethods)
- (void)focusedControllerChanged: (NSNotification *)aNotification;
- (void)topicChanged: (NSNotification *)aNotification;
- (void)suckFieldsFromChannel: (NSString *)aChannel withSource: (Channel *)aSource;
- (BOOL)topicKeyHit: (NSEvent *)aEvent sender: (id)sender;
- (void)windowDidBecomeKey:(NSNotification *)aNotification;
@end

@implementation TopicInspectorController
- (void)awakeFromNib
{
	id temp = nothingView;
	nothingView = RETAIN([(NSWindow *)temp contentView]);
	AUTORELEASE(temp);
	contentView = RETAIN([(NSWindow *)window contentView]);

	[window setContentView: nothingView];
	
	[topicText setFrame: [[[topicText enclosingScrollView] contentView] bounds]];

	[topicText setHorizontallyResizable: NO];
	[topicText setVerticallyResizable: YES];
	[topicText setMinSize: NSMakeSize(0, 0)];
	[topicText setMaxSize: NSMakeSize(1e7, 1e7)];

	[topicText setTextContainerInset: NSMakeSize(2, 2)];
	[[topicText textContainer] setWidthTracksTextView: YES];
	[[topicText textContainer] setHeightTracksTextView: YES];

	[topicText setEditable: YES];
	[topicText setSelectable: YES];
	[topicText setRichText: NO];
	
	[topicText setNeedsDisplay: YES];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(focusedControllerChanged:)
	  name: ContentControllerSelectedNameNotification
	  object: nil];

	[topicText setKeyTarget: self];
	[topicText setKeyAction: @selector(topicKeyHit:sender:)];

	[window setDelegate: self];
}
- (void)dealloc
{
	[window setDelegate: nil];
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	RELEASE(nothingView);
	RELEASE(contentView);
	RELEASE(window);
	RELEASE(connection);

	[super dealloc];
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
@end

@implementation TopicInspectorController (PrivateMethods)
- (void)focusedControllerChanged: (NSNotification *)aNotification
{
	id userInfo = nil;
	id name = nil;
	id data = nil;
	id tempView;
		
	[[NSNotificationCenter defaultCenter] removeObserver: self
	  name: ConnectionControllerUpdatedTopicNotification
	  object: nil];

	view = nil;
	connection = nil;
	content = nil;

	userInfo = [aNotification userInfo];
	tempView = [userInfo objectForKey: @"View"];
	if ([tempView conformsToProtocol: 
	  @protocol(ContentControllerChannelController)]) 
	{
		content = [aNotification object];
		userInfo = [aNotification userInfo];
		view = tempView;
		connection = [content connectionController];
		name = [content presentationalNameForName: 
		  [content nameForViewController: view]];
		data = [view channelSource];
	
		[[NSNotificationCenter defaultCenter] addObserver: self
		  selector: @selector(topicChanged:)
		  name: ConnectionControllerUpdatedTopicNotification
		  object: view];
	}
	
	[self suckFieldsFromChannel: name withSource: data];
}
- (void)topicChanged: (NSNotification *)aNotification
{
	id name, data;

	if ([aNotification object] == view)
	{
		name = [content presentationalNameForName:
		  [content nameForViewController: view]];
		data = [view channelSource];
		[self suckFieldsFromChannel: name withSource: data];
	}
}
- (void)suckFieldsFromChannel: (NSString *)aChannel withSource: (Channel *)aSource
{
	if (!aChannel || !aSource)
	{
		[window setContentView: nothingView];
	}
	else
	{
		[window setContentView: contentView];
		[channelField setStringValue: aChannel];
		[dateField setStringValue: [aSource topicDate]];
		[authorField setStringValue: [aSource topicAuthor]];
		[topicText setString: [aSource topic]];
	}
}
- (BOOL)topicKeyHit: (NSEvent *)aEvent sender: (id)sender
{
	id channel;
	NSString *characters = [aEvent characters];
	unichar character = 0;
	
	if ([characters length] == 0)
	{
		return YES;
	}

   character = [characters characterAtIndex: 0];
	
	if (   (character != NSCarriageReturnCharacter)
	    && (character != NSEnterCharacter)
	    && (character != NSFormFeedCharacter)) return YES;
	channel = [channelField stringValue];
	
	if (connection)
	{
		id realConnect = [connection connection];
		[_TS_ setTopicForChannel: S2AS(channel) to: 
		 S2AS([sender string]) onConnection: realConnect
		 withNickname: S2AS([realConnect nick])
		 sender: _GS_];
	}
	
	return NO;
}
- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	[window makeFirstResponder: topicText];
}
@end
