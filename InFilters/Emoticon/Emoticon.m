/***************************************************************************
                                Emoticon.m
                          -------------------
    begin                : Mon Jan 12 21:08:33 CST 2004
    copyright            : original(GNUMail)-Ludovic Marcotte Copyright 2003
                           TalkSoup adaptation-Andrew Ruder Copyright 2003
    email                : Andrew Ruder: aeruder@ksu.edu
                           Ludovic Marcotte: ludovic@Sophos.ca
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#import "Emoticon.h"

#import <TalkSoupBundles/TalkSoup.h>

#import <Foundation/NSAttributedString.h>
#import <Foundation/NSString.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSBundle.h>

#import <AppKit/NSAttributedString.h>
#import <AppKit/NSTextAttachment.h>
#import <AppKit/NSFileWrapper.h>

//
// The emoticon images are from gnomemeeting (http://www.gnomemeeting.org).
//
static struct { NSString *glyph; NSString *image; } emoticons[] = {
	{@":)",  @"emoticon-face1.tiff" },
	{@":-)", @"emoticon-face1.tiff" },
	{@":o)", @"emoticon-face1.tiff" },
	{@"8)",  @"emoticon-face2.tiff" },
	{@"8-)", @"emoticon-face2.tiff" },
	{@";)",  @"emoticon-face3.tiff" },
	{@";o)", @"emoticon-face3.tiff" },
	{@";-)", @"emoticon-face3.tiff" },
	{@":-(", @"emoticon-face4.tiff" },// :( conflicts with objc code! like: itemAtIndex:(int)theIndex
	{@":o(", @"emoticon-face4.tiff" },  
	{@":-0", @"emoticon-face5.tiff" },// :0 conflicts with a time value! like: 18:00
	{@":-o", @"emoticon-face5.tiff" },
	{@":D",  @"emoticon-face6.tiff" },
	{@":-D", @"emoticon-face6.tiff" },
	{@":|",  @"emoticon-face8.tiff" },
	{@":-|", @"emoticon-face8.tiff" },
	{@":-/", @"emoticon-face9.tiff" },// :/ conflicts with URLs! like: http://foobarbaz.com
	{@":o/", @"emoticon-face9.tiff" },  
	{@":p",  @"emoticon-face10.tiff"},
	{@":-p", @"emoticon-face10.tiff"},
	{@":'(", @"emoticon-face11.tiff"},
	{@":,(", @"emoticon-face11.tiff"},
	{@";o(", @"emoticon-face11.tiff"},
	{@":-*", @"emoticon-face13.tiff"},
	{@":-x", @"emoticon-face14.tiff"},
	{@"B)",  @"emoticon-face15.tiff"},
	{@"B-)", @"emoticon-face15.tiff"},
	{@":-.", @"emoticon-face19.tiff"},
	{@":o",  @"emoticon-face5.tiff" }
};

static NSString *resource_path = nil;

NSAttributedString *emoticonify(NSAttributedString *message)
{
	NSTextAttachment *aTextAttachment;
	NSFileWrapper *aFileWrapper;
	NSString *aString;
	NSMutableAttributedString *mas;
	int i, count;
	NSRange aRange;

	mas = [[NSMutableAttributedString alloc] 
	  initWithAttributedString: message];

	aString = [mas string];
	
	count = sizeof(emoticons)/sizeof(emoticons[0]);

	for (i = 0; i < count; i++)
	{
	    aRange.location = [aString length];
		do
		{
			aRange = [aString rangeOfString: emoticons[i].glyph
			   options: NSBackwardsSearch|NSCaseInsensitiveSearch
			   range: NSMakeRange(0, aRange.location)];
	  
			if (aRange.location != NSNotFound)
			{      
				aFileWrapper = [[NSFileWrapper alloc] 
				  initWithPath: [NSString stringWithFormat: @"%@/%@", 
				    resource_path, emoticons[i].image]];
				
				aTextAttachment = [[NSTextAttachment alloc] 
				  initWithFileWrapper: aFileWrapper];
	      
				[mas replaceCharactersInRange: aRange
				  withAttributedString: 
				  [NSAttributedString attributedStringWithAttachment: 
				   aTextAttachment]];
	      
				RELEASE(aTextAttachment);
				RELEASE(aFileWrapper);
			}
		} while (aRange.location != NSNotFound);
	}
	
	return AUTORELEASE(mas);
}

@implementation Emoticon
+ (void)initialize
{
	id bundle;
	
	bundle = [NSBundle bundleForClass: [Emoticon class]];

	resource_path = [bundle resourcePath];
	RETAIN(resource_path);
}
- (NSAttributedString *)pluginDescription
{
	int i;
	int count;
	id tmp;
	NSMutableAttributedString *aString = 
	 BuildAttributedString([NSNull null], IRCBold, IRCBoldValue,
	   _l(@"Author: "), @"Ludovic Marcotte\n",
	   [NSNull null], IRCBold, IRCBoldValue,
	   _l(@"TalkSoup adaptation: "), @"Andrew Ruder\n",
	   [NSNull null], IRCBold, IRCBoldValue,
	   _l(@"Icons: "), @"http://www.gnomemeeting.org\n\n",
	   [NSNull null], IRCBold, IRCBoldValue,
	   _l(@"Description: "), _l(@"Converts commonly used emoticons to pictures."
	   @" Has a similar look to many instant messengers in use today.\n\n"
	   @"Available emoticons:\n"), nil);
	
	count = sizeof(emoticons)/sizeof(emoticons[0]);
	for (i = 0; i < count; i++)
	{
		tmp = S2AS(emoticons[i].glyph);
		[aString appendAttributedString: emoticonify(tmp)];
		[aString appendAttributedString: 
		  BuildAttributedString([NSNull null], IRCColor, IRCColorRed, @" --- ", 
		   nil)];
		[aString appendAttributedString: tmp];
		[aString appendAttributedString: S2AS(@"\n")];
	}

	[aString appendAttributedString:	 
	  S2AS(_l(@"\nCopyright (C) 2005 by Ludovic Marcotte with changes "
	     @"by Andrew Ruder"))]; 
	
	return aString;
}
- sendMessage: (NSAttributedString *)message to: (NSAttributedString *)receiver 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick    
   sender: aPlugin
{
	[_TS_ sendMessage: emoticonify(message) to: receiver
	  onConnection: aConnection withNickname: aNick sender: self];
	return self;
}
- sendAction: (NSAttributedString *)anAction to: (NSAttributedString *)receiver 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ sendAction: emoticonify(anAction) to: receiver
	  onConnection: aConnection withNickname: aNick sender: self];
	return self;
}
- messageReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ messageReceived: emoticonify(aMessage) to: to
	  from: sender onConnection: connection withNickname: aNick
	  sender: self];
	return self;
}
- actionReceived: (NSAttributedString *)anAction to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ actionReceived: emoticonify(anAction) to: to
	  from: sender onConnection: connection withNickname: aNick
	  sender: self];
	return self;
}
@end
