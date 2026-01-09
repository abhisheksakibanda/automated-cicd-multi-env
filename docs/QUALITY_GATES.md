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

