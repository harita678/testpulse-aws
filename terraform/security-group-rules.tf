# ============================================================================
# security-group-rules.tf — Ingress rules - incldue rules for each security group here
# ============================================================================

# Rules(#4) for Web Tier security group

resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}


# --- APP TIER (2 rules) ---
# My lambda and EC2 both are in App Tier
# Meaning that they both are sharing the same SG and that's why they are in same tier
# As EC2 is not in front(web) and now in app tier, it should accept connection from web tier(ALB)
# It should accept 8000 and 8001
# Remeber here that since EC2 and Lambda are sharing the SG, they dont need any rule to accept connection from each other


resource "aws_vpc_security_group_ingress_rule" "app_from_alb_8000" {
  security_group_id            = aws_security_group.app.id
  from_port                    = 8000
  to_port                      = 8000
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.web.id
  description                  = "ALB to ingestor"
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb_8001" {
  security_group_id            = aws_security_group.app.id
  from_port                    = 8001
  to_port                      = 8001
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.web.id
  description                  = "ALB to dashboard"
}

# --- DB TIER (3 rules) ---

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_vpc_security_group_ingress_rule" "db_from_laptop" {
  security_group_id = aws_security_group.db.id
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  cidr_ipv4         = "76.67.45.97/32"
}