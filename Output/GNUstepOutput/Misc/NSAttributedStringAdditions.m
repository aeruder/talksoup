/***************************************************************************
                                NSAttributedStringAdditions.m
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
 
#import "Misc/NSAttributedStringAdditions.h"
#import "Misc/NSColorAdditions.h"
#import "Controllers/Preferences/FontPreferencesController.h"
#import "Controllers/Preferences/ColorPreferencesController.h"
#import "Controllers/Preferences/PreferencesController.h"
#import "GNUstepOutput.h"
#import <TalkSoupBundles/TalkSoup.h>

#import <AppKit/NSColor.h>
#import <AppKit/NSAttributedString.h>
#import <AppKit/NSFont.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSScanner.h>

NSString *TypeOfColor = @"TypeOfColor";
NSString *InverseTypeForeground = @"InverseTypeForeground";
NSString *InverseTypeBackground = @"InverseTypeBackground";

@implementation NSAttributedString (OutputAdditions)	  
- (NSMutableAttributedString *)substituteColorCodesIntoAttributedStringWithFont: 
  (NSFont *)chatFont
{
	NSMutableAttributedString *a = AUTORELEASE([NSMutableAttributedString new]);
	NSRange all =  { 0 };
	NSRange work =  { 0 };
	int len = [self length];
	NSMutableDictionary *dict;
	id obj;
	id fg;
	id bg;
	
	all.length = len;
	
	while (all.length > 0)
	{
		dict = [NSMutableDictionary dictionaryWithDictionary: 
		 [self attributesAtIndex: all.location longestEffectiveRange: &work
		 inRange: all]];
		
		fg = NSForegroundColorAttributeName;
		bg = NSBackgroundColorAttributeName;
		
		if ([dict objectForKey: IRCReverse])
		{
			fg = NSBackgroundColorAttributeName;
			bg = NSForegroundColorAttributeName;
		}
		
		if ((obj = [dict objectForKey: IRCColor]))
		{
			if (![dict objectForKey: fg])
			{
				id temp;
				temp = [NSColor colorFromIRCString: obj];
				if (temp)
				{
					[dict setObject: temp forKey: fg];
				}
			}
		}
		if ((obj = [dict objectForKey: IRCBackgroundColor]))
		{
			if (![dict objectForKey: bg])
			{
				id temp;
				temp = [NSColor colorFromIRCString: obj];
				if (temp)
				{
					[dict setObject: temp forKey: bg];
				}
			}
		}
		if ([dict objectForKey: IRCUnderline])
		{
			[dict setObject: [NSNumber numberWithInt: NSSingleUnderlineStyle] 
			  forKey: NSUnderlineStyleAttributeName];
		}
		if ([dict objectForKey: IRCBold])
		{
			[dict setObject: [NSFont boldSystemFontOfSize: [chatFont pointSize]]
			  forKey: NSFontAttributeName];
		}
		else
		{
			[dict setObject: chatFont
			  forKey: NSFontAttributeName];
		}
	
		[a appendAttributedString: AUTORELEASE([[NSAttributedString alloc]
		  initWithString: [[self string] substringWithRange: work] attributes: dict])];
		all.location = work.location + work.length;
		all.length = len - all.location;
	}
	
	return a;
}
@end


@implementation NSMutableAttributedString (OutputAdditions2)	  
#define COLOR_FOR_KEY(_aKey) ([NSColor colorFromEncodedData: \
   [_PREFS_ preferenceForKey: (_aKey)]])
+ (NSMutableAttributedString *)attributedStringWithGNUstepOutputPreferences: (id)aString
{
	NSMutableAttributedString *aResult;
	id chatFont;
	NSRange aRange;

	chatFont = AUTORELEASE(RETAIN([FontPreferencesController
	  getFontFromPreferences: GNUstepOutputChatFont]));

	if ([aString isKindOfClass: [NSAttributedString class]])
	{
		aRange = NSMakeRange(0, [aString length]);
		// Change those attributes used by the underlying TalkSoup system into attributes
		// used by AppKit
		aResult = [aString substituteColorCodesIntoAttributedStringWithFont: chatFont];
		
		// NOTE: a large part of the code below sets an attribute called 'TypeOfColor' to the
		// GNUstepOutput type of color.  This is used to more accurately change the colors should
		// the colors change at a later time.
		
		// Set the InverseTypeForeground to non-nil for ones without foreground already set
		// Set the foreground to the default background color when the foreground color
		// does not already have a color and IRCReverse is set
		
		[aResult setAttribute: InverseTypeForeground toValue: @""
		  inRangesWithAttributes: [NSArray arrayWithObjects: NSForegroundColorAttributeName,
		    IRCReverse, nil] matchingValues: [NSArray arrayWithObjects: [NSNull null], 
		    IRCReverseValue, nil] withRange: aRange];

		[aResult setAttribute: NSForegroundColorAttributeName toValue:
		  COLOR_FOR_KEY(GNUstepOutputBackgroundColor)
		  inRangesWithAttribute: InverseTypeForeground
		  matchingValue: @"" withRange: aRange];
		
		// Set the InverseTypeBackground to non-nil for ones without background already set
		// Set the background to the default foreground color when the background color
		// does not already have a color and IRCReverse is set.
		[aResult setAttribute: InverseTypeBackground toValue: @""
		  inRangesWithAttributes: [NSArray arrayWithObjects: NSBackgroundColorAttributeName,
		    IRCReverse, nil] matchingValues: [NSArray arrayWithObjects: [NSNull null], 
		    IRCReverseValue, nil] withRange: aRange];

		[aResult setAttribute: NSBackgroundColorAttributeName toValue:
		  COLOR_FOR_KEY(GNUstepOutputTextColor)
		  inRangesWithAttribute: InverseTypeBackground
		  matchingValue: @"" withRange: aRange];
		
		// When NSForegroundColorAttribute is not set, set the type of color to foreground color
		[aResult setAttribute: TypeOfColor toValue: GNUstepOutputTextColor
		  inRangesWithAttributes: 
		    [NSArray arrayWithObjects: NSForegroundColorAttributeName,
		      TypeOfColor, nil]
		  matchingValues: 
		    [NSArray arrayWithObjects: [NSNull null], [NSNull null], nil]
		  withRange: aRange];
		// and then set the actual color to the foreground color
		[aResult setAttribute: NSForegroundColorAttributeName
		  toValue: COLOR_FOR_KEY(GNUstepOutputTextColor)
		 inRangesWithAttribute: TypeOfColor
		  matchingValue: GNUstepOutputTextColor
		 withRange: aRange];
		 
		// set the other bracket colors type of color attribute 
		[aResult setAttribute: NSForegroundColorAttributeName
		  toValue: COLOR_FOR_KEY(GNUstepOutputOtherBracketColor)
		 inRangesWithAttribute: TypeOfColor
		  matchingValue: GNUstepOutputOtherBracketColor
		 withRange: aRange];
		
		// set the personal bracket colors type of color attribute
		[aResult setAttribute: NSForegroundColorAttributeName
		  toValue: COLOR_FOR_KEY(GNUstepOutputPersonalBracketColor)
		 inRangesWithAttribute: TypeOfColor
		  matchingValue: GNUstepOutputPersonalBracketColor
		 withRange: aRange];
	}
	else
	{
		// just make it all the foreground color if they just passed in a regular string
		aRange = NSMakeRange(0, [[aString description] length]);
		aResult = AUTORELEASE(([[NSMutableAttributedString alloc] 
		  initWithString: [aString description]
		  attributes: [NSDictionary dictionaryWithObjectsAndKeys:
			 chatFont, NSFontAttributeName,
			 TypeOfColor, GNUstepOutputTextColor,
			 COLOR_FOR_KEY(GNUstepOutputTextColor), NSForegroundColorAttributeName,
		     nil]]));
	}

	return aResult;
}
- (void)updateAttributedStringForGNUstepOutputPreferences: (NSString *)aKey
{
	id font, color;

	if ([aKey isEqualToString: GNUstepOutputChatFont])
	{
		font = [FontPreferencesController getFontFromPreferences: aKey];

		[self setAttribute: NSFontAttributeName
		   toValue: font
		  inRangesWithAttribute: IRCBold
		   matchingValue: nil 
		   withRange: NSMakeRange(0, [self length])];
	}
	else if ([aKey isEqualToString: GNUstepOutputBoldChatFont])
	{
		font = [FontPreferencesController getFontFromPreferences: aKey];

		[self setAttribute: NSFontAttributeName
		   toValue: font
		  inRangesWithAttribute: IRCBold
		   matchingValue: IRCBoldValue 
		   withRange: NSMakeRange(0, [self length])];
	}
	else if ((color = COLOR_FOR_KEY(aKey)))
	{
		[self
		 setAttribute: NSForegroundColorAttributeName
		  toValue: color
		 inRangesWithAttribute: TypeOfColor
		  matchingValue: aKey
		 withRange: NSMakeRange(0, [self length])];
		if ([aKey isEqualToString: GNUstepOutputBackgroundColor])
		{
			[self setAttribute: NSForegroundColorAttributeName
			  toValue: color inRangesWithAttribute: InverseTypeForeground
			  matchingValue: @"" withRange: NSMakeRange(0, [self length])];
		}
		else if ([aKey isEqualToString: GNUstepOutputTextColor])
		{
			[self setAttribute: NSBackgroundColorAttributeName
			  toValue: color inRangesWithAttribute: InverseTypeBackground
			  matchingValue: @"" withRange: NSMakeRange(0, [self length])];
		}
	}
}
#undef COLOR_FOR_KEY
@end

