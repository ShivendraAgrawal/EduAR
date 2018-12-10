import numpy as np
from io import BytesIO
from pprint import pprint
import cv2
import pytesseract as pytesseract
from PIL import Image
from flask_cors import CORS
from flask import Flask, render_template, request, url_for, Response
from multiprocessing.dummy import Pool as ThreadPool
import os, json, re, string
from base64 import b64decode


app = Flask(__name__, static_url_path='')

cors = CORS(app, resources={r"/*": {"origins": "*"}})


@app.route('/classify', methods=['GET','POST'])
def show_all_markers():
    print("Classify API called")
    if request.method == 'POST':
        offset = 0
        data = request.get_json(force=True)
        # image = Image.frombytes('RGB',(400, 600), b64decode(data['image']))
        image = Image.open(BytesIO(b64decode(data['image'])))
        print(image)
        image = image.rotate(270)
        # image.show()
        np_image = np.array(image)
        h, w, _ = np_image.shape
        result = None
        try:
            topleft, botright = bb_ocr(np_image)
            x_min, y_min = topleft[0], botright[1]
            x_max, y_max = botright[0], topleft[1]

            import matplotlib.pyplot as plt
            import matplotlib.patches as patches
            fig = plt.figure()
            ax = fig.add_subplot(111)
            plt.imshow(image)

            # Create a Rectangle patch
            rect = patches.Rectangle((x_min, y_min),
                                     x_max - x_min, y_max - y_min,
                                     linewidth=1,
                                     edgecolor='r',
                                     facecolor='none')
            ax.add_patch(rect)
            plt.show()

        except:
            return Response(json.dumps({'text': "Oops. No text detected",
                                        'object': 'none',
                                        'x': 1000,
                                        'y': h - 350 + offset
                                        }),
                            mimetype='application/json')

        text = ocrRec(np_image)
        object = find_object(text)
        return Response(json.dumps({'text' : text,
                                    'object': object,
                                    'x' : (x_min + x_max)/2,
                                    'y' : h - ((y_min + y_max)/2) + offset
                                    }),
                        mimetype='application/json')

def find_object(text):
    regex = re.compile('[%s]' % re.escape(string.punctuation))
    text = regex.sub('', text)
    text = text.lower()
    words = set(text.split())
    object_set = {"airplane", "billiards", "candle", "car",
                   "chair", "cup", "lamp", "sled", "snowman",
                   "table", "treasure", "vase"}
    found = words.intersection(object_set)
    if len(found) == 0:
        return "none"
    return found.pop()


def ocrRec(image):
    config = ('-l eng --oem 1 --psm 3')
    # Run tesseract OCR on image
    text = pytesseract.image_to_string(image, config=config)
    return text

def bb_ocr(img):
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


@app.route('/', methods=['GET'])
def index():
    return "Server up and running"


if __name__ == '__main__':
   app.run(host='0.0.0.0')