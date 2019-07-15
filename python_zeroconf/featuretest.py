import cv2
import numpy as np

orb = cv2.ORB_create()
# detection
frame1 = cv2.imread("Images/1.png")
frame2 = cv2.imread("Images/2.png")
pts1 = cv2.goodFeaturesToTrack(np.mean(frame1, axis=2).astype(np.uint8), 3000, qualityLevel=0.01, minDistance=7)
pts2 = cv2.goodFeaturesToTrack(np.mean(frame2, axis=2).astype(np.uint8), 3000, qualityLevel=0.01, minDistance=7)

kps1 = [cv2.KeyPoint(x=f[0][0], y=f[0][1], _size=20) for f in pts1]
kps1, des1 = orb.compute(frame1, kps1)

kps2 = [cv2.KeyPoint(x=f[0][0], y=f[0][1], _size=20) for f in pts2]
kps2, des2 = orb.compute(frame2, kps2)


bf = cv2.BFMatcher(cv2.NORM_HAMMING)
matches = bf.knnMatch(des1, des2, k=2)
print(matches)