#import "Foundation/NSString.h"

#import "IRCClient.h"
#import "TerminalView/TerminalView.h"

static NSMapTable *selTable=NULL;

@implementation IRCClient 
+(void)initialize
{
    selTable = NSCreateMapTable(NSObjectMapKeyCallBacks, 
                                NSIntMapValueCallBacks, 10);

    NSMapInsert(selTable, RPL_NAMREPLY, @selector(setNicks::));
    NSMapInsert(selTable, RPL_ENDOFNAMES, @selector(setNicks::));

}
- numericCommandReceived: (NSString *)command 
              withParams: (NSArray *)paramList
                    from: (NSString *)sender
{
    SEL method;

    method=NSMapGet(selTable, command);
    if ([_delegate respondsToSelector: method])
    {
        [_delegate performSelector: method withObject: paramList 
                                           withObject: command];
    }
    
    return self;

};
- sendAction: (NSString *)anAction to: (NSString *)receiver
{
    [super sendAction: anAction to: receiver];
    [self actionReceived: anAction to: receiver from: nick];

    return self;
};
- actionReceived: (NSString *)anAction to: (NSString *)to
              from: (NSString *)sender
{
    NSLog(@"an action was received %@", anAction);
    NSLog(@"an action was received from %@", sender);
    NSLog(@"an action was received to %@", to);

    [_delegate actionReceived: anAction
                           to: to
                         from: sender];
    return self;
};
- registeredWithServer
{
    [_delegate finishedConnecting];
	return self;
}

- sendMessage: (NSString *)aMessage to: (NSString *)person
{
    [super sendMessage: aMessage to: person];
    [self messageReceived: aMessage to: person from: nick];

    return self;
}

- channelJoined: (NSString *)channel from: (NSString *)joiner
{
	[_delegate channelJoined:channel from:joiner];
	return self;
}

- channelParted: (NSString *)channel withMessage: (NSString *)aMessage
	   from: (NSString *)parter
{
	[_delegate channelParted:channel withMessage:aMessage from:parter];
	return self;
}
- nickChangedTo: (NSString *)new from: (NSString *)old
{
	[_delegate nickChangedTo: new from: old];
	return self;
}
- setDelegate:(id)aDelegate
{
	_delegate=aDelegate;
	return self;
}

- delegate
{
	return _delegate;
}
- versionRequestReceived: (NSString *)query from: (NSString *)aPerson
{
	[self sendVersionReplyTo: ExtractIRCNick(aPerson) name: @"Charla.app"
	 version: @"ExtremeBeta" environment: @"GNUstep CVS"];
	return self;
}
- pingRequestReceived: (NSString *)argument from: (NSString *)aPerson
{
	[self sendPingReplyTo: ExtractIRCNick(aPerson) withArgument: argument];
	return self;
}
- messageReceived: (NSString *)aMessage to: (NSString *)to
			 from: (NSString *)sender
{
    [_delegate messageReceived:aMessage to:to from:sender];
	return self;
}
@end
