#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>


@interface ServerInfo : NSObject
{
    NSString *serverName;
    int port;
    NSString *channel;
    NSString *password;
    NSString *nick;
    NSString *comment;
}
-init;
-(void)dealloc;
-(void)setComment:(char *)aComment;
-(void)setNick:(char *)aNick;
-(void)setPassword:(char *)aPassword;
-(void)setChannel:(char *)name;
-(void)setServerName:(char *)name;
-(void)setPort:(int)aPort;
-(void)print;
-(NSString *)getNick;
-(NSString *)getPassword;
-(NSString *)getChannel;
-(int)getPort;
-(NSString *)getName;
@end

@interface GroupInfo : NSObject
{
    NSString *name;
    NSMutableArray *servers;
}
-(id)init;
-(void)setName:(NSString *)aName;
-(NSString *)getName;
-(NSMutableArray *)getServers;
@end
