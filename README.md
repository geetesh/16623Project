# 16623Project

##Realtime Pose Estimation using fiducial marker tracking

##Summary
Fiducials are a reliable approach when trying to estimate pose accurately. In this project I plan to detect and track a marker in realtime and obtain the pose and render objects in scene relative to this pose.

##Background
OpenCV will be used to detect the fiducial marker and then high speed camera at 120FPS will be used to track the fiducial patch to achieve realtime pose estimate. Due to realtime requirement a correlation based tracker will be used to track the required patch. 

##Challenge
For AR applications fiducials need to be detected and tracked in realtime. Fiducial detection consumes a lot of CPU time due to searching through the entire image. This time can be hugely reduced by reducing the search space or image size. In general a tracker is employed to get an estimate of search space. By employing a correlation based tracker we can do the second part more efficiently on a mobile cpu as correlation in frequency domain heavily reduces computational requirements.

##Goals & Deliverables
* Plan to achieve: Correlation based high speed Fiducial pose estimator. This shall be demonstrated by capturing a video of the APP in action displaying the pose of the fiducial marker at atleast 50FPS.

* Hope to achieve: Use OpenGL ES to render an object in the scene. Manipulate the object motion in the scene. This shall be demonstrated by capturing a video of the APP showing rendering/manipulation of the object at more than 30FPS.

##Schedule

- [x] Week1: Access High speed camera and run fiducial detector

- [x] Week2: Run MOSSE tracker as discussed in class to do high speed correlation based tracking

- [x] Week3.0: Run high speed tracking with patch initialised from fiducial detector and implement recovery in case marker is lost

- [x] Week: 3.5 Calibrate Camera

- [x] Week4.0: Estimate Pose

- [ ] Week4.5: Slack week in case above goals aren't met

- [ ] Week5: Display/Render an object in scene
