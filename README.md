# Spheroid Segmentation and Registration

Python functions for segmentation and registration of one centrally alligned spheroid. 

## Table of Contents
- [Set up python environment](#set-up-python-environment)
- [Usage Registration Segmentation](#usage-registration-segmentation)
- [PIV Analysis](#piv-analysis)
- [PIV Post Processing](#piv-post-processing)
- [Help](#help)


## Set up python environment
1. Download the necessary packages:

   pip install torch, torchvision, numpy, matplotlib, opencv-python, git+https://github.com/facebookresearch/segment-anything.git

2a. Option 1: To create a new environment with all necessary packages using the command below. Make sure to add the corresponding file path before environment_packages.txt, e.g.       /Users/leongebhard/Desktop/environment_packages.txt

    conda create --name SpheroidProcessing --file environment_packages.txt

Subsequently, remember to chose the newly created environment (SpheroidProcessing).
If you encounter problems along the way make sure you have conda correctly installed.
  
2b. Option 2: install the necessary libraries in your current environment.
    For this, you can use the command below and by again adjusting the path to the environments_packages.txt file.

    conda install --file environment_packages.txt

3. Download the Segment Anything model (doc via https://github.com/facebookresearch/segment-anything/). Choose between the huge, large or base model.
   
    huge (default): https://dl.fbaipublicfiles.com/segment_anything/sam_vit_h_4b8939.pth
   
    large: https://dl.fbaipublicfiles.com/segment_anything/sam_vit_l_0b3195.pth
   
    base: https://dl.fbaipublicfiles.com/segment_anything/sam_vit_b_01ec64.pth

   I did all the tests with the huge model, which takes about 20 seconds for a frame of 500kb. 
   Probably, the smaller ones would also work but if you don't have huge datasets, I recommend to just stick with the huge model which works great.


## Usage Registration Segmentation

1. Prepare the videos to be processed as .tif images in a seperate folder for each video
2. The .tif images in each folder must be numbered from 0000 to the maximum frame number (not higher then 9999). The image names must be of format: image_stem_name+four-digit-frame-number.tif (e.g. cancer_spheroid0000.tif)
3. Adjust Paths and the image_stem_name variable (explanation in the comments of the code)
4. Decide if images shall be only segmented  (register_image = False) or also registered (register_image = True)
5. The code automatically resets the registration when there are  changes in the detected spheroids size. The threshhold can be adjusted via the "area_deviation_threshold" parameter.

## PIV Analysis

general guide via (https://de.mathworks.com/matlabcentral/fileexchange/27659-pivlab-particle-image-velocimetry-piv-tool-with-gui) 

1. Import Images
2. Select folder with (registered) images
3. Select images + "import"
4. Image Settings  - Exclusion
    --> select ROI
5. Image Settings - Image pre-processing
       --> Apply and preview current frame
6. Analysis - PIV Settings
7. Analysis - ANALYZE! - Analyze all frames
8. Calibration
9. Validation
    --> find image and velocity based criterias for the specific data (e.g. filter low threshhold = 0.001)
10. File --> Export --> Mat file --> Export all frames
11. File --> Export --> image / video --> Export all frames

## PIV Post Processing

1. adjust the path behind "addpath" to the folder containing the "PIV_analysis.m" file
2. change the PIVFilePath to the the PIV data in .m format
3. change the outputpath to the desired output folder. The heatmaps will be saved here.


## Help
I'm happy if the codes find use - feel free to contact me for further questions via leon.gebhard@polytechnique.edu

