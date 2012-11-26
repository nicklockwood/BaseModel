//
//  TodoItem.h
//  TodoList
//
//  Created by Nick Lockwood on 28/07/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//



#import "BaseModel.h"

@interface TodoItem : BaseModel

@property (nonatomic, strong)  NSString  *label;
@property (nonatomic, assign)  BOOL       checked;
@property (nonatomic, strong)  NSNumber  *priority;

//@property (readonly) NSDate *created;
@property (readonly) NSColor  *color;

//+ (instancetype)instanceWithLabel:(NSString *)label;

@end

@interface TodoList : BaseModel
@property (nonatomic, retain) NSMutableArray *items;
@end