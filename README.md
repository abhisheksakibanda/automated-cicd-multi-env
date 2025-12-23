# Automated CI/CD Pipeline with Multi-Environment Deployment

A fully automated CI/CD pipeline that handles code compilation, testing, and deployment across development, staging, and production environments using AWS CodePipeline, CodeBuild, and CodeDeploy.

## Table of Contents

- [Project Overview](#project-overview)
- [Repository Structure](#repository-structure)
- [Branching Strategy](#branching-strategy)
- [Branch Protection Rules](#branch-protection-rules)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
- [Pipeline Workflow](#pipeline-workflow)
- [Troubleshooting](#troubleshooting)
- [Rollback Procedures](#rollback-procedures)

## Project Overview

This project demonstrates a production-ready CI/CD pipeline with:
- **Multi-environment deployment** (dev, staging, production)
- **Automated testing** (unit tests, integration tests, security scanning)
- **Blue/Green deployments** with automated rollback
- **Infrastructure as Code** using Terraform
- **Comprehensive monitoring** with CloudWatch dashboards

## Repository Structure

```
automated-cicd-multi-env/
├── app/                          # Application code
│   ├── app.py                   # Flask application
│   └── requirements.txt         # Python dependencies
├── cicd/                        # CI/CD configuration files
│   ├── appspecs/
│   │   └── appspec.yml         # CodeDeploy application specification
│   ├── buildspecs/
│   │   └── buildspec.yml       # CodeBuild build specification
│   └── scripts/                # Deployment scripts
│       ├── before_install.sh   # Pre-deployment cleanup
│       ├── after_install.sh    # Dependency installation
│       ├── start_server.sh     # Application startup
│       └── validate.sh         # Health check validation
├── infra/                       # Infrastructure as Code (Terraform)
│   ├── main.tf                 # Main Terraform configuration
│   ├── variables.tf            # Variable definitions
│   ├── providers.tf            # Provider configuration
│   ├── terraform.tfvars        # Variable values (not committed)
│   └── modules/                # Terraform modules
│       ├── alb/                # Application Load Balancer
│       ├── codebuild/          # CodeBuild projects
│       ├── codedeploy/         # CodeDeploy configuration
│       ├── iam/                # IAM roles and policies
│       ├── monitoring/         # CloudWatch dashboards and alarms
│       └── pipeline/           # CodePipeline configuration
└── tests/                       # Test suites
    ├── test_app.py             # Unit tests
    └── integration/
        └── test_integration.py  # Integration tests
```

## Branching Strategy

This project uses a **three-branch strategy** aligned with the three deployment environments:

### Branches

1. **`dev`** - Development Environment
   - Active development branch
   - Automatically deploys to development environment
   - No branch protection (allows direct pushes for rapid iteration)
   - Pipeline triggers on every push

2. **`staging`** - Staging Environment
   - Pre-production testing environment
   - Requires pull request from `dev` branch
   - Automatically deploys to staging environment
   - Protected branch (see [Branch Protection Rules](#branch-protection-rules))

3. **`main`** - Production Environment
   - Production-ready code
   - Requires pull request from `staging` branch
   - Automatically deploys to production environment
   - Protected branch with strict rules (see [Branch Protection Rules](#branch-protection-rules))

### Workflow

```
Feature Development → dev → staging → main (production)
                      ↓        ↓         ↓
                   Dev Env  Staging   Production
```

**Typical Flow:**
1. Developers work on feature branches or directly on `dev`
2. Code is merged to `dev` → triggers deployment to **Development** environment
3. After testing in dev, create PR: `dev` → `staging` → triggers deployment to **Staging** environment
4. After staging validation, create PR: `staging` → `main` → triggers deployment to **Production** environment

## Branch Protection Rules

Branch protection rules ensure code quality and prevent direct pushes to critical branches.

### Staging Branch Protection

**Branch:** `staging`

**Rules:**
- **Require a pull request before merging**
  - Require 1 approval
- **Require status checks to pass before merging**
  - All CI/CD pipeline stages must pass
  - Code must be up to date before merging

**Purpose:** Ensures code is reviewed and tested before reaching staging environment.

### Production (main) Branch Protection

**Branch:** `main`

**Rules:**
- **Require a pull request before merging**
  - Require 1 approval
  - Dismiss stale pull request approvals when new commits are pushed
- **Require status checks to pass before merging**
  - All CI/CD pipeline stages must pass
  - Code must be up to date before merging

**Purpose:** Maximum protection for production code. Stale approvals are dismissed to ensure reviewers see the latest changes.

### How to Work with Protected Branches

1. **Create a Pull Request:**
   ```bash
   # From your feature branch or dev
   git checkout -b feature/your-feature
   # Make changes and commit
   git push origin feature/your-feature
   # Create PR on GitHub: feature/your-feature → staging (or staging → main)
   ```

2. **Wait for CI/CD Pipeline:**
   - Pipeline automatically runs on PR creation
   - All tests and security scans must pass

3. **Get Approval:**
   - At least 1 team member must approve the PR
   - For `main` branch, approvals are dismissed if new commits are added

4. **Merge:**
   - Once approved and all checks pass, merge the PR
   - Deployment to the target environment will trigger automatically

## Architecture

### CI/CD Pipeline Flow

```
GitHub Repository
    ↓
[Source Stage] - GitHub webhook triggers pipeline
    ↓
[Build Stage] - CodeBuild compiles, tests, and packages
    ├── Install dependencies
    ├── Run unit tests (coverage ≥ 80%)
    ├── Security scan (Bandit)
    ├── Run integration tests
    └── Package artifacts
    ↓
[Test Stage] - Automated testing in isolated environment
    ↓
[Deploy to Dev] - CodeDeploy Blue/Green deployment
    ↓
[Manual Approval] - Review dev deployment
    ↓
[Deploy to Staging] - CodeDeploy Blue/Green deployment
    ↓
[Manual Approval] - Review staging deployment
    ↓
[Deploy to Production] - CodeDeploy Blue/Green deployment
```

### AWS Services Used

- **AWS CodePipeline** - Orchestrates the CI/CD workflow
- **AWS CodeBuild** - Builds, tests, and packages the application
- **AWS CodeDeploy** - Deploys to EC2 instances using Blue/Green strategy
- **Amazon EC2 & Auto Scaling** - Deployment targets
- **Application Load Balancer (ALB)** - Traffic routing for Blue/Green deployments
- **Amazon S3** - Stores pipeline artifacts
- **AWS CloudWatch** - Monitoring, logging, and alerting
- **Amazon SNS** - Pipeline notifications

## Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 1.5.0
- AWS CLI configured
- GitHub account and repository access
- Python 3.11+ (for local testing)

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/abhisheksakibanda/automated-cicd-multi-env.git
cd automated-cicd-multi-env
```

### 2. Configure Terraform Variables

Create or update `infra/terraform.tfvars`:

```hcl
project_name = "automated-cicd-multi-env"
github_token = "your-github-oauth-token"

# VPC Configuration (use existing or create new)
vpc_id         = "vpc-xxxxxxxxx"
public_subnets = ["subnet-xxxxx", "subnet-yyyyy"]
private_subnets = ["subnet-zzzzz", "subnet-wwwww"]
```

### 3. Update GitHub Configuration

Edit `infra/main.tf` and update:
- `github_owner` - Your GitHub username
- `github_repo` - Repository name (should match current repo)
- `alert_email` - Email for SNS notifications

### 4. Initialize and Apply Terraform

```bash
cd infra
terraform init
terraform plan
terraform apply
```

### 5. Configure GitHub Webhook (if needed)

The pipeline should automatically connect to GitHub. Verify in AWS CodePipeline console that the source stage is connected.

## Pipeline Workflow

### Build Phase (CodeBuild)

1. **Install Phase:**
   - Install Python 3.11
   - Install application dependencies
   - Install testing tools (pytest, bandit, coverage)

2. **Pre-Build Phase:**
   - Run unit tests with coverage
   - Generate coverage report
   - **Quality Gate:** Fail if coverage < 80%

3. **Build Phase:**
   - Package application code
   - Include appspec.yml and deployment scripts
   - Create deployment artifact

4. **Post-Build Phase:**
   - Start application for integration testing
   - Run integration tests
   - Run security scan (Bandit)
   - **Quality Gate:** Fail if high-severity vulnerabilities found

### Deploy Phase (CodeDeploy)

1. **BeforeInstall:**
   - Stop existing application
   - Clean up previous deployment

2. **AfterInstall:**
   - Install application dependencies
   - Prepare application directory

3. **ApplicationStart:**
   - Start Flask application
   - Configure service

4. **ValidateService:**
   - Health check validation
   - Verify application is responding

### Blue/Green Deployment

- **Blue Environment:** Current production traffic
- **Green Environment:** New deployment
- Traffic is gradually shifted from Blue to Green
- If validation fails, traffic remains on Blue (automatic rollback)
- On success, Blue instances are terminated

## 🐛 Troubleshooting

### Pipeline Fails at Build Stage

**Issue:** Build fails during unit tests
- **Check:** Test coverage may be below 80%
- **Solution:** Review coverage report, add tests to increase coverage

**Issue:** Security scan fails
- **Check:** Bandit found high-severity vulnerabilities
- **Solution:** Review `bandit-output.json`, fix security issues

### Pipeline Fails at Deploy Stage

**Issue:** Deployment fails during ValidateService
- **Check:** Application health check endpoint
- **Solution:** 
  - Verify `/health` endpoint is accessible
  - Check EC2 instance logs: `/var/log/aws/codedeploy-agent/`
  - Review CloudWatch Logs for application errors

**Issue:** Rollback triggered
- **Check:** CloudWatch alarms for application health
- **Solution:** 
  - Review application logs
  - Check ALB target group health
  - Verify application dependencies are installed

### Common Issues

1. **GitHub Connection Issues:**
   - Verify OAuth token is valid
   - Check CodePipeline source stage connection

2. **IAM Permission Errors:**
   - Ensure IAM roles have required permissions
   - Review CloudWatch Logs for specific error messages

3. **Artifact Not Found:**
   - Verify S3 bucket exists and is accessible
   - Check artifact store configuration in pipeline

## Rollback Procedures

### Automatic Rollback

The pipeline automatically rolls back if:
- CloudWatch alarms detect application health issues
- Deployment validation fails
- Health checks fail during traffic shifting

### Manual Rollback

1. **Via AWS Console:**
   - Navigate to CodeDeploy → Deployments
   - Find the failed deployment
   - Click "Rollback" or redeploy previous successful version

2. **Via Terraform:**
   ```bash
   # Revert to previous Terraform state
   terraform state list
   terraform apply -target=module.codedeploy
   ```

3. **Via Git:**
   ```bash
   # Revert to previous commit
   git revert HEAD
   git push origin <branch>
   # Pipeline will redeploy previous version
   ```

### Rollback Verification

After rollback:
1. Check CloudWatch dashboard for deployment success
2. Verify application health endpoint responds
3. Review CloudWatch Logs for any errors
4. Confirm traffic is routed to healthy instances

## Monitoring

### CloudWatch Dashboard

Access the dashboard:
- AWS Console → CloudWatch → Dashboards
- Dashboard name: `automated-cicd-multi-env-cicd-dashboard`

**Metrics Tracked:**
- Pipeline execution success rate
- Mean build duration
- Deployment success rate
- Recent deployment errors

### SNS Notifications

Receive email notifications for:
- Pipeline failures
- Deployment failures
- CloudWatch alarm triggers

### CloudWatch Logs Insights

Query deployment logs:
```sql
fields @timestamp, @message 
| filter @message like /error/ or /fail/ 
| sort @timestamp desc 
| limit 20
```
