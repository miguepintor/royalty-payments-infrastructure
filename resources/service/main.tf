data "aws_region" "current" {}

resource "aws_ecs_service" "service" {
  name = "${var.app_name}-service"
  cluster = "${var.cluster_name}"
  desired_count = "${var.instances}"
  launch_type = "FARGATE"
  task_definition = "${aws_ecs_task_definition.task_definition.arn}"
  
  load_balancer {
    container_name = "${var.app_name}-api"
    container_port = "${var.container_port}"
    target_group_arn = "${var.alb_target_group_arn}"
  }
  
  network_configuration {
    assign_public_ip = false
    subnets = "${var.service_subnets}"
    security_groups = [
      "${aws_security_group.sg.id}"
    ]
  }
}

resource "aws_security_group" "sg" {
  name = "${var.app_name}-service-sg-${var.environment}"
  description = "Allow traffic from ALB to the service"
  vpc_id = "${var.vpc_id}"
  ingress {
    from_port = "${var.container_port}"
    to_port = "${var.container_port}"
    protocol = "tcp"
    security_groups = ["${var.alb_security_group_id}"]
    description = "Allows traffic from ALB only"
  }
  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.app_name}-service-sg-${var.environment}"
    )
  )}"
}

resource "aws_security_group_rule" "sg_egress" {
  count       = "${length(keys(var.egress_cidrs))}"
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = ["${element(values(var.egress_cidrs), count.index)}"]
  description = "${element(keys(var.egress_cidrs), count.index)}"
  security_group_id = "${aws_security_group.sg.id}"
}

# If the list of egress_cidrs are empty then allow all traffic
resource "aws_security_group_rule" "sg_allow_all" {
  count       = "${length(keys(var.egress_cidrs)) == 0 ? 1 : 0}"
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Whole World. All protocols."
  security_group_id = "${aws_security_group.sg.id}"
}

resource "aws_ecs_task_definition" "task_definition" {
  family = "${var.app_name}-task-${var.environment}"
  cpu = "${var.default_cpu}"
  memory = "${var.default_memory}"
  network_mode = "awsvpc"
  execution_role_arn = "${aws_iam_role.task_def_role.arn}"
  task_role_arn = "${aws_iam_role.task_def_role.arn}"
  requires_compatibilities = ["FARGATE", "EC2"]
  container_definitions = <<EOF
[
  {
    "name": "${var.app_name}-api",
    "image": "${var.image_uri}",
    "essential": true,
    "portMappings": [
      {
        "containerPort": ${var.container_port},
        "hostPort": ${var.container_port}
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-group": "${aws_cloudwatch_log_group.lg.id}",
        "awslogs-stream-prefix": "${var.app_name}-service"
      }
    },
    "environment": [
      {
        "name": "PORT",
        "value": "${var.container_port}"
      }
    ]
  }
]
  EOF

  lifecycle {
    ignore_changes = ["container_definitions"]
  }

  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.app_name}-task-${var.environment}"
    )
  )}"
}

resource "aws_cloudwatch_log_group" "lg" {
  name = "/apps/${var.environment}/${var.app_name}-service"
  retention_in_days = "${var.logs_retention}"
}

##########################
# Task definition role   #
##########################

resource "aws_iam_role" "task_def_role" {
  name = "${var.app_name}-task-role-${var.environment}"
  assume_role_policy = "${data.aws_iam_policy_document.task_def_asumme_role_policy_document.json}"
  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.app_name}-task-role-${var.environment}"
    )
  )}"
}

data "aws_iam_policy_document" "task_def_asumme_role_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "task_def_policy" {
  name = "${var.app_name}-task-policy-${var.environment}"
  role = "${aws_iam_role.task_def_role.id}"
  policy = "${data.aws_iam_policy_document.task_def_policy_document.json}"
}

data "aws_iam_policy_document" "task_def_policy_document" {
  statement {
    actions   = [
    "ecr:GetAuthorizationToken",
    "ecr:BatchCheckLayerAvailability",
    "ecr:GetDownloadUrlForLayer",
    "ecr:BatchGetImage",
    "logs:CreateLogStream",
    "logs:PutLogEvents",
    "ssm:Describe*",
    "ssm:Get*",
    "ssm:List*",
    "s3:GetObject"
    ]
    resources = ["*"]
  }
}

##########################
# Auto Scaling Resources #
##########################

resource "aws_appautoscaling_target" "service_scaling_target" {
  min_capacity = "${var.min_capacity}"
  max_capacity = "${var.max_capacity}"
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"


  depends_on = [
    "aws_ecs_service.service",
  ]

  count = "${var.enable_autoscaling == true ? 1 : 0}"
}

resource "aws_appautoscaling_policy" "scale_down_policy" {
  name               = "${var.app_name}-ScaleDownPolicy-${var.environment}"
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"
    step_adjustment {
      scaling_adjustment          = -1
      metric_interval_upper_bound = 0
    }
  }
  depends_on = [
    "aws_appautoscaling_target.service_scaling_target",
  ]
  count = "${var.enable_autoscaling == true ? 1 : 0}"
}

resource "aws_appautoscaling_policy" "scale_up_policy" {
  name               = "${var.app_name}-ScaleUpPolicy-${var.environment}"
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 120
    metric_aggregation_type = "Average"
    step_adjustment {
      scaling_adjustment          = 1
      metric_interval_lower_bound = 0
      metric_interval_upper_bound = 10
    }
    step_adjustment {
      scaling_adjustment          = 2
      metric_interval_lower_bound = 10
    }
  }
  depends_on = [
    "aws_appautoscaling_target.service_scaling_target",
  ]
  count = "${var.enable_autoscaling == true ? 1 : 0}"
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "${var.app_name}-Low-${var.cpu_to_scale_down}-cpu-${var.environment}"
  evaluation_periods  = 5
  statistic = "Average"
  threshold = "${var.cpu_to_scale_down}"
  alarm_description = "Alarm to reduce capacity if container CPU is low"
  period    = 60
  alarm_actions     = ["${element(aws_appautoscaling_policy.scale_down_policy.*.arn, 0)}"]
  namespace = "AWS/ECS"
  dimensions = {
    ClusterName = "${var.cluster_name}"
    ServiceName = "${aws_ecs_service.service.name}"
  }
  comparison_operator = "LessThanThreshold"
  metric_name         = "CPUUtilization"
  count = "${var.enable_autoscaling == true ? 1 : 0}"
  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.app_name}-Low-${var.cpu_to_scale_down}-cpu-${var.environment}"
    )
  )}"
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "${var.app_name}-High-${var.cpu_to_scale_up}-cpu-${var.environment}"
  evaluation_periods  = 2
  statistic = "Average"
  threshold = "${var.cpu_to_scale_up}"
  alarm_description = "Alarm to increase capacity if container CPU is high"
  period    = 60
  alarm_actions     = ["${element(aws_appautoscaling_policy.scale_up_policy.*.arn, 0)}"]
  namespace = "AWS/ECS"
  dimensions = {
    ClusterName = "${var.cluster_name}"
    ServiceName = "${aws_ecs_service.service.name}"
  }
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "CPUUtilization"
  count = "${var.enable_autoscaling == true ? 1 : 0}"
  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.app_name}-High-${var.cpu_to_scale_up}-cpu-${var.environment}"
    )
  )}"
}