/***************************************************************************
                                TopicInspectorController.h
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

@class TopicInspectorController;

#ifndef TOPIC_INSPECTOR_CONTROLLER_H
#define TOPIC_INSPECTOR_CONTROLLER_H

#import <Foundation/NSObject.h>
#import "Controllers/ContentControllers/ContentController.h"

@class NSView, NSWindow, NSTextField, KeyTextView;
@class NSString, ConnectionController, Channel;

@interface TopicInspectorController : NSObject
	{
		NSView *nothingView;
		NSView *contentView;
		NSWindow *window;
		NSTextField *dateField;
		NSTextField *authorField;
		NSTextField *channelField;
		KeyTextView *topicText;
		ConnectionController *connection;
		id <ContentController> content;
		id <ContentControllerChannelController> view;
	}
- (NSView *)contentView;
- (NSView *)nothingView;

- (NSWindow *)window;

- (NSTextField *)dateField;
- (NSTextField *)authorField;
- (NSTextField *)channelField;

- (KeyTextView *)topicText;
@end


#endif
