/***************************************************************************
                                ChannelController.m
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

#include "ChannelController.h"

#include <AppKit/NSSplitView.h>

@implementation ChannelController
- (void)awakeFromNib
{
	id x;
	[splitView setVertical: YES];
	
	x = RETAIN([window contentView]);
	[window close];
	RELEASE(window);
	window = RETAIN(x);
}
- (void)dealloc
{
	RELEASE(window);
	RELEASE(chatView);
	RELEASE(splitView);
	RELEASE(tableView);
	[super dealloc];
}
- (id)chatView
{
	return chatView;
}
- (id)contentView
{
	return window;
}
- (id)splitView
{
	return splitView;
}
- (id)tableView
{
	return tableView;
}
@end
