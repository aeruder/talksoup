/***************************************************************************
                                NSColorAdditions.h
                          -------------------
    begin                : Mon Apr  7 20:52:48 CDT 2003
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
 
#ifndef NS_COLOR_ADDITIONS_H
#define NS_COLOR_ADDITIONS_H

#import <AppKit/NSColor.h>

@interface NSColor (EncodingAdditions)
+ (NSString *)commonColorSpaceName;
+ colorFromEncodedData: (id)aData;
+ (NSColor *)colorFromIRCString: (NSString *)aString;
- (id)encodeToData;
@end

#endif

