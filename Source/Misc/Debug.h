/***************************************************************************
                                Debug.h
                          -------------------
    begin                : Wed Mar 13 00:20:02 UTC 2002
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

@interface DebugObject : NSObject
+ (void)initialize; 
+ (void)debugClass;
- (void)dealloc;
+ allocWithZone: (NSZone *)zone;
- retain;
- (oneway void)release;
@end


