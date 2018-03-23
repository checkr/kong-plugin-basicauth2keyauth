-- TODO: rename, must match the info in the filename of this rockspec!
-- as a convention; stick to the prefix: `kong-plugin-`
package = "kong-plugin-basicauth2keyauth"

-- TODO: renumber, must match the info in the filename of this rockspec!
-- The version '0.1.0' is the source code version, the trailing '1' is the version of this rockspec.
-- whenever the source version changes, the rockspec should be reset to 1. The rockspec version is only
-- updated (incremented) when this file changes, but the source remains the same.
version = "0.1.0-1"

-- TODO: This is the name to set in the Kong configuration `custom_plugins` setting.
-- Here we extract it from the package name.
local pluginName = package:match("^kong%-plugin%-(.+)$")  -- "myPlugin"

supported_platforms = {"linux", "macosx"}

source = {
  url = "git://github.com/checkr/kong-plugin-basicauth2keyauth",
  tag = "0.1.0"
}

description = {
  summary = "basicauth2keyauth converts basic auth's username to be the key in key-auth"
}

dependencies = {
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins."..pluginName..".handler"] = "kong/plugins/"..pluginName.."/handler.lua",
    ["kong.plugins."..pluginName..".schema"] = "kong/plugins/"..pluginName.."/schema.lua",
  }
}
