/***************************************************************************
                                TopicInspectorController.h
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

@class TopicInspectorController;

#ifndef TOPIC_INSPECTOR_CONTROLLER_H
#define TOPIC_INSPECTOR_CONTROLLER_H

#include <Foundation/NSObject.h>

@class NSView, NSWindow, NSTextField, KeyTextView;
@class NSString, ConnectionController;

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
	}

- setTopic: (NSString *)aTopic inChannel: (NSString *)aChannel
   setBy: (NSString *)author onDate: (NSString *)date
	forConnectionController: (ConnectionController *)controller;

- (NSView *)contentView;
- (NSView *)nothingView;

- (NSWindow *)window;

- (NSTextField *)dateField;
- (NSTextField *)authorField;
- (NSTextField *)channelField;

- (KeyTextView *)topicText;

- (ConnectionController *)connectionController;
@end


#endif
