/***************************************************************************
                                ContentController.h
                          -------------------
    begin                : Mon Jan 19 12:09:57 CST 2004
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

#ifndef CONTENT_CONTROLLER_H
#define CONTENT_CONTROLLER_H

#import <Foundation/NSObject.h>

@protocol MasterController;
@protocol ContentController;
@protocol ContentControllerDelegate;

@class ConnectionController, NSView, NSString, NSAttributedString;
@class NSArray, NSTextView;

extern NSString *ContentControllerChannelType;
extern NSString *ContentControllerQueryType;

@protocol ContentController
- setDelegate: aDelegate;  // Doesn't retain
- delegate;

- (id <MasterController>)primaryMasterController;

- (NSView *)viewForName: (NSString *)aName;
- (NSTextView *)chatViewForName: (NSString *)aName;
- (id)controllerForName: (NSString *)aName;
- (NSString *)typeForName: (NSString *)aName;
- (NSArray *)allViews;
- (NSArray *)allNames;
- (NSArray *)allViewsOfType: (NSString *)aType;
- (NSArray *)allNamesOfType: (NSString *)aType;

- putMessage: (NSAttributedString *)aMessage in: (NSString *)aName;
- putMessage: (NSAttributedString *)aMessage in: (NSString *)aName 
    withEndLine: (BOOL)hasEnd;
- putMessageInAll: (NSAttributedString *)aMessage;
- putMessageInAll: (NSAttributedString *)aMessage
    withEndLine: (BOOL)hasEnd;

- (NSString *)presentationalNameForName: (NSString *)aName;
- (NSAttributedString *)labelForName: (NSString *)aName;

- (NSString *)nickname;
- setNickname: (NSString *)aNickname;
@end

@protocol ContentControllerDelegate // Informal
- (void)contentController: (id <ContentController>)aController
   selectedName: (NSString *)aName inMaster: (id <MasterController>)aMaster;
@end

@protocol MasterController
- (NSArray *)containedContentControllers;
- (NSArray *)channelListForContentController: 
    (id <ContentController>)aContentController;

- setChatFont: (NSFont *)aFont;
- (NSFont *)chatFont;

- (NSTextField *)typeView;
- (NSTextField *)nickView;

- (NSWindow *)window;

- (void)updateNickname;
@end

#endif
