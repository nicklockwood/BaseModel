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

+ (instancetype)instanceWithLabel:(NSString *)label
{
	TodoItem *instance = [self instance];
    instance.label = label;
    return instance;
}

- (BOOL)save
{
	//save the todolist
	return [[TodoList sharedInstance] save];
}

//NOTE: no need to implement the NSCoding methods
//BaseModel does that for us automagically

@end
