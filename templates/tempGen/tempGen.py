import os, sys, argparse
import json

# function to update JSON a with b
def mergeJSON(a, b, path=None):
    if path is None: path = []
    for key in b:
        if key in a:
            if isinstance(a[key], dict) and isinstance(b[key], dict):
                mergeJSON(a[key], b[key], path + [str(key)])
            elif a[key] == b[key]:
                pass
            else:
            	a[key] = b[key]
        else:
            a[key] = b[key]
    return a

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