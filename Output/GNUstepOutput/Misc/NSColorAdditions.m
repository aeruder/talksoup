/***************************************************************************
                                NSColorAdditions.m
                          -------------------
    begin                : Mon Apr  7 20:52:48 CDT 2003
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

#include "Misc/NSColorAdditions.h"

#include <Foundation/NSArchiver.h>
#include <Foundation/NSData.h>

@implementation NSColor (EncodingAdditions)
+ colorFromEncodedData: (id)aData
{
	return [NSUnarchiver unarchiveObjectWithData: aData];
}
- (id)encodeToData
{
	return [NSArchiver archivedDataWithRootObject: self];
}
@end

