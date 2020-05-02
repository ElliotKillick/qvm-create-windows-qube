#!/usr/bin/python3

"""Modify answer file to use given image"""

import argparse
import lxml.etree

def main():
    """Program entry point"""

    parser = argparse.ArgumentParser()
    parser.add_argument('-a', '--answer-file', type=argparse.FileType('r'), required=True,
                        help='Settings for automatic Windows installation')
    parser.add_argument('-i', '--image', type=str, required=True,
                        help='Image name inside Windows image (WIM)')
    args = parser.parse_args()

    # Beware XXE is enabled by default: https://bugs.launchpad.net/lxml/+bug/1742885
    safe_parser = lxml.etree.XMLParser(resolve_entities=False)

    tree = lxml.etree.parse(args.answer_file.name, safe_parser)
    image = tree.xpath(('/u:unattend/u:settings/u:component/u:ImageInstall'
                        '/u:OSImage/u:InstallFrom/u:MetaData/u:Value'),
                       namespaces={'u': 'urn:schemas-microsoft-com:unattend'})

    image[0].text = args.image

    tree.write(args.answer_file.name, encoding='UTF-8', pretty_print=True,
               doctype='<?xml version="1.0" encoding="utf-8"?>')

if __name__ == '__main__':
    main()
