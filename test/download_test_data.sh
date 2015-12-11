#!/bin/bash -e

mkdir -p data
cd data

if [ -f data_downloaded ]; then
  echo "Skipping test data download"
else
  echo "Downloading test data..."
  curl -O http://hubblesource.stsci.edu/sources/video/clips/details/images/centaur_1.mpg
  touch data_downloaded
  echo "Test data downloaded successfully"
fi
