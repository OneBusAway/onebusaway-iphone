# Build Instructions

1. Clone the repository.
1. Execute the following Git commands to pull in external project dependencies:

    git submodule init
    git submodule update

1. Open the `onebusaway-iphone-workspace.xcworkspace` workspace file.
1. Under `File > Workspace Settings...`, make sure that for "Build Locations", "Place build products in derived data location" is selected.

You should now be able to build.
