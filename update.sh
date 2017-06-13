#! /bin/sh
cd ../genie
python3 genie.py
cd ../skyline75489.github.io
git add -A
git commit -a -m "update `date`"
git push origin master
