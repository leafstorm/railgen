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
args = parser.parse_args()

yaml_file = open(args.inputfile, 'r')
yaml_data = yaml.load(yaml_file)

stations = yaml_data["stations"]
lines = yaml_data["lines"]

for station in stations:
	stations[station]["destinations"] = []

for linename,line in lines.iteritems():
	if line["flow"] == "twoway":
		previous = ""
		for stopindex, stop in enumerate(line["stops"]):
			try:
				stations[getStopStation(stop)]["destinations"].append(getStopStation(line["stops"][stopindex-1]))
			except IndexError:
				pass
			try:
				stations[getStopStation(stop)]["destinations"].append(getStopStation(line["stops"][stopindex+1]))
			except IndexError:
				pass
			
pprint(stations)