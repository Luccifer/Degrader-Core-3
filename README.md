# DPCore3 #

*created by denis svinarchuk*

https://imagemetalling.wordpress.com/

imagemetalling@gmail.com

## About ##

The DPCore3 is an Image Processing framework for iOS using Apple Metal to accelerate processing. 
Instead of Core Image framework DPCore3 lets your programm create your own new amazing image filters
and also use Apple Metal Shading Language that is a C++11 dialect. 

The project is similar to the incredible Brad Larson GPUImage framework, but DPCore3 uses Metal API on a lower 
level and potentially more efficiently utilizes data interchange between CPU and GPU.

## Technical requirements ##

- iOS 8.0 and later
- devices with A7 processor and later
- XCode 6.0 and later
- Application can be launched on a real device only, iOS simulator still does not support Metal 

## License ##

BSD3. Text is avalable in LICENSE file.

## How to use ##

* Install cocoapods: http://cocoapods.org/
* Edit Podfile in the your XCode project directory YourApp:

        platform :ios, '8.0'


        pod 'DegradrMath', :git => 'https://bitbucket.org/degrader/degradr-math.git', :tag => '0.2.0'
        pod 'DegradrCore3', :git => 'https://bitbucket.org/degrader/degradr-core-3.git', :tag => '0.6.0'

        post_install do |installer|
            installer.pods_project.targets.each do |target|
                target.build_configurations.each do |config|
                    config.build_settings['DYLIB_COMPATIBILITY_VERSION'] = ''
                    config.build_settings['ENABLE_BITCODE'] = 'NO'
                end
            end
        end


The DPCore3 framework uses libturbojpeg which could not be build with ENABLE_BITCODE, you need to disable this option in 
your project. Go to the project Build Settings, search ENABLE_BITCODE, choose Enable Bitcode "NO". That's all.



* Install dependencies in your project

        $ pod install



* Open the XCode workspace instead of the project file
        
        $ open YourApp.xcworkspace



* To add DPCore3 framework into Swift project you can use Objective-C bridging:
 
    1. Add <your project name>-Bridging-Header.h file
    2. Add to this file a line like this:
 
            #import "DPCore3.h"
        
    3. Go to your project Build settings and search for bridging
    4. Edit Objective-C Bridging Header property: add path to your bridging file created before
    5. Add a Metal file into the project
    6. Add to the Metal file standard DPCore3 metal library :

                #include <metal_stdlib>
                #include "DPMetal_main.h"
                using namespace metal;
                

    7. Now you can use the DPCore3




## Example of filtering video stream from iPhone camera ##

        //
        //  ViewController.swift
        //  ImageMetalling-02
        //
        //  Created by denis svinarchuk on 31.10.15.
        //  Copyright © 2015 ImageMetalling. All rights reserved.
        //

        import UIKit

        class ViewController: UIViewController {

        
            var liveView:UIView!=nil
            var camera:DPCameraManager!=nil
            var exposureFilter:DPExposureFilter!=nil;

            override func viewDidAppear(animated: Bool) {
                super.viewDidAppear(animated)
                camera.start()
            }

            override func viewDidDisappear(animated: Bool) {
                super.viewDidDisappear(animated)
                camera.stop()
            }

            override func viewDidLoad() {
                super.viewDidLoad()

                liveView = UIView(frame: CGRectMake( 0, 20,
                    self.view.bounds.size.width,
                    self.view.bounds.size.height*3/4
                ));
                self.view .addSubview(liveView)

                camera = DPCameraManager(outputContainerPreview: liveView)

                //
                // Create exposure filer
                //
                exposureFilter = DPExposureFilter(context: DPContext.newLazyContext())

                //
                // Set exposure compensation 1/2 EV stop
                //
                exposureFilter.adjustment.exposure = 0.5

                //
                // Set blending mode. DPCore3 supports 2 standart blanding Normal an Luminosity
                // In your custom filter you can add any blending mode you want.
                // 
                exposureFilter.adjustment.blending.mode = Int32(DP_BLENDING_LUMINOSITY.rawValue)

                //
                // Set the live view filtering
                //
                camera.liveViewFilter = exposureFilter
            }

        }


## Example of filtering video stream from iPhone camera with custom filer ##

        class DPCustomFilter: DPFilter {

            //
            // Filter adjustment parameter
            //
            var adjustment:Float=0{
            didSet(oldValue){
                adjustmentUniform = adjustmentUniform ?? self.context.device.newBufferWithLength(sizeof(Float), options: MTLResourceOptions.CPUCacheModeDefaultCache)
                memcpy(adjustmentUniform.contents(), &adjustment, sizeof(Float))
                }
            }

            private var kernelFunction:DPFunction!=nil
            private var adjustmentUniform:MTLBuffer!=nil

            //
            // Create custom function from .metal 
            //
            required init!(context aContext: DPContext!) {

                super.init(context: aContext)
                
                //
                // initialize kernel function
                //
                if let actualKernelFunction = DPFunction(functionName: "kernel_adjustCustom", context: self.context){
                    kernelFunction = actualKernelFunction
                    //
                    // add function to filter, you can add more then one
                    //
                    self.addFunction(kernelFunction)
                }
                else{
                        NSLog(" *** error load kernel_adjustSaturation function...")
                    }
                }

                override func configureFunction(function: DPFunction!, uniform commandEncoder: MTLComputeCommandEncoder!) {
                    //
                    // apply function parameters to kernel
                    //
                    if function == kernelFunction{
                        commandEncoder.setBuffer(adjustmentUniform, offset: 0, atIndex: 0)
                    }
                }

        }

* Create filers chain

        ...
        //
        // Initialize main filter
        //
        exposureFilter = DPExposureFilter(context: DPContext.newLazyContext())
        exposureFilter.adjustment.exposure = 0.5
        exposureFilter.adjustment.blending.mode = Int32(DP_BLENDING_LUMINOSITY.rawValue)

        //
        // Initialize custom filter 
        //
        customFilter = DPCustomFilter(context: exposureFilter.context)
        customFilter.adjustment = 0.5

        //
        // Set camera live view
        //
        exposureFilter.addFilter(customFilter)


## The main idea working with filters is using source/destination properties ##


## Texture providers. DPImageProvider

This is conceptual API difference between DPCore3 and GPUImage. The DPCore3 filters directly process images 
class and always work with abstract data type: DPImageProvider. DPImageProvider binding provides a particular 
type of image processing in the context of filter.

Specific provider implementations allow to bind filters with UIImage/CGImage, CVPixelBuffer and JPEG files.
DPImageProvider can also export processed data to JPEG file, UIImage and NSData (JPEG in memory). 

* For example: 

        [DPContext setMaximumTextureSize: 1500]; 
        DPContext * context = [DPContext new]; 

        // Create a dawnscaled texture provider to 1500 on the large side 
        DPImageProvider * provider = [DPImageFileProvider newWithImageFile: @ "image.jpg" context: context]; 
        NSError * error; 
        // Save the texture in jpeg-file with QUALITY 90% 
        [provider writeJpegToFile: @ "new-image.jpg" quality: .9 error: & error]; 
        If (error) 
            NSLog (@ "... saving error... ");



## The main providers

    1. DPPixelBufferProvider gets cached texture from the video camera frames, imageOrientation always Left main camera 
    2. DPUIImageProvider creates provider from UIImage object, imageOrientation == property UIImage 
    3. DPImageURLProvider creates provider from URL of image, imageOrientation == UIImageOrientationUp - always normalized 
    4. DPImageFileProvider is the most efficient way to get a big image from file, imageOrientation - undefined, the default is Up.


## Extensions 

        UIImage (DPImageProvider) 
        // 
        // Create an image from any provider 
        // 
        + (UIImage *) imageWithImageProvider: (DPImageProvider *) provider scale: (CGFloat) scale orientation: (UIImageOrientation) orientation; 
        + (UIImage *) imageWithImageProvider: (DPImageProvider *) provider; 
        
        NSData (DPImageProvider) 
        // 
        // Generate jpeg memory data from provider . 
        // Inside, contains jpeg-turbo, so this is the cost-effective solution than using UIImage 
        // 
        + (NSData *) jpegWithImageProvider: (DPImageProvider *) provider quality: (CGFloat) quality;


## Ready-to-use filters

* Photo adjustment filters:
    1. DPAWBFilter - auto white balance
    2. DPExposureFilter - exposure compensation filter
    3. DPBrightnesFilter - brightnes correction
    4. DPLevelsFilter - photoshop-instrument-like levels filter
    5. DPContrastFilter - image contrast enhancer
    6. DPCurveFilter - photoshop-instrument-like curve filter
    7. DPHSVFilter - HSV adjustment
    8. DPInvertFilter - make image "negative"
    
* Convolve filters
    1. DPGaussianBlur 
    2. DPUnshurpMaskFilter

* Samplers filters:
    1. DPBiLinearSampler - 2x2 classic biLinear sampler
    2. DPBiLinear3Sampler - 3x3 biLinear sampler
    3. DPTriangularSampler - triangular sampler
    3. DPBSplineSampler - d-spline sampler
    4. DPCMRomSampler - catmull-rom sampler
    5. DPLancsozSampler - lancsoz sampler
    6. DPFancySampler - fancy sampler
    7. DPResizeSampler - resize image sampler
    8. DPSmartResizeSampler - smart image resizer

* Analizers
    1. DPHistogramAnalizer - create histogram from image
    2. DPNeutralsAnalizer - analize color weights in image
    Analizes conform to several solvers like image range and zones (A.Adams zone theory), 
    image average solver and histogram equalization solver.
    
* Layers
    1. DPHistogramLayer - draw image histogram to DPImageProvider (to live-view presentation in DPView, for instance)

* Devices
    1. DPView - present providers on screen
    2. DPLiveView - present filtered video on screen
    3. DPImageView - present filtered static image on screen
    4. DPCameraManager - a camera manager, just to reduce writing code...