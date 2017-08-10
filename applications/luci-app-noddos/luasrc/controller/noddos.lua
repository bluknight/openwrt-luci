module("luci.controller.noddos", package.seeall)
function index()
  	entry({"admin", "status", "noddos"}, template("noddos/clients"), _("NoDDoS Clients"), 3)
    entry({"admin", "network", "noddos"}, cbi("noddos"), _("NoDDoS Client Tracking"), 55)
end
