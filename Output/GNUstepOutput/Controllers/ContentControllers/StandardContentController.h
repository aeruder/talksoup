/***************************************************************************
                         StandardContentController.h
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

@class StandardContentController;

#ifndef STANDARD_CONTENT_CONTROLLER_H
#define STANDARD_CONTENT_CONTROLLER_H

#import "Controllers/ContentControllers/ContentController.h"

#import <Foundation/NSObject.h>
#import <Foundation/NSMapTable.h>

@class NSMutableArray, NSMutableDictionary, NSArray, NSString, NSAttributedString;
@class NSFont, NSText, ConnectionController;

@interface StandardContentController : NSObject < ContentController >
	{
		NSMutableArray *masterControllers;
		NSMutableDictionary *nameToChannel;
		NSMutableDictionary *nameToQuery;
		NSMutableDictionary *nameToBoth;
		NSMutableDictionary *nameToPresentation;
		NSMutableDictionary *nameToLabel;
		NSMutableDictionary *nameToMasterController;
		NSMutableDictionary *nameToTyping;
		NSMapTable *bothToName;
		NSString *nickname;
		NSString * (*lowercase)(NSString *);
		NSString *title;
		Class channelClass;
		Class queryClass;
		ConnectionController *connectionController;
		NSFont *chatFont;
		id <ContentControllerQueryController>lastSelected;
	}
+ (Class)masterClass;
+ (Class)queryClass;
+ (Class)channelClass;

- initWithMasterController: (id <MasterController>) aMaster;

- (id <TypingController>)typingControllerForViewController: 
   (id <ContentControllerQueryController>)aController;

- (NSArray *)masterControllers;
- (id <MasterController>)primaryMasterController;
- (void)setPrimaryMasterController: (id <MasterController>)aController;

- (NSString *)nameForViewController: (id <ContentControllerQueryController>)aController;
- (id <MasterController>)masterControllerForName: (NSString *)aName;
- (NSTextView *)chatViewForName: (NSString *)aName;
- (id <ContentControllerQueryController>)viewControllerForName: (NSString *)aName;
- (NSString *)typeForName: (NSString *)aName;

- (NSArray *)allChatViews;
- (NSArray *)allControllers;
- (NSArray *)allNames;
- (NSArray *)allChatViewsOfType: (NSString *)aType;
- (NSArray *)allViewControllersOfType: (NSString *)aType;
- (NSArray *)allNamesOfType: (NSString *)aType;

- (void)putMessage: (NSAttributedString *)aMessage in: (id)aName;
- (void)putMessage: (NSAttributedString *)aMessage in: (id)aName 
    withEndLine: (BOOL)hasEnd;
- (void)putMessageInAll: (NSAttributedString *)aMessage;
- (void)putMessageInAll: (NSAttributedString *)aMessage
    withEndLine: (BOOL)hasEnd;
- (void)putMessageInAll: (NSAttributedString *)aMessage
    ofType: (NSString *)aType;
- (void)putMessageInAll: (NSAttributedString *)aMessage
    ofType: (NSString *)aType
    withEndLine: (BOOL)hasEnd;

- (id <ContentControllerQueryController>)addViewControllerOfType: (NSString *)aType 
   withName: (NSString *)aName 
   withLabel: (NSAttributedString *)aLabel 
   inMasterController: (id <MasterController>)aMaster;
- (void)removeViewControllerWithName: (NSString *)aName;
- (void)renameViewControllerWithName: (NSString *)aName 
   to: (NSString *)newName;

- (NSString *)presentationalNameForName: (NSString *)aName;
- (void)setPresentationName: (NSString *)aPresentationName forName: (NSString *)aName;

- (NSAttributedString *)labelForName: (NSString *)aName;
- (void)setLabel: (NSAttributedString *)aLabel forName: (NSString *)aName;

- (NSString *)nickname;
- (void)setNickname: (NSString *)aNickname;

- (NSString *)title;
- (void)setTitle: (NSString *)aTitle;

- (NSString * (*)(NSString *))lowercasingFunction;
- (void)setLowercasingFunction: (NSString * (*)(NSString *))aFunction;

- (void)bringNameToFront: (NSString *)aName;
@end

#endif
