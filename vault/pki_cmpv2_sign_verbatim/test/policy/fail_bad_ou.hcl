# OU not in allowlist — OU=Finance is not in allowed_org_units.

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
      common_name         = "cnom.bcon.amf.01.c01.f1252.5g.int.example.ca"
      country             = ["CA"]
      province            = ["ON"]
      locality            = ["Toronto"]
      organization        = ["Example Corp"]
      organizational_unit = ["Finance"]
      email_address       = ["ops@example.ca"]
      alt_names           = ["cnom.bcon.amf.01.c01.f1252.5g.int.example.ca"]
      ext_key_usage       = ["serverAuth", "clientAuth"]
    }
  }
}

test {
  rules = {
    main = false
  }
}
