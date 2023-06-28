variable "default_redirector_domain" {
  description = "Default domain name to use for short links where a pool does not have a dedicated redirector domain."
  type        = string
}

variable "entry_points" {
  description = "List of domain names to present the redirector at."
  type        = list(string)
}

variable "maxmind_account_id" {
  description = "MaxMind account ID of an account with at least a GeoIP2 Country subscription."
  type        = string
}

variable "maxmind_licence_key" {
  description = "MaxMind licence key of an account with at least a GeoIP2 Country subscription."
  type        = string
}

variable "public_key" {
  description = "API key of the public pool from the Bypass Censorship portal."
  type        = string
}

variable "secret_key" {
  description = <<EOT
    Secret key used for Flask sessions and hash ID generation. WARNING: changing this in a deployment will cause all
    existing short URLs to break.
  EOT
  type        = string
}

variable "update_key" {
  description = "Update key that will be used by the Bypass Censorship portal to authenticate updates."
  type        = string
}

variable "mirror_countries" {
  description = "List of ISO 3166-2 country codes for countries where a mirror is required."
  type        = list(string)
}