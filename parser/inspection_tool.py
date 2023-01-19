#!/usr/bin/env python

import os
from os import walk
import time

minutes = 60
nanoseconds = 1000000000
saveTime = time.time()

newFile = []
crossLine = []
filesToParse = []
x = 0      

spanLimit = [0]
instances = [0]

masterFile = os.path.join(os.getcwd(), "filesToParse")
spanDirectory = os.path.join(os.getcwd(), "spanLimit")

for (dirpath, dirnames, filenames) in walk(masterFile, topdown=True):
    for files in filenames:
        filesToParse.append(os.path.join(masterFile, files))
    print(filesToParse)    
for fileToParsePath in filesToParse:
    with open(fileToParsePath, 'r') as fileToParse:
        for parseLine in fileToParse: #Reading line by line from the master file since it might be to large to do readlines() on
            
            splitParseLine = parseLine.split("\t")
            parseLineTime = splitParseLine[0].split('.')
            seconds  = int(parseLineTime[0]) * nanoseconds
            final = seconds + int(parseLineTime[1])

            if(final <= spanLimit[x]): 
                instances[x] += 1
            else: 
                spanLimit.append(10*(x)*minutes*nanoseconds)
                instances.append(0)
                x += 1
        else:
            print("out of lines!")
os.mkdir(spanDirectory)
newPath = os.path.join(spanDirectory, "spans.txt")

newFile = open(newPath, 'a')
i = 0
for span in spanLimit:
    newFile.writelines("time in minutes: ")
    newFile.writelines(str(((span/nanoseconds)/minutes)))
    newFile.writelines("\t")
    newFile.writelines("timestamps: ")
    newFile.writelines(str(instances[i]))
    newFile.writelines("\n")
    i += 1

print("done in", saveTime, "seconds")