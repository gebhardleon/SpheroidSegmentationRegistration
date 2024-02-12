import matplotlib.pyplot as plt
import numpy as np
from scipy import ndimage


def show_mask(mask, ax, random_color=False):
    if random_color:
        color = np.concatenate([np.random.random(3), np.array([0.6])], axis=0)
    else:
        color = np.array([30 / 255, 144 / 255, 255 / 255, 0.6])
    h, w = mask.shape[-2:]
    mask_image = mask.reshape(h, w, 1) * color.reshape(1, 1, -1)
    ax.imshow(mask_image)


def show_points(coords, labels, ax, marker_size=375):
    pos_points = coords[labels == 1]
    neg_points = coords[labels == 0]
    ax.scatter(pos_points[:, 0], pos_points[:, 1], color='green', marker='*', s=marker_size, edgecolor='white',
               linewidth=1.25)
    ax.scatter(neg_points[:, 0], neg_points[:, 1], color='red', marker='*', s=marker_size, edgecolor='white',
               linewidth=1.25)

def show_multiple_masks(image, input_points, input_label, masks, scores, ax):
    for i, (mask, score) in enumerate(zip(masks, scores)):

        plt.imshow(image)
        show_mask(mask, plt.gca())
        show_points(input_points, input_label, plt.gca())
        plt.title(f"Mask {i + 1}, Score: {score:.3f}", fontsize=18)
        plt.axis('off')
        plt.show()

def clean_up_mask(mask):
    # remove all objects which are not attached to the biggest area
    # find the biggest area
    labeled_matrix, num_features = ndimage.label(mask)
    biggest_area = 0
    for i in range(1, int(np.max(labeled_matrix)) + 1):
        if np.sum(labeled_matrix == i) > biggest_area:
            biggest_area = np.sum(labeled_matrix == i)
            biggest_area_index = i
    # remove all other objects
    labeled_matrix[labeled_matrix != biggest_area_index] = 0

    #  set all pixels with one or less non zero elements to zero
    # count the neighbouring non-zero elements for each pixel
    for i in range(0, labeled_matrix.shape[0]):
        for j in range(0, labeled_matrix.shape[1]):
            if labeled_matrix[i, j] != 0:
                if np.sum(labeled_matrix[i - 1:i + 1, j - 1:j + 1] != 0) < 2:
                    labeled_matrix[i, j] = 0


    return labeled_matrix

def get_input_points(image):
    input_points = [[int(image.shape[1] / 2), int(image.shape[0] / 2)]]
    for i in [-1, 1]:
        for j in [-1, 1]:
            input_points.append( [int(input_points[0][0] * (1+0.15*i)),  int(input_points[0][1] * (1+0.15*j))])
    input_points = np.array(input_points)
    input_label = np.ones(len(input_points))
    return input_points, input_label
