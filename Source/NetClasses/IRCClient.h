#import <Foundation/NSMapTable.h>

#import "IRCObject.h"

@interface IRCClient : IRCObject
{
	id _delegate;
}
- setDelegate:(id)aDelegate;
- delegate;
- messageReceived: (NSString *)aMessage to: (NSString *)to
			 from: (NSString *)sender;
- numericCommandReceived: (NSString *)command
              withParams: (NSArray *)paramList
                    from: (NSString *)sender;
- sendMessage: (NSString *)aMessage to: (NSString *)person;
- sendAction: (NSString *)anAction to: (NSString *)receiver;
- registeredWithServer;
- channelJoined: (NSString *)channel from: (NSString *)joiner;
- channelParted: (NSString *)channel withMessage: (NSString *)aMessage
                 from: (NSString *)parter;
@end
