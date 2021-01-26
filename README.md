# Dependency Checker

This utility is to be paired with the kiosk-build-tool in order to ensure the build environment has the necessary dependencies to function.

# Setup

1. Create two files in which the utility can read from. By default it looks for these: 

* `packages.txt`
* `programs.txt`

    You can decide to pass it new files as part of the arguments.

    Each file lists the name of the packages or programs that the dependency checker will look for within that environment.