/***************************************************************************
                                IRCObjecct.h
                          -------------------
    begin                : Thu May 30 22:06:25 UTC 2002
    copyright            : (C) 2002 by Andy Ruder
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

#import "LineObject.h"
#import "NetTCP.h"
#import <Foundation/NSObject.h>

extern NSString *IRCException;

/* When one of the callbacks ends with from: (NSString *), that last 
 * argument is where the callback originated from.  It is usually in a slightly
 * different format: nick!host.  So if you want the nick you use
 * ExtractIRCNick, if you want the host you use ExtractIRCHost, and if you
 * want both, you can use SeparateIRCNickAndHost(which stores nick then host
 * in that order)
 * 
 * If, for example, the message originates from a server, it will not be in
 * this format, in this case, ExtractIRCNick will return the original string
 * and ExtractIRCHost will return nil, and SeparateIRCNickAndHost will return
 * an array with just one object.
 * 
 * So, if you are using a callback, and the last argument has a from: before
 * it, odds are you may want to look into using these functions.
 */


@interface NSString (IRCAddition)
// Because in IRC {}|^ are lowercase of []\~
- (NSString *)uppercaseIRCString;
- (NSString *)lowercaseIRCString;
- (NSComparisonResult)caseInsensitiveIRCCompare: (NSString *)aString;
@end

NSString *ExtractIRCNick(NSString *prefix);
NSString *ExtractIRCHost(NSString *prefix);

NSArray *SeparateIRCNickAndHost(NSString *prefix);

@interface IRCObject : LineObject
	{
		NSString *nick;
		BOOL connected;
		
		NSString *userName;
		NSString *realName;
		NSString *password;

		NSString *errorString;
	}
- initWithNickname: (NSString *)nickname
   withUserName: (NSString *)user withRealName: (NSString *)realName
   withPassword: (NSString *)password;

- setNickname: (NSString *)nickname;
- (NSString *)nickname;

- setUserName: (NSString *)user;
- (NSString *)userName;

- setRealName: (NSString *)realName;
- (NSString *)realName;

- setPassword: (NSString *)password;
- (NSString *)password;

- (NSString *)errorString;

- (BOOL)connected;

- (NSString *)nick;

// IRC Operations
- changeNick: (NSString *)aNick;

- quitWithMessage: (NSString *)aMessage;

- partChannel: (NSString *)channel withMessage: (NSString *)aMessage;

- joinChannel: (NSString *)channel withPassword: (NSString *)aPassword;

- sendCTCPReply: (NSString *)aCTCP withArgument: (NSString *)args
   to: (NSString *)aPerson;

- sendCTCPRequest: (NSString *)aCTCP withArgument: (NSString *)args
   to: (NSString *)aPerson;

- sendMessage: (NSString *)message to: (NSString *)receiver;

- sendNotice: (NSString *)message to: (NSString *)receiver;

- sendAction: (NSString *)anAction to: (NSString *)receiver;

- becomeOperatorWithName: (NSString *)aName withPassword: (NSString *)pass;

- requestNamesOnChannel: (NSString *)aChannel fromServer: (NSString *)aServer;

- requestMOTDOnServer: (NSString *)aServer;

- requestSizeInformationFromServer: (NSString *)aServer
                      andForwardTo: (NSString *)anotherServer;

- requestVersionOfServer: (NSString *)aServer;

- requestServerStats: (NSString *)aServer for: (NSString *)query;

- requestServerLink: (NSString *)aLink from: (NSString *)aServer;

- requestTimeOnServer: (NSString *)aServer;

- requestServerToConnect: (NSString *)aServer to: (NSString *)connectServer
                  onPort: (NSString *)aPort;

- requestTraceOnServer: (NSString *)aServer;

- requestAdministratorOnServer: (NSString *)aServer;

- requestInfoOnServer: (NSString *)aServer;

- requestServiceListWithMask: (NSString *)aMask ofType: (NSString *)type;

- requestServerRehash;

- requestServerShutdown;

- requestServerRestart;

- requestUserInfoOnServer: (NSString *)aServer;

- areUsersOn: (NSString *)userList;

- sendWallops: (NSString *)message;

- queryService: (NSString *)aService withMessage: (NSString *)aMessage;

- listWho: (NSString *)aMask onlyOperators: (BOOL)operators;

- whois: (NSString *)aPerson onServer: (NSString *)aServer;

- whowas: (NSString *)aPerson onServer: (NSString *)aServer
                     withNumberEntries: (NSString *)aNumber;

- kill: (NSString *)aPerson withComment: (NSString *)aComment;

- setTopicForChannel: (NSString *)aChannel to: (NSString *)aTopic;

- setMode: (NSString *)aMode on: (NSString *)anObject 
                     withParams: (NSArray *)list;
					 
- listChannel: (NSString *)aChannel onServer: (NSString *)aServer;

- invite: (NSString *)aPerson to: (NSString *)aChannel;

- kick: (NSString *)aPerson offOf: (NSString *)aChannel for: (NSString *)reason;

- setAwayWithMessage: (NSString *)message;

// Callbacks
- registeredWithServer;

- couldNotRegister: (NSString *)reason;

- CTCPRequestReceived: (NSString *)aCTCP 
   withArgument: (NSString *)argument from: (NSString *)aPerson;

- CTCPReplyReceived: (NSString *)aCTCP
   withArgument: (NSString *)argument from: (NSString *)aPerson;

- errorReceived: (NSString *)anError;

- wallopsReceived: (NSString *)message from: (NSString *)sender;

- userKicked: (NSString *)aPerson outOf: (NSString *)aChannel 
         for: (NSString *)reason from: (NSString *)kicker;
		 
- invitedTo: (NSString *)aChannel from: (NSString *)inviter;

- modeChanged: (NSString *)mode on: (NSString *)anObject 
   withParams: (NSArray *)paramList from: (NSString *)aPerson;
   
- numericCommandReceived: (NSString *)command withParams: (NSArray *)paramList 
                      from: (NSString *)sender;

- nickChangedTo: (NSString *)newName from: (NSString *)aPerson;

- channelJoined: (NSString *)channel from: (NSString *)joiner;

- channelParted: (NSString *)channel withMessage: (NSString *)aMessage
             from: (NSString *)parter;

- quitIRCWithMessage: (NSString *)aMessage from: (NSString *)quitter;

- topicChangedTo: (NSString *)aTopic in: (NSString *)channel
              from: (NSString *)aPerson;

- messageReceived: (NSString *)aMessage to: (NSString *)to
               from: (NSString *)sender;

- noticeReceived: (NSString *)aMessage to: (NSString *)to
              from: (NSString *)sender;

- actionReceived: (NSString *)anAction to: (NSString *)to
              from: (NSString *)sender;

- newNickNeededWhileRegistering;

// Low-Level   
- lineReceived: (NSData *)aLine;

- writeString: (NSString *)format, ...;
@end

/* The DCC support's ideas(and much of the code) came mostly from
 * Juan Pablo Mendoza <jpablo@gnome.org>
 */

@interface IRCObject (DCCSupport)
- DCCSendRequestReceived: (NSDictionary *)fileInfo from: (NSString *)sender;
- DCCInitiated: aConnection;
- DCCStatusChanged: (NSString *)aStatus forObject: aConnection;
- DCCReceivedData: (NSData *)data forObject: aConnection;
- DCCDone: aConnection;
- DCCNeedsMoreData: aConnection;
- sendDCCSendRequest: (NSDictionary *)info to: (NSString *)person;
@end

extern NSString *DCCStatusTransferring;
extern NSString *DCCStatusError;
extern NSString *DCCStatusTimeout;
extern NSString *DCCStatusDone;
extern NSString *DCCStatusConnecting;
extern NSString *DCCStatusAborted;

extern NSString *DCCInfoFileName; //NSString
extern NSString *DCCInfoFileSize; //NSNumber 
extern NSString *DCCInfoPort;     //NSNumber
extern NSString *DCCInfoHost;     //NSString

@interface DCCObject : NSObject < NetObject >
	{
		int transferredBytes;
		IRCObject *delegate;
		NSString *status;
		NSDictionary *info;
		NSDictionary *userInfo;
		id transport;
	}
- initWithDelegate: (IRCObject *)aDelegate withInfo: (NSDictionary *)info
   withUserInfo: (NSDictionary *)userInfo;

- (int)transferredBytes;
- (void)abortConnection;

- (void)connectionLost;
- connectionEstablished: aTransport;
- dataReceived: (NSData *)data;
- transport;

- (NSString *)status;
- (NSDictionary *)info;
- (NSDictionary *)userInfo;
@end

@interface DCCReceiveObject : DCCObject
	{
		id connection;
	}
- initWithReceiveOfFile: (NSDictionary *)info 
    withDelegate: (IRCObject *)aDelegate
	withTimeout: (int)seconds
	withUserInfo: (NSDictionary *)userInfo;
@end

@interface DCCSendObject : DCCObject
	{
		TCPPort *port;
		NSTimer *timeout;
		int blockSize;
		int confirmedBytes;
		NSMutableData *receivedData;
		NSMutableData *dataToWrite;
		BOOL noMoreData;
	}
- initWithSendOfFile: (NSString *)name
    withSize: (NSNumber *)size
    withDelegate: (IRCObject *)aDelegate
    withTimeout: (int)seconds
    withBlockSize: (int)numBytes
	withUserInfo: (NSDictionary *)userInfo;
- writeData: (NSData *)someData;
@end

/* Below is all the numeric commands that you can receive as listed
 * in the RFC
 */

extern NSString *RPL_WELCOME;
extern NSString *RPL_YOURHOST;
extern NSString *RPL_CREATED;
extern NSString *RPL_MYINFO;
extern NSString *RPL_BOUNCE;
extern NSString *RPL_USERHOST;
extern NSString *RPL_ISON;
extern NSString *RPL_AWAY;
extern NSString *RPL_UNAWAY;
extern NSString *RPL_NOWAWAY;
extern NSString *RPL_WHOISUSER;
extern NSString *RPL_WHOISSERVER;
extern NSString *RPL_WHOISOPERATOR;
extern NSString *RPL_WHOISIDLE;
extern NSString *RPL_ENDOFWHOIS;
extern NSString *RPL_WHOISCHANNELS;
extern NSString *RPL_WHOWASUSER;
extern NSString *RPL_ENDOFWHOWAS;
extern NSString *RPL_LISTSTART;
extern NSString *RPL_LIST;
extern NSString *RPL_LISTEND;
extern NSString *RPL_UNIQOPIS;
extern NSString *RPL_CHANNELMODEIS;
extern NSString *RPL_NOTOPIC;
extern NSString *RPL_TOPIC;
extern NSString *RPL_INVITING;
extern NSString *RPL_SUMMONING;
extern NSString *RPL_INVITELIST;
extern NSString *RPL_ENDOFINVITELIST;
extern NSString *RPL_EXCEPTLIST;
extern NSString *RPL_ENDOFEXCEPTLIST;
extern NSString *RPL_VERSION;
extern NSString *RPL_WHOREPLY;
extern NSString *RPL_ENDOFWHO;
extern NSString *RPL_NAMREPLY;
extern NSString *RPL_ENDOFNAMES;
extern NSString *RPL_LINKS;
extern NSString *RPL_ENDOFLINKS;
extern NSString *RPL_BANLIST;
extern NSString *RPL_ENDOFBANLIST;
extern NSString *RPL_INFO;
extern NSString *RPL_ENDOFINFO;
extern NSString *RPL_MOTDSTART;
extern NSString *RPL_MOTD;
extern NSString *RPL_ENDOFMOTD;
extern NSString *RPL_YOUREOPER;
extern NSString *RPL_REHASHING;
extern NSString *RPL_YOURESERVICE;
extern NSString *RPL_TIME;
extern NSString *RPL_USERSSTART;
extern NSString *RPL_USERS;
extern NSString *RPL_ENDOFUSERS;
extern NSString *RPL_NOUSERS;
extern NSString *RPL_TRACELINK;
extern NSString *RPL_TRACECONNECTING;
extern NSString *RPL_TRACEHANDSHAKE;
extern NSString *RPL_TRACEUNKNOWN;
extern NSString *RPL_TRACEOPERATOR;
extern NSString *RPL_TRACEUSER;
extern NSString *RPL_TRACESERVER;
extern NSString *RPL_TRACESERVICE;
extern NSString *RPL_TRACENEWTYPE;
extern NSString *RPL_TRACECLASS;
extern NSString *RPL_TRACERECONNECT;
extern NSString *RPL_TRACELOG;
extern NSString *RPL_TRACEEND;
extern NSString *RPL_STATSLINKINFO;
extern NSString *RPL_STATSCOMMANDS;
extern NSString *RPL_ENDOFSTATS;
extern NSString *RPL_STATSUPTIME;
extern NSString *RPL_STATSOLINE;
extern NSString *RPL_UMODEIS;
extern NSString *RPL_SERVLIST;
extern NSString *RPL_SERVLISTEND;
extern NSString *RPL_LUSERCLIENT;
extern NSString *RPL_LUSEROP;
extern NSString *RPL_LUSERUNKNOWN;
extern NSString *RPL_LUSERCHANNELS;
extern NSString *RPL_LUSERME;
extern NSString *RPL_ADMINME;
extern NSString *RPL_ADMINLOC1;
extern NSString *RPL_ADMINLOC2;
extern NSString *RPL_ADMINEMAIL;
extern NSString *RPL_TRYAGAIN;
extern NSString *ERR_NOSUCHNICK;
extern NSString *ERR_NOSUCHSERVER;
extern NSString *ERR_NOSUCHCHANNEL;
extern NSString *ERR_CANNOTSENDTOCHAN;
extern NSString *ERR_TOOMANYCHANNELS;
extern NSString *ERR_WASNOSUCHNICK;
extern NSString *ERR_TOOMANYTARGETS;
extern NSString *ERR_NOSUCHSERVICE;
extern NSString *ERR_NOORIGIN;
extern NSString *ERR_NORECIPIENT;
extern NSString *ERR_NOTEXTTOSEND;
extern NSString *ERR_NOTOPLEVEL;
extern NSString *ERR_WILDTOPLEVEL;
extern NSString *ERR_BADMASK;
extern NSString *ERR_UNKNOWNCOMMAND;
extern NSString *ERR_NOMOTD;
extern NSString *ERR_NOADMININFO;
extern NSString *ERR_FILEERROR;
extern NSString *ERR_NONICKNAMEGIVEN;
extern NSString *ERR_ERRONEUSNICKNAME;
extern NSString *ERR_NICKNAMEINUSE;
extern NSString *ERR_NICKCOLLISION;
extern NSString *ERR_UNAVAILRESOURCE;
extern NSString *ERR_USERNOTINCHANNEL;
extern NSString *ERR_NOTONCHANNEL;
extern NSString *ERR_USERONCHANNEL;
extern NSString *ERR_NOLOGIN;
extern NSString *ERR_SUMMONDISABLED;
extern NSString *ERR_USERSDISABLED;
extern NSString *ERR_NOTREGISTERED;
extern NSString *ERR_NEEDMOREPARAMS;
extern NSString *ERR_ALREADYREGISTRED;
extern NSString *ERR_NOPERMFORHOST;
extern NSString *ERR_PASSWDMISMATCH;
extern NSString *ERR_YOUREBANNEDCREEP;
extern NSString *ERR_YOUWILLBEBANNED;
extern NSString *ERR_KEYSET;
extern NSString *ERR_CHANNELISFULL;
extern NSString *ERR_UNKNOWNMODE;
extern NSString *ERR_INVITEONLYCHAN;
extern NSString *ERR_BANNEDFROMCHAN;
extern NSString *ERR_BADCHANNELKEY;
extern NSString *ERR_BADCHANMASK;
extern NSString *ERR_NOCHANMODES;
extern NSString *ERR_BANLISTFULL;
extern NSString *ERR_NOPRIVILEGES;
extern NSString *ERR_CHANOPRIVSNEEDED;
extern NSString *ERR_CANTKILLSERVER;
extern NSString *ERR_RESTRICTED;
extern NSString *ERR_UNIQOPPRIVSNEEDED;
extern NSString *ERR_NOOPERHOST;
extern NSString *ERR_UMODEUNKNOWNFLAG;
extern NSString *ERR_USERSDONTMATCH;
extern NSString *RPL_SERVICEINFO;
extern NSString *RPL_ENDOFSERVICES;
extern NSString *RPL_SERVICE;
extern NSString *RPL_NONE;
extern NSString *RPL_WHOISCHANOP;
extern NSString *RPL_KILLDONE;
extern NSString *RPL_CLOSING;
extern NSString *RPL_CLOSEEND;
extern NSString *RPL_INFOSTART;
extern NSString *RPL_MYPORTIS;
extern NSString *RPL_STATSCLINE;
extern NSString *RPL_STATSNLINE;
extern NSString *RPL_STATSILINE;
extern NSString *RPL_STATSKLINE;
extern NSString *RPL_STATSQLINE;
extern NSString *RPL_STATSYLINE;
extern NSString *RPL_STATSVLINE;
extern NSString *RPL_STATSLLINE;
extern NSString *RPL_STATSHLINE;
extern NSString *RPL_STATSSLINE;
extern NSString *RPL_STATSPING;
extern NSString *RPL_STATSBLINE;
extern NSString *RPL_STATSDLINE;
extern NSString *ERR_NOSERVICEHOST;

