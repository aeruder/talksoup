/***************************************************************************
                                TabContentController.h
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

@class TabContentController;

#ifndef TAB_CONTENT_CONTROLLER_H
#define TAB_CONTENT_CONTROLLER_H

#import "Controllers/ContentControllers/ContentController.h"

#import <Foundation/NSObject.h>
#import <Foundation/NSMapTable.h>

@class NSMutableArray, NSMutableDictionary, NSArray, NSString, NSAttributedString;

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
	}
- (NSArray *)masterControllers;
- (id <MasterController>)primaryMasterController;
- setPrimaryMasterController: (id <MasterController>)aController;

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

- (NSString *)presentationalNameForName: (NSString *)aName;
- (NSAttributedString *)labelForName: (NSString *)aName;

- (NSString *)nickname;
- setNickname: (NSString *)aNickname;

- setLowercasingFunction: (NSString * (*aFunction)(NSString *));
@end

#endif
