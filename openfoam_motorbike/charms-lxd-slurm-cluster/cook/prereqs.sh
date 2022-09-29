#!/bin/bash


set -eux

## 1) Install and configure LXD
sudo snap install lxd
sudo lxd init --auto
sudo lxc network set lxdbr0 ipv6.address none

## 2) Install Juju client and bootstrap the LXD provider
sudo snap install juju --classic
juju bootstrap localhost

## 3) Install charmcraft
sudo snap install charmcraft --classic

## 4) Install jq
sudo snap install jq

## 5) Install git
sudo apt-get install git -y
