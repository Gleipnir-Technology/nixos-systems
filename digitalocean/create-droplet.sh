doctl compute droplet create \
	"test.nidus.cloud" \
	--enable-ipv6 \
	--image debian-12-x64 \
	--project-id ce2159e8-02f5-4169-8943-f34ccf812d23 \
	--region sfo3 \
	--size s-1vcpu-1gb \
	--ssh-keys 48777034,46710608 \
	--tag-name nixos \
	--wait

