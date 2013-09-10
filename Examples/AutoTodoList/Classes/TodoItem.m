//
//  TodoItem.m
//  TodoList
//
//  Created by Nick Lockwood on 28/07/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "TodoItem.h"
#import "TodoList.h"


@implementation TodoItem

@synthesize label;
@synthesize checked;

+ (instancetype)instanceWithLabel:(NSString *)label
{
    return [self instanceWithObject:label];
}

- (void)setWithString:(NSString *)string
{
	self.label = string;
}

- (void)save
{
	//save the todolist
	[[TodoList sharedInstance] save];
}

//note: we've not implemented the NSCoding methods
//the AutoCoding library takes care of this for us

@end
