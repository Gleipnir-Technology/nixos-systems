# Example to create a bios compatible gpt partition
{ lib, ... }:
{
	disko.devices = {
		disk = {
			sda = {
				device = "/dev/sda";
				type = "disk";
				content = {
					type = "gpt";
					partitions = {
						MBR = {
							size = "1M";
							type = "EF02"; # for grub MBR
						};
						boot = {
							size = "500M";
							type = "EF00"; # for grub MBR
							content = {
								type = "filesystem";
								format = "vfat";
								mountpoint = "/boot";
								mountOptions = [
									"defaults"
								];
							};
						};
						root = {
							size = "100%";
							content = {
								type = "lvm_pv";
								vg = "pool";
							};
						};
					};
				};
			};
			sdb = {
				device = "/dev/sdb";
				type = "disk";
				content = {
					type = "gpt";
					partitions = {
						bigdisk = {
							size = "100%";
							content = {
								type = "filesystem";
								format = "ext4";
								mountpoint = "/mnt/bigdisk";
								mountOptions = [
									"defaults"
								];
							};
						};
					};
				};
			};
		};
		lvm_vg = {
			pool = {
				type = "lvm_vg";
				lvs = {
					root = {
						size = "50G";
						content = {
							type = "filesystem";
							format = "ext4";
							mountpoint = "/";
							mountOptions = [
								"defaults"
							];
						};
					};
					var = {
						size = "100%FREE";
						content = {
							type = "filesystem";
							format = "ext4";
							mountpoint = "/var";
							mountOptions = [
								"defaults"
							];
						};
					};
				};
			};
		};
	};
}
