//
//  TodoItem.h
//  TodoList
//
//  Created by Nick Lockwood on 28/07/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "BaseModel.h"


@interface TodoItem : BaseModel

@property  NSString * label;
@property  	   BOOL   checked;

+ (instancetype) instanceWithLabel:(NSString*)label;

@end
