import numpy as np
import cv2
import matplotlib.pyplot as plt
from matplotlib.backends.backend_agg import FigureCanvasAgg
from openpiv import windef  # <---- see windef.py for details
from openpiv import tools, scaling, validation, filters, preprocess
import openpiv.pyprocess as process
from openpiv import pyprocess
import numpy as np
import pathlib
import importlib_resources
from time import time
import warnings


import matplotlib.pyplot as plt
import os
def register_images(img1, img2):
    sift_detector = cv2.SIFT_create()
    # Find the keypoints and descriptors with SIFT
    kp1, des1 = sift_detector.detectAndCompute(img1, None)
    kp2, des2 = sift_detector.detectAndCompute(img2, None)

    # BFMatcher with default params
    bf = cv2.BFMatcher()
    matches = bf.knnMatch(des1, des2, k=2)

    # Filter out poor matches
    good_matches = []
    for m, n in matches:
        if m.distance < 0.75 * n.distance:
            good_matches.append(m)

    matches = good_matches

    points1 = np.zeros((len(matches), 2), dtype=np.float32)
    points2 = np.zeros((len(matches), 2), dtype=np.float32)

    for i, match in enumerate(matches):
        points1[i, :] = kp1[match.queryIdx].pt
        points2[i, :] = kp2[match.trainIdx].pt

    [H, inliers] = cv2.estimateAffinePartial2D(points2, points1)
    if H is None:
        warnings.warn("Registration failed, returning original image")
        return img2
    scale = (H[0, 1]**2 + H[0, 0]**2)**0.5
    H[0:2, 0:2] = H[0:2, 0:2] / scale
    registered_image = cv2.warpAffine(img2, H, (img1.shape[1], img1.shape[0]))
    return registered_image


def calculate_piv(image1, image2, mask=None):
    # Calculate the optical flow using Farneback method

    flow = cv2.calcOpticalFlowFarneback(
        cv2.cvtColor(image1, cv2.COLOR_BGR2GRAY),
        cv2.cvtColor(image2, cv2.COLOR_BGR2GRAY),
        None,
        0.5, 3, 64, 3, 3, 1.2, 0
    )

    # Extract flow components
    u = flow[:, :, 0]
    v = flow[:, :, 1]

    # Apply the mask to keep only velocities inside the mask
    if mask is not None:
        u[mask.astype(np.uint8) == 0] = 0
        v[mask.astype(np.uint8) == 0] = 0


    return u, v

def overlay_piv_on_video(video_path, output_video_path, u, v ):
    cap = cv2.VideoCapture(video_path)
    #fourcc = cv2.VideoWriter_fourcc(*'MJPG')
    #out_piv = cv2.VideoWriter(output_video_path, fourcc, 5, (int(cap.get(3)), int(cap.get(4))))
    directory = os.path.dirname(output_video_path)
    if not os.path.exists(directory):
        os.makedirs(directory)
    frame_num = 0
    u_np = np.array(u)
    v_np = np.array(v)
    abs_vel = np.array((u_np ** 2 + v_np ** 2) ** 0.5)
    mean_vel = abs_vel.mean()
    while cap.isOpened():
        ret, frame = cap.read()
        print('frame_num: ', frame_num)
        if not ret:
            break
        if frame_num >= len(u):
            break

        # Calculate the coordinates for the quiver plot
        y, x = np.meshgrid(np.arange(0, frame.shape[0]), np.arange(0, frame.shape[1]), indexing='ij')

        # Scale the vectors to fit within the frame
        scale_factor = 10  # Adjust as needed
        x_quiver = x[::scale_factor, ::scale_factor]
        y_quiver = y[::scale_factor, ::scale_factor]
        u_quiver = u[frame_num][::scale_factor, ::scale_factor]
        v_quiver = v[frame_num][::scale_factor, ::scale_factor]
        # scale the size of the vectors for visualization purposes
        u_quiver =  0.01* u_quiver / mean_vel
        v_quiver =  0.01* v_quiver / mean_vel



        fig, ax = plt.subplots(dpi = 100)
        frame_plot = ax.imshow(frame)
        ax.quiver(x_quiver, y_quiver, u_quiver, v_quiver, color='r', width = 0.005, scale = 0.5)
        ax.axis('off')
        # Check if the directory of the file_path exists, if not, create it

        plt.savefig(output_video_path + str(frame_num) + '.tif', format='tiff', dpi=100, bbox_inches='tight', pad_inches=0)


        # Render the figure to a NumPy array
        '''canvas = FigureCanvasAgg(fig)
        canvas.draw()
        # remove the white space and axis around the image
        fig.tight_layout(pad=0)
        # Convert to NumPy array

        image_np = np.frombuffer(canvas.tostring_rgb(), dtype=np.uint8)
        image_np = cv2.resize(image_np, (int(cap.get(3)), int(cap.get(4)),3))

        out_piv.write(image_np)'''
        plt.close()


        frame_num += 1

    cap.release()
    cv2.destroyAllWindows()



def overlay_piv_on_video2(videopath, output_path, u, v):
    cap = cv2.VideoCapture(videopath)
    fourcc = cv2.VideoWriter_fourcc(*'MJPG')
    out_piv = cv2.VideoWriter(output_path, fourcc, 5, (int(cap.get(3)), int(cap.get(4))))

    frame_num = 0
    while cap.isOpened():
        ret, frame = cap.read()
        print('frame_num: ', frame_num)
        if not ret:
            break


            fig, ax = plt.subplots(figsize=(8, 8))
            tools.display_vector_field(
                pathlib.Path('exp1_001.txt'),
                ax=ax, scaling_factor=100,
                scale=50,  # scale defines here the arrow length
                width=0.0035,  # width is the thickness of the arrow
                on_img=True,  # overlay on the image
                image_name=str(output_path + 'frame_' + str(frame_num) + '.bmp'),
            );
            plt.close()