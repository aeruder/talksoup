/***************************************************************************
                                TalkController.m
                          -------------------
    begin                : Sun Nov 10 13:03:07 CST 2002
    copyright            : (C) 2002 by Andy Ruder
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

#import "Controllers/TalkController.h"
#import "Views/ScrollingTextView.h"
#import "Controllers/ConnectionController.h"

#import <Foundation/NSString.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSView.h>
#import <AppKit/NSScrollView.h>

@implementation TalkController
- (void)dealloc
{
	connection = nil;
	DESTROY(talkView);
	DESTROY(contentView);
	DESTROY(talkScroll);
	DESTROY(identifier);

	[super dealloc];
}
- setConnection: (ConnectionController *)aConnection
{
	connection = aConnection;
	return self;
}
- (ConnectionController *)connection
{
	return connection;
}
- (NSView *)contentView
{
	return contentView;
}
- (ScrollingTextView *)talkView
{
	return talkView;
}
- (NSScrollView *)talkScroll
{
	return talkScroll;
}
- (NSString *)identifier
{
	return identifier;
}
- setIdentifier: (NSString *)aIdentifier
{
	if (identifier == aIdentifier) return self;

	RELEASE(identifier);
	identifier = RETAIN(aIdentifier);

	return self;
}
@end
