#!/usr/bin/lua

require "nixio.fs"

print ("Content-type: Text/html\n")
local info = os.getenv("QUERY_STRING")

local params = {}
local echo = {}

function print_row(key)
	print ("<tr><th>")
	print (key)
	print ("</th><td>")
	print (device[key])
	print ("</td></tr>")
end

for name, value in string.gmatch(info .. '&', '(.-)%=(.-)%&') do
    value = string.gsub(value , '%+', ' ')
    value = string.gsub(value , '%%(%x%x)', function(dpc)
        return string.char(tonumber(dpc,16))
		end )
	params[name] = value

    value = string.gsub(value, "%&", "&amp;")
    value = string.gsub(value, "%<", "&lt;")
    value = string.gsub(value, '%"', "&quot;")
    echo[name] = value
end

device = {}
profile = {}

if nixio.fs.access("/var/lib/noddos/DeviceDump.json") then
        io.input("/var/lib/noddos/DeviceDump.json")
        local t = io.read("*all")
        local json = require "dkjson"
        local devdump = json.decode(t)
        for i, v in ipairs(devdump) do
				if v.MacAddress == params["mac"] then
                        device = v
                end
        end
        io.input("/var/lib/noddos/DeviceProfiles.json")
        t = io.read("*all")
        local temp = json.decode(t)
        for i, v in ipairs(temp) do
                if device.DeviceProfileUuid == v.DeviceProfileUuid then
                        profile = v
                end
        end
end
pagetop = [[
<html>
  <head>
    <title>Client Details by Nddos</title>
    <meta charset="utf-8">
    <!--[if lt IE 9]><script src="/luci-static/bootstrap/html5.js?v=git-17.100.70571-29fabe2"></script><![endif]-->
    <meta name="viewport" content="initial-scale=1.0">
    <link rel="stylesheet" href="/luci-static/bootstrap/cascade.css?v=git-17.100.70571-29fabe2">
    <link rel="stylesheet" media="only screen and (max-device-width: 854px)" href="/luci-static/bootstrap/mobile.css?v=git-17.100.70571-29fabe2" type="text/css" />
    <link rel="shortcut icon" href="/luci-static/bootstrap/favicon.ico">
    <script src="/luci-static/resources/xhr.js?v=git-17.100.70571-29fabe2"></script>
  </head>
  <body text=blue>
    <h1>Client Details</h1>
]]
print (pagetop)

if params["mac"] ~= nil then
	print ("<table>")
	for i, key in ipairs{"MacAddress", "Ipv4Address", "Ipv6Address", "DeviceProfileUuid","DhcpHostname","DhcpVendor","Hostname", "SsdpFriendlyName","SsdpLocation", "SsdpManufacturer","SsdpModelName","SsdpModelUrl","SsdpSerialNumber","SsdpServer","SsdpUserAgent", "DnsQueries"} do
		print_row(key)
	end
	print ("</table>")
else
	print ("no mac address specified")
end

pagebase = [[<br><br>
Client Details by
<a href=http://www.noddos.io>Noddos</a>
</body></html>
]]

print (pagebase)
