local resty_sha256 = require "resty.sha256"
local to_hex = require "resty.string".to_hex

local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")
local plugin = require("kong.plugins.base_plugin"):extend()

-- retrieve_credentials gets the username from basic auth
-- @param request ngx request object
-- @param {table} conf Plugin config
-- @return {string} username
local function retrieve_credentials(request, header_name, conf)
  local username
  local authorization_header = request.get_headers()[header_name]

  if authorization_header then
    local iterator, iter_err = ngx.re.gmatch(authorization_header, "\\s*Basic\\s*(.+)", "oji")
    if not iterator then
      ngx.log(ngx.ERR, iter_err)
      return
    end

    local m, err = iterator()
    if err then
      ngx.log(ngx.ERR, err)
      return
    end

    if m and m[1] then
      local decoded_basic = ngx.decode_base64(m[1])
      if decoded_basic then
        local basic_parts, err = ngx.re.match(decoded_basic, "([^:\\s]+):?([^\\s]*)", "oj")
        if err then
          ngx.log(ngx.ERR, err)
          return
        end

        if not basic_parts then
          ngx.log(ngx.ERR, "[basic-auth] header has unrecognized format")
          return
        end

        username = basic_parts[1]
      end
    end
  end

  if conf.hide_credentials then
    request.clear_header(header_name)
  end

  return username
end

local function sha256(s)
  local digest = resty_sha256:new()
  assert(digest:update(s))
  return to_hex(digest:final())
end

local function set_apikey_header(given_username, conf)
  if not conf.sha256_enabled then
    ngx.req.set_header(conf.key_name_in_header, given_username)
  else
    ngx.req.set_header(conf.key_name_in_header, sha256(given_username))
  end
end

function plugin:new()
  plugin.super.new(self, plugin_name)
end

function plugin:access(conf)
  plugin.super.access(self)

  local given_username
  given_username = retrieve_credentials(ngx.req, "proxy-authorization", conf)
  if not given_username then
    given_username = retrieve_credentials(ngx.req, "authorization", conf)
  end

  if given_username then
    set_apikey_header(given_username, conf)
  end
end

plugin.PRIORITY = 1999
plugin.VERSION = "0.1.0"

return plugin
