variable "prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "queue_name" {
  description = "Name of the SQS queue (will be prefixed)"
  type        = string
  default     = "main-queue"
}

variable "queue_purpose" {
  description = "Description of what this queue is used for"
  type        = string
  default     = "General purpose message queue"
}

variable "message_retention_seconds" {
  description = "How long messages are retained in the queue (1 minute to 14 days)"
  type        = number
  default     = 1209600 # 14 days (maximum)
}

variable "visibility_timeout_seconds" {
  description = "How long messages are invisible after being received (0 to 12 hours)"
  type        = number
  default     = 300 # 5 minutes
}

variable "max_message_size" {
  description = "Maximum message size in bytes (1024 to 262144)"
  type        = number
  default     = 262144 # 256 KB (maximum)
}

variable "delay_seconds" {
  description = "Time to delay message delivery (0 to 900 seconds)"
  type        = number
  default     = 0
}

variable "enable_encryption" {
  description = "Enable server-side encryption for the queue"
  type        = bool
  default     = true
}

variable "enable_dlq" {
  description = "Enable Dead Letter Queue for failed messages"
  type        = bool
  default     = true
}

variable "max_receive_count" {
  description = "Maximum times a message can be received before going to DLQ"
  type        = number
  default     = 3
}

variable "dlq_message_retention_seconds" {
  description = "How long messages are retained in the Dead Letter Queue"
  type        = number
  default     = 1209600 # 14 days
}

variable "create_queue_policy" {
  description = "Create a queue policy for cross-account access"
  type        = bool
  default     = false
}

variable "allowed_principals" {
  description = "List of AWS principals allowed to access the queue"
  type        = list(string)
  default     = []
}