#!/usr/bin/env python

import os
from os import walk
from re import search
import time
import pandas as pd

hours = 60*60
minutes = 60
nanoseconds = 1000000000
saveTime = time.time()
IP_host = '10.88.0.9'
filesToParseDir = "filesToParse"
parsedFilesDir = "parsedFiles"
crossFilesDir = "crossFiles"
excelFile = "fold-0.csv"
header = 40

deviationTime = 0
crossFilePath = []
newFilePath = []
newFile = []
crossLine = []
filesToParse = []

trainFiles = []
validFiles = []
testFiles = []
parsedTrainFiles = []
parsedValidFiles = []
parsedTestFiles = []

masterFile = os.path.join(os.getcwd(), filesToParseDir)
parsedDirectory = os.path.join(os.getcwd(), parsedFilesDir)
directory = os.path.join(os.getcwd(), crossFilesDir)

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

#----------------------limited data data set sorting--------------------

df = pd.read_csv(excelFile)
dfFormat = ['log', 'is_train', 'is_valid', 'is_test']
dfFiles = df[dfFormat]

for x in range(0, len(dfFiles['log'])):
    if(dfFiles['is_train'][x] == True): 
        parsedTrainFiles.append(os.path.join(parsedDirectory, dfFiles['log'][x]))
        trainFiles.append(os.path.join(directory, dfFiles['log'][x]))
    elif(dfFiles['is_valid'][x] == True): 
        parsedValidFiles.append(os.path.join(parsedDirectory, dfFiles['log'][x]))
        validFiles.append(os.path.join(directory, dfFiles['log'][x]))
    else: 
        parsedTestFiles.append(os.path.join(parsedDirectory, dfFiles['log'][x]))
        testFiles.append(os.path.join(directory, dfFiles['log'][x]))
                    
#-----------------------------------------------------------------------
filesToParse.sort()
for fileToParsePath in filesToParse:
    print("New file to parse: ", fileToParsePath)
    with open(fileToParsePath, 'r') as fileToParse:
        print("opening ", fileToParse)
        for parseLine in fileToParse: #Reading line by line from the master file since it might be to large to do readlines() on
            splitParseLine = parseLine.split("\t")
            parseLineTime = splitParseLine[0].split('.')
            totalTime = int(parseLineTime[0]) * nanoseconds
            totalTime += int(parseLineTime[1])

            directionSplit = splitParseLine[1].split(',')
            
            #-------------------limited files open test, valid then training-----------------------

            if (not len(crossLine) and len(testFiles) > 0): #Check if it's time to preload a new file
                deviationTime = totalTime #make deviation to match start at zero

                crossFile = open(testFiles[0], 'r') #File from Tobias set
                testFiles.pop(0)
                
                crossLine = crossFile.readlines()
                crossFile.close()

                newFile = open(parsedTestFiles[0], 'a') #What we write to
                print("Printing to new file", parsedTestFiles[0])
                parsedTestFiles.pop(0)
            elif (not len(crossLine) and len(validFiles) > 0): #Check if it's time to preload a new file
                deviationTime = totalTime #make deviation to match start at zero

                crossFile = open(validFiles[0], 'r') #File from Tobias set
                validFiles.pop(0)
                
                crossLine = crossFile.readlines()
                crossFile.close()

                newFile = open(parsedValidFiles[0], 'a') #What we write to
                print("Printing to new file", parsedValidFiles[0])
                parsedValidFiles.pop(0)

            #-------------------------rewrite this shit code above to take less lines, this looks abyssmal---------------

            finalTime = totalTime - deviationTime

            if(directionSplit[0] == ''):
                continue
            if (directionSplit[0] == IP_host):
                direction = 's'
            elif(directionSplit[1] == IP_host):
                direction = 'r'
            else: 
                checkIfLocal = directionSplit[0].split('.')
                if checkIfLocal[0] == '10':
                    IP_host = directionSplit[0]
                else: IP_host = directionSplit[1]
            #if(int(splitParseLine[2]) > 1420): splitParseLine[2] = '1420\n'

            splitCrossLine = crossLine[0].split(",")

            packetSize = str(int(splitParseLine[2])-header)

            if(finalTime < int(splitCrossLine[0])):
                newFile.writelines([str(finalTime), ",", direction, ",", packetSize, "\n"])
                saveTime = totalTime
            else:
                newFile.writelines(crossLine[0])
                crossLine.pop(0)
        print("out of lines in", fileToParsePath, "closing", fileToParse)
        deviationTime = 0
        fileToParse.close()
    print("popping", filesToParse[0])
    filesToParse.pop(0)
    print("now first one is: ", filesToParse[0])
