/***************************************************************************
                                NSAttributedStringAdditions.h
                          -------------------
    begin                : Mon Apr 28 06:48:06 CDT 2003
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

#ifndef OUTPUT_NS_ATTRIBUTED_STRING_ADDITIONS_H
#define OUTPUT_NS_ATTRIBUTED_STRING_ADDITIONS_H

#import <Foundation/NSAttributedString.h>

extern NSString *TypeOfColor;
extern NSString *InverseTypeForeground;
extern NSString *InverseTypeBackground;

@class NSFont, NSColor;
 
@interface NSAttributedString (OutputAdditions)	  
- (NSMutableAttributedString *)substituteColorCodesIntoAttributedStringWithFont:
  (NSFont *)aFont;
@end

@interface NSMutableAttributedString (OutputAdditions2)	  
+ (NSMutableAttributedString *)attributedStringWithGNUstepOutputPreferences: (id)aString;
- (void)updateAttributedStringForGNUstepOutputPreferences: (NSString *)aKey;
@end

#endif
