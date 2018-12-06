import numpy as np
import json
import logging
import random
from collections import Counter, defaultdict
import socket
from io import BytesIO
from pprint import pprint
import cv2
import sys
import pytesseract as pytesseract
from PIL import Image
from flask_cors import CORS
from flask import Flask, render_template, request, url_for, Response
from multiprocessing.dummy import Pool as ThreadPool
import os, json
from base64 import b64decode


PEOPLE_FOLDER = os.path.join('static', 'people_photo')

app = Flask(__name__, static_url_path='')

cors = CORS(app, resources={r"/*": {"origins": "*"}})




@app.route('/classify', methods=['GET','POST'])
def show_all_markers():
    print("Classify API called")
    if request.method == 'POST':
        data = request.get_json(force=True)
        # image = Image.frombytes('RGB',(400, 600), b64decode(data['image']))
        image = Image.open(BytesIO(b64decode(data['image'])))
        print(image)
        image = image.rotate(270)
        # image.show()
        np_image = np.array(image)
        result = None
        topleft, botright = bb_ocr(np_image)

        import matplotlib.pyplot as plt
        import matplotlib.patches as patches
        fig = plt.figure()
        ax = fig.add_subplot(111)
        plt.imshow(image)
        x_min, y_min = topleft[0], botright[1]
        x_max, y_max = botright[0], topleft[1]

        # Create a Rectangle patch
        rect = patches.Rectangle((x_min, y_min),
                                 x_max - x_min, y_max - y_min,
                                 linewidth=1,
                                 edgecolor='r',
                                 facecolor='none')
        ax.add_patch(rect)
        plt.show()
        print(result)


    return Response(json.dumps({'text' : ocrRec(np_image),
                                'x' : (x_min + x_max)/2,
                                'y' : (y_min + y_max)/2
                                }),
                    mimetype='application/json')


def ocrRec(image):
    config = ('-l eng --oem 1 --psm 3')
    # Run tesseract OCR on image
    text = pytesseract.image_to_string(image, config=config)
    return text

def bb_ocr(img):
    # h, w, _ = image.shape  # assumes color image
    #
    # # run tesseract, returning the bounding boxes
    # boxes = pytesseract.image_to_boxes(image)  # also include any config options you use
    #
    # # draw the bounding boxes on the image
    # for b in boxes.splitlines():
    #     b = b.split(' ')
    #     img = cv2.rectangle(image, (int(b[1]), h - int(b[2])), (int(b[3]), h - int(b[4])), (0, 255, 0), 2)
    #
    # # show annotated image and wait for keypress
    # cv2.imshow("image", image)
    # cv2.waitKey(0)
    h, w, _ = img.shape

    # apply tesseract to BOXES
    boxes = pytesseract.image_to_boxes(img)
    temp = boxes.split('\n')
    boxList = []
    for i in temp:
        j = list(map(int, i.split(' ')[1:-1]))
        boxList.append(j)

    # apply tesseract to STRING
    text = pytesseract.image_to_string(img)
    text = text.replace(' ', '')
    textList = text.split('\n')
    print(textList)

   
    countt = 0
    x1, y1, x2, y2 = boxList[0][0], 0, 0, 0
    lastLetterList = []
    firstRow = []
    lastRow = []
    for i in range(len(textList)):  # column
        for j in range(len(textList[i])):  # row (or line)
            if i == 0:  # loop over first row
                if boxList[countt][1] > y1:
                    y1 = h - boxList[countt][1]  # top-Left y kordinat
            if j == (len(textList[i]) - 1):
                lastLetterList.append(boxList[countt][2])
            if i == (len(textList) - 1):  # loop over last row
                if boxList[countt][3] > y2:
                    y2 = h - boxList[countt][3]
            countt += 1

    x2 = max(lastLetterList)
    topLeft = [x1, y1]
    botRight = [x2, y2]

    # boxing every letter
    for box in boxes.splitlines():
        box = box.split(' ')
        img = cv2.rectangle(img=img, pt1=(int(box[1]), h - int(box[2])), pt2=(int(box[3]), h - int(box[4])),
                            color=(0, 255, 0), thickness=1)

    # boxing whole paragraph
    # cv2.rectangle(img=img, pt1=(topLeft[0], topLeft[1]), pt2=(botRight[0], botRight[1]), color=(0, 255, 0), thickness=1)
    # print(topLeft)
    # print(botRight)
    #
    # # show the output image
    # cv2.imshow("Output", img)
    # cv2.waitKey(0)
    return topLeft, botRight


@app.route('/index', methods=['GET'])
def index():
    pass


if __name__ == '__main__':
   app.run(host='0.0.0.0')