//
//  TodoList1ViewController.m
//  TodoList1
//
//  Created by Nick Lockwood on 08/04/2010.
//  Copyright AKQA 2010. All rights reserved.
//

#import "TodoListViewController.h"
#import "NewItemViewController.h"
#import "TodoItem.h"
#import "TodoList.h"


@implementation TodoListViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.navigationItem.leftBarButtonItem = self.editButtonItem;
	self.clearsSelectionOnViewWillAppear = YES;
}

- (void)viewWillAppear:(__unused BOOL)animated
{
	[super viewWillAppear:YES];
	[self.tableView reloadData];
}

- (IBAction)createNewItem
{	
	UIViewController *viewController = [[NewItemViewController alloc] init];
	[self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark -
#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{	
	TodoItem *item = [TodoList sharedInstance].items[indexPath.row];
	item.checked = !item.checked;
	[item save];
	
	[tableView reloadData];
}

- (UITableViewCellEditingStyle)tableView:(__unused UITableView *)tableView editingStyleForRowAtIndexPath:(__unused NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(__unused UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	[[TodoList sharedInstance].items removeObjectAtIndex:indexPath.row];
	[[TodoList sharedInstance] save];
	
	[tableView reloadData];
}

#pragma mark -
#pragma mark UITableViewDataSource methods

- (NSInteger)tableView:(__unused UITableView *)table numberOfRowsInSection:(__unused NSInteger)section
{	
	return [[TodoList sharedInstance].items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{	
	static NSString *cellType = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellType];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellType];
	}
	
	TodoItem *item = [TodoList sharedInstance].items[indexPath.row];
	cell.textLabel.text = item.label;
	cell.accessoryType = item.checked? UITableViewCellAccessoryCheckmark: UITableViewCellAccessoryNone;
	return cell;
}

@end
