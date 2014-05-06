//
//  test.m
//  sunSmash
//
//  Created by Benjamin Chirlin on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "planetoid.h"

static cpFloat gravityStrength = 5.0e6f;
static cpFloat sunX;
static cpFloat sunY;

static void
planetGravityVelocityFunc(cpBody *body, cpVect gravity, cpFloat damping, cpFloat dt)
{
	// Gravitational acceleration is proportional to the inverse square of
	// distance, and directed toward the origin. The central planet is assumed
	// to be massive enough that it affects the satellites but not vice versa.
	
	// Sun position
	cpVect disp = cpv(sunX, sunY);
	
	// Point mass position
	cpVect p = body->p;
	
	// Point mass relative to Sun
	p = cpvsub(p, disp);
	
	cpFloat sqdist = cpvlengthsq(p);
	cpVect g = cpvmult(p, -gravityStrength / (sqdist * cpfsqrt(sqdist)));
	
	cpBodyUpdateVelocity(body, g, damping, dt);
}

@implementation Planetoid

@synthesize myid;
@synthesize dim;

- (id) init {
    // Default Constructor
    if( (self=[super init]) ) {
    }
    return self; 
}

- (id) initSun: (cpVect) sun {
    // Constructor
    if( (self=[super init]) ) {
        sunX = sun.x;
        sunY = sun.y;    }
    return self; 
}

- (CCSprite*) sprite {
    return sprite;
}

- (cpShape*) shape {
    return shape;
}

- (void) setSprite: (CCSprite*) input {
    [sprite autorelease];
    sprite = [input retain];
}

-(void) setSpace: (cpSpace*) input {
    [sprite autorelease];
    space = input;
}

-(cpSpace*) space {
    return space;
}

-(CCSprite*) addToSpace : (NSString*)spriteImg : (CCLayer*) layer : (NSMutableArray*)tracker source: (cpVect) source velocity: (cpVect) vel radius: (float) radius dim: (int) d mass: (float) mass type: (int) type;
{
    // Add a sprite
    // If dim != 0 then we have a planetoid so we add BatchNode for damage states
    if (d != 0) {
        lives = [CCSpriteBatchNode batchNodeWithFile:spriteImg];
        [layer addChild:lives z:-2];
        
        sprite = [CCSprite spriteWithBatchNode:lives rect:CGRectMake(0, 0, d, d)];
        dim = d;
        [lives addChild:sprite z:-2];
        
        // Start sprite slowly rotating
        int randD = (arc4random() % 10) + 10;
        id rot = [CCRotateBy actionWithDuration:randD angle:-360];
        id rep = [CCRepeatForever actionWithAction:rot];
        
        [sprite runAction:rep];
    }
    // Else its a bullet so we animate the pulsing
    else {
        lives = [CCSpriteBatchNode batchNodeWithFile:spriteImg];
        [layer addChild:lives z:-2];
        
        sprite = [CCSprite spriteWithBatchNode:lives rect:CGRectMake(0, 0, 13, 13)];
        dim = d;
        [lives addChild:sprite z:-2];
    }
    
    [tracker addObject:sprite];
    
    //NSLog(@"Fire Vector: (%f, %f)", vel.x, vel.y);
    
    sprite.position = ccp(source.x, source.y);
    
    // Setup body
    body = cpBodyNew(mass, INFINITY);
    body->p = source;
    body->velocity_func = planetGravityVelocityFunc;
    
    // Firing velocity
    body->v = vel;
    
    cpSpaceAddBody(space, body);
    body->space = space;
    
    shape = cpCircleShapeNew(body, radius, cpvzero);
    shape->data = sprite;
    shape->life = 60.0f;
    shape->collision_type = type;
    cpSpaceAddShape(space, shape);
    
    return sprite;
}

-(CCSprite*) genSun : (NSString*)spriteImg : (CCLayer*) layer : (NSMutableArray*)tracker source: (cpVect) source radius: (float) radius;
{
    // Add sprite
    sprite = [CCSprite spriteWithFile: spriteImg];
    [tracker addObject:sprite];
    
    sprite.position = ccp(source.x, source.y);
    sunX = source.x;
    sunY = source.y;
    [layer addChild:sprite z:-1];
    
    // Setup body
    body = cpBodyNew(INFINITY, INFINITY);
    body->p = source;
    body->velocity_func = planetGravityVelocityFunc;
    
    // Firing velocity
    body->v = cpv(0,0);
    
    //cpSpaceAddBody(space, body);
    
    shape = cpCircleShapeNew(body, radius, cpvzero);
    shape->data = sprite;
    shape->collision_type = 1;
    cpSpaceAddShape(space, shape);
    
    // Start sprite slowly rotating
    int randD = (arc4random() % 10) + 30;
    id rot = [CCRotateBy actionWithDuration:randD angle:-360];
    id rep = [CCRepeatForever actionWithAction:rot];
    
    [sprite runAction:rep];
    
    return sprite;
}

- (void) dealloc { 
    [sprite stopAllActions];
    
    CCNode *layer = [sprite parent];
    
    [layer removeChild:sprite cleanup:YES];
    
    // Note, chipmunk doesn't support destruction of bodies while it's iterating over the collisions
    
    cpSpaceRemoveBody(space, shape->body);
    cpSpaceRemoveShape(space, shape);
    cpBodyFree(shape->body);
    cpShapeFree(shape);
    
    shape->data = nil;
    shape->body = nil;
    shape = nil;
    sprite = nil;
    
    [super dealloc]; 
}

@end
