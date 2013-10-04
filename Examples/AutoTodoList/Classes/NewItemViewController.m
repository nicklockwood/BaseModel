//
//  NewItemViewController.m
//  TodoList4
//
//  Created by Nick Lockwood on 15/04/2010.
//  Copyright 2010 Charcoal Design. All rights reserved.
//

#import "NewItemViewController.h"
#import "TodoList.h"
#import "TodoItem.h"

@interface NewItemViewController()		@property TodoItem *item;		@end

@implementation NewItemViewController

#pragma mark - UITextViewDelegate methods

- (void)textViewDidChange:(UITextView *)tV	{

													//	either update the existing TodoItem (setLabel:)
	_item ? [_item setLabel:tV.text]		//	or create a new TodoItem and add to list (addObject:)
			: [TodoList.sharedInstance.items addObject:_item = [TodoItem instanceWithLabel:tV.text]];

	[_item save]; 	//save the item
}

#pragma mark -
#pragma mark Cleanup


@end
