/***************************************************************************
                                TabContentController.m
                          -------------------
    begin                : Tue Jan 20 22:08:40 CST 2004
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
 
#import "Controllers/ContentControllers/StandardContentController.h"
#import "GNUstepOutput.h"

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
 
@implementation StandardContentController
- init
{
	if (!(self = [super init])) return nil;
	
	masterControllers = [NSMutableArray new];
	nameToChannel = [NSMutableDictionary new];
	nameToQuery = [NSMutableDictionary new];
	nameToBoth = [NSMutableDictionary new];
	nameToPresentation = [NSMutableDictionary new];
	nameToLabel = [NSMutableDictionary new];
	nameToMasterController = [NSMutableDictionary new];
	bothToName = NSCreateMapTable(NSObjectMapKeyCallBacks,
	  NSObjectMapValueCallBacks, 10);
	  
	lowercase = IRCLowercase;
	
	return self;
}
- (NSArray *)masterControllers
{
	return masterControllers;
}
- (id <MasterController>)primaryMasterController
{
	return [masterControllers objectAtIndex: 0];
}
- (void)setPrimaryMasterController: (id <MasterController>)aController
{
	[masterControllers removeObject: aController];
	[masterControllers insertObject: aController atIndex: 0];
}	
- (NSView *)viewForName: (NSString *)aName
{
	return [nameToBoth objectForKey: lowercase(aName)];
}
- (NSTextView *)chatViewForName: (NSString *)aName
{
	return [[nameToBoth objectForKey: lowercase(aName)] chatView];
}
- (id)controllerForName: (NSString *)aName
{
	return [[nameToBoth objectForKey: lowercase(aName)] contentView];
}
- (NSString *)typeForName: (NSString *)aName
{
	id object = [nameToBoth objectForKey: lowercase(aName)];
	
	if (!object) return nil;
	
	if ([object conformsToProtocol: @protocol(ContentControllerChannelView)])
	{
		return ContentControllerChannelType;
	}
	
	if ([object conformsToProtocol: @protocol(ContentControllerQueryView)])
	{
		return ContentControllerQueryType;
	}
	
	return nil;
}
- (NSArray *)allChatViews
{
	NSMutableArray *anArray = [NSMutableArray new];
	NSEnumerator *iter;
	id obj;
	
	iter = [[nameToBoth allValues] objectEnumerator];
	while ((obj = [iter nextObject]))
	{
		if ((obj = [obj chatView]))
		{
			[anArray addObject: obj];
		}
	}
	
	return AUTORELEASE(anArray);
}
- (NSArray *)allControllers
{
	return [nameToBoth allValues];
}	
- (NSArray *)allViews
{
	NSMutableArray *anArray = [NSMutableArray new];
	NSEnumerator *iter;
	id obj;
	
	iter = [[nameToBoth allValues] objectEnumerator];
	while ((obj = [iter nextObject]))
	{
		if ((obj = [obj contentView]))
		{
			[anArray addObject: obj];
		}
	}
	
	return AUTORELEASE(anArray);
}
- (NSArray *)allNames
{
	return [nameToBoth allKeys];
}
- (NSArray *)allChatViewsOfType: (NSString *)aType
{
	NSMutableArray *anArray = [NSMutableArray new];
	NSArray *targetArray;
	NSEnumerator *iter;
	id obj;
	
	if ([aType isEqualToString: ContentControllerChannelType])
	{
		targetArray = [nameToChannel allValues];
	}
	else if ([aType isEqualToString: ContentControllerQueryType])
	{
		targetArray = [nameToQuery allValues];
	}
	else
	{
		return AUTORELEASE(anArray);
	}
	
	iter = [targetArray objectEnumerator];
	while ((obj = [iter nextObject]))
	{
		if ((obj = [obj chatView]))
		{
			[anArray addObject: obj];
		}
	}
	
	return AUTORELEASE(anArray);
}
- (NSArray *)allControllersOfType: (NSString *)aType
{
	if ([aType isEqualToString: ContentControllerChannelType])
	{
		return [nameToChannel allValues];
	}
	else if ([aType isEqualToString: ContentControllerQueryType])
	{
		return [nameToQuery allValues];
	}
	
	return AUTORELEASE([NSArray new]);
}
- (NSArray *)allViewsOfType: (NSString *)aType
{
	NSMutableArray *anArray = [NSMutableArray new];
	NSArray *targetArray;
	NSEnumerator *iter;
	id obj;
	
	if ([aType isEqualToString: ContentControllerChannelType])
	{
		targetArray = [nameToChannel allValues];
	}
	else if ([aType isEqualToString: ContentControllerQueryType])
	{
		targetArray = [nameToQuery allValues];
	}
	else
	{
		return AUTORELEASE(anArray);
	}
	
	iter = [targetArray objectEnumerator];
	while ((obj = [iter nextObject]))
	{
		if ((obj = [obj contentView]))
		{
			[anArray addObject: obj];
		}
	}
	
	return AUTORELEASE(anArray);
}				
- (NSArray *)allNamesOfType: (NSString *)aType
{
	if ([aType isEqualToString: ContentControllerChannelType])
	{
		return [nameToChannel allKeys];
	}
	else if ([aType isEqualToString: ContentControllerQueryType])
	{
		return [nameToQuery allKeys];
	}
	
	return AUTORELEASE([NSArray new]);
}
- putMessage: (NSAttributedString *)aMessage in: (id)aName
{
	[self putMessage: aMessage in: aName withEndLine: YES];
	return self;
}
- putMessage: (NSAttributedString *)aMessage in: (id)aName 
    withEndLine: (BOOL)hasEnd
{
	id controller = nil;
	id string;
	NSRange aRange;
	
	if (!aString) return self;
	
	if ([aCName conformsToProtocol: @protocol(ContentControllerQueryView)])
	{
		controller = aName;
	}
	else if ([aName isKindOfClass: [NSString class]])
	{
		controller = [nameToBoth objectForKey: lowercase(aName)];
	}
	else if ([aName isKindOfClass: [NSAttributedString class]])
	{
		controller = [nameToBoth objectForKey: 
		    lowercase([aName string])];
	}
	else if ([aName isKindOfClass: [NSArray class]])
	{
		NSEnumerator *iter;
		id object;
		
		iter = [aName objectEnumerator];
		while ((object = [iter nextObject]))
		{
			[self putMessage: aString in: object withEndLine: aBool];
		}
		return self;
	}
	
	if (controller == nil)
	{
		controller = [nameToBoth objectForKey: current];
	}

	controller = [[controller chatView] textStorage];	
	
	if ([aString isKindOfClass: [NSAttributedString class]])
	{
		aRange = NSMakeRange(0, [aString length]);
		// Change those attributes used by the underlying TalkSoup system into attributes
		// used by AppKit
		string = [aString substituteColorCodesIntoAttributedStringWithFont: chatFont];
		
		// NOTE: a large part of the code below sets an attribute called 'TypeOfColor' to the
		// GNUstepOutput type of color.  This is used to more quickly change the colors should
		// the colors change at a later time.
		
		// Set the foreground to the default background color when the foreground color
		// does not already have a color and IRCReverse is set
		[string setAttribute: NSForegroundColorAttributeName toValue:
		  [self colorForKey: GNUstepOutputBackgroundColor]
		  inRangesWithAttributes: [NSArray arrayWithObjects: NSForegroundColorAttributeName,
		    IRCReverse, nil] matchingValues: [NSArray arrayWithObjects: [NSNull null], 
		    IRCReverseValue, nil] withRange: aRange];
		
		// Set the background to the default foreground color when the background color
		// does not already have a color and IRCReverse is set.
		[string setAttribute: NSBackgroundColorAttributeName toValue:
		  [self colorForKey: GNUstepOutputTextColor]
		  inRangesWithAttributes: [NSArray arrayWithObjects: NSBackgroundColorAttributeName,
		    IRCReverse, nil] matchingValues: [NSArray arrayWithObjects: [NSNull null], 
		    IRCReverseValue, nil] withRange: aRange];		
		
		// When NSForegroundColorAttribute is not set, set the type of color to foreground color
		[string setAttribute: TypeOfColor toValue: GNUstepOutputTextColor
		  inRangesWithAttributes: 
		    [NSArray arrayWithObjects: NSForegroundColorAttributeName,
		      TypeOfColor, nil]
		  matchingValues: 
		    [NSArray arrayWithObjects: [NSNull null], [NSNull null], nil]
		  withRange: aRange];
		// and then set the actual color to the foreground color
		[string setAttribute: NSForegroundColorAttributeName
		  toValue: [self colorForKey: GNUstepOutputTextColor]
		 inRangesWithAttribute: TypeOfColor
		  matchingValue: GNUstepOutputTextColor
		 withRange: aRange];
		 
		// set the other bracket colors type of color attribute 
		[string setAttribute: NSForegroundColorAttributeName
		  toValue: [self colorForKey: GNUstepOutputOtherBracketColor]
		 inRangesWithAttribute: TypeOfColor
		  matchingValue: GNUstepOutputOtherBracketColor
		 withRange: aRange];
		
		// set the personal bracket colors type of color attribute
		[string setAttribute: NSForegroundColorAttributeName
		  toValue: [self colorForKey: GNUstepOutputPersonalBracketColor]
		 inRangesWithAttribute: TypeOfColor
		  matchingValue: GNUstepOutputPersonalBracketColor
		 withRange: aRange];
	}
	else
	{
		// just make it all the foreground color if they just passed in a regular string
		aRange = NSMakeRange(0, [[aString description] length]);
		string = AUTORELEASE(([[NSMutableAttributedString alloc] 
		  initWithString: [aString description]
		  attributes: [NSDictionary dictionaryWithObjectsAndKeys:
			 chatFont, NSFontAttributeName,
			 TypeOfColor, GNUstepOutputTextColor,
			 [self colorForKey: GNUstepOutputTextColor], NSForegroundColorAttributeName,
		     nil]]));
	}
	
	[controller appendAttributedString: string];
	
	if (hasEnd)
	{
		[controller appendAttributedString: AUTORELEASE(([[NSAttributedString alloc]
		  initWithString: @"\n" attributes: [NSDictionary dictionaryWithObjectsAndKeys:
		  chatFont, NSFontAttributeName, nil]]))];
	}
	
	//clear_scrollback(controller);
	// FIXME: the controllers should handle the removing of extra LINES (need to get rid of this byte nonsense)
}
- putMessageInAll: (NSAttributedString *)aMessage
{
	[self putMessageInAll: aMessage withEndLine: YES];
	return self;	
}
- putMessageInAll: (NSAttributedString *)aMessage
    withEndLine: (BOOL)hasEnd
{
	NSEnumerator *iter;
	id obj;
	
	iter = [[nameToBoth allKeys] objectEnumerator];
	
	while ((obj = [iter nextObject]))
	{
		[self putMessage: aMessage in: obj withEndLine: hasEnd];
	}
	
	return self;
}
- putMessageInAll: (NSAttributedString *)aMessage
    ofType: (NSString *)aType
{
	[self putMessageInAll: aMessage ofType: aType withEndLine: YES];
	return self;
}
- putMessageInAll: (NSAttributedString *)aMessage
    ofType: (NSString *)aType
    withEndLine: (BOOL)hasEnd
{
	NSArray *targetArray;
	NSEnumerator *iter;
	id obj;
	
	if ([aType isEqualToString: ContentControllerChannelType])
	{
		targetArray = [nameToChannel allKeys];
	}
	else if ([aType isEqualToString: ContentControllerQueryType])
	{
		targetArray = [nameToQuery allKeys];
	}
	else
	{
		return self;
	}
	
	iter = [targetArray objectEnumerator];
	while ((obj = [iter nextObject]))
	{
		[self putMessage: aMessage in: obj withEndLine: hasEnd];
	}
	return self;
}
- (NSString *)presentationalNameForName: (NSString *)aName
{
	return [nameToPresentation objectForKey: lowercase(aName)];
}
- (NSAttributedString *)labelForName: (NSString *)aName
{
	return [nameToLabel objectForKey: lowercase(aName)];
}
- (NSString *)nickname
{
	return nickname;
}
- setNickname: (NSString *)aNickname
{
	if (aNickname == nickname) return self;
	RELEASE(nickname);
	nickname = RETAIN(aNickname);
	return self;
}
- setLowercasingFunction: (NSString * (*aFunction)(NSString *))
{
	lowercase = aFunction;
}
@end
