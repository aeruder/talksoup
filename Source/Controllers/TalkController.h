/***************************************************************************
                                TalkController.h
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

#import <Foundation/NSObject.h>

@class NSView, ConnectionController, ScrollingTextView, NSScrollView;
@class NSString;

@interface TalkController : NSObject
	{
		NSView *contentView;
		ConnectionController *connection;
		ScrollingTextView *talkView;
		NSScrollView *talkScroll;
		NSString *identifier;
	}	
- setConnection: (ConnectionController *)aConnection;
- (ConnectionController *)connection;

- (NSView *)contentView;

- (ScrollingTextView *)talkView;

- (NSScrollView *)talkScroll;

- (NSString *)identifier;
- setIdentifier: (NSString *)aIdentifier;
@end

