/***************************************************************************
                       StandardChannelController.h
                          -------------------
    begin                : Sat Jan 18 01:38:06 CST 2003
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

@class StandardChannelController;

#ifndef CHANNEL_CONTROLLER_H
#define CHANNEL_CONTROLLER_H

@class NSTableView, ScrollingTextView, NSSplitView, NSView;
@class Channel;

#import <Foundation/NSObject.h>
#import "Controllers/ContentControllers/ContentController.h"
#import "Controllers/ContentControllers/StandardQueryController.h"

@interface StandardChannelController : StandardQueryController 
   < ContentControllerChannelController >
	{
		NSTableView *tableView;
		NSSplitView *splitView;
		Channel *channelSource;
	}

- (Channel *)channelSource;
- (void)attachChannelSource: (Channel *)aChannel;
- (void)detachChannelSource;
@end

#endif
