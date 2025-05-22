# SQS Queue
resource "aws_sqs_queue" "main_queue" {
  name = "${var.prefix}-${var.queue_name}"

  # Message retention period (how long messages stay in queue)
  message_retention_seconds = var.message_retention_seconds

  # Visibility timeout (how long a message is invisible after being received)
  visibility_timeout_seconds = var.visibility_timeout_seconds

  # Maximum message size (in bytes)
  max_message_size = var.max_message_size

  # How long to wait for a response when sending messages
  delay_seconds = var.delay_seconds

  # Enable server-side encryption
  kms_master_key_id = var.enable_encryption ? "alias/aws/sqs" : null

  # Dead letter queue configuration (for failed messages)
  redrive_policy = var.enable_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.max_receive_count
  }) : null

  tags = {
    Name        = "${var.prefix}-${var.queue_name}"
    Environment = var.prefix
    Purpose     = var.queue_purpose
  }
}

# Dead Letter Queue (optional)
# This receives messages that couldn't be processed after multiple attempts
resource "aws_sqs_queue" "dlq" {
  count = var.enable_dlq ? 1 : 0
  
  name = "${var.prefix}-${var.queue_name}-dlq"
  
  # DLQ messages are kept longer for troubleshooting
  message_retention_seconds = var.dlq_message_retention_seconds

  tags = {
    Name        = "${var.prefix}-${var.queue_name}-dlq"
    Environment = var.prefix
    Purpose     = "Dead letter queue for ${var.queue_name}"
  }
}

# Queue Policy (optional - for cross-account access or specific permissions)
resource "aws_sqs_queue_policy" "main_queue_policy" {
  count     = var.create_queue_policy ? 1 : 0
  queue_url = aws_sqs_queue.main_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.allowed_principals
        }
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.main_queue.arn
      }
    ]
  })
}