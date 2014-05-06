//
//  levelGen.h
//  sunSmash
//
//  Created by Benjamin Chirlin on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "CCTouchDispatcher.h"
// Importing Chipmunk headers
#import "chipmunk.h"
#import "mainMenu.h"

#import "planetoid.h"

@interface levelGen : CCLayer {
    int level; // level number
    int planets; // total number of planets at start
    
    cpSpace *space;
    Planetoid *sun;
    CCSprite *reticle;
    
	CGPoint fireU;
	CGPoint fireV;
    
    BOOL fired; // 0 - no shots fired, 1 - shot has been fired
    BOOL firing; // shot in motion?
    
    BOOL win;
    NSArray *scoreScreen;
    BOOL scoring;
    
    int bullets;

    CCSprite *prevSprite;
	
	NSMutableArray *_planets;
	NSMutableArray *_bullets;
    NSMutableArray *pathed;
}

@property int level;
@property int planets;
@property BOOL scoring;
@property BOOL win;

// returns a Scene with corresponding parameters
+(id) scene: (int)num;
-(id) init;
-(id) initLevel: (int) n;
-(void) draw;
-(void) reboot;

-(void) destroyBullet : (id)sender data:(void*) data;
-(void) logBullet:(id)sender;

-(void) resetBullet:(CCSprite*)check;
-(BOOL) removePlanetoid:(CCSprite*) target;

-(void) genSpace;
-(void) genPlanets;
-(void) genSun: (NSString*) img loc: (cpVect) s radius: (float) r;

-(int) compScore;
-(void) setupScoreScreen;
-(void) addScoreScreen: (int) score;
-(void) removeScoreScreen;

-(void) backMenu: (CCNode*)menu;
-(void) replay: (CCNode*)menu;
-(void) nextLevel: (CCNode*)menu;
-(void) haltUpdate;

@end
