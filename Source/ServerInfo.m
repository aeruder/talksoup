#import "ServerInfo.h"

@implementation ServerInfo
-init
{
    if([super init] != nil)
    {
        serverName=nil;
        port=0;
        channel=0;
        password=0;
        nick=0;
        comment=0;
    }

    return self;
};
-(NSString *)getName
{
    return serverName;
}
-(void)print
{
    NSLog(@"The server name es %@", serverName);
    NSLog(@"The port %i", port);
    NSLog(@"The channel %@", channel);
    NSLog(@"The password %@", password);
    NSLog(@"The nick %@", nick);
    NSLog(@"The comment %@", comment);
}
-(void)dealloc
{
    
    if(password)   [password release];
    if(nick)       [nick release];
    if(comment)    [comment release];
}
-(void)setComment:(char *)aComment
{
    if(aComment)
        {
            comment=[NSString stringWithCString: aComment];
        }
}
-(void)setNick:(char *)aNick
{
    if(aNick)
        {
            nick=[NSString stringWithCString: aNick];
        }
}
-(void)setPassword:(char *)aPassword
{
    if(aPassword)
        {
            password=[NSString stringWithCString: aPassword];
        }
}
-(void)setChannel:(char *)name
{
    if(name)
        {
            channel=[NSString stringWithCString: name];
        }
}
-(void)setServerName:(char *)name
{
    if(name)
        {
            serverName=[NSString stringWithCString: name];
        }
}
-(void)setPort:(int)aPort
{
    if(aPort!=0)
        port=aPort;
    else
        port=6667;
}
-(NSString *)getNick
{
    return [NSString stringWithString:nick];
};
-(NSString *)getPassword
{
    return [NSString stringWithString:password];
};
-(NSString *)getChannel
{
    return [NSString stringWithString:channel];
};
-(int)getPort
{
    return port;
};
@end


@implementation GroupInfo
-(id)init
{
    if([super init])
    {
        name=nil;
        servers=[[NSMutableArray alloc] init];
    }
    
    return self;
}
-(void)setName:(NSString *)aName
{
    name=[aName retain];
};
-(NSString *)getName
{
    return name;
};
-(NSMutableArray *)getServers
{
    return servers;
};
@end
