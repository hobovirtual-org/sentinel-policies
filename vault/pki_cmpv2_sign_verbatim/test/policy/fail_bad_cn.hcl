# CN does not match cn_regex — invalid-cn.example.com fails the 5G node pattern.

param "allowed_countries"     { value = ["CA"] }
param "allowed_organizations" { value = ["Example Corp"] }
param "allowed_org_units"     { value = ["Platform Security"] }
param "allowed_states"        { value = ["ON", "QC", "NS", "MB", "AB", "BC"] }
param "allowed_localities"    { value = ["Toronto", "Montreal", "Halifax", "Winnipeg", "Calgary", "Vancouver"] }
param "allowed_email"         { value = "ops@example.ca" }
param "cn_regex"              { value = "^(cnom|li|gsa)\\.(bcon|bent)\\.(amf|smf|upf|nrf|nssf)\\.[a-z0-9]+\\.[a-z0-9]+\\.[a-z0-9]+\\.5g\\.int\\.example\\.ca$" }
param "uid_regex"             { value = "^[a-z0-9]+-[a-z0-9]+-(bcon|bent)-(amf|smf|upf|nrf|nssf)-[a-z0-9]+$" }
param "li_cn_prefix"          { value = "li." }
param "required_eku"          { value = ["serverAuth", "clientAuth"] }
param "require_dns_san_match" { value = true }
param "dns_san_regexes"       { value = ["^(cnom|li|gsa)\\.(bcon|bent)\\.(amf|smf|upf|nrf|nssf)\\.[a-z0-9]+\\.[a-z0-9]+\\.[a-z0-9]+\\.5g\\.int\\.example\\.ca$"] }
param "require_uri_sans"      { value = false }
param "uri_san_regex"         { value = "" }
param "san_uri_prefix"        { value = "urn:etsi:li:103221-1:cert-binding:" }
param "max_san_entries"       { value = 20 }

mock "request" {
  data = {
    data = {
      common_name         = "invalid-cn.example.com"
      country             = ["CA"]
      province            = ["ON"]
      locality            = ["Toronto"]
      organization        = ["Example Corp"]
      organizational_unit = ["Platform Security"]
      email_address       = ["ops@example.ca"]
      alt_names           = ["invalid-cn.example.com"]
      ext_key_usage       = ["serverAuth", "clientAuth"]
    }
  }
}

test {
  rules = {
    main = false
  }
}
