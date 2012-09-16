# JCMSegmentedPageController

Custom container view controller for iOS that functions similarly to a UITabBarController, but the way to switch tabs is through a UISegmentedControl on top.  [Demo](https://github.com/jcmendez/JCMSegmentPageController/blob/master/Demo/DemoSimpleTableViewController.m) included.
Very well [documented](http://jcmendez.github.com/JCMSegmentPageController/).  This project is set up using ARC (Automatic Reference Counting).  The main branch is set up for iOS5 and later.  Thanks to [@mosamer](https://github.com/mosamer) there is an iOS 4.3  [backport](https://github.com/jcmendez/JCMSegmentPageController/tree/ios4).

![Screenshot](https://github.com/jcmendez/JCMSegmentPageController/raw/master/Screenshot.png)

## Start using it

Get the source code:

	    git clone git://github.com/jcmendez/JCMPagedViewControl.git

The only files you need to add to your project are

        JCMSegmentPageController.h
        JCMSegmentPageController.m

See [this thread on Stack Overflow](http://stackoverflow.com/questions/10723434/how-to-use-jcmsegmentpagecontroller-with-storyboards/) on how to define the contained subviews in XCode/IB

## Author
Juan-Carlos Mendez: jcmendez@alum.mit.edu

## License

Copyright 2012 Juan-Carlos Mendez (jcmendez@alum.mit.edu)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 
