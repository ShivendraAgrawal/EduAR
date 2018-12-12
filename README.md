# EDU-AR

### CSCI-5413 VR Project

### Hardware Requirement
1) A Macbook
2) Xcode installed
3) An IOS device beyond iphone 6

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

#### Image Place Holder

The Application reads from the paper with the LSTM mode of the Tesseract OCR. We visalise this on a 3D plane in our augmented reality plane.
<br>
This will help learners augment their text with visally anchored 3D text.
#### Image Place Holder

When we tap on the text that appears on the plane it spawns a 3D object. This should aid visual learners grasp the concepts better.

#### Image Place Holder
