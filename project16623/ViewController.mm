//
//  ViewController.m
//  project16623
//
//  Created by geetesh dubey on 11/17/16.
//  Copyright © 2016 geetesh dubey. All rights reserved.
//


#import "ViewController.h"
#include "MOSSE.h"
//#import "UIImage+OpenCV.h"

// converting ratio between bounding box on overlay and opencv
const float convertRatio = 1.066666667;
const float convertBiasY = 160;

//cv::Mat objectPoints;
std::vector<cv::Point3f> objectPoints;
cv::Mat cameraMatrix;
cv::Vec4f distCoeff;
cv::Rect trackerRect;
NSTimeInterval frameInterval;
std::string status_string;
MOSSE tracker;
float x,y,z;

@interface ViewController () {
    // UI elements
    __weak IBOutlet UIImageView *imageView;
    __weak IBOutlet UIButton *startButton;
    __weak IBOutlet UIButton *stopButton;
    __weak IBOutlet UIView *drag1;
    __weak IBOutlet UIView *drag2;
    __weak IBOutlet UILabel *fpsText;
    __weak IBOutlet UILabel *sizeText;
    CAShapeLayer * rectOverlay;
    
    // opencv video stream
    MyVideoCamera* _videoCamera;
    
    // Tracker
//    MOSSE tracker;
    bool needInitialize;
    bool startTrack;
    bool initAll;
    bool success_status;
    
    // Timer
    NSDate *lastFrameTime;
    
}

- (IBAction)actionStart:(id)sender;
- (IBAction)actionStop:(id)sender;


@property (nonatomic, retain) MyVideoCamera* videoCamera;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // set up opencv video camera
    self.videoCamera = [[MyVideoCamera alloc] initWithParentView:imageView];
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.grayscaleMode = YES;
    self.videoCamera.delegate = self;
    
    // set up bounding box
    [self addOverlayRect];
    [self addGestureRecognizersForViews];
    
    // set up button
    [self->startButton setEnabled:YES];
    [self->stopButton setEnabled:NO];
    
    // set up tracker
    needInitialize = true;
    startTrack = false;
    initAll = true;
    success_status = false;
//    objectPoints = cv::Mat::zeros(35, 3, CV_32F);
    cameraMatrix = cv::Mat::zeros(3, 3, CV_32F);
    distCoeff.zeros();
    for(int v = 0; v<7 ; v++)
    {
        for(int u = 0; u<5 ; u++)
        {
//            objectPoints.at<float>(u*v,0) = u*0.27;
//            objectPoints.at<float>(u*v,1) = v*0.27;
//            objectPoints.at<float>(u*v,2) = 0.0;
            cv::Point3f p;
//            float s = 0.02571;
            float s = 0.02717;
            p.x = u*s;
            p.y = v*s;
            p.z = 0;
            objectPoints.push_back(p);
        }
    }
    double fx=1165.304443, fy=1160.893677, x0=645.923828, y0=359.284729;
    //note camera is rotated for us so swap fx fy
    cameraMatrix.at<float>(0,0) = fy;
    cameraMatrix.at<float>(0,2) = y0;
    cameraMatrix.at<float>(1,1) = fx;
    cameraMatrix.at<float>(1,2) = x0;
    cameraMatrix.at<float>(2,2) = 1.0;
    
    //k1=0.1373341233, k2=-0.3064711094, p1=0.0006870319, p2=0.0039324202
    distCoeff(0) = 0.1373341233;
    distCoeff(1) = 0.3064711094;
    distCoeff(3) = 0.0006870319;
    distCoeff(2) = 0.0039324202;
    
    
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    [self refreshRect];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // start live stream!
    [self.videoCamera start];
    
    // refresh bounding box
    [self refreshRect];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:(BOOL)animated];
    // stop live stream!
    [self.videoCamera stop];
}

// main method to process the image and do tracking
- (void)processImage:(Mat&)image {
    
    // log incoming frame rate
    NSDate *curFrameTime = [NSDate date];
//    NSTimeInterval frameInterval = [curFrameTime timeIntervalSinceDate:lastFrameTime];
//    NSLog(@"frameInterval = %f", frameInterval);
//    lastFrameTime = curFrameTime;
    //    cv::circle(image, cv::Point(100,100), 30, cv::Scalar(0,255,255));
    //    cv::flip(image, image, 3);
    //    imageView.image = [UIImage imageWithCVMat:image];
    std::vector<cv::Point2f> corners;
//    cv::Rect trackerRect;
    if(!startTrack)
    {
        std::printf("\nINIT");
        if(findChess(image,corners))
        {
            success_status = true;
            startTrack = true;
            initAll = false;
            needInitialize = true;
            float padding  = std::max(fabs(corners[0].x-corners[1].x),fabs(corners[0].y-corners[1].y))+5;//30.0;
            float u = corners[0].x - padding;
            float v = corners[0].y - padding;
            float w = corners[35-1].x - corners[0].x + 2*padding;
            float h = corners[35-1].y - corners[0].y + 2*padding;
            if(w<0 || h<0 || u<0 || v<0 || (u+w)>=image.cols || (v+h)>=image.rows)
                return;
            trackerRect.x = (int)u;
            trackerRect.y = (int)v;
            trackerRect.width = (int)w;
            trackerRect.height = (int)h;
            std::printf("\nImage Size: %d %d",image.cols,image.rows);
            std::printf("\nUVWH %f %f %f %f",u,v,w,h);
            std::printf("\nTrackerRect %d %d %d %d",trackerRect.x,trackerRect.y,trackerRect.width,trackerRect.height);
//            std::cout<<"\nCorners:\n"<<corners;
//            std::cout<<"\nObjPts:\n"<<objectPoints;
        }
    }
    
    cv::Point loc;
    if(startTrack){
        if(needInitialize){
            // set up tracker
            //            cv::Rect rect = [self getRect];
            //            tracker.init(image, rect);
            tracker.init(image, trackerRect);
            needInitialize = false;
            // visualize
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                cv::Rect rect = tracker.getRect();
                sizeText.text = [NSString stringWithFormat:@"W:%d H:%d",rect.width,rect.height ];
            }];
        } else {
            tracker.update(image);
        }
        static int visCount = 0;
        static int failCount = 0;
//        if(visCount%10)
        {
            cv::Mat chessImage;
            if(tracker.getRect().width<0 || tracker.getRect().height<0 || tracker.getRect().x<0 || tracker.getRect().y<0 || (tracker.getRect().x+tracker.getRect().width)>=image.cols || (tracker.getRect().y+tracker.getRect().height)>=image.rows)
                return;
            chessImage = image(tracker.getRect());
            if(findChess(chessImage,corners))
            {
                success_status = true;
                failCount = 0;
            }
            else
            {
                success_status = false;
                initAll = true;
                failCount++;
                if(failCount >= 4)
                {
                    startTrack = false;
                }
            }
        }
//        else
        {
            frameInterval = [curFrameTime timeIntervalSinceDate:lastFrameTime];
            lastFrameTime = curFrameTime;
        }
        // log processing frame rate
        NSDate *finishTime = [NSDate date];
        NSTimeInterval methodExecution = [finishTime timeIntervalSinceDate:curFrameTime];
        //NSLog(@"execution = %f", methodExecution);
        //        static int visCount = 0;
        if(visCount>15){
            std::string s;
            if(!initAll)
            {
                if(success_status)
                {
                    s = "Board Detected";
                }
                else
                {
                    s = "Board Detection Failed";
                }
            }
            else
            {
                s = "Re-Initializing Board Detection";
            }
            
            status_string = s;
        
            visCount = 0;
        } else {visCount++;}
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//            fpsText.text = [NSString stringWithFormat:@"fps: %d %s \t%.1f %.1f %.1f", (int)(1/methodExecution) , status_string.c_str(),x,y,z];
//            std::printf("\nfps:%03d\tX:%-2.2f\tY:%-2.2f\tZ:%-2.2f", (int)(1/methodExecution),x,y,z);
            fpsText.text = [NSString stringWithFormat:@"fps:%03d\tX:%-+2.2f\tY:%-+2.2f\tZ:%-+2.2f", (int)(1/methodExecution),x,y,z];
            //                fpsText.text = [NSString stringWithFormat:@"fps: %d %s", (int)(1/frameInterval) , s.c_str()];
        }];

        
        // visualize bounding box
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self moveRect: tracker.getRect()];
        }];
    }
}

bool findChess(cv::Mat& chessImage, std::vector<cv::Point2f>& corners)
{
    //    cv::Size S(5,7);//5,7
    bool success = cv::findChessboardCorners(chessImage, cv::Size(5,7), corners,CALIB_CB_ADAPTIVE_THRESH+CALIB_CB_NORMALIZE_IMAGE+CALIB_CB_FAST_CHECK);
    if(!success){
        //        std::printf("\nSUCCESS");
        //    else
        std::printf("\nFAILED TO FIND BOARD");
    }
    else
    {
        cv::cornerSubPix(chessImage, corners, cv::Size(11, 11), cv::Size(-1, -1),cv::TermCriteria(CV_TERMCRIT_EPS + CV_TERMCRIT_ITER, 30, 0.1));
        std::vector<cv::Point2f> corners2 = corners;
        for(int i =0 ;i<corners2.size();i++)
        {
            corners2[i].x += tracker.getRect().x;
            corners2[i].y += tracker.getRect().y;
        }
        findPose(corners2);
    }
    return success;
}

void findPose(std::vector<cv::Point2f>& corners)
{
    cv::Mat rvec(3,3,CV_32F);
    cv::Mat tvec(3,1,CV_32F);
//    cv::solvePnPRansac(objectPoints, corners, cameraMatrix, distCoeff, rvec, tvec);
    cv::solvePnP(objectPoints, corners, cameraMatrix, distCoeff, rvec, tvec);
//    std::cout<<"\nRvec: "<<rvec<<"\n Tvec: "<<tvec;
    cv::transpose(tvec, tvec);
    cv::Rodrigues(rvec, rvec);
    cv::Mat u,l;
    cv::Vec3d rpy =cv::RQDecomp3x3(rvec,u,l);
    x = tvec.at<double>(0,0);
    y = tvec.at<double>(0,1);
    z = tvec.at<double>(0,2);
    std::cout<<"\n"<<tvec<<"\t"<<rpy;
}

// when the start button is pressed
- (IBAction)actionStart:(id)sender {
    [self->drag1 setHidden:YES];
    [self->drag2 setHidden:YES];
    [self->startButton setEnabled:NO];
    [self->stopButton setEnabled:YES];
    
    startTrack = true;
    needInitialize = true;
}

// when the stop button is pressed
- (IBAction)actionStop:(id)sender {
    [self->drag1 setHidden:NO];
    [self->drag2 setHidden:NO];
    [self->startButton setEnabled:YES];
    [self->stopButton setEnabled:NO];
    
    startTrack = false;
    needInitialize = true;
    
    [[NSOperationQueue mainQueue] waitUntilAllOperationsAreFinished];
    [self refreshRect];
}

// get bounding box size into opencv
-(cv::Rect) getRect{
    int x = drag1.center.x/convertRatio;
    int y = drag1.center.y/convertRatio + convertBiasY;
    int width = (drag2.center.x - drag1.center.x)/convertRatio;
    int height = (drag2.center.y - drag1.center.y)/convertRatio;
    return cv::Rect(x,y,width,height);
}

// move bounding box based on its updated location from opencv
-(void)moveRect:(cv::Rect)rect {
    
    UIBezierPath * rectPath=[UIBezierPath bezierPath];
    
    //Rectangle coordinates
    CGPoint view1Center=CGPointMake(rect.x*convertRatio, (rect.y-convertBiasY)*convertRatio);
    CGPoint view4Center=CGPointMake(view1Center.x+rect.width*convertRatio, view1Center.y+rect.height*convertRatio);
    CGPoint view2Center=CGPointMake(view4Center.x, view1Center.y);
    CGPoint view3Center=CGPointMake(view1Center.x, view4Center.y);
    
    //Rectangle drawing
    [rectPath moveToPoint:view1Center];
    [rectPath addLineToPoint:view2Center];
    [rectPath addLineToPoint:view4Center];
    [rectPath addLineToPoint:view3Center];
    [rectPath addLineToPoint:view1Center];
    
    self->rectOverlay.path=rectPath.CGPath;
}

// add layer which bounding box is drawed on
-(void)addOverlayRect{
    self->rectOverlay=[CAShapeLayer layer];
    self->rectOverlay.fillColor=[UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.1].CGColor;
    self->rectOverlay.lineWidth = 2.0f;
    self->rectOverlay.lineCap = kCALineCapRound;
    self->rectOverlay.strokeColor = [[UIColor redColor] CGColor];
    [self.view.layer addSublayer:self->rectOverlay];
}

// initialize the interactive drager
-(void)addGestureRecognizersForViews{
    UIPanGestureRecognizer * pan=[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panEventHandler:)];
    [self->drag1 addGestureRecognizer:pan];
    pan=[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panEventHandler:)];
    [self->drag2 addGestureRecognizer:pan];
}

// moving event for interactive drag
-(void)panEventHandler:(UIPanGestureRecognizer *)pan{
    [self translateView:pan.view becauseOfGestureRecognizer:pan];
    [self refreshRect];
}

// moving event for interactive drag
-(void)translateView:(UIView *)view becauseOfGestureRecognizer:(UIPanGestureRecognizer *)pan{
    UIView * target= pan.view;
    CGPoint translation= [pan translationInView:self.view];
    target.center=CGPointMake(target.center.x+translation.x, target.center.y+translation.y);
    [pan setTranslation:CGPointZero inView:self.view];
}

// redraw the rectangle based on the drags' positions
-(void)refreshRect{
    UIBezierPath * rectPath=[UIBezierPath bezierPath];
    //Rectangle coordinates
    CGPoint view1Center=[self->drag1 center];
    CGPoint view4Center=[self->drag2 center];
    CGPoint view2Center=CGPointMake(view4Center.x, view1Center.y);
    CGPoint view3Center=CGPointMake(view1Center.x, view4Center.y);
    
    //Rectangle drawing
    [rectPath moveToPoint:view1Center];
    [rectPath addLineToPoint:view2Center];
    [rectPath addLineToPoint:view4Center];
    [rectPath addLineToPoint:view3Center];
    [rectPath addLineToPoint:view1Center];
    
    self->rectOverlay.path=rectPath.CGPath;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
