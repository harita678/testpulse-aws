# ============================================================================
# alb.tf — Application Load Balancer: the only public entry point.
# Lives in the public subnets, uses the web SG. Forwards to the private EC2.
# ============================================================================

resource "aws_lb" "alb" {
  name               = "testpulse-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]

  subnets = [
    data.aws_subnet.public_1a.id,
    data.aws_subnet.public_1b.id,
    data.aws_subnet.public_1d.id,
  ]

  tags = {
    Name        = "testpulse-alb"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }
}

# ── Target group: ingestor (port 8000) ──
resource "aws_lb_target_group" "ingestor-tg" {
  name        = "testpulse-ingestor-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "instance"

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name        = "testpulse-ingestor-tg"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }
}
# ── Target group: dashboard (port 8001) ──
resource "aws_lb_target_group" "dashboard-tg" {
  name        = "testpulse-dashboard-tg"
  port        = 8001
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "instance"

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name        = "testpulse-dashboard-tg"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }
}

# ── Register the EC2 into both target groups ── 
# Above we only created TGs, we dont refer the target (here ec2) in the TG. We only define rules there.
# Attachment to target is a separate resource

resource "aws_lb_target_group_attachment" "ingestor" {
  target_group_arn = aws_lb_target_group.ingestor-tg.arn
  target_id        = aws_instance.ingestor.id
  port             = 8000
}
resource "aws_lb_target_group_attachment" "dashboard" {
  target_group_arn = aws_lb_target_group.dashboard-tg.arn
  target_id        = aws_instance.ingestor.id
  port             = 8001
}

# ── Listener on :80 — the ALB's front door ──
# Default action sends everything to the dashboard; the rule below
# peels off /results/* to the ingestor.

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dashboard-tg.arn

  }
}

# ── Rule: /results/* → ingestor ──
# for now we added the rule that /results/* will go to ingestor otherwise(the default rule) dashbaod
# we are skipping the health check for ingestor for now

resource "aws_lb_listener_rule" "ingestor-rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ingestor-tg.arn
  }
  condition {
    path_pattern {
      values = ["/results/*"]
    }
  }
}