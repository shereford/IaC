# Define the list of instances to monitor
locals {
  # Ids for multiple sets of EC2 instances, merged together
  all_instances = concat(aws_instance.web_ec2.*, aws_instance.app_ec2.*, aws_instance.db_ec2.*)
  web_and_db_instances = concat(aws_instance.web_ec2.*, aws_instance.db_ec2.*)
  web_and_app_instances = concat(aws_instance.web_ec2.*, aws_instance.app_ec2.*)
  web = aws_instance.web_ec2.*
  app = aws_instance.app_ec2.*
  db = aws_instance.db_ec2.*
}

# Create a CloudWatch metric alarm for the C drive
resource "aws_cloudwatch_metric_alarm" "c_drive_alarm" {
  count               = length(local.all_instances)
  alarm_name          = "c-drive-alarm-${local.all_instances[count.index].tags.Name}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "LogicalDisk % Free Space"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = "5"
  alarm_description   = "This metric monitors the free space on the C drive."
  dimensions = {
    ImageId       = local.all_instances[count.index].ami
    InstanceId    = local.all_instances[count.index].id
    InstanceType  = local.all_instances[count.index].instance_type
    instance      = "C:"
    objectname    = "LogicalDisk"
  }
}

# Create a CloudWatch metric alarm for the D drive
resource "aws_cloudwatch_metric_alarm" "d_drive_alarm" {
  count               = length(local.web_and_app_instances)
  alarm_name          = "d-drive-alarm-${local.web_and_app_instances[count.index].tags.Name}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "LogicalDisk % Free Space"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = "5"
  alarm_description   = "This metric monitors the free space on the D drive."
  dimensions = {
    ImageId       = local.web_and_app_instances[count.index].ami
    InstanceId    = local.web_and_app_instances[count.index].id
    InstanceType  = local.web_and_app_instances[count.index].instance_type
    instance      = "D:"
    objectname    = "LogicalDisk"
  }
}

# Create a CloudWatch metric alarm for CPU utilization
resource "aws_cloudwatch_metric_alarm" "cpu_utilization_alarm" {
  count               = length(local.all_instances)
  alarm_name          = "cpu-utilization-alarm-${local.all_instances[count.index].tags.Name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "95"
  alarm_description   = "This metric monitors CPU utilization."
  dimensions = {
    InstanceId = local.all_instances[count.index].id
  }
}

# Create a CloudWatch metric alarm for system status checks
resource "aws_cloudwatch_metric_alarm" "system_status_alarm" {
  count               = length(local.all_instances)
  alarm_name          = "system-status-alarm-${local.all_instances[count.index].tags.Name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "This metric monitors system status checks."
  dimensions = {
    InstanceId = local.all_instances[count.index].id
  }
}


# Create composite alarm (from metric alarms) for each instance
# ALARM RULE names are dependant on metric filter names in logstream_alarms.tf

# DB instance composite alarms
resource "aws_cloudwatch_composite_alarm" "db_composite_alarm" {
  count             = length(local.db)
  alarm_name        = "DEMO ${local.db[count.index].tags.Name} Composite"
  alarm_description = "Alarm for CPU,Disk,Status Checks, and SQL for DB Instancesr"
 
  alarm_rule = join(" OR " , tolist(["ALARM(\"system-status-alarm-${local.db[count.index].tags.Name}\")", 
                                     "ALARM(\"c-drive-alarm-${local.db[count.index].tags.Name}\")",
                                     "ALARM(\"cpu-utilization-alarm-${local.db[count.index].tags.Name}\")",
                                     "ALARM(\"${local.db[count.index].tags.Name}-SQL-Service-Stopped\")",
                                     "ALARM(\"${local.db[count.index].tags.Name}-Disk-Error\")",
                                     "ALARM(\"${local.db[count.index].tags.Name}-Service-Alarm\")",
                                     "ALARM(\"${local.db[count.index].tags.Name}-Cluster-Failover\")"]))
}
# Web instance composite alarms
resource "aws_cloudwatch_composite_alarm" "web_composite_alarm" {
  count             = length(local.web)
  alarm_name        = "DEMO ${local.web[count.index].tags.Name} Composite"
  alarm_description = "Alarm for CPU,Disk,Status Checks, and URI for Web Instances"
 
  alarm_rule = join(" OR " , tolist(["ALARM(\"system-status-alarm-${local.web[count.index].tags.Name}\")", 
                                     "ALARM(\"c-drive-alarm-${local.web[count.index].tags.Name}\")",
                                     "ALARM(\"cpu-utilization-alarm-${local.web[count.index].tags.Name}\")",
                                     "ALARM(\"d-drive-alarm-${local.web[count.index].tags.Name}\")",
                                     "ALARM(\"${local.web[count.index].tags.Name}-Service-Alarm\")",
                                     "ALARM(\"${local.web[count.index].tags.Name}-URI-Monitoring\")"]))
}
# App instance composite alarms
resource "aws_cloudwatch_composite_alarm" "app_composite_alarm" {
  count             = length(local.app)
  alarm_name        = "DEMO ${local.app[count.index].tags.Name} Composite"
  alarm_description = "Alarm for CPU,Disk,Status Checks, and URI for App Instances"
 
  alarm_rule = join(" OR " , tolist(["ALARM(\"system-status-alarm-${local.app[count.index].tags.Name}\")", 
                                     "ALARM(\"c-drive-alarm-${local.app[count.index].tags.Name}\")",
                                     "ALARM(\"cpu-utilization-alarm-${local.app[count.index].tags.Name}\")",
                                     "ALARM(\"d-drive-alarm-${local.app[count.index].tags.Name}\")",
                                     "ALARM(\"${local.app[count.index].tags.Name}-Service-Alarm\")",
                                     "ALARM(\"${local.app[count.index].tags.Name}-URI-Monitoring\")"]))
}

resource "aws_cloudwatch_composite_alarm" "environment_alarm" {
  alarm_name        = "Environment Composite Alarm"
  alarm_description = "Alarm for all Instances in Environment"
 
  alarm_rule = join(" OR " , tolist(["ALARM(\"${aws_cloudwatch_composite_alarm.app_composite_alarm[0].alarm_name}\")", 
                                     "ALARM(\"${aws_cloudwatch_composite_alarm.app_composite_alarm[1].alarm_name}\")",
                                     "ALARM(\"${aws_cloudwatch_composite_alarm.db_composite_alarm[0].alarm_name}\")",
                                     "ALARM(\"${aws_cloudwatch_composite_alarm.db_composite_alarm[1].alarm_name}\")",
                                     "ALARM(\"${aws_cloudwatch_composite_alarm.web_composite_alarm[0].alarm_name}\")",
                                     "ALARM(\"${aws_cloudwatch_composite_alarm.web_composite_alarm[1].alarm_name}\")"]))
}

