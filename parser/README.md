The files which we inject the data into is places in crossFiles. (web traffic dataset)
The files we want to inject is placed in filesToParse. (noise traffic data)
parsedFiles will contain the more realistic dataset after finishing running tshark_parse-n-inject.py
	requires cross files and files to parse
spanLimit will contain a text file with timestamps per timespan after running inspection_tool.py
	requires files to parse
parser.py is the first version of the parser, used on our old tcpdump files