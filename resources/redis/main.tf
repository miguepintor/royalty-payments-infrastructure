resource "aws_elasticache_subnet_group" "redis_subnets" {
  name        = "${var.app_name}-redis-sng-${var.environment}"
  subnet_ids = "${var.redis_subnets}"
}

resource "aws_elasticache_parameter_group" "redis_parameters" {
  name   = "${var.app_name}-redis-params-${var.environment}"
  family = "redis4.0"
}

resource "aws_elasticache_replication_group" "redis" {
  automatic_failover_enabled    = true
  node_type                     = "cache.t2.micro"
  replication_group_id          = "${var.app_name}-redis-${var.environment}"
  replication_group_description = "Redis cache"
  number_cache_clusters         = 2
  parameter_group_name          = "${aws_elasticache_parameter_group.redis_parameters.name}"
  subnet_group_name = "${aws_elasticache_subnet_group.redis_subnets.name}"
  port                          = "${var.redis_port}"
  engine = "redis"
  engine_version = "4.0"
  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.app_name}-redis-${var.environment}"
    )
  )}"
}