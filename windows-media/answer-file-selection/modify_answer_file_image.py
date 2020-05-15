#!/usr/bin/python3

"""Modify settings of answer file"""

import argparse
import sys
import lxml.etree
import common

def main():
    """Program entry point"""

    args = parse_args()

    xpath = setting_to_xpath(args.setting)
    xml_tree = lxml.etree.parse(args.answer_file.name, common.SAFE_PARSER)
    old_value = get_answer_file_value_at_xpath(xpath, xml_tree)

    old_value.text = args.value

    write_answer_file(xml_tree, args.answer_file.name)

def parse_args():
    """Parse command-line arguments"""

    parser = argparse.ArgumentParser()
    parser.add_argument('-s', '--setting', type=str, required=True,
                        help='Setting to change in answer file: image, admin_password')
    parser.add_argument('-v', '--value', type=str, required=True,
                        help='New value of setting')
    parser.add_argument('-a', '--answer-file', type=argparse.FileType('r'), required=True,
                        help='Settings for Windows installation')
    return parser.parse_args()

def setting_to_xpath(setting):
    """Convert setting name to answer file xpath location"""

    setting_to_xpath_dict = {
        'image': ('/u:unattend/u:settings/u:component/u:ImageInstall'
                  '/u:OSImage/u:InstallFrom/u:MetaData/u:Value'),
        'admin_password': ('/u:unattend/u:settings/u:component/u:UserAccounts'
                           '/u:AdministratorPassword/u:Value')
    }
    try:
        return setting_to_xpath_dict[setting]
    except KeyError:
        print('Setting does not exist:', setting, file=sys.stderr)
        sys.exit(1)

def get_answer_file_value_at_xpath(xpath, xml_tree):
    """Get value of answer file at XPath"""

    return xml_tree.xpath(xpath, namespaces={'u': 'urn:schemas-microsoft-com:unattend'})[0]

def write_answer_file(xml_tree, answer_file_name):
    """Write XML tree to answer file"""

    # Try to create minimal diff between formatting of original answer file for consistency
    # i.e. Output of Windows AIK/ADK
    xml_tree.write(answer_file_name, encoding='UTF-8', pretty_print=True,
                   doctype='<?xml version="1.0" encoding="utf-8"?>')

if __name__ == '__main__':
    main()
