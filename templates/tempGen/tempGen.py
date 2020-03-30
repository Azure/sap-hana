import os, sys, argparse
import json

# function to update baseJSON with updateJSON
def mergeJSON(baseJSON, updateJSON, path=None):
    if path is None: path = []
    for key in updateJSON:
        if key in baseJSON:
            if isinstance(baseJSON[key], dict) and isinstance(updateJSON[key], dict):
                t = mergeJSON(baseJSON[key], updateJSON[key], path + [str(key)])
            elif isinstance(baseJSON[key], list) and isinstance(updateJSON[key], list):
                path += [str(key)]
                for i in range(len(baseJSON[key])):
                    mergeJSON(baseJSON[key][i], updateJSON[key][i], path)
            elif baseJSON[key] == updateJSON[key]:
                pass
            else:
            	baseJSON[key] = updateJSON[key]
        else:
            baseJSON[key] = updateJSON[key]
    return baseJSON

def main():
	parser = argparse.ArgumentParser(description="Create input JSON for terraform")
	parser.add_argument('--custom', dest='filenameCustom', default='custom.json', help='custom JSON file that will overwrite the template')
	parser.add_argument('--template', dest='filenameTemplate', default='template.json', help='template JSON file')
	parser.add_argument('--output', dest='filenameOutput', default='output.json', help='output (merged) JSON file')
	args = parser.parse_args()

	with open(args.filenameCustom) as f:
		jsonCustom = json.load(f)
	with open(args.filenameTemplate) as f:
		jsonTemplate = json.load(f)

	jsonMerged = mergeJSON(jsonTemplate, jsonCustom)

	with open(args.filenameOutput, 'w') as f:
	    json.dump(jsonMerged, f, indent=4, sort_keys=True)

if __name__ == "__main__":
   main()