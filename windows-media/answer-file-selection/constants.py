#!/usr/bin/python3

"""Constants used in answer-file-selection"""

import subprocess
import lxml.etree

# Beware, XML External Entities (XXEs) are enabled by default:
# https://bugs.launchpad.net/lxml/+bug/1742885
SAFE_PARSER = lxml.etree.XMLParser(resolve_entities=False)

def get_wim_image_names(wim):
    """Get a list of all the image names in a WIM"""

    wiminfo = subprocess.check_output(['wiminfo', '--xml', wim], encoding='utf-16-le')
    wiminfo_tree = lxml.etree.fromstring(wiminfo, SAFE_PARSER)

    wim_image_elements = wiminfo_tree.xpath('/WIM/IMAGE/NAME')

    wim_image_names = []
    for wim_image_element in wim_image_elements:
        wim_image_names.append(wim_image_element.text)

    return wim_image_names
