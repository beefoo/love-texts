# -*- coding: utf-8 -*-

# Description:
#   Reads an xml dump of texts and allows user to manually categorize each text
#
# Example usage:
#   python analyze_texts.py data/texts_2015-03-31_2015-07-11.xml data/categories.json output/texts_2015-03-31_2015-07-11.json 0

from datetime import datetime
import json
import os.path
from pprint import pprint
import sys
import urllib
import xml.etree.ElementTree

# input
if len(sys.argv) < 4:
    print "Usage: %s <inputfile texts> <inputfile categories> <outputfile> <reset file>" % sys.argv[0]
    sys.exit(1)
TEXTS_FILE = sys.argv[1]
CATEGORIES_FILE = sys.argv[2]
OUTPUT_FILE = sys.argv[3]
RESET_FILE = int(sys.argv[4])

# config
DATE_FORMAT = '%Y-%m-%d %H:%M:%S'

# init
messages = []
categories = []

# is integer?
def is_int(s):
    try:
        int(s)
        return True
    except ValueError:
        return False

# save messages
def saveMessages(the_file, the_messages):

    with open(the_file, 'w') as outfile:
        json.dump(the_messages, outfile)

# retrieve categories from file
with open(CATEGORIES_FILE) as data_file:
    categories = json.load(data_file)
    print('Retrieved '+str(len(categories))+' categories from file: ' + CATEGORIES_FILE)

# output file already exists, so read that
if not RESET_FILE and os.path.isfile(OUTPUT_FILE):

    with open(OUTPUT_FILE) as data_file:
        messages = json.load(data_file)
        print('Retrieved '+str(len(messages))+' messages from file: ' + OUTPUT_FILE)

# otherwise, start fresh
else:

    # parse message tree
    tree = xml.etree.ElementTree.parse(TEXTS_FILE).getroot()
    for message_node in tree.iter('message'):
        message = {}
        message['body'] = urllib.unquote_plus(message_node.find('body').text)
        message['date'] = datetime.fromtimestamp(int(message_node.find('date').text[0:-3])).strftime(DATE_FORMAT)
        message['person'] = int(message_node.find('type').text)
        message['categories'] = []
        messages.append(message)

    # sort messages
    messages = sorted(messages, key=lambda k: k['date'])

    # immediately save the file
    saveMessages(OUTPUT_FILE, messages)
    print('Saved '+str(len(messages))+' messages to file: ' + OUTPUT_FILE)

# go through each message and prompt user for category
for mi, message in enumerate(messages):

    # skip if already categorized
    if len(message['categories']) > 0:
        continue

    # Show the user the message and category options
    print 'Person ' + str(message['person']) + ': ' + message['body']
    for ci, c in enumerate(categories):
        print(' ' + str(ci) + '. ' + c['name'])

    # retrieve selection and save
    message_categories = []
    selection = raw_input('Your selection: ')
    if len(selection):

        # retrieve valid categories
        category_selections = selection.split(',')
        for ci in category_selections:
            if is_int(ci) and int(ci) < len(categories):
                message_categories.append(categories[int(ci)]["name"])

    # save messages
    messages[mi]['categories'] = message_categories
    saveMessages(OUTPUT_FILE, messages)
    print str(round(float(mi+1)/len(messages)*100, 2)) + '% complete'
