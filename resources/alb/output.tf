output "alb_security_group_id" {
  value = "${aws_security_group.alb_security_group.id}"
}

output "alb_target_group_arn" {
  value = "${aws_lb_target_group.target_group.arn}"
}

output "alb_target_group_suffix" {
  value = "${aws_lb_target_group.target_group.arn_suffix}"
}

output "alb_target_group_name" {
  value = "${aws_lb_target_group.target_group.name}"
}

output "alb_arn" {
  value = "${aws_alb.alb.arn}"
}

output "alb_suffix" {
  value = "${aws_alb.alb.arn_suffix}"
}

output "alb_name" {
  value = "${aws_alb.alb.name}"
}