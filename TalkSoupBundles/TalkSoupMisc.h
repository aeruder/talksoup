/***************************************************************************
                                TalkSoupMisc.h
                          -------------------
    begin                : Mon Apr  7 21:45:49 CDT 2003
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
 
#ifndef TALKSOUP_MISC_H
#define TALKSOUP_MISC_H

#import <Foundation/NSAttributedString.h>
#import <Foundation/NSString.h>

NSArray *PossibleUserColors(void);
NSString *IRCColorFromUserColor(NSString *string);

NSString *StringFromEncoding(const NSStringEncoding aEncoding);

@interface NSString (Separation)
- separateIntoNumberOfArguments: (int)num;
@end

@interface NSMutableAttributedString (AttributesAppend)
- (void)addAttributeIfNotPresent: (NSString *)name value: (id)aVal
   withRange: (NSRange)aRange;
- (void)replaceAttribute: (NSString *)name withValue: (id)aVal
   withValue: (id)newVal withRange: (NSRange)aRange;
- (void)setAttribute: (NSString *)name toValue: (id)aVal
   inRangesWithAttribute: (NSString *)name2 matchingValue: (id)aVal2
   withRange: (NSRange)aRange;
- (void)setAttribute: (NSString *)name toValue: (id)aVal
   inRangesWithAttributes: (NSArray *)name2 matchingValues: (NSArray *)aVal2
   withRange: (NSRange)aRange;
@end

NSMutableAttributedString *BuildAttributedString(id aObject, ...);
// This only understands '%@' which will ALWAYS be interepretted literally
NSMutableAttributedString *BuildAttributedFormat(id aObject, ...);

NSArray *IRCUserComponents(NSAttributedString *from);

#endif
