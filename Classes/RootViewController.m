//
//  RootViewController.m
//  AsynImageLoadingByThreads
//
//  Created by Abhishek chatterjee on 15/03/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "RootViewController.h"
#import "CallbacksTableViewCell.h"
#import "UIImage+Resize.h"
#import <objc/runtime.h>

static char * const kIndexPathAssociationKey = "IndexPath";

@interface RootViewController(Private)

- (void)showLoadingIndicators;
- (void)hideLoadingIndicators;
- (void)beginLoadingFlickrData;
- (void)synchronousLoadFlickrData;

@end

NSString *const LoadingPlaceholder = @"Loading";

const NSInteger NumberOfImages = 30;

NSString *const FlickrAPIKey = @"9af6feb4c889be27497a4e4217ba3b72";

@implementation RootViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) 
    {
        imageCache = [[NSCache alloc] init];
        [imageCache setName:@"JKImageCache"];
        photoURLs = [[NSMutableArray alloc] init];
        photoNames = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)dealloc 
{
    [imageCache release];
    [photoNames release];
    [photoURLs release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    if (!imageCache) 
    {
        imageCache = [[NSCache alloc] init];
        [imageCache setName:@"JKImageCache"];
    }
    if (!photoURLs) 
    {
        photoURLs = [[NSMutableArray alloc] init];
    }
    if (!photoNames) 
    {
        photoNames = [[NSMutableArray alloc] init];
    }
    
    // Register for our table view cell notification
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(tableViewCellIsPreparingForReuse:)
												 name:kJKPrepareForReuseNotification
											   object:nil];
    
    self.tableView.rowHeight = 95.0f;
    [self showLoadingIndicators];
    [self beginLoadingFlickrData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [photoNames count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    CallbacksTableViewCell *cell = (CallbacksTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[CallbacksTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSString *imageFilename = [photoNames objectAtIndex:[indexPath row]];
    NSURL *imagePath        = [photoURLs objectAtIndex:[indexPath row]];
    
	UIImage *image = [imageCache objectForKey:imageFilename];
	
    if (image) 
    {
		[[cell imageView] setImage:image];
	} 
    /*else 
    {    
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
		
		// Get the height of the cell to pass to the block.
		CGFloat cellHeight = [tableView rowHeight];
		
		// Now, we can’t cancel a block once it begins, so we’ll use associated objects and compare
		// index paths to see if we should continue once we have a resized image.
		objc_setAssociatedObject(cell,
								 kIndexPathAssociationKey,
								 indexPath,
								 OBJC_ASSOCIATION_RETAIN);
		
		dispatch_async(queue, ^{

			UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:imagePath]];
			
			UIImage *resizedImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill
																bounds:CGSizeMake(cellHeight, cellHeight)
												  interpolationQuality:kCGInterpolationHigh];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				NSIndexPath *cellIndexPath =
				(NSIndexPath *)objc_getAssociatedObject(cell, kIndexPathAssociationKey);
				
				if ([indexPath isEqual:cellIndexPath]) {
					[[cell imageView] setImage:resizedImage];
				}
				
				[imageCache setObject:resizedImage forKey:imageFilename];
			});
		});
	}*/
    else
    {
        objc_setAssociatedObject(cell,
                                 kIndexPathAssociationKey,
                                 indexPath,
                                 OBJC_ASSOCIATION_RETAIN);
        [NSThread detachNewThreadSelector:@selector(loadImage:) toTarget:self withObject:indexPath];
    }
    cell.textLabel.text = imageFilename;
    return cell;
}

-(void)loadImage:(NSIndexPath*)indexPath
{
    NSLog(@"Is main Thread:%d",[NSThread isMainThread]);   
    CGFloat cellHeight = [self.tableView rowHeight];
    NSURL *imagePath   = [photoURLs objectAtIndex:indexPath.row];
    UIImage *image     = [UIImage imageWithData:[NSData dataWithContentsOfURL:imagePath]];
    
    UIImage *resizedImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill
                                                        bounds:CGSizeMake(cellHeight, cellHeight)
                                          interpolationQuality:kCGInterpolationHigh];
    
    NSDictionary *context = [[NSDictionary alloc]initWithObjectsAndKeys:indexPath,@"IndexPath",resizedImage,@"CellImage", nil];
    [self performSelectorOnMainThread:@selector(setTableViewCellImage:) withObject:context waitUntilDone:YES];
    [context release];
}

-(void)setTableViewCellImage:(NSDictionary*)context
{
    NSLog(@"Is main Thread!:%d",[NSThread isMainThread]);
    UIImage *image = [context objectForKey:@"CellImage"];
    NSIndexPath *indexPath = [context objectForKey:@"IndexPath"];
    NSString *imageFilename = [photoNames objectAtIndex:[indexPath row]];
    CallbacksTableViewCell *cell = (CallbacksTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    NSIndexPath *cellIndexPath = (NSIndexPath *)objc_getAssociatedObject(cell, kIndexPathAssociationKey);
    if ([indexPath isEqual:cellIndexPath]) 
    {
        [[cell imageView] setImage:image];
    }
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];
    [imageCache setObject:image forKey:imageFilename];
}

#pragma mark -
#pragma mark Loading Progress UI

- (void)showLoadingIndicators
{
    if (!spinner) {
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [spinner startAnimating];
        
        loadingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        loadingLabel.font = [UIFont systemFontOfSize:20];
        loadingLabel.textColor = [UIColor grayColor];
        loadingLabel.text = @"Loading...";
        [loadingLabel sizeToFit];
        
        static CGFloat bufferWidth = 8.0;
        
        CGFloat totalWidth = spinner.frame.size.width + bufferWidth + loadingLabel.frame.size.width;
        
        CGRect spinnerFrame = spinner.frame;
        spinnerFrame.origin.x = (self.tableView.bounds.size.width - totalWidth) / 2.0;
        spinnerFrame.origin.y = (self.tableView.bounds.size.height - spinnerFrame.size.height) / 2.0;
        spinner.frame = spinnerFrame;
        [self.tableView addSubview:spinner];
        
        CGRect labelFrame = loadingLabel.frame;
        labelFrame.origin.x = (self.tableView.bounds.size.width - totalWidth) / 2.0 + spinnerFrame.size.width + bufferWidth;
        labelFrame.origin.y = (self.tableView.bounds.size.height - labelFrame.size.height) / 2.0;
        loadingLabel.frame = labelFrame;
        [self.tableView addSubview:loadingLabel];
    }
}

- (void)hideLoadingIndicators
{
    if (spinner) {
        [spinner stopAnimating];
        [spinner removeFromSuperview];
        [spinner release];
        spinner = nil;
        
        [loadingLabel removeFromSuperview];
        [loadingLabel release];
        loadingLabel = nil;
    }
}

- (void)beginLoadingFlickrData
{
    [NSThread detachNewThreadSelector:@selector(synchronousLoadFlickrData) toTarget:self withObject:nil];
	//[self synchronousLoadFlickrData];
}

/*- (void)synchronousLoadFlickrData
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        NSString *urlString = [NSString stringWithFormat:@"http://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=%@&tags=%@&per_page=%d&format=json&nojsoncallback=1", FlickrAPIKey, @"stanfordtree", NumberOfImages];
        NSURL *url = [NSURL URLWithString:urlString];
        
        // Get the contents of the URL as a string, and parse the JSON into Foundation objects.
        NSString *jsonString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
        NSDictionary *results = [jsonString JSONValue];  
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *photos = [[results objectForKey:@"photos"] objectForKey:@"photo"];
            for (NSDictionary *photo in photos) {
                // Get the title for each photo
                NSString *title = [photo objectForKey:@"title"];
                [photoNames addObject:(title.length > 0 ? title : @"Untitled")];
                
                // Construct the URL for each photo.
                NSString *photoURLString = [NSString stringWithFormat:@"http://farm%@.static.flickr.com/%@/%@_%@_s.jpg", [photo objectForKey:@"farm"], [photo objectForKey:@"server"], [photo objectForKey:@"id"], [photo objectForKey:@"secret"]];
                [photoURLs addObject:[NSURL URLWithString:photoURLString]];
            }    
            
            [self hideLoadingIndicators];
            [self.tableView reloadData];
            [self.tableView flashScrollIndicators];
        });
    });
}*/

- (void)synchronousLoadFlickrData
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    
    // Construct a Flickr API request.
    NSString *urlString = [NSString stringWithFormat:@"http://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=%@&tags=%@&per_page=%d&format=json&nojsoncallback=1", FlickrAPIKey, @"stanfordtree", NumberOfImages];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // Get the contents of the URL as a string, and parse the JSON into Foundation objects.
    NSString *jsonString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    NSDictionary *results = [jsonString JSONValue];    
    
    [self performSelectorOnMainThread:@selector(didFinishLoadingFlickrDataWithResults:) withObject:results waitUntilDone:NO];
	[pool drain];
}

- (void)didFinishLoadingFlickrDataWithResults:(NSDictionary *)results
{
    NSArray *photos = [[results objectForKey:@"photos"] objectForKey:@"photo"];
    for (NSDictionary *photo in photos) 
    {
        // Get the title for each photo
        NSString *title = [photo objectForKey:@"title"];
        [photoNames addObject:(title.length > 0 ? title : @"Untitled")];
        
        // Construct the URL for each photo.
        NSString *photoURLString = [NSString stringWithFormat:@"http://farm%@.static.flickr.com/%@/%@_%@_s.jpg", [photo objectForKey:@"farm"], [photo objectForKey:@"server"], [photo objectForKey:@"id"], [photo objectForKey:@"secret"]];
        [photoURLs addObject:[NSURL URLWithString:photoURLString]];
    }    
    
    [self hideLoadingIndicators];
    [self.tableView reloadData];
    [self.tableView flashScrollIndicators];
}

#pragma mark -

- (void)tableViewCellIsPreparingForReuse:(NSNotification *)notification
{
	if ([[notification object] isKindOfClass:[CallbacksTableViewCell class]]) {
		CallbacksTableViewCell *cell = (CallbacksTableViewCell *)[notification object];
		
		objc_setAssociatedObject(cell,
								 kIndexPathAssociationKey,
								 nil,
								 OBJC_ASSOCIATION_RETAIN);
		
		[[cell imageView] setImage:nil];
	}
}

@end

