{ pkgs, lib, config, ... }:
with lib;
{
	options.myModules.asterisk.enable = mkEnableOption "custom asterisk configuration";

	config = mkIf config.myModules.asterisk.enable {
		networking.firewall = {
			allowedTCPPorts = [ 5060 ];
			allowedUDPPortRanges = [
				{ from=1000; to=20000; }
			];
			allowedUDPPorts = [ 4569 5060 ];
		};
		services.asterisk = {
			enable = true;
			confFiles = {
				"extensions.conf" = ''
[from-internal]
; dial the lecture rooms & backoffice
; the syntax is NUMBER,SEQUENCE,FUNCTION
; to call someone do Dial(MODULE/account, timeout)
exten => 1001,1,Dial(PJSIP/saal1,20)
exten => 1002,1,Dial(PJSIP/saal2,20)
exten => 1600,1,Dial(PJSIP/backoffice,20)

; Dial 100 for "hello, world"
; this is useful when configuring/debugging clients (snoms)
exten => 100,1,Answer()
same  =>     n,Wait(1)
same  =>     n,Playback(hello-world)
same  =>     n,Hangup()
; note: "n" is a keyword meaning "the last line's value, plus 1"
; "same" is a keyword referring to the last-defined extension
'';
				"pjsip.conf" = ''
; we use UDP for transport
[transport-udp]
type=transport
protocol=udp
bind=0.0.0.0

; Note: this defines a macro, to shorten the config further down
[endpoint_internal](!)
type=endpoint
context=from-internal
disallow=all
allow=ulaw

[auth_userpass](!)
type=auth
auth_type=userpass

[aor_dynamic](!)
type=aor
max_contacts=1


; here come the definitions for our phones, using the macros from above

; lecture hall 1
[saal1](endpoint_internal)
auth=saal1
aors=saal1
[saal1](auth_userpass)
; well, maybe set a better password than this
password=saal1
username=saal1
[saal1](aor_dynamic)

; lecture hall 2
[saal2](endpoint_internal)
auth=saal2
aors=saal2
[saal2](auth_userpass)
password=saal2
username=saal2
[saal2](aor_dynamic)

[backoffice](endpoint_internal)
auth=backoffice
aors=backoffice
[backoffice](auth_userpass)
password=backoffice
username=backoffice
[backoffice](aor_dynamic)
'';
				"logger.conf" = ''
[general]

[logfiles]
; Add debug output to log
syslog.local0 => notice,warning,error,debug
'';
			};
		};
	};
}
