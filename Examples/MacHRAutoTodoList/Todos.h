
//  TodoItem.h - TodoList
//  Created by Alex Gray on 11/26/12. -	Part of BaseModel by Nick Lockwood.

#import "BaseModel.h"


@interface          TodoItem : BaseModel
@property (readonly) NSColor * color;
@property           NSString * label;
@property           NSNumber * priority;
@property               BOOL   checked;
@end

@interface          TodoList : BaseModel
@property     NSMutableArray * items;

- (TodoItem*) newTodo;
- (TodoItem*) copyTodo:(TodoItem*)todo;

@end
