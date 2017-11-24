readmeURL = "https://github.com/openwrt/packages/tree/master/net/vpn-policy-routing/files/README.md"
readmeURL = "https://github.com/stangri/openwrt-packages/blob/vpn-policy-routing/net/vpn-policy-routing/files/README.md"

-- function log(obj)
-- 	if obj ~= nil then if type(obj) == "table" then luci.util.dumptable(obj) else luci.util.perror(obj) end else luci.util.perror("Empty object") end
-- end

-- General options
c = Map("vpn-policy-routing", translate("OpenVPN/WAN Policy-Based Routing"))
s1 = c:section(NamedSection, "config", "vpn-policy-routing", translate("General"))
s1.rmempty  = false

e = s1:option(Flag, "enabled", translate("Enable/start service"))
e.rmempty  = false

function e.cfgvalue(self, section)
	return self.map:get(section, "enabled") == "1" and luci.sys.init.enabled("vpn-policy-routing") and self.enabled or self.disabled
end

function e.write(self, section, value)
	if value == "1" then
		luci.sys.call("/etc/init.d/vpn-policy-routing enable >/dev/null")
		luci.sys.call("/etc/init.d/vpn-policy-routing start >/dev/null")
	else
		luci.sys.call("/etc/init.d/vpn-policy-routing stop >/dev/null")
		luci.sys.call("/etc/init.d/vpn-policy-routing disable >/dev/null")
	end
	return Flag.write(self, section, value)
end

v = s1:option(ListValue, "verbosity", translate("Output verbosity"),translate("Controls both system log and console output verbosity"))
v:value("0", translate("Suppress output"))
v:value("1", translate("Some output"))
v:value("2", translate("Verbose output"))
v.rmempty = false
v.default = 2

se = s1:option(ListValue, "strict_enforcement", translate("Strict enforcement"),translate("See ")
  .. [[<a href="]] .. readmeURL .. [[#strict-enforcement" target="_blank">]]
  .. translate("README") .. [[</a>]] .. translate(" for details"))
se:value("0", translate("Do not enforce policies when their gateway is down"))
se:value("1", translate("Strictly enforce policies when their gateway is down"))
se.rmempty = false
se.default = 1

-- ipv6 = s1:option(ListValue, "ipv6_enabled", translate("IPv6 Support"))
-- ipv6:value("0", translate("Disabled"))
-- ipv6:value("1", translate("Enabled"))
-- ipv6.rmempty = false
-- ipv6.default = 0
--
dnsmasq = s1:option(ListValue, "dnsmasq_enabled", translate("Use DNSMASQ for domain policies"),
	translate("Please check the "
  .. [[<a href="]] .. readmeURL .. [[#use-dnsmasq" target="_blank">]]
  .. translate("README") .. [[</a>]] .. translate(" before enabling this option.")))
dnsmasq:value("0", translate("Disabled"))
dnsmasq:value("1", translate("Enabled"))
dnsmasq.rmempty = false
dnsmasq.default = 0

icmp = s1:option(ListValue, "icmp_interface", translate("ICMP (ping) Interface"))
icmp.default = ""
icmp:value("", translate("Default/No Change"))
icmp:value("wan", "WAN")
luci.model.uci.cursor():foreach("network", "interface", function(s)
	local name=s['.name']
	local ifname=s['ifname']
	local proto=s['proto']
	if name then
		if ifname and string.sub(ifname,0,3) == "tun" then icmp:value(name,string.upper(name)) end
		if proto and string.sub(proto,0,9) == "wireguard" then icmp:value(name,string.upper(name)) end
	end
end)


-- Policies
p = Map("vpn-policy-routing")
p.template="cbi/map"

s3 = p:section(TypedSection, "policy", translate("Policies"), translate("Comment, interface and at least one other field are required. Local and remote addresses/devices/domains and ports can be space or semi-colon separated. Placeholders below represent just the format/syntax and will not be used if fields are left blank."))
s3.template = "cbi/tblsection"
s3.sortable  = false
s3.anonymous = true
s3.addremove = true

s3:option(Value, "comment", translate("Comment"))

la = s3:option(Value, "local_addresses", translate("Local addresses/devices"))
if uci.cursor():get("network", "lan", "ipaddr") and uci.cursor():get("network", "lan", "netmask") then
	la.placeholder = luci.ip.new(uci.cursor():get("network", "lan", "ipaddr") .. "/" .. uci.cursor():get("network", "lan", "netmask"))
end
la.rmempty = true

lp = s3:option(Value, "local_ports", translate("Local ports"))
lp.datatype    = "list(neg(portrange))"
lp.placeholder = "0-65535"
lp.rmempty = true

ra = s3:option(Value, "remote_addresses", translate("Remote addresses/domains"))
ra.placeholder = "0.0.0.0/0"
ra.rmempty = true

rp = s3:option(Value, "remote_ports", translate("Remote ports"))
rp.datatype    = "list(neg(portrange))"
rp.placeholder = "0-65535"
rp.rmempty = true

gw = s3:option(ListValue, "interface", translate("Interface"))
-- gw.datatype = "network"
gw.rmempty = false
gw.default = "wan"
gw:value("wan","WAN")
luci.model.uci.cursor():foreach("network", "interface", function(s)
	local name=s['.name']
	local ifname=s['ifname']
	local proto=s['proto']
	if name then
		if ifname and string.sub(ifname,0,3) == "tun" then gw:value(name, string.upper(name)) end
		if proto and string.sub(proto,0,9) == "wireguard" then gw:value(name, string.upper(name)) end
	end
end)

dscp = Map("vpn-policy-routing")
s6 = dscp:section(NamedSection, "config", "vpn-policy-routing", translate("DSCP Tagging"), translate("Set DSCP tags (in range between 1 and 63) for specific interfaces."))
wan = s6:option(Value, "wan_dscp", translate("WAN DSCP Tag"))
wan.datatype = "range(1, 63)"
wan.rmempty = true
luci.model.uci.cursor():foreach("network", "interface", function(s)
	local name=s['.name']
	local ifname=s['ifname']
	local proto=s['proto']
	if name then
		if ifname and string.sub(ifname,0,3) == "tun" then s6:option(Value, name .. "_dscp", string.upper(name) .. " " .. translate("DSCP Tag")).rmempty = true end
		if proto and string.sub(proto,0,9) == "wireguard" then s6:option(Value, name .. "_dscp", string.upper(name) .. " " .. translate("DSCP Tag")).rmempty = true end
	end
end)

return c, p, dscp
