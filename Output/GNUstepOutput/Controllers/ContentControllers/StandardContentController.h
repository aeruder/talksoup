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
@class NSFont, NSText;

@interface StandardContentController : NSObject < ContentController >
	{
		NSMutableArray *masterControllers;
		NSMutableDictionary *nameToChannel;
		NSMutableDictionary *nameToQuery;
		NSMutableDictionary *nameToBoth;
		NSMutableDictionary *nameToPresentation;
		NSMutableDictionary *nameToLabel;
		NSMutableDictionary *nameToMasterController;
		NSMapTable *bothToName;
		NSString *nickname;
		NSString * (*lowercase)(NSString *);
		NSString *title;
		Class channelClass;
		Class queryClass;
		NSFont *chatFont;
		NSText *fieldEditor;
	}
+ (Class)masterClass;
+ (Class)queryClass;
+ (Class)channelClass;

- initWithMasterController: (id <MasterController>) aMaster;

- setFieldEditor: (NSText *)aFieldEditor;
- (NSText *)fieldEditor;

- (NSArray *)masterControllers;
- (id <MasterController>)primaryMasterController;
- (void)setPrimaryMasterController: (id <MasterController>)aController;

- (id <MasterController>)masterControllerForName: (NSString *)aName;
- (NSView *)viewForName: (NSString *)aName;
- (NSTextView *)chatViewForName: (NSString *)aName;
- (id)controllerForName: (NSString *)aName;
- (NSString *)typeForName: (NSString *)aName;

- (NSArray *)allChatViews;
- (NSArray *)allControllers;
- (NSArray *)allViews;
- (NSArray *)allNames;
- (NSArray *)allChatViewsOfType: (NSString *)aType;
- (NSArray *)allControllersOfType: (NSString *)aType;
- (NSArray *)allViewsOfType: (NSString *)aType;
- (NSArray *)allNamesOfType: (NSString *)aType;

- putMessage: (NSAttributedString *)aMessage in: (id)aName;
- putMessage: (NSAttributedString *)aMessage in: (id)aName 
    withEndLine: (BOOL)hasEnd;
- putMessageInAll: (NSAttributedString *)aMessage;
- putMessageInAll: (NSAttributedString *)aMessage
    withEndLine: (BOOL)hasEnd;
- putMessageInAll: (NSAttributedString *)aMessage
    ofType: (NSString *)aType;
- putMessageInAll: (NSAttributedString *)aMessage
    ofType: (NSString *)aType
    withEndLine: (BOOL)hasEnd;

- addControllerOfType: (NSString *)aType withName: (NSString *)aName 
   withLabel: (NSAttributedString *)aLabel 
   inMasterController: (id <MasterController>)aMaster;
- removeControllerWithName: (NSString *)aName;
- renameControllerWithName: (NSString *)aName to: (NSString *)newName;

- (NSAttributedString *)labelForName: (NSString *)aName;
- setLabel: (NSAttributedString *)aLabel forName: (NSString *)aName;

- (NSString *)presentationalNameForName: (NSString *)aName;

- (NSString *)nickname;
- setNickname: (NSString *)aNickname;

- (NSString *)title;
- (void)setTitle: (NSString *)aTitle;

- (void)setLowercasingFunction: (NSString * (*)(NSString *))aFunction;
@end

#endif
