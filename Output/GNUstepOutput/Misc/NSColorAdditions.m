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

#import "Misc/NSColorAdditions.h"
#import <TalkSoupBundles/TalkSoup.h>

#import <Foundation/NSArchiver.h>
#import <Foundation/NSData.h>
#import <Foundation/NSScanner.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSCharacterSet.h>
#import <AppKit/NSColor.h>

static NSColor *common_color = nil;

#define COL_CON 1000

static inline NSColor *map_color(NSString *aName)
{
	static NSDictionary *colors = nil;
	
	if (!colors)
	{
	colors = RETAIN(([NSDictionary dictionaryWithObjectsAndKeys:
	  [NSColor colorWithCalibratedRed: 1.0
	                green: 1.0 blue: 1.0 alpha: 1.0], IRCColorWhite, 
	  [NSColor colorWithCalibratedRed: 0.0
	                green: 0.0 blue: 0.0 alpha: 1.0], IRCColorBlack,
	  [NSColor colorWithCalibratedRed: 0.0
	                green: 0.0 blue: 1.0 alpha: 1.0], IRCColorBlue,
	  [NSColor colorWithCalibratedRed: 0.0
	                green: 1.0 blue: 0.0 alpha: 1.0], IRCColorGreen,
	  [NSColor colorWithCalibratedRed: 1.0
	                green: 0.0 blue: 0.0 alpha: 1.0], IRCColorRed,
	  [NSColor colorWithCalibratedRed: 0.5
	                green: 0.0 blue: 0.0 alpha: 1.0], IRCColorMaroon,
	  [NSColor colorWithCalibratedRed: 0.5
	                green: 0.0 blue: 0.5 alpha: 1.0], IRCColorMagenta,
	  [NSColor colorWithCalibratedRed: 1.0
	                green: 0.7 blue: 0.0 alpha: 1.0], IRCColorOrange,
	  [NSColor colorWithCalibratedRed: 1.0
	                green: 1.0 blue: 0.0 alpha: 1.0], IRCColorYellow,
	  [NSColor colorWithCalibratedRed: 0.6
	                green: 0.9 blue: 0.6 alpha: 1.0], IRCColorLightGreen,
	  [NSColor colorWithCalibratedRed: 0.0
	                green: 0.5 blue: 0.5 alpha: 1.0], IRCColorTeal,
	  [NSColor colorWithCalibratedRed: 0.5
	                green: 1.0 blue: 1.0 alpha: 1.0], IRCColorLightCyan,
	  [NSColor colorWithCalibratedRed: 0.7
	                green: 0.8 blue: 0.9 alpha: 1.0], IRCColorLightBlue,
	  [NSColor colorWithCalibratedRed: 1.0
	                green: 0.75 blue: 0.75 alpha: 1.0], IRCColorLightMagenta,
	  [NSColor colorWithCalibratedRed: 0.5
	                green: 0.5 blue: 0.5 alpha: 1.0], IRCColorGrey,
	  [NSColor colorWithCalibratedRed: 0.8
	                green: 0.8 blue: 0.8 alpha: 1.0], IRCColorLightGrey,
	  nil]));
	}
	  
	if ([aName hasPrefix: IRCColorCustom])
	{
		id scan;
		float r=0.0,g=0.0,b=0.0;
		int ri=0,gi=0,bi=0;
		scan = [NSScanner scannerWithString: aName];
		[scan scanUpToCharactersFromSet:
		  [NSCharacterSet whitespaceCharacterSet] intoString: 0];
		[scan scanInt: &ri];
		[scan scanInt: &gi];
		[scan scanInt: &bi];
		
		r = ri / (float)COL_CON;
		g = gi / (float)COL_CON;
		b = bi / (float)COL_CON;		
		
		return [NSColor colorWithCalibratedRed: r green: g
		  blue: b alpha: 1.0];
	}
	
	return [colors objectForKey: aName];
}

@implementation NSColor (EncodingAdditions)
+ (NSString *)commonColorSpaceName
{
	if (!common_color)
	{
		common_color = RETAIN([NSColor colorWithCalibratedRed: 1.0 green: 1.0 
		  blue: 1.0 alpha: 1.0]);
	}
	
	return [common_color colorSpaceName];
}
+ colorFromEncodedData: (id)aData
{
	return map_color(aData);
}
+ (NSColor *)colorFromIRCString: (NSString *)aString
{
	return map_color(aString);
}
- (id)encodeToData
{
	id color = [self colorUsingColorSpaceName: [NSColor commonColorSpaceName]];
	
	return [NSString stringWithFormat: @"IRCColorCustom %d %d %d",
	  (int)([color redComponent] * COL_CON),
	  (int)([color greenComponent] * COL_CON), 
	  (int)([color blueComponent] * COL_CON)];
}
@end

