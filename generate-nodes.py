#!/usr/bin/python
import yaml
import json
import argparse
from pprint import pprint

def getStopStation(stop):
	if type(stop) is list:
		return stop[0]
	else:
		return stop

def removeCorners(lines):
	for linename,line in lines.iteritems():
		stops = []
		for stop in line["stops"]:
			if not(type(getStopStation(stop)) is int):
				stops.append(stop)
		line["stops"]=stops
		lines[linename] = line
	return lines

parser = argparse.ArgumentParser(description='''
Generates a json file containing node link information,
to be used to determine fastest route.''')
parser.add_argument('inputfile', metavar='INPUT', type=str, help='input yaml file')
parser.add_argument('outputfile', metavar='OUTPUT', type=str, help='output json file')
parser.add_argument('--javascript', action='store_true', help='output valid js file hack')
parser.add_argument('--quiet', action='store_true', help='suppress JSON on stdout')
args = parser.parse_args()

yaml_file = open(args.inputfile, 'r')
yaml_data = yaml.load(yaml_file)
yaml_file.close()

stations = yaml_data["stations"]
lines = yaml_data["lines"]

lines = removeCorners(lines)

for station in stations:
	stations[station]["destinations"] = []

for linename,line in lines.iteritems():
	previous = ""
	for stopindex, stop in enumerate(line["stops"]):
		if stopindex > 0 or line["flow"] == "loop":
			previousStation = getStopStation(line["stops"][stopindex-1])
			stations[getStopStation(stop)]["destinations"].append(previousStation)
		try:
			if line["flow"] == "loop" and stopindex+1 > len(line["stops"])-1:
				nextStation = getStopStation(line["stops"][0])
			else:
				nextStation = getStopStation(line["stops"][stopindex+1])
			stations[getStopStation(stop)]["destinations"].append(nextStation)
		except IndexError:
			pass

if not(args.quiet):
	pprint(stations)
json_file = open(args.outputfile, 'w')
if args.javascript:
	json_file.write("stations =")
json.dump(stations, json_file)
if args.javascript:
	json_file.write(";")
json_file.close()
