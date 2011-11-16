//
//  TodoList.h
//  TodoListExample
//
//  Created by Nick Lockwood on 28/07/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "BaseModel.h"


@interface TodoList : BaseModel

@property (nonatomic, retain) NSMutableArray *items;

//override the generic sharedInstance
//with a concrete type, this makes it
//easier to use without casting
+ (TodoList *)sharedInstance;

@end
