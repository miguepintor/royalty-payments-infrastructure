resource "aws_elasticache_subnet_group" "redis_subnets" {
  name        = "${var.app_name}-redis-sng-${var.environment}"
  subnet_ids = "${var.redis_subnets}"
}

resource "aws_elasticache_parameter_group" "redis_parameters" {
  name   = "${var.app_name}-redis-params-${var.environment}"
  family = "redis4.0"
}

resource "aws_security_group" "redis_security_group" {
  name        = "${var.app_name}-redis-sg-${var.environment}"
  description = "Redis security group"
  vpc_id      = "${var.vpc_id}"

  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.app_name}-redis-sg-${var.environment}"
    )
  )}"
}

resource "aws_security_group_rule" "ingress_rules" {
  count = "${length(keys(var.ingress_cidrs))}"
  type            = "ingress"
  from_port       = "${var.redis_port}"
  to_port         = "${var.redis_port}"
  protocol        = "tcp"
  cidr_blocks = ["${element(values(var.ingress_cidrs), count.index)}"]
  description = "${element(keys(var.ingress_cidrs), count.index)}"
  security_group_id = "${aws_security_group.redis_security_group.id}"
}

resource "aws_elasticache_replication_group" "redis" {
  automatic_failover_enabled    = true
  node_type                     = "cache.t2.micro"
  replication_group_id          = "${var.app_name}-redis-${var.environment}"
  replication_group_description = "Redis cache"
  number_cache_clusters         = 2
  security_group_ids = ["${aws_security_group.redis_security_group.id}"]
  parameter_group_name          = "${aws_elasticache_parameter_group.redis_parameters.name}"
  subnet_group_name = "${aws_elasticache_subnet_group.redis_subnets.name}"
  port                          = "${var.redis_port}"
  engine = "redis"
  engine_version = "4.0.10"
  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.app_name}-redis-${var.environment}"
    )
  )}"
}