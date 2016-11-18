//
//  ViewController.h
//  project16623
//
//  Created by geetesh dubey on 11/17/16.
//  Copyright © 2016 geetesh dubey. All rights reserved.
//

#import "MyVideoCamera.h"
#import <UIKit/UIKit.h>
#import <opencv2/videoio/cap_ios.h>
#import <opencv2/opencv.hpp>

using namespace cv;

@interface ViewController : UIViewController<MyVideoCameraDelegate>

@end

