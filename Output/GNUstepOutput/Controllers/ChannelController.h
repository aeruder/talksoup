/***************************************************************************
                                ChannelController.h
                          -------------------
    begin                : Sat Jan 18 01:38:06 CST 2003
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

@class ChannelController;

#ifndef CHANNEL_CONTROLLER_H
#define CHANNEL_CONTROLLER_H

#include <AppKit/AppKit.h>

@interface ChannelController : NSObject
	{
		id tableView;
		id chatView;
		id splitView;
		id window;
	}

- (id)chatView;

- (id)window;

- (id)splitView;

- (id)tableView;
@end

#endif
