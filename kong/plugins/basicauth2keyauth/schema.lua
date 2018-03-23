return {
  no_consumer = false, -- this plugin is available on APIs as well as on Consumers,
  fields = {
    key_name_in_header = {type = "string", default = "apikey_from_basicauth"},
    sha256_enabled = {type = "boolean", default = false},
    hide_credentials = {type = "boolean", default = false}
  }
}
