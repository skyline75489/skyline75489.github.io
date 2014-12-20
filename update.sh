#! /bin/sh
cd ../genie
python2.7 genie.py
cd ../skyline75489.github.io
git add -A
git commit -a -m "update"
git push origin master
