#!/usr/bin/env python3

import sys


REQUIRED_MAJOR_V = 3
REQUIRED_MINOR_V = 10


def main():
    version = sys.version_info
    is_suitable_version = (
        version.major == REQUIRED_MAJOR_V and version.minor >= REQUIRED_MINOR_V
    )

    if not is_suitable_version:
        print(
            "Required python version is {}.{}+".format(
                REQUIRED_MAJOR_V, REQUIRED_MINOR_V
            )
        )
        exit(1)


if __name__ == "__main__":
    main()
