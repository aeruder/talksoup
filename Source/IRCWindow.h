#import <AppKit/NSWindowController.h>
#import <AppKit/NSTabView.h>
#import <AppKit/NSTextField.h>

#import "NetClasses/IRCClient.h"

@class CommandView;

@interface IRCWindowController : NSWindowController
{
	IRCClient *server;        /* This is the Netclasses child that handles 
                                 the connection to a single server */
	NSMutableDictionary *connectedChannels; /* This is adictionary of 
                                               ChannelName for TabViewItem */
	NSTabView *tabView;       /* Main tabView holding all channels, server, and 
                                 conversations within the server */
    NSTabViewItem *serverTab; /* represent the server tab, information that 
                                 does not belong on any channel goes to this
                                 tab */
	CommandView *commandLineView; /* This is where the user types stuff */
	NSTextField *nickView;        /* this displays the nick you have on the
                                     server */
    NSWindow *win;            /* Window that holds everything together */
}
-(id)init;
-(void)windowDidLoad;
-(void)connectToServer:(NSString *)host
				onPort: (int)aPort
		   withTimeout: (int)timeout 
		 withNicknames: (NSArray *)nicknames
		  withUserName: (NSString *)user  
		  withRealName: (NSString *)realName
		  withPassword: (NSString *)password;
-(void)joinChannel: (NSString *)channel 
      withPassword: (NSString *)aPassword;
-(void)messageReceived: (NSString *)aMessage 
                    to: (NSString *)to
                  from: (NSString *)sender;
-(void)commandReceived:(id)sender;
-(void)channelJoined: (NSString *)channel 
                from: (NSString *)joiner;
-(void)channelParted: (NSString *)channel 
         withMessage: (NSString *)aMessage 
                from: (NSString *)parter;
-(void)nickChangedTo: (NSString *)newName from: (NSString *)aPerson;
-(void)finishedConnecting;

/*
 * Numeric Command Method callbacks
 * */
-(void)setNicks:(NSArray *)list :(NSString *)command;

@end
