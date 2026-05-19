variable "porkbun_api_key" {
  description = "API key for Porkbun provider"
  type        = string
  sensitive   = true
}

variable "porkbun_secret_api_key" {
  description = "Secret API key for Porkbun provider"
  type        = string
  sensitive   = true
}

variable "porkbun_domain" {
  description = "Domain name for the application"
  type        = string
}

variable "vultr_api_key" {
  description = "API key for Vultr provider"
  type        = string
  sensitive   = true
}

# Ghost variables
variable "domain" {
  description = "Domain name for the application"
  type        = string
}

variable "admin_domain" {
  description = "Admin domain name for the application"
  type        = string
}

variable "database_user" {
  description = "mysql user"
  type        = string
  default     = "eizouwrwoiu897002"
}

variable "http_port" {
  description = "HTTP port for the application"
  type        = number
}

variable "https_port" {
  description = "HTTPS port for the application"
  type        = number
}

variable "database_root_password" {
  description = "Root password for the database"
  type        = string
  sensitive   = true
}

variable "database_password" {
  description = "Password for the database user"
  type        = string
  sensitive   = true
}

variable "mail_transport" {
  description = "Mail transport method"
  type        = string
}

variable "mail_options_host" {
  description = "SMTP host for mail configuration"
  type        = string
}

variable "mail_options_port" {
  description = "SMTP port for mail configuration"
  type        = number
}

variable "mail_options_secure" {
  description = "Whether to use secure connection for mail"
  type        = bool
}

variable "mail_options_auth_user" {
  description = "Username for mail authentication"
  type        = string
}

variable "mail_options_auth_pass" {
  description = "Password for mail authentication"
  type        = string
  sensitive   = true
}

variable "mail_from" {
  description = "Sender email address for mail configuration"
  type        = string
}

variable "upload_location" {
  description = "Location for file uploads"
  type        = string
  default     = "./data/ghost"
}

variable "mysql_data_location" {
  description = "Location for MySQL data"
  type        = string
  default     = "./data/mysql"
}

variable "activitypub_target" {
  description = "Target URL for ActivityPub integration"
  type        = string
  default     = "https://ap.ghost.org"
}

variable "tinybird_stats_endpoint" {
  description = "Tinybird stats endpoint"
  type        = string
  default     = "https://api.tinybird.co"
}