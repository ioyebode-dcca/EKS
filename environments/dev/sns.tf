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
resource "aws_cloudwatch_event_rule" "cluster_runtime" {
  name                = "eks-runtime-3hr-dev"
  description         = "Alert if EKS cluster is still running after 3 hours"
  schedule_expression = "rate(3 hours)"
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.cluster_runtime.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.cluster_runtime_alert.arn

  input = jsonencode({
    message = "⚠️ EKS cluster underwater-dev has been running for 3+ hours. Remember to destroy!"
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
