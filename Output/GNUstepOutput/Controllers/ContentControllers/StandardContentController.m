/***************************************************************************
                          StandardContentController.m
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
#import "Controllers/ContentControllers/StandardChannelController.h"
#import "Controllers/ContentControllers/StandardQueryController.h"
#import "Controllers/Preferences/PreferencesController.h"
#import "Controllers/Preferences/FontPreferencesController.h"
#import "Controllers/Preferences/ColorPreferencesController.h"
#import "Misc/NSAttributedStringAdditions.h"
#import "Misc/NSColorAdditions.h"
#import "GNUstepOutput.h"

#import <AppKit/NSNibLoading.h>
#import <AppKit/NSTextView.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSAttributedString.h>
#import <AppKit/NSWindow.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNull.h>

static NSString *TypeOfColor = @"TypeOfColor";
 
@interface StandardContentController (PrivateMethods)
- (NSColor *)colorForKey: (NSString *)aKey;
@end

@implementation StandardContentController
+ (Class)masterClass
{
	return Nil;
}
+ (Class)queryClass
{
	return [StandardQueryController class];
}
+ (Class)channelClass
{
	return [StandardChannelController class];
}
- initWithMasterController: (id <MasterController>) aMaster
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
	  
	if (!aMaster) aMaster = [[[self class] masterClass] new]; 
	if (!aMaster)
	{
		[self dealloc];
		return nil;
	}
	
	[masterControllers addObject: aMaster];

	lowercase = IRCLowercase;

	chatFont = RETAIN([FontPreferencesController
	  getFontFromPreferences: GNUstepOutputChatFont]);
	
	channelClass = [[self class] channelClass];
	queryClass = [[self class] queryClass];
	
	return self;
}
/* Initializes the content controller in a new master
 * controller 
 */
- init
{
	return [self initWithMasterController: nil];
}
/* Returns the corresponding input manager for a view.
 */
- (id <TypingController>)typingControllerForView:
   (id <ContentControllerQueryView>)aView
{
	id name;

	name = NSMapGet(bothToName, aView);
	if (!name) return nil;

	return [nameToTyping objectForName: name];
}
/* Sets the connectioncontroller for this content controller.
 * Does not retain.
 */
- (void)setConnectionController: (ConnectionController *)aController
{
	connectionController = aController;
}
/* Returns ConnectionController for this content controller.
 */
- (ConnectionController *)connectionController
{
	return connectionController;
}
// FIXME a dealloc needs to be written
/* Returns an array of all master controllers that are used by any of the channels or 
 * queries within this controller
 */
- (NSArray *)masterControllers
{
	return masterControllers;
}
/* Returns the default master controller that queries and channels will be added to.
 * Defaults to the master controller holding the console view.
 */
- (id <MasterController>)primaryMasterController
{
	return [masterControllers objectAtIndex: 0];
}
/* Sets another primary master controller, <var>aController</var>
 */
- (void)setPrimaryMasterController: (id <MasterController>)aController
{
	[masterControllers removeObject: aController];
	[masterControllers insertObject: aController atIndex: 0];
}	
/* Returns the master controller used by the view with the name 
 * <var>aName</var>
 */
- (id <MasterController>)masterControllerForName: (NSString *)aName
{
	return [nameToMasterController objectForKey: lowercase(aName)];
}
/* Returns the view for the name <var>aName</var>
 */
- (NSView *)viewForName: (NSString *)aName
{
	return [nameToBoth objectForKey: lowercase(aName)];
}
/* Returns the chat view for the name <var>aName</var>
 */
- (NSTextView *)chatViewForName: (NSString *)aName
{
	return [[nameToBoth objectForKey: lowercase(aName)] chatView];
}
/* Returns the controller for the name <var>aName</var>
 * This will conform to [(ContentControllerQueryView)] in the case of
 * a query or [(ContentControllerQueryView)] and [(ContentControllerChannelName)]
 * in the case of a channel. 
 */
- (id)controllerForName: (NSString *)aName
{
	return [[nameToBoth objectForKey: lowercase(aName)] contentView];
}
/* Returns the type of view for the name <var>aName</var>.  The types is either
 * <var>ContentControllerChannelType</var> or <var>ContentControllerQueryType</var>.
 */
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
/* Returns an array of all chat views of all queries and all channels
 */
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
/* Returns an array of all controllers.
 */
- (NSArray *)allControllers
{
	return [nameToBoth allValues];
}
/* Returns an array of all views.
 */
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
/* Returns an array of all names.
 */
- (NSArray *)allNames
{
	return [nameToBoth allKeys];
}
/* Will return all chat views of the type <var>aType</var> which can either
 * be <var>ContentControllerChannelType</var> or <var>ContentControllerQueryType</var>
 */ 
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
/* Returns an array of all controllers of a certain type <var>aType</var> which can either
 * be <var>ContentControllerChannelType</var> or <var>ContentControllerQueryType</var>
 */
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
/* Returns an array of all views of a certain type <var>aType</var> which can either
 * be <var>ContentControllerChannelType</var> or <var>ContentControllerQueryType</var>
 */
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
/* Returns array of all the names of a certain type <var>aType</var> which can
 * be either <var>ContentControllerChannelType</var> or <var>ContentControllerQueryType</var>
 */			
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
/* Calls putMessage:in:withEndLine: as [self putMessage: aMessage: in: aName 
 * withEndLine: YES];
 */
- putMessage: (NSAttributedString *)aMessage in: (id)aName
{
	[self putMessage: aMessage in: aName withEndLine: YES];
	return self;
}
/* Puts the message <var>aMessage</var> in <var>aName</var> with an optional
 * endline character appended to the end (specified by <var>hasEnd</var>).
 * <var>aName</var> can be a view conforming to <ContentControllerQueryView>,
 * a NSString with the channel name, a NSAttributedString of the channel name,
 * or an NSArray of any of the above.  If it is nil, it'll put it in the 
 * currently visible channel.
 */
- putMessage: (NSAttributedString *)aMessage in: (id)aName 
    withEndLine: (BOOL)hasEnd
{
	id controller = nil;
	id string;
	NSRange aRange;
	
	if (!aMessage) return self;
	
	if ([aName conformsToProtocol: @protocol(ContentControllerQueryView)])
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
			[self putMessage: aMessage in: object withEndLine: hasEnd];
		}
		return self;
	}
	
	if (controller == nil)
	{
		// FIXME this should put it in the current window
		// whatever that means now.
		//controller = [nameToBoth objectForKey: current];
	}

	controller = [[controller chatView] textStorage];	
	
	if ([aMessage isKindOfClass: [NSAttributedString class]])
	{
		aRange = NSMakeRange(0, [aMessage length]);
		// Change those attributes used by the underlying TalkSoup system into attributes
		// used by AppKit
		string = [aMessage substituteColorCodesIntoAttributedStringWithFont: chatFont];
		
		// NOTE: a large part of the code below sets an attribute called 'TypeOfColor' to the
		// GNUstepOutput type of color.  This is used to more accurately change the colors should
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
		aRange = NSMakeRange(0, [[aMessage description] length]);
		string = AUTORELEASE(([[NSMutableAttributedString alloc] 
		  initWithString: [aMessage description]
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
	
	return self;
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
- addControllerOfType: (NSString *)aType withName: (NSString *)aName 
   withLabel: (NSAttributedString *)aLabel 
   inMasterController: (id <MasterController>)aMaster
{
	id controller;
	id name;
	BOOL isQuery, isChannel;
	
	isQuery = [aType isEqualToString: ContentControllerQueryType];
	isChannel = [aType isEqualToString: ContentControllerChannelType];
	
	name = lowercase(aName);
	
	if ([nameToBoth objectForKey: name])
	{
		[self setLabel: aLabel forName: name];
		return nil;
	}
		
	if (!isQuery && !isChannel)
	{
		return self;
	}
	if (isQuery)
	{
		controller = AUTORELEASE([queryClass new]);
		if (![NSBundle loadNibNamed: [queryClass standardNib] owner: controller])
		{
			return nil;
		}
		
		[nameToQuery setObject: controller forKey: name];
	}
	else if (isChannel)
	{
		controller = AUTORELEASE([channelClass new]);
		if (![NSBundle loadNibNamed: [channelClass standardNib] owner: controller])
		{
			return nil;
		}
		
		[nameToChannel setObject: controller forKey: name];
	}
		
	[nameToBoth setObject: controller forKey: name];
	[nameToPresentation setObject: aName forKey: name];
	[nameToLabel setObject: aLabel forKey: name];
	
	NSMapInsert(bothToName, controller, name);
	
	if (!aMaster) aMaster = [masterControllers objectAtIndex: 0];
	
	[aMaster addView: controller withLabel: aLabel 
	  forContentController: self];
	[nameToMasterController setObject: aMaster forKey: name];
	
	return self;
}
- removeControllerWithName: (NSString *)aName
{
	id master;
	id lo;
	id cont;
	
	lo = lowercase(aName);
	
	master = [nameToMasterController objectForKey: lo];
	
	if (!master)
	{
		return self;
	}
	
	cont = [nameToBoth objectForKey: lo];
	if (!cont)
	{
		return self;
	}
	
	[master removeView: cont];
	
	[nameToChannel removeObjectForKey: lo];	
	[nameToQuery removeObjectForKey: lo];
	[nameToBoth removeObjectForKey: lo];
	[nameToPresentation removeObjectForKey: lo];
	[nameToLabel removeObjectForKey: lo];
	NSMapRemove(bothToName, cont);
		
	return self;
}
- renameControllerWithName: (NSString *)aName to: (NSString *)newName
{
	id lo1, lo2;
	id obj, which;
	
	lo1 = lowercase(aName);
	lo2 = lowercase(newName);
	
	if (![nameToBoth objectForKey: lo1]) return self;
	
	if ([lo1 isEqualToString: lo2])
	{
		if (![[nameToPresentation objectForKey: lo1]
		       isEqualToString: newName])
		{
			[nameToPresentation setObject: newName forKey: lo2];
		}
		return self;
	}
	
	if ([nameToBoth objectForKey: lo2]) return self;
	
	[nameToPresentation setObject: newName forKey: lo2];
	[nameToPresentation removeObjectForKey: lo1];
		
	obj = [nameToBoth objectForKey: lo1];
	which = ([obj conformsToProtocol: @protocol(ContentControllerChannelView)]) ?
	  nameToChannel : nameToQuery;
		
	[nameToBoth setObject: obj forKey: lo2];
	[which setObject: obj forKey: lo2];
		
	[nameToBoth removeObjectForKey: lo1];
	[which removeObjectForKey: lo1];
	
	NSMapInsert(bothToName, obj, lo2);
		
	[nameToLabel setObject: [nameToLabel objectForKey:
	  lo1] forKey: lo2];
	[nameToLabel removeObjectForKey: lo1];
		
	return self;
}
- (NSAttributedString *)labelForName: (NSString *)aName
{
	return [nameToLabel objectForKey: lowercase(aName)];
}
- (void)setLabel: (NSAttributedString *)aLabel forName: (NSString *)aName
{
	id label;
	id lo;
	id cont;
	id mast;
	
	lo = lowercase(aName);
	
	if (!(label = [nameToLabel objectForKey: lo]))
	{
		return;
	}
	
	if (!(cont = [nameToBoth objectForKey: lo]))
	{
		return;
	}
	
	if (!(mast = [nameToMasterController objectForKey: lo]))
	{
		return;
	}
	
	if (label == aLabel) return;
	
	[nameToLabel setObject: aLabel forKey: lowercase(aName)];

	[mast setLabel: aLabel forView: cont];
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName: ContentControllerChangedLabelNotification
	 object: self userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
	  label, @"OldLabel",
	  aLabel, @"Label",
	  cont, @"View",
	  self, @"Content",
	  mast, @"Master",
	  nil]];

	return;
}
- (NSString *)presentationalNameForName: (NSString *)aName
{
	return [nameToPresentation objectForKey: lowercase(aName)];
}
- (void)setPresentationName: (NSString *)aPresentationName forName: (NSString *)aName
{
	[nameToPresentation setObject: aPresentationName forKey: lowercase(aName)];
}
- (NSString *)nickname
{
	return nickname;
}
- (void)setNickname: (NSString *)aNickname
{
	if (aNickname == nickname) return;
	
	RELEASE(nickname);
	nickname = RETAIN(aNickname);

	[NSNotificationCenter postNotificationName: ContentControllerChangedNicknameNotification
	 object: self userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
	  nickname, @"OldNickname",
	  aNickname, @"Nickname",
	  self, @"Content",
	  nil]];

	return;
}
- (NSString *)title
{
	return title;
}
- (void)setTitle: (NSString *)aTitle
{
	ASSIGN(title, aTitle);
}
- (void)setLowercasingFunction: (NSString * (*)(NSString *))aFunction
{
	lowercase = aFunction;
}
- (void)bringNameToFront: (NSString *)aName
{
	id <MasterController> master;
	id <ContentControllerQueryView> view;

	master = [nameToMasterController objectForKey: lowercase(aName)];
	view = [nameToBoth objectForKey: lowercase(aName)];
	
	if (master) {
		[master bringToFront];
		[master selectView: view];
	}
}
@end

@implementation StandardContentController (PrivateMethods)
- (NSColor *)colorForKey: (NSString *)aKey
{
	return [NSColor colorFromEncodedData: [_PREFS_ preferenceForKey:
	  aKey]];
}
@end
