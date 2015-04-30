//
//  NPCManager.h
//  MiniRPG
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@class GameLayer;

@interface NPCManager : NSObject
@property(nonatomic, strong) NSMutableDictionary *npcs;

- (id) initWithGameLayer:(GameLayer *)layer;
- (void) interactWithNPCNamed:(NSString *) npcName;
- (void)loadNPCsForTileMap:(CCTMXTiledMap *) map named:(NSString *) name;
@end
