# Quality Gates Documentation

This document describes all quality gates configured in the CI/CD pipeline that must pass before code can be deployed.

## Overview

Quality gates ensure code quality, security, and reliability before deployment. If any gate fails, the pipeline stops
and prevents deployment.

## Quality Gates by Stage

### 1. Build Stage - Code Quality Gates

#### Code Coverage Gate

- **Tool:** Coverage package
- **Threshold:** 80% minimum
- **Location:** `cicd/buildspecs/buildspec.yml` (pre_build phase)
- **Action on Failure:** Pipeline fails immediately
- **Command:**
  ```bash
  coverage run -m pytest tests/
  COVERAGE=$(coverage report | grep TOTAL | awk '{print $4}' | sed 's/%//')
  if [ "$COVERAGE" -lt 80 ]; then exit 1; fi
  ```

#### Security Scanning Gates

##### Bandit Security Scan

- **Tool:** Bandit (Python security linter)
- **Severity Threshold:** No HIGH severity issues allowed
- **Location:** `cicd/buildspecs/buildspec.yml` (post_build phase)
- **Action on Failure:** Pipeline fails immediately
- **Scans:** Python code for common security issues
- **Command:**
  ```bash
  bandit -r app/ -f json -o bandit-output.json
  # Fails if HIGH severity issues found
  ```

##### Safety Dependency Scan

- **Tool:** Safety (Python dependency vulnerability scanner)
- **Threshold:** No known vulnerabilities allowed
- **Location:** `cicd/buildspecs/buildspec.yml` (post_build phase)
- **Action on Failure:** Pipeline fails immediately
- **Scans:** Python package dependencies against known vulnerability database
- **Command:**
  ```bash
  safety check --json --output safety-output.json
  # Fails if vulnerabilities found
  ```

##### AWS Inspector Scan

- **Tool:** AWS Inspector v2
- **Severity Threshold:** No HIGH or CRITICAL findings allowed
- **Location:** `cicd/buildspecs/buildspec.yml` (post_build phase)
- **Script:** `cicd/scripts/inspector_scan.sh`
- **Action on Failure:** Pipeline fails immediately
- **Scans:** AWS resources and code for security vulnerabilities
- **Note:** Requires AWS Inspector to be enabled in the account

### 2. Test Stage - Integration Test Gates

#### Integration Test Execution

- **Tool:** Pytest
- **Location:** `cicd/buildspecs/test-buildspec.yml`
- **Action on Failure:** Pipeline fails immediately
- **Tests:**
    - Health endpoint accessibility
    - Response time validation
    - JSON format validation
    - Root endpoint functionality
- **Command:**
  ```bash
  pytest tests/integration -v --tb=short
  ```

### 3. Deploy Stage - Deployment Validation Gates

#### Application Health Check

- **Tool:** CodeDeploy ValidateService hook
- **Location:** `cicd/appspecs/appspec.yml`
- **Script:** `cicd/scripts/validate.sh`
- **Action on Failure:** Deployment fails, automatic rollback
- **Check:** Application responds to `/health` endpoint

#### Pre-Traffic Validation

- **Tool:** CodeDeploy BeforeAllowTraffic hook
- **Location:** `cicd/appspecs/appspec.yml`
- **Script:** `cicd/scripts/before_allow_traffic.sh`
- **Action on Failure:** Traffic shift prevented, deployment fails
- **Check:** Final health validation before traffic shift

#### Post-Traffic Monitoring

- **Tool:** CodeDeploy AfterAllowTraffic hook
- **Location:** `cicd/appspecs/appspec.yml`
- **Script:** `cicd/scripts/after_allow_traffic.sh`
- **Action on Failure:** Monitors health, CloudWatch alarms trigger rollback if needed
- **Check:** Application health after traffic shift

### 4. CloudWatch Alarm Gates (Automatic Rollback)

#### Application Unhealthy Alarm

- **Metric:** `UnHealthyHostCount` (ALB Target Group)
- **Threshold:** > 0 unhealthy hosts
- **Evaluation Periods:** 2
- **Period:** 60 seconds
- **Action on Breach:** Automatic CodeDeploy rollback
- **Location:** `infra/modules/codedeploy/main.tf`

## Quality Gate Summary Table

| Gate                 | Stage  | Tool          | Threshold         | Failure Action               |
|----------------------|--------|---------------|-------------------|------------------------------|
| Code Coverage        | Build  | Coverage.py   | ≥ 80%             | Fail Pipeline                |
| Bandit Scan          | Build  | Bandit        | 0 HIGH issues     | Fail Pipeline                |
| Safety Scan          | Build  | Safety        | 0 vulnerabilities | Fail Pipeline                |
| Inspector Scan       | Build  | AWS Inspector | 0 HIGH/CRITICAL   | Fail Pipeline                |
| Integration Tests    | Test   | Pytest        | All pass          | Fail Pipeline                |
| Health Check         | Deploy | CodeDeploy    | HTTP 200          | Rollback                     |
| Pre-Traffic Check    | Deploy | CodeDeploy    | Health OK         | Prevent Traffic Shift        |
| Post-Traffic Monitor | Deploy | CodeDeploy    | Health OK         | Monitor + Rollback if needed |
| Unhealthy Hosts      | Deploy | CloudWatch    | 0 unhealthy       | Automatic Rollback           |

## Bypassing Quality Gates

**Quality gates should NOT be bypassed in production.**

If a gate fails:

1. **Fix the issue** - Address the root cause
2. **Re-run the pipeline** - After fixes are committed
3. **Review exceptions** - Only in emergency situations with proper approval

## Monitoring Quality Gates

### CloudWatch Dashboard

- View pipeline execution metrics
- Monitor build success rates
- Track deployment health

### SNS Notifications

- Receive email alerts on:
    - Pipeline failures
    - Quality gate failures
    - Security scan findings
    - Deployment failures

### Logs

- CodeBuild logs: `/aws/codebuild/{project-name}`
- CodeDeploy logs: EC2 instance logs
- Application logs: Application-specific locations

## Best Practices

1. **Run tests locally** before pushing code
2. **Check coverage** before committing
3. **Review security scan results** regularly
4. **Monitor CloudWatch alarms** after deployments
5. **Keep dependencies updated** to avoid Safety warnings
6. **Review Inspector findings** periodically

## Updating Quality Gates

To modify quality gate thresholds:

1. **Code Coverage:** Edit `cicd/buildspecs/buildspec.yml` line 20
2. **Security Scans:** Modify scan commands in `post_build` phase
3. **Integration Tests:** Add/remove tests in `tests/integration/`
4. **CloudWatch Alarms:** Update `infra/modules/codedeploy/main.tf`

---
