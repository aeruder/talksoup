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
@class NSArray, NSTextView, NSTextField, NSWindow, Channel;

extern NSString *ContentControllerChannelType;
extern NSString *ContentControllerQueryType;

extern NSString *ContentConsoleName;

@protocol ContentControllerQueryView
+ (NSString *)standardNib;
- (NSTextView *)chatView;
- (NSView *)contentView;
@end

//@protocol ContentControllerChannelName < ContentControllerChannelName >
//- (NSString *)stringName;
//- (NSAttributedString *)presentationName;
//@end

@protocol ContentControllerChannelView < ContentControllerQueryView >
- (Channel *)channelSource;
- (void)attachChannelSource: (Channel *)aChannel;
- (void)detachChannelSource;
@end


@protocol MasterController
- addView: (id <ContentControllerQueryView>)aView withLabel: (NSAttributedString *)aLabel
   forContentController: (id <ContentController>)aContentController;
- addView: (id <ContentControllerQueryView>)aView withLabel: (NSAttributedString *)aLabel
   atIndex: (int)aIndex forContentController: (id <ContentController>)aContentController;

- removeView: (id <ContentControllerQueryView>)aView;
- removeViewAtIndex: (int)aIndex;

- moveView: (id <ContentControllerQueryView>)aView toIndex: (int)aIndex;
- moveViewAtIndex: (int)aIndex toIndex: (int)aNewIndex;
	 
- (NSArray *)containedContentControllers;
- (NSArray *)viewListForContentController: 
    (id <ContentController>)aContentController;
- (NSArray *)allViews;

- (NSTextField *)typeView;
- (NSTextField *)nickView;

- (NSWindow *)window;
@end


@protocol ContentController
- (NSArray *)masterControllers;
- (id <MasterController>)primaryMasterController;
- (void)setPrimaryMasterController: (id <MasterController>)aController;

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

- (void)setLowercasingFunction: (NSString * (*)(NSString *))aFunction;
@end

/*
	object:          The content controller.
	
	userinfo:
	@"OldIndex"      Old index
	@"Index"         The new index
	@"Master"        The master controller
	@"View"          The view controller.
	@"Content"       The content controller
*/
extern NSString *ContentControllerMovedInMasterControllerNotification;

/*
	object:          The content controller
	
	userinfo:
	@"Master":       The master controller.
	@"View":         The view controller.
	@"Index":        The index
	@"Content":      The content controller
*/
extern NSString *ContentControllerAddedToMasterControllerNotification;

/*
	object:          The content controller
	
	userinfo:
	@"Master":       The master controller.
	@"View":         The view controller.
	@"Content":      The content controller.
*/
extern NSString *ContentControllerRemovedFromMasterControllerNotification;

/* 
	object:          The content controller
	
	userinfo:
	@"OldNickname": Old nickname
	@"Nickname":    New nickname
	@"Content":     The content controller
*/
extern NSString *ContentControllerChangedNicknameNotification;

/* 
	object:       The content controller

	userinfo:
	@"View":     The view controller
	@"Content":  The content controller
	@"Master":   The master controller
*/
extern NSString *ContentControllerSelectedNameNotification;

/* 
	object:       The content controller
	
	userinfo:
   @"OldLabel": The old label
	@"Label":    The new label
	@"View":     The view controller
	@"Content":  The content controller
	@"Master":   The master controller
*/
extern NSString *ContentControllerChangedLabelNotification;

	
#endif
