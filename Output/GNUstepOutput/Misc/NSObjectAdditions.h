/***************************************************************************
                                NSObjectAdditions.h
                          -------------------
    begin                : Fri Apr 11 15:10:32 CDT 2003
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
 
#ifndef NSOBJECT_ADDITIONS_H
#define NSOBJECT_ADDITIONS_H

#include <Foundation/NSObject.h>

@interface NSObject (Introspection)
+ (NSArray *)methodsDefinedForClass;
@end

#endif
