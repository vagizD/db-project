#!/usr/bin/env sh

echo '---- FORMATTING ----'
echo '--BLACK--' && python3 -m black environment/init-db logic;
echo '--ISORT--' && python3 -m isort environment/init-db logic;
echo '--FLAKE8--' && python3 -m flake8 environment/init-db logic;