/***************************************************************************
                       StandardQueryController.h
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

@class StandardQueryController;

#ifndef QUERY_CONTROLLER_H
#define QUERY_CONTROLLER_H

#import <Foundation/NSObject.h>
#import "Controllers/ContentControllers/ContentController.h"

@class NSView, ScrollingTextView;
 
@interface StandardQueryController : NSObject < ContentControllerQueryController >
	{
		id window;
		id chatView;
	}
+ (NSString *)standardNib;
- (NSView *)contentView;
- (NSTextView *)chatView;
@end

#endif
