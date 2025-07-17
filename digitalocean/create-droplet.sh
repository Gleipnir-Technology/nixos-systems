#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash
set -xe
NAME="test.nidus.cloud"
PROJECT="1782f0e0-0968-4fe2-ac7d-192584ec7ce5"
REGION="sfo3"
SIZE="s-1vcpu-2gb"
#SIZE="s-1vcpu-1gb" \
SSH_KEYS="48777034,46710608"
TAGS="nixos,test"
doctl compute droplet create \
	$NAME \
	--enable-ipv6 \
	--image debian-12-x64 \
	--project-id $PROJECT\
	--region $REGION \
	--size $SIZE\
	--ssh-keys $SSH_KEYS\
	--tag-name $TAGS \
	--wait
