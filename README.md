# TestPulse — Cloud-Native Test Analytics Platform on AWS

> Event-driven pipeline that ingests CI/CD test results, processes them asynchronously, and serves analytics — running on a private, tiered AWS VPC, fully provisioned with Terraform.

**Stack:** AWS (VPC · EC2 · Lambda · RDS · S3 · SQS · ALB · Secrets Manager · CloudWatch · SNS) · Terraform (IaC) · Docker · FastAPI · Python 3.12 · GitHub Actions (CI) · PostgreSQL

---

## What it does

A team's CI pipeline posts test results (JSON) to TestPulse. The results are ingested, archived, processed asynchronously into a pass/fail summary, stored in a relational database, and surfaced through a dashboard — with custom metrics and alerting on top.

The point of the project is not just that it works, but **why each piece is built the way it is** — the trade-offs behind an event-driven design, a private network, and runtime secret management.

---

## Architecture

```
                          Internet
                             │
                             ▼
                    ┌─────────────────┐
                    │       ALB       │   public subnets · the only public entry
                    │   (HTTP :80)    │
                    └────────┬────────┘
              /results/*     │      default
                 ┌───────────┴───────────┐
                 ▼                        ▼
        ┌─────────────────────────────────────────┐
        │   EC2 (private subnet, app tier)         │
        │   ┌───────────┐      ┌────────────────┐  │
        │   │ Ingestor  │      │   Dashboard    │  │
        │   │ FastAPI   │      │   FastAPI      │  │
        │   │ :8000     │      │   :8001        │  │
        │   └─────┬─────┘      └───────┬────────┘  │
        └─────────┼────────────────────┼───────────┘
                  │                     │
        S3 (raw)  │  SQS (pointer)      │ read
                  ▼                     │
        ┌──────────────────┐           │
        │ Lambda Processor │           │
        │ (private, SQS-   │           │
        │  triggered)      │           │
        └────────┬─────────┘           │
                 │ write               │
                 ▼                     ▼
        ┌──────────────────────────────────┐
        │   RDS PostgreSQL (private subnet) │
        └──────────────────────────────────┘

  Secrets Manager ──► apps fetch DB password at runtime (no password in config)
  CloudWatch (EMF metrics + alarms + dashboard) ──► SNS alerts
  NAT Gateway ──► private subnets' outbound; S3 Gateway Endpoint ──► private S3 access
```

**The data flow:** CI posts results → **Ingestor** (FastAPI on EC2) archives the raw payload to **S3** and drops a lightweight pointer on **SQS** → a **Lambda processor** (SQS-triggered, in the VPC) fetches the payload, computes a pass/fail summary, and writes to **RDS** → the **Dashboard** (FastAPI on EC2) reads RDS and serves the results. An **ALB** is the single public entry point, routing by path to the two services.

**The pointer pattern:** SQS carries a small message pointing to the S3 object; S3 holds the actual payload. The queue stays light, S3 keeps the durable copy.

Everything runs in `ca-central-1`, provisioned and managed as code with Terraform (remote state in S3).

---

## What makes this more than a demo

This started as a **flat, public** setup — everything in public subnets, the database reachable from the internet-facing tier — and was deliberately **re-architected into a secure, tiered design**. That re-architecture is the core of the project:

- **Network tiering** — split into public (ALB), app (EC2 + Lambda), and data (RDS) tiers using separate security groups. Each tier only accepts traffic from the tier in front of it.
- **Private subnets + NAT** — moved compute and the database off the public internet. Private resources reach out via a NAT gateway; S3 is reached privately through a gateway endpoint.
- **ALB as the sole entry point** — the EC2 has no public IP; all inbound traffic goes through the load balancer, which health-checks the targets and routes by path.
- **Least-privilege IAM** — every service uses a role scoped to exactly what it needs (e.g. the apps can read *one* secret, nothing more).
- **Runtime secret management** — the database password was moved out of environment variables and config into **AWS Secrets Manager**, fetched by the apps at runtime, then **rotated** so older copies (in state, snapshots) are invalidated.
- **Private-box operations via SSM** — the private EC2 has no SSH exposure; it's managed through AWS Systems Manager Session Manager.

Each of these was a decision with alternatives weighed — documented so the reasoning can be probed line by line.

---

## Observability

- **Custom metrics** emitted from the Lambda processor via the CloudWatch **Embedded Metric Format (EMF)** — tests passed / failed / total, dimensioned by team and project.
- **CloudWatch alarms** on those metrics, wired to an **SNS** topic for alerting.
- **CloudWatch dashboard** for at-a-glance health.

(This alerting caught a real bug during development — a Lambda crash after a config change surfaced immediately via the alarm.)

---

## Tech stack

| Area | Tools |
|---|---|
| Cloud | AWS — VPC, EC2, Lambda, RDS (PostgreSQL), S3, SQS, ALB, Secrets Manager, CloudWatch, SNS, NAT Gateway, IAM |
| IaC | Terraform (remote state in S3) |
| Containers | Docker (services run as containers via systemd on EC2) |
| App | Python 3.12, FastAPI |
| CI | GitHub Actions |
| Testing | pytest, moto (AWS mocking) |

---

## CI/CD

**Current:** a GitHub Actions pipeline runs on every push/PR (path-filtered to the project), using a matrix across the three services (ingestor, processor, dashboard). For each: checkout → set up Python 3.12 → install dependencies → run `pytest`. Tests mock AWS (moto) and the database, so they run fast without real infrastructure.

**In progress — Terraform in CI:** adding `terraform fmt -check` and `terraform validate` (credential-free, `-backend=false`) as gates so infrastructure code is formatted and valid before merge, plus `docker build` checks for the containerized services.

---

## Roadmap / future enhancements

- **Terraform CI** — formatting + validation gates (in progress); later, plan-on-PR with OIDC-based credentials.
- **Automated Lambda packaging** — replace the manual build with a reproducible packaging step.
- **HTTPS** — a domain + ACM certificate + a 443 listener on the ALB.
- **Path-prefix routing** (`/ingestor/*`, `/dashboard/*`) — cleaner ALB routing and per-service API docs.
- **JUnit XML ingestion** — accept the standard CI test format in addition to JSON.
- **State bucket hardening** — encryption, versioning, public-access blocking.

---

## Repository layout

```
05-testpulse/
├── ingestor/       # FastAPI service — receives results, writes to S3 + SQS
├── processor/      # Lambda — SQS-triggered, computes summary, writes to RDS
├── dashboard/      # FastAPI service — reads RDS, serves the UI
└── terraform/      # all infrastructure as code
```

---

## Notes

Built as a hands-on cloud engineering project to work through real architectural decisions end to end — network design, security, secrets, observability, and infrastructure as code — rather than following a tutorial. The design choices, trade-offs, and the defects encountered (and fixed) along the way are documented in the project's design notes.
