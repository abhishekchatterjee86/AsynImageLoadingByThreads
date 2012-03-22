//
//  RootViewController.h
//  AsynImageLoadingByThreads
//
//  Created by Abhishek chatterjee on 15/03/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource>
{
    NSCache                 *imageCache;
	NSMutableArray          *photoNames;
    NSMutableArray          *photoURLs;
    NSMutableDictionary     *cachedImages;
    UIActivityIndicatorView *spinner;
    UILabel                 *loadingLabel;
}

@end
