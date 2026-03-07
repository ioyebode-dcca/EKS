# ── SNS TOPIC ────────────────────────────────────────────────────────────────
resource "aws_sns_topic" "cluster_runtime_alert" {
  name = "eks-runtime-alert-dev"
}

resource "aws_sns_topic_subscription" "sms" {
  topic_arn = aws_sns_topic.cluster_runtime_alert.arn
  protocol  = "sms"
  endpoint  = var.alert_phone_number
}

# ── EVENTBRIDGE RULE ─────────────────────────────────────────────────────────
# Fires every 3 hours — reminder to destroy cluster if still running
resource "aws_cloudwatch_event_rule" "cluster_runtime" {
  name                = "eks-runtime-3hr-dev"
  description         = "Reminder to destroy EKS cluster if still running"
  schedule_expression = "rate(3 hours)"
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.cluster_runtime.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.cluster_runtime_alert.arn

  input = jsonencode({
    message = "⚠️ EKS cluster underwater-dev is still running. Remember to destroy if not needed!"
  })
}

resource "aws_sns_topic_policy" "allow_eventbridge" {
  arn = aws_sns_topic.cluster_runtime_alert.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.cluster_runtime_alert.arn
      }
    ]
  })
}