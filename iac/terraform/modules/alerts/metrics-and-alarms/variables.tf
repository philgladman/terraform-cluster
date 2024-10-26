variable "tags" {
  description = "Map of tags to add to all resources created"
  type        = map(string)
}

variable "name" {
  description = "A name for the metric filter."
  type        = string
}

variable "pattern" {
  description = "A valid CloudWatch Logs filter pattern for extracting metric data out of ingested log events."
  type        = string
}

variable "log_group_name" {
  description = "The name of the log group to associate the metric filter with"
  type        = string
}


variable "metric_transformation_name" {
  description = "The name of the CloudWatch metric to which the monitored log information should be published (e.g. ErrorCount)"
  type        = string
}

variable "metric_transformation_namespace" {
  description = "The destination namespace of the CloudWatch metric."
  type        = string
}

variable "metric_transformation_value" {
  description = "What to publish to the metric. For example, if you're counting the occurrences of a particular term like 'Error', the value will be '1' for each occurrence. If you're counting the bytes transferred the published value will be the value in the log event."
  type        = string
  default     = "1"
}

variable "metric_transformation_default_value" {
  description = "The value to emit when a filter pattern does not match a log event."
  type        = string
  default     = null
}

variable "metric_transformation_unit" {
  description = "The unit to assign to the metric. If you omit this, the unit is set as None."
  type        = string
  default     = null
}


####


variable "comparison_operator" {
  description = "The arithmetic operation to use when comparing the specified Statistic and Threshold. The specified Statistic value is used as the first operand. Either of the following is supported: GreaterThanOrEqualToThreshold, GreaterThanThreshold, LessThanThreshold, LessThanOrEqualToThreshold."
  type        = string
  default     = "GreaterThanOrEqualToThreshold"
}

variable "evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = "1"
}

variable "period" {
  description = "The period in seconds over which the specified statistic is applied."
  type        = string
  default     = "60"
}

variable "statistic" {
  description = "The statistic to apply to the alarm's associated metric. Either of the following is supported: SampleCount, Average, Sum, Minimum, Maximum"
  type        = string
  default     = "Sum"
}

variable "threshold" {
  description = "The value against which the specified statistic is compared."
  type        = number
  default     = "1"
}

variable "alarm_description" {
  description = "The description for the alarm."
  type        = string
  default     = null
}

variable "alarm_actions" {
  description = "The list of actions to execute when this alarm transitions into an ALARM state from any other state. Each action is specified as an Amazon Resource Name (ARN)."
  type        = list(string)
  default     = null
}

variable "lambda_function_name" {
  description = "The Name of the lambda function"
  type        = string
  default     = ""
}
