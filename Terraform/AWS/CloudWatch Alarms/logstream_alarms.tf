
# Below code block declared in alarms.tf (if alarms.tf file is moved to another module uncomment codeblock)
# Define the list of instances to monitor
#locals {
  # Ids for multiple sets of EC2 instances, merged together
#  all_instances = concat(aws_instance.web_ec2.*, aws_instance.app_ec2.*, aws_instance.db_ec2.*)
#  web_and_db_instances = concat(aws_instance.web_ec2.*, aws_instance.db_ec2.*)
#  web_and_app_instances = concat(aws_instance.web_ec2.*, aws_instance.app_ec2.*)
#  web = aws_instance.web_ec2.*
#  app = aws_instance.app_ec2.*
#  db = aws_instance.db_ec2.*
#}

resource "aws_cloudwatch_log_metric_filter" "metric_filter_service_alarm" {
  count          = length(local.all_instances)
  name           = "${local.all_instances[count.index].tags.Name}-Service-Alarm"
  pattern        = "\"Service not running: \""
  log_group_name = "${local.all_instances[count.index].tags.Name}"

  metric_transformation {
    name      = "Services"
    namespace = "${local.all_instances[count.index].tags.Name}-Service-Alarm"
    value     = "1"
    default_value    = "0"
    unit             = "Count"
    dimensions       = {}
  }

}

resource "aws_cloudwatch_log_metric_filter" "metric_filter_uri_monitoring" {
  count          = length(local.web_and_app_instances)
  name           = "${local.web_and_app_instances[count.index].tags.Name}-URI-Monitoring"
  pattern        = "DevOps URI Monitoring Multiple exceptions"
  log_group_name = "${local.web_and_app_instances[count.index].tags.Name}"

  metric_transformation {
    name      = "URI Monitoring"
    namespace = "${local.web_and_app_instances[count.index].tags.Name}-URI-Monitoring"
    value     = "1"
    default_value    = "0"
    unit             = "Count"
    dimensions       = {}
  }

}

resource "aws_cloudwatch_log_metric_filter" "metric_filter_db_failover_disk" {
  count          = length(local.db)
  name           = "${local.db[count.index].tags.Name}-DB-Disk-Error"
  pattern        = "Cluster physical disk resource encountered an error while attempting to terminate"
  log_group_name = "${local.db[count.index].tags.Name}"

  metric_transformation {
    name      = "DB Disk Failover"
    namespace = "${local.db[count.index].tags.Name}-Disk-Error"
    value     = "1"
    default_value    = "0"
    unit             = "Count"
    dimensions       = {}
  }

}

resource "aws_cloudwatch_log_metric_filter" "metric_filter_db_failover_sql_stopped" {
  count          = length(local.db)
  name           = "${local.db[count.index].tags.Name}-SQL-Stopped"
  pattern        = "Service Control Manager SQL Server stopped"
  log_group_name = "${local.db[count.index].tags.Name}"

  metric_transformation {
    name      = "SQL Server Stopped"
    namespace = "${local.db[count.index].tags.Name}-SQL-Stopped"
    value     = "1"
    default_value    = "0"
    unit             = "Count"
    dimensions       = {}
  }

}

resource "aws_cloudwatch_log_metric_filter" "metric_filter_cluster_failover" {
  count          = length(local.db)
  name           = "${local.db[count.index].tags.Name}-Failover-Cluster-Alarm"
  pattern        = "\"Microsoft-Windows-FailoverClustering\" 1069"
  log_group_name = "${local.db[count.index].tags.Name}"

  metric_transformation {
    name      = "Cluster Failover"
    namespace = "${local.db[count.index].tags.Name}-ClusterFailover"
    value     = "1"
    default_value    = "0"
    unit             = "Count"
    dimensions       = {}
  }

}

resource "aws_cloudwatch_metric_alarm" "service_alarm" {
  count               = length(local.all_instances)
  alarm_name          = "${aws_cloudwatch_log_metric_filter.metric_filter_service_alarm[count.index].name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Services"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  namespace           = "${local.all_instances[count.index].tags.Name}-Service-Alarm"
  alarm_description   = "Service Alarm based on Metric Filters"
  /*dimensions = {
    InstanceId = "${aws_cloudwatch_log_metric_filter.metric_filter_service_alarm[count.index].log_group_name}"
  }*/
  tags = {
    Name = "${aws_cloudwatch_log_metric_filter.metric_filter_service_alarm[count.index].name}"
  }
}

resource "aws_cloudwatch_metric_alarm" "uri_monitoring_alarm" {
  count               = length(local.web_and_app_instances)
  alarm_name          = "${aws_cloudwatch_log_metric_filter.metric_filter_uri_monitoring[count.index].name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "URI Monitoring"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  namespace           = "${local.web_and_app_instances[count.index].tags.Name}-URI-Monitoring"
  alarm_description   = "URI Monitoring based on Metric Filters"
  /*dimensions = {
    InstanceId = "${aws_cloudwatch_log_metric_filter.metric_filter_uri_monitoring[count.index].log_group_name}"
  }*/
  tags = {
    Name = "${aws_cloudwatch_log_metric_filter.metric_filter_uri_monitoring[count.index].name}"
  }
}

resource "aws_cloudwatch_metric_alarm" "db_failover_disk_alarm" {
  count               = length(local.db)
  alarm_name          = "${local.db[count.index].tags.Name}-Disk-Error"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "DB Disk Failover"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  namespace           = "${local.db[count.index].tags.Name}-Disk-Error"
  alarm_description   = "DB Failover Disk Error"
  /*dimensions = {
    InstanceId = "${aws_cloudwatch_log_metric_filter.metric_filter_db_failover_disk[count.index].log_group_name}"
  }*/
  tags = {
    Name = "${aws_cloudwatch_log_metric_filter.metric_filter_db_failover_disk[count.index].name}"
  }
}
resource "aws_cloudwatch_metric_alarm" "db_failover_sql_stopped_alarm" {
  count               = length(local.db)
  alarm_name          = "${local.db[count.index].tags.Name}-SQL-Service-Stopped"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "SQL Server Stopped"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  namespace           = "${local.db[count.index].tags.Name}-SQL-Stopped"
  alarm_description   = "SQL Stopped"
  /*(dimensions = {
    InstanceId = "${aws_cloudwatch_log_metric_filter.metric_filter_db_failover_sql_stopped[count.index].log_group_name}"
  }*/
  tags = {
    Name = "${aws_cloudwatch_log_metric_filter.metric_filter_db_failover_sql_stopped[count.index].name}"
  }
}

resource "aws_cloudwatch_metric_alarm" "cluster_failover_alarm" {
  count               = length(local.db)
  alarm_name          = "${local.db[count.index].tags.Name}-Cluster-Failover"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Cluster Failover"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  namespace           = "${local.db[count.index].tags.Name}-ClusterFailover"
  alarm_description   = "Cluster Failover"
  /*dimensions = {
    InstanceId = "${aws_cloudwatch_log_metric_filter.metric_filter_cluster_failover[count.index].log_group_name}"
  }*/
  tags = {
    Name = "${aws_cloudwatch_log_metric_filter.metric_filter_cluster_failover[count.index].name}"
  }
}
