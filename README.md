# SeniorDesign_ASHES
A repository for my senior project, a drone-mounted hyperspectral imager. 

## Installation
The following assumes you are running these scripts on a Windows, x86 machine. Installation instructions for linux devices will come at a later date. 

This code is built on python, along with some libraries that need to be downloaded. To install python, visit the webpage below and install through the python installer. 

[Download python Installation Manager](https://www.python.org/downloads/)

Pypylon is a library created for use specifically with Basler imaging systems. Our imager, the Resonon Pika-XC2, uses a Basler camera. To install pypylon, open your command prompt (press the windows button and type "cmd") and enter the following.

    pip install pypylon

Numpy is a library to enable numerical computing. To install, open your command prompt (press the windows button and type "cmd") and enter the following. 

    pip install numpy

## Running Python Scripts
To run this python script, you can either use a code editor/IDE or run from the command prompt. The following will show you how to use a command prompt. 

Download the python file and open your command prompt (press the windows button and type "cmd"). Once done, find what folder the python file is in and obtain the path to the folder. This can be done by right-clicking on the folder, and pressing the "Copy as path" option. Once done, type the following in the command prompt, replacing "path/to/your/folder" with the path to your folder. If "Copy as path" was selected, you can simply paste (Ctrl + V) the file path after the cd command. 

    cd path/to/your/folder

Once done, simply type the following in the terminal to run. 

    python PIKA-XC2


## Liscence
This project is distributed under the terms described in the LICENSE file. Please refer to the LICENSE file for complete details about usage and distribution rights.
