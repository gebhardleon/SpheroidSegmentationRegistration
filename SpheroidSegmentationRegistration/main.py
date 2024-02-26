import numpy as np
import torch
import matplotlib.pyplot as plt
import cv2
from segment_anything import sam_model_registry, SamPredictor, SamAutomaticMaskGenerator
from SegmentationFunctions import *
from RegistrationFunctions import *
import os

# paths
stacks = ['Chip3'] # list with folders to be preprocessed
image_stem_name =  ['Chip3_']# stem name of the images for each stack
sam_path = "/Users/leongebhard/Desktop/X/PRL/Python/sam_vit_h_4b8939.pth" # path to the segment anything model
output_base_path = '/Users/leongebhard/Desktop/X/PRL/Relaxation/PreprocessedStacks/' # path to save the preprocessed images
register_image = True # decide if images should be registered
#                     # if no relevant movement of the object is expected, this can be set to False to prevent artefacts
area_deviation_threshold = 0.04 # threshold for the change in mask area to reinitialise the mask and registration

device = 'mps' if torch.backends.mps.is_available() else 'cpu' # check if m1 mac acceleration is available
device = 'cuda' if torch.cuda.is_available() else device # check if cuda gpu acceleration is available
# in the future, the SAM model could be replaced with MedSAM - which is the SAM pretrained on medical images
# https://github.com/bowang-lab/MedSAM/blob/main/tutorial_quickstart.ipynb
print('Searching SAM model under ' + sam_path)
sam = sam_model_registry["default"](checkpoint=sam_path)
print('SAM model found and loaded')
sam.to(device=device)
predictor = SamPredictor(sam)
mask_area = 1
masks = []

for nr,stack in enumerate(stacks):
    output_path = os.path.join(output_base_path, stack)
    imagestack_path = os.path.join('/Users/leongebhard/Desktop/X/PRL/Relaxation/RawStacks/', stack)
    number_of_pictures = len(os.listdir(imagestack_path)) -1
    print('Preprocessing stack ' + stack + ' with ' + str(number_of_pictures) + ' images')

    start = 0
    end = number_of_pictures

    print('loading the first image to intialise the segmentation')
    image = cv2.imread(os.path.join(imagestack_path, image_stem_name[nr] +str(start).zfill(4)+'.tif'))
    predictor.set_image(image)
    input_points, input_label = get_input_points(image)
    # predict the masks
    masks, scores, logits = predictor.predict(
        point_coords=input_points,
        point_labels=input_label,
        # mask_input=mask_input[None, :, :],
        multimask_output=True,
    )
    mask_input = logits[np.argmax(scores), :, :]  # Choose the model's best mask



    for i in range(start, end):
        # load the next image
        print('Image ' + str(i) + ' of ' + str(number_of_pictures))
        image = cv2.imread(os.path.join(imagestack_path, image_stem_name[nr] + str(i).zfill(4) + '.tif'))
        # contrast stretch the image
        image = (image - np.min(image)) / (np.max(image) - np.min(image))
        image = (image * 255).astype(np.uint8)
        predictor.set_image(image)
        input_points, input_label = get_input_points(image)

        # predict the masks

        if i == start:

            masks, scores, logits = predictor.predict(
                point_coords=input_points,
                point_labels=input_label,
                #mask_input=mask_input[None, :, :],
                multimask_output=True,
            )
            mask_area = np.sum(masks[np.argmax(scores)])
        else:
            masks, scores, logits = predictor.predict(
                point_coords=input_points,
                point_labels=input_label,
                mask_input=mask_input[None, :, :],
                multimask_output=True,
            )

        if abs(np.sum(masks[np.argmax(scores)]) - mask_area)/abs(np.sum(masks[np.argmax(scores)]) + mask_area) > 0.04:
            print('Mask & registration reinitialised at frame ' + str(i) + ' due to a high change in mask area')
            last_image = image # reset the last_image variable to prevent registration of this frame
            masks, scores, logits = predictor.predict(
                point_coords=input_points,
                point_labels=input_label,
                #mask_input=mask_input[None, :, :],
                multimask_output=True,
            )
        mask_area = np.sum(masks[np.argmax(scores)])
        mask_input = logits[np.argmax(scores), :, :]  # Choose the model's best mask as input to the next frame segmentation
        best_mask = masks[np.argmax(scores), :, :]  # Choose the model's best mask

        #for more information / debugging use the function: show_multiple_masks(image, input_points, input_label, masks, scores, plt.gca())


        # optional: clean up the mask, removing all objects which are not attached to the biggest area
        #best_mask_cleaned = clean_up_mask(best_mask)


        if i ==start:
            last_image = image
            #clr = int(image.mean())
            image[best_mask.astype(np.uint8) == 0] = 0
            # save image under outputpath as bmp and create folder
            if not os.path.exists(output_path):
                print('Creating output directory ' + output_path)
                os.makedirs(output_path)

        else:
            image[best_mask.astype(np.uint8) == 0] = 0
            if register_image:
                image = register_images(last_image, image)

            last_image = image
        cv2.imwrite(os.path.join(output_path,image_stem_name + str(i).zfill(4) + '.tif'), image)

        cv2.destroyAllWindows()






