#include <Foundation/NSString.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSUserDefaults.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSScroller.h>
#include <AppKit/NSTabView.h>
#include <AppKit/NSTabViewItem.h>
#include <AppKit/GSHbox.h>
#include <AppKit/GSVbox.h>
#include <AppKit/PSOperators.h>

#import "IRCWindow.h"
#import "ChannelView.h"
#import "CommandView.h"
#import "NetTCP.h"

@implementation IRCWindowController 
/* This method is called by IRCClient to tell about the incomming list of nicks
 * of all the users that are connected to the channel;
 * inputs:  An array with information of all the users nicks (list)
 *          The numericCommand that triggered this method (command)
 * outputs: nothing
 */
-(void)setNicks:(NSArray *)list :(NSString *)command
{
    NSString *test;
    
    test= [NSString stringWithFormat: @"%@" arguments: list];
    NSLog(@"%@", list);
    NSLog(@"%@", test);
}
/* Gets the confirmation that the nick has been aproved to be changed from the
 * IRCClient
 * inputs: The new Nick (newName)
 *         The old Nick (aPerson)
 * outputs: nothing
 */
-(void)nickChangedTo: (NSString *)newName from: (NSString *)aPerson
{
	if ([newName caseInsensitiveCompare: [server nick]] == NSOrderedSame)
    {
        [nickView setStringValue: newName];
        [nickView sizeToFit];
    }
}
/* called when the window finished loading
 * inputs: NONE
 * outputs: NONE
 */
- (void)windowDidLoad
{
    [win setInitialFirstResponder: commandLineView];
    [win makeFirstResponder: commandLineView];
}
/* callet for instance initialization
 * inputs: NONE
 * outputs: NONE
 */
-init
{
    GSVbox *vbox;
    GSHbox *hbox;
  
    server = nil;
  
    connectedChannels =[NSMutableDictionary dictionaryWithCapacity:5];
    [connectedChannels retain];

    win=[[NSWindow alloc] initWithContentRect: NSMakeRect (100, 100, 600, 400) 
                                    styleMask: NSClosableWindowMask  | 
                                               NSTitledWindowMask    | 
                                               NSResizableWindowMask |
                                               NSMiniaturizableWindowMask 
                                      backing: NSBackingStoreRetained
                                        defer: YES];

    [win setMinSize:NSMakeSize (300, 225)];
    [win setDelegate:self];
    if (!(self =[super initWithWindow:win]))
    {
        return nil;
    };

    [win setTitle:@"Not Connected to any Server"];

    vbox=[[GSVbox alloc] init];
    [vbox setDefaultMinYMargin:0];
    [vbox setAutoresizingMask: NSViewWidthSizable |
                               NSViewHeightSizable];
    [vbox setBorder:0];
  
    hbox=[[GSHbox alloc] init];
    [hbox setDefaultMinXMargin: 2];
    [hbox setAutoresizesSubviews: YES];
    [hbox setAutoresizingMask: NSViewWidthSizable |
                               NSViewHeightSizable];
    [hbox setBorder: 2];

    commandLineView=[CommandView alloc];
    [commandLineView initWithFrame: NSMakeRect(20,3,25,20)];
    [commandLineView setAutoresizingMask: NSViewWidthSizable];
    [commandLineView setTarget:self];
    [commandLineView setAction:@selector(commandReceived:)];
    
    nickView=[[NSTextField alloc] init];
    [nickView setStringValue: @"- - -"];
    [nickView setEditable: NO];
    [nickView setDrawsBackground: NO];
    [nickView setBordered:NO];
    [nickView setBezeled:NO];
    [nickView setSelectable:NO];
    [nickView sizeToFit];
    [nickView setAutoresizingMask:NSViewHeightSizable|NSViewWidthSizable];
      
    [hbox addView: nickView enablingXResizing:NO];
    [hbox addView: commandLineView enablingXResizing:YES];

    [vbox addView: hbox enablingYResizing: NO];
    
    RELEASE(hbox);
    
    tabView=[[NSTabView alloc] init];
    [tabView setAutoresizingMask: NSViewWidthSizable |
                                  NSViewHeightSizable];
    serverTab=[[ChannelView alloc] initWithLabel:@"Server"];
    [tabView addTabViewItem: serverTab];

    [vbox addView: tabView enablingYResizing: YES];

    [win setContentView: vbox];
    [win setInitialFirstResponder: commandLineView];
    [win makeFirstResponder: commandLineView];

    RELEASE (vbox);
    //RELEASE (win);
    
    return self;
}
/* Called to make a requiest to the server that a connection must be 
 * established.
 * inputs: host,port,timeout,nicknames,user,real name and password
 * outputs: none
 */
-(void)connectToServer:(NSString *)host 
                onPort:(int)aPort 
           withTimeout:(int)timeout 
         withNicknames:(NSArray *)nicknames 
          withUserName:(NSString *)user 
          withRealName:(NSString *)realName 
          withPassword:(NSString *)password
{
    server = [[IRCClient alloc]
	   initWithNicknames: nicknames
	        withUserName: user
	        withRealName: realName
	        withPassword: password];
	
    [[TCPSystem sharedInstance] connectNetObjectInBackground: server 
                                                      toHost: host
                                                      onPort: aPort
                                                 withTimeout: timeout];
    [server setDelegate: self];
};
/* Makes a request to join a channel to the server checking first that the
 * channel or dialog does not exist already, and if it does, it ignores the 
 * request and puts a message on the server window.
 * inputs: channel and password
 * outputs: NONE
 */
-(void)joinChannel:(NSString *)channel 
      withPassword:(NSString *)aPassword
{
    NSString *channelName;

    if (server != nil)
    {
        channelName = [channel uppercaseString];
        if ([connectedChannels objectForKey:channelName] == nil)
	    {
            /* only the server request must be left here */
	        [server joinChannel: [NSString stringWithString:channel]
                   withPassword: aPassword];
        }
    }
};
/* called by the IRCClient.m when an action (/action /me) has arrived
 * inputs: the action message, to which channel/dialog and from whom 
 * outputs: NONE
 */
-(void)actionReceived: (NSString *)anAction 
                   to: (NSString *)to
                 from: (NSString *)sender
{
    id channelView;
    id terminalView;

    NSLog (@"El Mensaje es %@ para %@ de %@ ", anAction, to, sender);
    NSLog (@"Se busca %@ en el Diccionario",[to uppercaseString]);;

    channelView =[connectedChannels objectForKey:[to uppercaseString]];
    terminalView = [channelView getTerminalView];
  
    if (channelView == nil)
        NSLog (@" ERROR chanelView == nil");
    else
    {
        if([terminalView class] == [TerminalView class])
            [terminalView writeAction: anAction from:ExtractIRCNick(sender)];
        else
            NSLog(@"Unable to get TerminalView instance");
    }
};
/* called by the IRCClient.m when a message (/say) has arrived
 * inputs: the message, to which channel/dialog and from whom 
 * outputs: NONE
 */
-(void)messageReceived:(NSString *)aMessage 
              to:(NSString *)to 
            from:(NSString *)sender
{
  id channelView;

  NSLog (@"El Mensaje es %@ para %@ de %@ ", aMessage, to, sender);
  NSLog (@"Se busca %@ en el Diccionario",[to uppercaseString]);;

  channelView =[connectedChannels objectForKey:[to uppercaseString]];

  if (channelView == nil)
    NSLog (@" ERROR chanelView == nil");
  else
    {
        [channelView writeMessage: aMessage from:sender];
    }
};
/* called when someone hits enter on the commandView
 * inputs: the CommandView instance
 * outputs: NONE
 */
-(void)commandReceived:(id)sender
{
    NSString *channelName;
    NSString *command;
    NSString *commandLowered;
   
    channelName=[[tabView selectedTabViewItem] getChannelName];
    command=[sender stringValue];
    commandLowered=[command lowercaseString];
    
    [commandLineView setStringValue:@""]; 
    [win makeFirstResponder:sender];
    [sender selectText:nil];

    if([commandLowered hasPrefix:@"/nick "])
    {
        command = [command substringFromIndex:6];
        [server changeNick: command];  // nickChangeTo:from: will catch the actual name change
        return;
    }
    
    if([commandLowered hasPrefix:@"/join "])
    {
        command=[command substringFromIndex:6];
        [self joinChannel: command withPassword: nil]; 
        return;
    }
   
    if(channelName == nil)
    {
        // this means that the tab was the server tab
        return;
    }
    if([commandLowered hasPrefix:@"/me "] ||
       [commandLowered hasPrefix:@"/action "])
    {
        if([commandLowered hasPrefix:@"/me "])
            command=[command substringFromIndex:4];
        else
            command=[command substringFromIndex:8];
        [server sendAction:command to:channelName];
        
        return;
    };
    [server sendMessage: command to:channelName];
};
/* called by IRCObject when someone enters a channel the user is at
 * input: the channel name and the nick of the person who joined the channel
 * output: NONE
 */
-(void)channelJoined: (NSString *)channel from: (NSString *)joiner
{
	id channelView;
	id terminalView;
	id string;
	int index;
	
	NSString *nick, *host;
	
	nick = ExtractIRCNick (joiner);
	host = ExtractIRCHost (joiner);

    if ([nick caseInsensitiveCompare: [server nick]] == NSOrderedSame)
    {

// 	Do anything to locate the index, meanwhile total + 1
	    index = [tabView numberOfTabViewItems];
	    NSLog(@"El indice del tab nuevo va a ser %d", index);

	    channelView = [[[ChannelView alloc] initWithLabel:channel] autorelease];
	    [channelView setChannelName:channel ];
	    [tabView insertTabViewItem:channelView atIndex:index];
	    
	    [connectedChannels setObject: channelView 
			       forKey: [channel uppercaseString]];
	    
	    [tabView setNeedsDisplay: YES];
	    [tabView selectTabViewItemAtIndex:index];
	
    }
        
	string = [NSMutableString stringWithString: nick];
	[string appendString:@" ("];
	[string appendString:host];
	[string appendString:@") has joined "];
	[string appendString:channel];
		
	
	channelView = [connectedChannels objectForKey:[channel uppercaseString]];
	terminalView = [channelView getTerminalView];
	
	if (channelView == nil)
		NSLog (@" ERROR chanelView == nil");
	else
	{
		if([terminalView class] == [TerminalView class])
			[terminalView writeNSString: string];
		else
			NSLog(@"Unable to get TerminalView instance");
	}


};
/* called by IRCClient when someone lives a channel the user is at
 * input: the channel he was in, the message he left, and who parted
 * output: NONE
 */
-(void)channelParted: (NSString *)channel withMessage: (NSString *)aMessage
	            from: (NSString *)parter
{
	id channelView;
	id terminalView;
	id string;
	NSString *nick, *host;
	
	nick = ExtractIRCNick (parter);
	host = ExtractIRCHost (parter);
	
	string = [NSMutableString stringWithString:nick];
	[string appendString:@" ("];
	[string appendString:host];
	[string appendString:@") has left "];
	[string appendString:channel];
	[string appendString:@" ("];
	[string appendString:aMessage];
	[string appendString:@")"];

	channelView =[connectedChannels objectForKey:[channel uppercaseString]];
	terminalView = [channelView getTerminalView];
	
	if (channelView == nil)
		NSLog (@" ERROR chanelView == nil");
	else
	{
		if([terminalView isKindOf: [TerminalView class]])
			[terminalView writeNSString: string];
		else
			NSLog(@"Unable to get TerminalView instance");
		
	}

};
- (void)finishedConnecting
{
    [nickView setStringValue: [server nick]];
    [nickView sizeToFit];
	
	[win setTitle: [NSString stringWithFormat: @"Connected to %@", [[server transport] address]]];
}
- (BOOL)windowShouldClose:(id)sender
{
    NSLog(@"Window is closing");
    [server quitWithMessage:@""];
    [self release];

    return YES;
};
@end
