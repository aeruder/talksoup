/***************************************************************************
                                Functions.m
                          -------------------
    begin                : Sun Oct 13 20:13:10 CDT 2002
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

#import "Misc/Functions.h"

#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSScanner.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSArray.h>

#import <AppKit/NSColor.h>
#import <AppKit/NSAttributedString.h>

#import <objc/objc.h>

@implementation NSObject (Introspection)
+ (NSArray *)methodsDefinedForClass
{
	MethodList *list;
	Class class;
	int z;
	int y;
	SEL sel;
	NSMutableArray *array = AUTORELEASE([NSMutableArray new]);
	
	class = [self class];
	
	for (list = class->methods; list != NULL; list=list->method_next)
	{
		y = list->method_count;
		for (z = 0; z < y; z++)
		{
			sel = list->method_list[z].method_name;
			[array addObject: NSStringFromSelector(sel)];
		}
	}

	return [NSArray arrayWithArray: array];
}
@end

@interface NSScanner (ShortInt)
- (BOOL)scanTwoCharacterInt: (int *)aInt;
@end

@implementation NSScanner (ShortInt)
- (BOOL)scanTwoCharacterInt: (int *)x
{
	int y;
	id string;
	id two;
	NSRange sub;
	id scan;
	
	string = [self string];
	if (!string) return NO;

	sub.location = [self scanLocation];
	sub.length = 2;
	
	if (sub.location == [string length]) return NO;

	if (sub.location == ([string length] - 1)) sub.length = 1;

	two = [string substringWithRange: sub];

	scan = [NSScanner scannerWithString: two];
	[scan setCharactersToBeSkipped: [NSCharacterSet 
	  characterSetWithCharactersInString: @""]];
	if (![scan scanInt: &y]) return NO;

	[self setScanLocation: sub.location + [scan scanLocation]];

	if (x) *x = y;

	return YES;
}	
@end
	
static NSCharacterSet *comma = nil;
static NSCharacterSet *control = nil;
static NSCharacterSet *color_control = nil;
static NSCharacterSet *bold_control = nil;
static NSCharacterSet *underline_control = nil;
static NSCharacterSet *clear_control = nil;

static NSColor *colors[16] = { 0 };

@implementation NSString (ColorCodes)
+ (void)initializeStuff
{
	CREATE_AUTORELEASE_POOL(apr);
	
	comma = RETAIN([NSCharacterSet characterSetWithCharactersInString: @","]);
	color_control = 
	  RETAIN([NSCharacterSet characterSetWithCharactersInString: @"\003"]);
	bold_control =
	  RETAIN([NSCharacterSet characterSetWithCharactersInString: @"\002"]);
	underline_control = 
	  RETAIN([NSCharacterSet characterSetWithCharactersInString: @"\037"]);
	clear_control =
	  RETAIN([NSCharacterSet characterSetWithCharactersInString: @"\017"]);
	control =
	  RETAIN([NSCharacterSet characterSetWithCharactersInString: 
	   @"\003\002\037\017"]);
	
	colors[0] = RETAIN([NSColor colorWithCalibratedRed: 1.0
	                      green: 1.0 blue: 1.0 alpha: 1.0]);
	colors[1] = RETAIN([NSColor colorWithCalibratedRed: 0.0
	                      green: 0.0 blue: 0.0 alpha: 1.0]);
	colors[2] = RETAIN([NSColor colorWithCalibratedRed: 0.0
	                      green: 0.0 blue: 1.0 alpha: 1.0]);
	colors[3] = RETAIN([NSColor colorWithCalibratedRed: 0.0
	                      green: 1.0 blue: 0.0 alpha: 1.0]);
	colors[4] = RETAIN([NSColor colorWithCalibratedRed: 1.0
	                      green: 0.0 blue: 0.0 alpha: 1.0]);
	colors[5] = RETAIN([NSColor colorWithCalibratedRed: 0.5
	                      green: 0.0 blue: 0.0 alpha: 1.0]);
	colors[6] = RETAIN([NSColor colorWithCalibratedRed: 0.5
	                      green: 0.0 blue: 0.5 alpha: 1.0]);
	colors[7] = RETAIN([NSColor colorWithCalibratedRed: 1.0
	                      green: 0.7 blue: 0.0 alpha: 1.0]);
	colors[8] = RETAIN([NSColor colorWithCalibratedRed: 1.0
	                      green: 1.0 blue: 0.0 alpha: 1.0]);
	colors[9] = RETAIN([NSColor colorWithCalibratedRed: 0.6
	                      green: 0.9 blue: 0.6 alpha: 1.0]);
	colors[10] = RETAIN([NSColor colorWithCalibratedRed: 0.0
	                      green: 0.5 blue: 0.5 alpha: 1.0]);
	colors[11] = RETAIN([NSColor colorWithCalibratedRed: 0.5
	                      green: 1.0 blue: 1.0 alpha: 1.0]);
	colors[12] = RETAIN([NSColor colorWithCalibratedRed: 0.7
	                      green: 0.8 blue: 0.9 alpha: 1.0]);
	colors[13] = RETAIN([NSColor colorWithCalibratedRed: 1.0
	                      green: 0.75 blue: 0.75 alpha: 1.0]);
	colors[14] = RETAIN([NSColor colorWithCalibratedRed: 0.5
	                      green: 0.5 blue: 0.5 alpha: 1.0]);
	colors[15] = RETAIN([NSColor colorWithCalibratedRed: 0.8
	                      green: 0.8 blue: 0.8 alpha: 1.0]);
	
	RELEASE(apr);
}
- (NSAttributedString *)attributedStringFromColorCodedString
{
	NSScanner *scan;
	NSString *aString;
	int x;
	NSMutableAttributedString *string = 
	  AUTORELEASE([NSMutableAttributedString new]);
	NSMutableDictionary *dict = AUTORELEASE([NSMutableDictionary new]);

	if (!comma)
	{
		[[self class] initializeStuff];
	}
	
	scan = [NSScanner scannerWithString: self];
	[scan setCharactersToBeSkipped: [NSCharacterSet 
	  characterSetWithCharactersInString: @""]];
	
	while ([scan isAtEnd] == NO)
	{
		if ([scan scanUpToCharactersFromSet: control intoString: &aString])
		{
			[string appendAttributedString: 
			  AUTORELEASE([[NSAttributedString alloc] initWithString: aString
			  attributes: [NSDictionary dictionaryWithDictionary: dict]])];
		}
		
		if ([scan isAtEnd] == YES) break;
		
		if ([scan scanCharactersFromSet: bold_control intoString: 0])
		{
			[dict setObject: [NSFont boldSystemFontOfSize: 12.0]
			  forKey: NSFontAttributeName];
		}
		else if ([scan scanCharactersFromSet: underline_control intoString: 0])
		{
			[dict setObject: [NSNumber numberWithInt: 1]
			  forKey: NSUnderlineStyleAttributeName];
		}
		else if ([scan scanCharactersFromSet: clear_control intoString: 0])
		{
			[dict removeAllObjects];
		}
		else if ([scan scanCharactersFromSet: color_control intoString: 0])
		{
			if ([scan scanTwoCharacterInt: &x])
			{
				x = x % 16;
				[dict setObject: colors[x] forKey: 
				  NSForegroundColorAttributeName];
	
				if ([scan scanCharactersFromSet: comma intoString: 0])
				{
					if ([scan scanTwoCharacterInt: &x])
					{
						x = x % 16;
						[dict setObject: colors[x] forKey:
						  NSBackgroundColorAttributeName];
					}
				}
			}
			else
			{
				[dict removeObjectForKey: NSBackgroundColorAttributeName];
				[dict removeObjectForKey: NSForegroundColorAttributeName];
			}
		}	
	}
	return AUTORELEASE([[NSAttributedString alloc] initWithAttributedString:
	  string]);
}		
@end

@implementation NSString (ContainsSpace)
- (BOOL)containsSpace
{
	NSRange aRange;

	aRange = [self rangeOfCharacterFromSet: 
	  [NSCharacterSet whitespaceCharacterSet]];
	
	if (aRange.location == NSNotFound && aRange.length == 0)
	{
		return NO;
	}
	
	return YES;
}
@end
