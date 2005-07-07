/***************************************************************************
                             HelperExecutor.h
                          -------------------
    begin                : Thu Jun  9 19:12:10 CDT 2005
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

#ifndef HELPER_EXECUTOR_H
#define HELPER_EXECUTOR_H

#import <Foundation/NSObject.h>

@class NSConnection, NSString, NSMutableArray, NSArray;

@interface HelperExecutor : NSObject
	{	
		NSString *notificationName;
		NSMutableArray *executingTasks;
		NSString *helper;
	}
- initWithHelperName: (NSString *)aName identifier: (NSString *)aIdentifier;
- (void)runWithArguments: (NSArray *)aArgs;
- (void)cleanup;
@end

#endif
