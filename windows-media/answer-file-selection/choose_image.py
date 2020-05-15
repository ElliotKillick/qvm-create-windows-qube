#!/usr/bin/python3

"""Get and/or validate Windows edition image name or number"""

import argparse
import sys
import common

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-w', '--wim', type=argparse.FileType('r'), required=True,
                        help='Windows Imaging Format (WIM) file')
    parser.add_argument('-i', '--image', type=str,
                        help='Image name or number in WIM')
    return parser.parse_args()

def print_numbered_list(items):
    """Print a numbered list of the given items"""

    for num, item in enumerate(items):
        print(num + 1, ') ', item, sep='', file=sys.stderr)

def get_edition_image_name(wim_images):
    """Get and validate input of Windows edition image number/name"""

    image_name = None

    while image_name is None:
        image = input('Please select which edition of Windows to install: ')
        image_name = validate_image_num_name(image, wim_images)

    return image_name

def validate_image_num_name(image, wim_images):
    """Validate Windows edition image number/name"""

    image_name = None

    if image.isdigit():
        try:
            image_name = wim_images[int(image) - 1]
        except IndexError:
            print('Image number does not exist:', image, file=sys.stderr)
    else:
        if image in wim_images:
            image_name = image
        else:
            print('Image name does not exist:', image, file=sys.stderr)

    return image_name

def main():
    """Program entry point"""

    args = parse_args()

    print('[i] Detecting editions of Windows on media...', file=sys.stderr)

    wim_images = common.get_wim_image_names(args.wim.name)

    edition_image_name = None

    if args.image is not None:
        edition_image_name = validate_image_num_name(args.image, wim_images)

    if edition_image_name is None:
        print_numbered_list(wim_images)
        edition_image_name = get_edition_image_name(wim_images)

    print(edition_image_name)

if __name__ == '__main__':
    main()
