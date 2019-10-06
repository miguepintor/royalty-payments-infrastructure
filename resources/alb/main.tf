resource "aws_alb" "alb" {
  name            = "${var.app_name}-alb-${var.environment}"
  subnets         = "${var.alb_subnets}"
  security_groups = ["${aws_security_group.alb_security_group.id}"]
  internal = "${var.internal}"

  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.app_name}-alb-${var.environment}"
    )
  )}"
}

resource "aws_security_group" "alb_security_group" {
  name        = "${var.app_name}-alb-sg-${var.environment}"
  description = "Alb security group"
  vpc_id      = "${var.vpc_id}"

  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.app_name}-alb-sg-${var.environment}"
    )
  )}"
}

resource "aws_security_group_rule" "ingress_http_rules" {
  count = "${length(keys(var.ingress_cidrs))}"
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  cidr_blocks = ["${element(values(var.ingress_cidrs), count.index)}"]
  description = "${element(keys(var.ingress_cidrs), count.index)}"
  security_group_id = "${aws_security_group.alb_security_group.id}"
}

resource "aws_security_group_rule" "egress_rules" {
  count = "${length(keys(var.egress_cidrs))}"
  type            = "egress"
  from_port       = 0
  to_port         = 65535
  protocol        = "tcp"
  cidr_blocks = ["${element(values(var.egress_cidrs), count.index)}"]
  description = "${element(keys(var.egress_cidrs), count.index)}"
  security_group_id = "${aws_security_group.alb_security_group.id}"
}

resource "aws_lb_target_group" "target_group" {
  name        = "${var.app_name}-tg-${var.environment}"
  port        = "${var.target_group_port}"
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${var.vpc_id}"
  depends_on  = ["aws_alb.alb"]

  health_check {
    path      = "${var.health_check_path}"
  }

  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.app_name}-tg-${var.environment}"
    )
  )}"
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = "${aws_alb.alb.arn}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group.arn}"
  }

  depends_on      = ["aws_alb.alb"]
}
