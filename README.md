# EDU-AR

### CSCI-5413 VR Project

### Hardware Requirement
1) A Macbook
2) Xcode installed
3) An iOS device beyond iphone 6

### Installing the app
1) Install python 3.6
2) Install the required libraries - 

    `Flask==0.12.2`
    `Flask-Cors==3.0.3`
    `numpy==1.14.2`
    `opencv-python==3.4.1.15`
    `Pillow==5.1.0`
    `pytesseract==0.2.5`
3) Start the Python server by running the app
4) Find you public IP address by using `ifconfig` (on Unix based systems)
5) Change the IP address on Line 36 of ViewController.swift

6) Open the Xcode project (EduAR.xcodeproj)
7) Set the team ID as shivendra.agrawal@gmail.com
8) Provide a unique budle identifier.
9) Connect your ipad or iphone and build the project

### The main focus of this project is to aid individuals with learning disabilities.

First you have to spatially map the surrounding, the yellow dots are feature points which show that the environment is being perceived.

![img1](https://github.com/ShivendraAgrawal/EduAR/blob/master/EduAR%20gifs/GIF1.gif?raw=true)

Then, EduAR reads from the paper with the LSTM mode of the Tesseract OCR. We visalise this on a 3D plane in AR anchored on the real text.

![img2](https://github.com/ShivendraAgrawal/EduAR/blob/master/EduAR%20gifs/GIF2.gif?raw=true)

This will help learners to generate visually anchored 3D text for all the texts in a scene. Then they can tap the desired text and enter the visual aide of EduAR. They can view words, sentences or paragraphs as per their convinience.

![img3](https://github.com/ShivendraAgrawal/EduAR/blob/master/EduAR%20gifs/GIF3.gif?raw=true)

To encourage visual learning we have enabled a tap to visualize feature. When the user double taps anywhere on the screen it spawns a 3D object on the plane with hit test. This should aid visual learners grasp the concepts better.

![img4](https://github.com/ShivendraAgrawal/EduAR/blob/master/EduAR%20gifs/GIF4.gif?raw=true)

### Now download the code and have fun!
