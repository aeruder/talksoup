/***************************************************************************
                                NSAttributedStringAdditions.m
                          -------------------
    begin                : Mon Apr 28 06:48:06 CDT 2003
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
#import <AppKit/NSParagraphStyle.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSScanner.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSRange.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSNotification.h>

NSString *TypeOfColor = @"TypeOfColor";
NSString *InverseTypeForeground = @"InverseTypeForeground";
NSString *InverseTypeBackground = @"InverseTypeBackground";

@implementation NSAttributedString (OutputAdditions)	  
- (NSMutableAttributedString *)substituteColorCodesIntoAttributedStringWithFont: 
  (NSFont *)chatFont withBoldFont: (NSFont *)aBoldFont
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
			[dict setObject: aBoldFont 
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

#define COLOR_FOR_KEY(_aKey) \
  [NSColor colorFromEncodedData: [_PREFS_ preferenceForKey: (_aKey)]]

@implementation NSMutableAttributedString (OutputAdditions2)
+ (NSMutableAttributedString *)attributedStringWithGNUstepOutputPreferences: (id)aString
{
	NSMutableAttributedString *aResult;
	NSFont *chatFont, *boldFont;
	NSRange aRange;
	NSMutableParagraphStyle *paraStyle;
	float wIndentF;
	id object1, object2;

	chatFont = RETAIN([FontPreferencesController
	  getFontFromPreferences: GNUstepOutputChatFont]);
	boldFont = RETAIN([FontPreferencesController
	  getFontFromPreferences: GNUstepOutputBoldChatFont]);

	if ([aString isKindOfClass: [NSAttributedString class]])
	{
		aRange = NSMakeRange(0, [aString length]);
		// Change those attributes used by the underlying TalkSoup system into attributes
		// used by AppKit
		aResult = [aString substituteColorCodesIntoAttributedStringWithFont: chatFont
		  withBoldFont: boldFont];
		
		// NOTE: a large part of the code below sets an attribute called 'TypeOfColor' to the
		// GNUstepOutput type of color.  This is used to more accurately change the colors should
		// the colors change at a later time.
		
		// Set the InverseTypeForeground to non-nil for ones without foreground already set
		// Set the foreground to the default background color when the foreground color
		// does not already have a color and IRCReverse is set
		
		object1 = [[NSArray alloc] initWithObjects: [NSNull null], 
		  IRCReverseValue, nil];
		object2 = [[NSArray alloc] initWithObjects: NSForegroundColorAttributeName, 
		  IRCReverse, nil];
		[aResult setAttribute: InverseTypeForeground toValue: @""
		  inRangesWithAttributes: object2
		  matchingValues: object1 withRange: aRange];
		RELEASE(object2);

		[aResult setAttribute: NSForegroundColorAttributeName toValue:
		  COLOR_FOR_KEY(GNUstepOutputBackgroundColor)
		  inRangesWithAttribute: InverseTypeForeground
		  matchingValue: @"" withRange: aRange];
		
		// Set the InverseTypeBackground to non-nil for ones without background already set
		// Set the background to the default foreground color when the background color
		// does not already have a color and IRCReverse is set.
		object2 = [[NSArray alloc] initWithObjects: NSBackgroundColorAttributeName, 
		  IRCReverse, nil];
		[aResult setAttribute: InverseTypeBackground toValue: @""
		  inRangesWithAttributes: object2
		  matchingValues: object1 withRange: aRange];
		RELEASE(object1);
		RELEASE(object2);

		[aResult setAttribute: NSBackgroundColorAttributeName toValue:
		  COLOR_FOR_KEY(GNUstepOutputTextColor)
		  inRangesWithAttribute: InverseTypeBackground
		  matchingValue: @"" withRange: aRange];
		
		// When NSForegroundColorAttribute is not set, set the type of color to foreground color
		object1 = [[NSArray alloc] initWithObjects: NSForegroundColorAttributeName,
		  TypeOfColor, nil];
		object2 = [[NSArray alloc] initWithObjects: 
		  [NSNull null], [NSNull null], nil];
		[aResult setAttribute: TypeOfColor toValue: GNUstepOutputTextColor
		  inRangesWithAttributes: object1
		  matchingValues: object2
		  withRange: aRange];
		RELEASE(object1);
		RELEASE(object2);
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

	wIndentF = [[_PREFS_ preferenceForKey: GNUstepOutputWrapIndent]
	  floatValue];
	paraStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[paraStyle setHeadIndent: wIndentF];
	[aResult addAttribute: NSParagraphStyleAttributeName 
	  value: paraStyle range: aRange];

	RELEASE(chatFont);
	RELEASE(boldFont);
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
	else if ([aKey isEqualToString: GNUstepOutputWrapIndent])
	{
		NSRange aRange;
		float wIndentF;
		NSMutableParagraphStyle *paraStyle;

		aRange = NSMakeRange(0, [self length]);
		
		wIndentF = [[_PREFS_ preferenceForKey: GNUstepOutputWrapIndent]
		  floatValue];
		paraStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[paraStyle setHeadIndent: wIndentF];
		[self addAttribute: NSParagraphStyleAttributeName 
		  value: paraStyle range: aRange];
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
- (void)chopNumberOfLines: (int)numLines
{
	NSRange aRange;
	NSString *text;
	int start, len;

	text = [self string];
	len = [text length];
	start = 0;
	while (numLines > 0)
	{
		aRange = [text rangeOfString: @"\n"
		  options: 0 range: NSMakeRange(start, len - start)];
		if (aRange.location == NSNotFound) 
			return;
		start = aRange.location + aRange.length;
		numLines--;
	}

	[self deleteCharactersInRange: NSMakeRange(0, start)];
}
@end
#undef COLOR_FOR_KEY

