#!/usr/bin/env python

import os
from os import walk
from re import search
import time

hours = 60*60
minutes = 60
nanoseconds = 1000000000
saveTime = time.time()

deviationTime = 0
crossFilePath = []
newFilePath = []
newFile = []
crossLine = []
filesToParse = []

masterFile = os.path.join(os.getcwd(), "filesToParse")
parsedDirectory = os.path.join(os.getcwd(), "parsedFiles")
directory = os.path.join(os.getcwd(), "crossFiles")

for (dirpath, dirnames, filenames) in walk(masterFile, topdown=True):
    for files in filenames:
        filesToParse.append(os.path.join(masterFile, files))
    print(filesToParse)

for (dirpath, dirnames, filenames) in walk(directory, topdown=True):
    
    for dirs in dirnames:

        try: 
            os.mkdir(os.path.join(parsedDirectory, dirs))
        except: 
            print("file and directory exists!") 

        subdirectory = os.path.join(directory, dirpath, dirs)

        for (subdirpath, subdirnames, subfilenames) in walk(subdirectory, topdown=True):

            for subfiles in subfilenames: #Read log files from unrealistic dataset and make files with matching names for realistic set
                if search(".png", subfiles): #Photofilter
                    continue
                else:
                    crossFilePath.append(os.path.join(subdirectory, subfiles))
                    newFilePath.append(os.path.join(parsedDirectory, dirs, subfiles))
for fileToParsePath in filesToParse:
    with open(fileToParsePath, 'r') as fileToParse:
        for parseLine in fileToParse: #Reading line by line from the master file since it might be to large to do readlines() on

            splitParseLine = parseLine.split(",")
            parseLineTime = splitParseLine[0].split(':')
            parseLineSeconds = parseLineTime[2].split('.')

            totalTime = int(parseLineTime[0])*hours #add hours, minutes and convert to nano
            totalTime += int(parseLineTime[1])*minutes
            totalTime += int(parseLineSeconds[0])
            totalTime = int(totalTime * nanoseconds)
            totalTime += int(parseLineSeconds[1]) #add nanoseconds

            if totalTime < 1000000: deviationTime = 0

            if (not len(crossLine)): #Check if it's time to preload a new file
                deviationTime = totalTime #make deviation to match start at zero
                
                crossFile = open(crossFilePath[0], 'r') #File from Tobias set
                crossFilePath.pop(0)
                crossLine = crossFile.readlines()
                crossFile.close()

                newFile = open(newFilePath[0], 'a') #What we write to
                newFilePath.pop(0)

            finalTime = totalTime - deviationTime
            
            splitCrossLine = crossLine[0].split(",")

            if(finalTime < int(splitCrossLine[0])):
                newFile.writelines([str(finalTime), ",", splitParseLine[1], ",", splitParseLine[2]])
                saveTime = totalTime
            else:
                newFile.writelines(crossLine[0])
                crossLine.pop(0)
        else:
            print("out of lines!")
