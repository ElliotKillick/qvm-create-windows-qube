#!/usr/bin/python3

"""Selects and modifies answer file to use given Windows image name"""

import argparse
import os
import sys
from difflib import SequenceMatcher
import lxml.etree
import subprocess
import Levenshtein

# Beware XXE is enabled by default: https://bugs.launchpad.net/lxml/+bug/1742885
safe_parser = lxml.etree.XMLParser(resolve_entities=False)

def get_wim_image_names(wim):
    wiminfo = subprocess.check_output(['wiminfo', '--xml', wim], encoding='utf-16-le')
    wiminfo_tree = lxml.etree.fromstring(wiminfo, safe_parser)

    wim_image_elements = wiminfo_tree.xpath('/WIM/IMAGE/NAME')

    wim_image_names = []
    for wim_image_element in wim_image_elements:
        wim_image_names.append(wim_image_element.text)

    return wim_image_names

def get_answer_file_image_names():
    answer_file_images = []

    for entry in os.scandir('../answer-files'):
        tree = lxml.etree.parse(entry.path, safe_parser)
        answer_file_image = tree.xpath(('/u:unattend/u:settings/u:component/u:ImageInstall'
                                        '/u:OSImage/u:InstallFrom/u:MetaData/u:Value'),
                                        namespaces={'u': 'urn:schemas-microsoft-com:unattend'})
        answer_file_images.append(answer_file_image[0].text)

    return answer_file_images

# This is a classic classification problem we could potentially utilize machine learning to solve
# However,
# 1. This is probably overkill; and
# 2. Bigger data would most likely be required to create a good classification model
def similar(str_a, str_b):
    """
    Get float value of how similar two strings are

    https://stackoverflow.com/questions/17388213/find-the-similarity-metric-between-two-strings
    """

    return SequenceMatcher(None, str_a, str_b).ratio()

def main():
    """Program entry point"""

    parser = argparse.ArgumentParser()
    parser.add_argument('-w', '--wim', type=argparse.FileType('r'), required=True,
                        help='Windows image (WIM) file')
    args = parser.parse_args()

    wim_images = get_wim_image_names(args.wim.name)

    #for wim_image in wim_images:
    #    print(wim_image)

    answer_file_images = get_answer_file_image_names()

    #for answer_file_image in answer_file_images:
    #    print(answer_file_image)

    # Make 2D list (list of lists)
    w, h = answer_file_images.len(), wim_image_names.len()
    match_scores = [[0 for x in range(w)] for y in range(h)]

    for wim_image_name in wim_image_names:
        for answer_file_name in answer_file_names:
            match_scores[answer_file_name][wim_in] = similar(wim_image_name, answer_file_name)

    #match_ratios.append(similar(args.image, image_val))

    # Pass in wim, loop through available images on that
    # TODO: If WIM "Image/Name" property is empty then fallback to the "Description" property
    # e.g. The property does not exist in our Windows 7 ISO

    #best_match_indicies = [i for i, x in enumerate(match_ratios) if x == max(match_ratios)]

    print("Best match(es): ", file=sys.stderr)
    for x in best_match_indicies:
        print(answer_files[x], sep='\n')

    if len(best_match_indicies) != 1:
        print("[!] Multiple best matches, using first one", file=sys.stderr)

    answer_file = answer_files[best_match_indicies[0]]

    print(answer_file)

if __name__ == '__main__':
    main()
