/***************************************************************************
                                NSObjectAdditions.h
                          -------------------
    begin                : Fri Apr 11 15:10:32 CDT 2003
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
 
#ifndef NSOBJECT_ADDITIONS_H
#define NSOBJECT_ADDITIONS_H

#import <Foundation/NSObject.h>

@class NSArray;

@interface NSObject (Introspection)
+ (NSArray *)methodsDefinedForClass;
@end

#endif
