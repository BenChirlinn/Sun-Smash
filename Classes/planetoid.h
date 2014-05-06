//
//  test.h
//  sunSmash
//
//  Created by Benjamin Chirlin on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

// Importing Chipmunk headers
#import "chipmunk.h"

@interface Planetoid : NSObject {
    CCSprite* sprite;
    CCSpriteBatchNode* lives;
    cpBody* body;
    cpShape* shape;
    cpSpace* space;
    
    int myid;
    int dim;
}

@property int myid;
@property int dim;

-(id)init;
-(id)initSun: (cpVect) sun;

-(CCSprite*) sprite;
-(cpShape*) shape;
-(cpSpace*) space;

-(void) setSprite: (CCSprite*) input;
-(void) setSpace: (cpSpace*) input;

// sprite file path, tracking array for release, velocity path vector from u to v
-(CCSprite*) addToSpace : (NSString*)spriteImg : (CCLayer*) layer : (NSMutableArray*)tracker source: (cpVect) source velocity: (cpVect) vel radius: (float) radius dim: (int) d mass: (float) mass type: (int) type;
-(CCSprite*) genSun : (NSString*)spriteImg : (CCLayer*) layer : (NSMutableArray*)tracker source: (cpVect) source radius: (float) radius;

@end 
