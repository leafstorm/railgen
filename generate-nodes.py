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

parser = argparse.ArgumentParser(description='''
Generates a json file containing node link information,
to be used to determine fastest route.''')
parser.add_argument('inputfile', metavar='INPUT', type=str, help='input yaml file')
parser.add_argument('outputfile', metavar='OUTPUT', type=str, help='output json file')
args = parser.parse_args()

yaml_file = open(args.inputfile, 'r')
yaml_data = yaml.load(yaml_file)
yaml_file.close()

stations = yaml_data["stations"]
lines = yaml_data["lines"]

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
			
pprint(stations)
json_file = open(args.outputfile, 'w')
json.dump(stations, json_file)
json_file.close()