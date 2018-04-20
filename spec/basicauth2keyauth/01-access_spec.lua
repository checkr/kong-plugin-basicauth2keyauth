local helpers = require "spec.helpers"

describe("Plugin: key-auth (access)", function()
  local client
  setup(function()
    local api1 = assert(helpers.dao.apis:insert {
      name         = "api-1",
      hosts        = { "host1.com" },
      upstream_url = helpers.mock_upstream_url,
    })
    assert(helpers.dao.plugins:insert {
      name   = "basicauth2keyauth",
      api_id = api1.id,
    })

    local api2 = assert(helpers.dao.apis:insert {
      name         = "api-2",
      hosts        = { "host2.com" },
      upstream_url = helpers.mock_upstream_url,
    })
    assert(helpers.dao.plugins:insert {
      name   = "basicauth2keyauth",
      api_id = api2.id,
      config = {
        sha256_enabled = true,
      },
    })

    assert(helpers.start_kong({
      nginx_conf = "spec/fixtures/custom_nginx.template",
      custom_plugins = "basicauth2keyauth",
    }))
    client = helpers.proxy_client()
  end)

  teardown(function()
    if client then client:close() end
    helpers.stop_kong()
  end)

  describe("plugin: basicauth2keyauth", function()
    it("does nothing if there's no basic auth in the headers", function()
      local res = assert(client:send {
        method = "GET",
        path = "/request",
        headers = {
          ["Host"] = "host1.com",
        }
      })
      assert.res_status(200, res)
    end)
    it("generates new api_key header if basic auth is in the headers", function()
      local res = assert(client:send {
        method = "GET",
        path = "/request",
        headers = {
          ["Host"] = "host1.com",
          ["Authorization"] = "Basic YXBpMTIzNDo=" -- "api1234:"
        }
      })
      assert.res_status(200, res)
      local header_value = assert.request(res).has.header("apikey_from_basicauth")
      assert.equal("api1234", header_value)
    end)
    it("generates nothing if basic auth has the password part", function()
      local res = assert(client:send {
        method = "GET",
        path = "/request",
        headers = {
          ["Host"] = "host2.com",
          ["Authorization"] = "Basic YXBpMTIzNDpwYXNzd29yZA==" -- "api1234:password"
        }
      })
      assert.res_status(200, res)
      assert.request(res).has.no.header("apikey_from_basicauth")
    end)
    it("generates new api_key header with sha256 value if basic auth is in the headers", function()
      local res = assert(client:send {
        method = "GET",
        path = "/request",
        headers = {
          ["Host"] = "host2.com",
          ["Authorization"] = "Basic YXBpMTIzNDo=" -- "api1234:"
        }
      })
      assert.res_status(200, res)
      local header_value = assert.request(res).has.header("apikey_from_basicauth")
      assert.equal("632d187cde1f395f3fb17e9783748d101b70174988a8e148bc7bc20f63453ea5", header_value)
    end)
    it("generates new api_key header with sha256 value if basic auth is in the headers without colon", function()
      local res = assert(client:send {
        method = "GET",
        path = "/request",
        headers = {
          ["Host"] = "host2.com",
          ["Authorization"] = "Basic YXBpMTIzNA==" -- "api1234"
        }
      })
      assert.res_status(200, res)
      local header_value = assert.request(res).has.header("apikey_from_basicauth")
      assert.equal("632d187cde1f395f3fb17e9783748d101b70174988a8e148bc7bc20f63453ea5", header_value)
    end)
    it("generates new api_key header with sha256 value if basic is in upper case", function()
      local res = assert(client:send {
        method = "GET",
        path = "/request",
        headers = {
          ["Host"] = "host2.com",
          ["Authorization"] = "BASIC YXBpMTIzNA==" -- "api1234"
        }
      })
      assert.res_status(200, res)
      local header_value = assert.request(res).has.header("apikey_from_basicauth")
      assert.equal("632d187cde1f395f3fb17e9783748d101b70174988a8e148bc7bc20f63453ea5", header_value)
    end)
  end)
end)
