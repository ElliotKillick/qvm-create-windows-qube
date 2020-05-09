#!/usr/bin/python3

"""Modify settings of answer file"""

import argparse
import sys
import lxml.etree
import constants

def setting_to_xpath(setting):
    """Convert setting name to xpath of its location"""

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

def write_xml_file(xml_tree, xml_file):
    """Write XML tree to file"""

    # Try to create minimal diff between formatting of original XML document
    xml_tree.write(xml_file, encoding='UTF-8', pretty_print=True,
                   doctype='<?xml version="1.0" encoding="utf-8"?>')

def main():
    """Program entry point"""

    parser = argparse.ArgumentParser()
    parser.add_argument('-s', '--setting', type=str, required=True,
                        help='Setting to change in answer file: image, admin_password')
    parser.add_argument('-v', '--value', type=str, required=True,
                        help='New value of setting')
    parser.add_argument('-a', '--answer-file', type=argparse.FileType('r'), required=True,
                        help='Settings for Windows installation')
    args = parser.parse_args()

    xpath = setting_to_xpath(args.setting)
    xml_tree = lxml.etree.parse(args.answer_file.name, constants.SAFE_PARSER)
    old_value = get_answer_file_value_at_xpath(xpath, xml_tree)

    old_value.text = args.value

    write_xml_file(xml_tree, args.answer_file.name)

if __name__ == '__main__':
    main()
