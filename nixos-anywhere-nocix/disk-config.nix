# Example to create a bios compatible gpt partition
{ lib, ... }:
{
	disko.devices = {
		disk = {
			sdb = {
				device = "/dev/sdb";
				type = "disk";
				content = {
					type = "table";
					format = "mbr";
					partitions = {
						boot = {
							size = "500M";
							type = "EF02"; # for grub MBR
							attributes = [ 0 ]; # partition attribute
						};
						root = {
							size = "100%";
							content = {
								type = "filesystem";
								format = "ext4";
								mountpoint = "/";
							};
						};

					};
				};
			};
		};
	};
}
