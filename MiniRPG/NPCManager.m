//
//  NPCManager.m
//  MiniRPG
//

// 1
#import "cocos2d.h"
#import "NPCManager.h"
#import "LuaObjCBridge.h"
#import "GameLayer.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>

// 2
@interface NPCManager()
@property(nonatomic) lua_State *luaState;
@property(nonatomic, strong) GameLayer *gameLayer;
@end

@implementation NPCManager

- (id)initWithGameLayer:(GameLayer *)layer
{
    if (self = [super init]) {
        self.npcs = [@{} mutableCopy];
        self.gameLayer = layer;

        // 3
        self.luaState = lua_objc_init();

        // 4
        lua_pushstring(self.luaState, "game");
        lua_objc_pushid(self.luaState, self.gameLayer);
        lua_settable(self.luaState, LUA_GLOBALSINDEX);
    }
    return self;
}

/**
 * Loads all NPCs on a given tilemap.  Initializeds empty lua table to hold
 * NPCs in lua.
 */
- (void)loadNPCsForTileMap:(CCTMXTiledMap *) map named:(NSString *) name
{
    // Reset NPCs for the current map
    [self runLua:@"npcs = {}"];

    [self loadLuaFilesForMap:map layerName:@"npc" named:name];
}

/**
 * For a given layer on a tilemap, this method tries to load files of the format:
 * [MapName]-[NPCName].lua
 *
 * Lua files are responsible for initializing themselves and adding themselves to the
 * global npcs table.
 *
 * All lua objects in the npcs table must have an interact method that will be invoked when
 * the player interacts with them.
 */
- (void) loadLuaFilesForMap:(CCTMXTiledMap *) map layerName:(NSString *) layerName named:(NSString *) name
{
    NSFileManager *manager = [NSFileManager defaultManager];
    CCTMXLayer *layer = [map layerNamed:layerName];

    // Enumerate the layer
    for(int i = 0; i < layer.layerSize.width; i++)
    {
        for(int j = 0; j < layer.layerSize.height; j++)
        {
            CGPoint tileCoord = CGPointMake(j,i);
            int tileGid = [layer tileGIDAt:tileCoord];

            // Check to see if there is an NPC at this location
            if(tileGid)
            {
                // Fetch the name of the NPC
                NSDictionary *properties = [map propertiesForGID:tileGid];
                NSString *npcName = [properties objectForKey:@"name"];

                // Resolve the path to the NPCs lua file
                NSString *roomName = [name stringByReplacingOccurrencesOfString:@".tmx" withString:@""];
                NSString *npcFilename = [NSString stringWithFormat:@"%@-%@.lua",roomName,npcName];
                NSString *path = [[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"npc"] stringByAppendingPathComponent:npcFilename];

                // If the NPC has a lua file, initialize it.
                if([manager fileExistsAtPath:path])
                {
                    NSError *error = nil;
                    NSString *lua = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
                    if(!error)
                    {
                        [self runLua:lua];
                    }
                    else
                    {
                        NSLog(@"Error loading NPC: %@",error);
                    }
                }
                else
                {
                    NSLog(@"Warning: No lua file for npc %@ at path %@",npcName,path);
                }
            }
        }
    }

}

- (void) interactWithNPCNamed:(NSString *) npcName
{
    NSString *luaCode = [NSString stringWithFormat:@"npcs[\"%@\"]:interact()",npcName];
    [self runLua:luaCode];
}

/**
 * Executes lua code and prints results to the console.
 */
- (void) runLua:(NSString *) luaCode
{
    char buffer[256] = {0};
    int out_pipe[2];
    int saved_stdout;

    // Set up pipes for output
    saved_stdout = dup(STDOUT_FILENO);
    pipe(out_pipe);
    fcntl(out_pipe[0], F_SETFL, O_NONBLOCK);
    dup2(out_pipe[1], STDOUT_FILENO);
    close(out_pipe[1]);

    // Run Lua
    luaL_loadstring(self.luaState, [luaCode UTF8String]);
    int status = lua_pcall(self.luaState, 0, LUA_MULTRET, 0);

    // Report errors if there are any
    report_errors(self.luaState, status);

    // Grab the output
    read(out_pipe[0], buffer, 255);
    dup2(saved_stdout, STDOUT_FILENO);

    // Print the output to the log
    NSString *output = [NSString stringWithFormat:@"%@\r\n", [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding]];
    if(output && [output length] > 2)
    {
        NSLog(@"Lua: %@",output);
    }
}

/**
 * Reports lua errors to the console
 */
void report_errors(lua_State *L, int status)
{
    if ( status!=0 ) {
        const char *error = lua_tostring(L, -1);
        NSLog(@"Lua Error: %s",error);
        lua_pop(L, 1); // remove error message
    }
}

@end