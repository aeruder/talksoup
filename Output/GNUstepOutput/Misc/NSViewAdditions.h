/***************************************************************************
                           NSViewAdditions.h
                          -------------------
    begin                : Thu Jul 14 02:37:49 CDT 2005
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

#import <AppKit/NSView.h>

@class NSString;

@interface NSView (View_Debugging_GNUstepOutput)
- (NSString *)viewHierarchyWithFunction: (NSString *(*)(NSView *obj))descFunction;
- (NSString *)viewHierarchy;
- (NSString *)viewHierarchyWithResizingInfo;
@end

