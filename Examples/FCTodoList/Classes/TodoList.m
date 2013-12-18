//
//  TodoList.m
//  TodoListExample
//
//  Created by Nick Lockwood on 28/07/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "TodoList.h"
#import "TodoItem.h"


@implementation TodoList

+ (BMFileFormat)saveFormat
{
    //this is the format that will be used to save the model
    return BMFileFormatFastCoding;
}

- (void)setUp
{
    self.items = [NSMutableArray array];
}

@end
