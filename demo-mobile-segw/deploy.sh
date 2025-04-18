#!/bin/bash

containerlab deploy

echo "Press <Enter> to jump in the screen"
read
screen -c screenrc
