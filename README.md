# Spheroid Segmentation and Registration

Python functions for segmentation and registration of one centrally alligned spheroid. 

## Table of Contents
- [Set up python environment](#set-up-python-environment)
- [Usage](#usage)
- [Help](#help)


## Set up
1. Download the environment_packages.txt from this repository

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


## Usage Registration & Segmentation

1. Adjust Paths
2. 








  



