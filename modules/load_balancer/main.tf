resource "aws_lb" "role_lb" {
  for_each = var.target_instances
  
  name               = "${each.key}-${var.cluster_name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = var.subnet_ids
}

resource "aws_security_group" "lb" {
  vpc_id = var.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "targets" {
  for_each = var.target_instances
  
  name     = "${each.key}-${var.cluster_name}-tg"
  port     = 9200
  protocol = "HTTPS"
  vpc_id   = var.vpc_id
  
  health_check {
    protocol = "HTTPS"
    path     = "/_cluster/health"
    port     = "traffic-port"
  }
}

resource "aws_lb_target_group_attachment" "targets" {
  for_each = flatten([
    for role, instances in var.target_instances : [
      for idx, instance in instances : {
        key     = "${role}-${idx}"
        role    = role
        instance = instance
      }
    ]
  ])

  target_group_arn = aws_lb_target_group.targets[each.value.role].arn
  target_id        = each.value.instance.id
  port             = 9200
}

resource "aws_lb_listener" "https" {
  for_each = var.target_instances
  
  load_balancer_arn = aws_lb.role_lb[each.key].arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = "arn:aws:acm:region:account:certificate/xxx" # Replace with actual ARN
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.targets[each.key].arn
  }
}

resource "aws_route53_record" "dns" {
  for_each = var.target_instances
  
  zone_id = var.dns_zone_id
  name    = "${each.key}-${var.cluster_name}.${var.domain_name}"
  type    = "A"
  
  alias {
    name                   = aws_lb.role_lb[each.key].dns_name
    zone_id                = aws_lb.role_lb[each.key].zone_id
    evaluate_target_health = true
  }
}