# Branching Strategy Documentation

This document describes the Git branching strategy used alongside a single multi-stage CodePipeline.

## Overview

This project implements a **three-branch Git workflow** that aligns with three deployment environments: Development,
Staging, and Production.

## Branch Structure

```
main (production)
  ↑
staging
  ↑
dev
```

### Branch Details

#### 1. `dev` Branch

- **Purpose:** Active development and rapid iteration
- **Deployment Target:** Development environment
- **Protection:** None (allows direct pushes for developer velocity)
- **Workflow:**
    - Developers can push directly or create feature branches
    - Every push triggers CI/CD pipeline
    - Automatic deployment to development environment
    - Used for initial testing and validation

#### 2. `staging` Branch

- **Purpose:** Pre-production testing and validation
- **Deployment Target:** Staging environment
- **Protection:** Protected (see protection rules below)
- **Workflow:**
    - Requires pull request from `dev` branch
    - All CI/CD checks must pass
    - Requires 1 approval before merge
    - Automatic deployment to staging environment
    - Used for integration testing and user acceptance testing

#### 3. `main` Branch

- **Purpose:** Production-ready code
- **Deployment Target:** Production environment
- **Protection:** Protected with strict rules (see protection rules below)
- **Workflow:**
    - Requires pull request from `staging` branch
    - All CI/CD checks must pass
    - Requires 1 approval before merge
    - Stale approvals are dismissed on new commits
    - Deployment to production environment after manual approval in pipeline
    - Used for live production deployments

## Branch Protection Rules

### Staging Branch Protection

**Configuration:**

- Require a pull request before merging
    - Minimum approvals: **1**
- Require status checks to pass before merging
    - All CI/CD pipeline stages must succeed
    - Code must be up to date before merging

**Rationale:** Ensures code quality and prevents untested code from reaching staging environment.

### Production (main) Branch Protection

**Configuration:**

- Require a pull request before merging
    - Minimum approvals: **1**
    - **Dismiss stale pull request approvals when new commits are pushed**
- Require status checks to pass before merging
    - All CI/CD pipeline stages must succeed
    - Code must be up to date before merging

**Rationale:** Maximum protection for production. Stale approvals are dismissed to ensure reviewers always see the
latest code changes before approving.

## Development Workflow

### Scenario 1: Feature Development

```bash
# 1. Create feature branch from dev
git checkout dev
git pull origin dev
git checkout -b feature/new-feature

# 2. Make changes and commit
git add .
git commit -m "Add new feature"
git push origin feature/new-feature

# 3. Create PR: feature/new-feature → dev
# 4. After merge, code auto-deploys to dev environment
```

### Scenario 2: Promote to Staging

```bash
# 1. Ensure dev branch is up to date
git checkout dev
git pull origin dev

# 2. Create PR: dev → staging
# 3. Wait for CI/CD pipeline to complete
# 4. Get approval from team member
# 5. Merge PR
# 6. Code auto-deploys to staging environment
```

### Scenario 3: Promote to Production

```bash
# 1. Ensure staging branch is up to date
git checkout staging
git pull origin staging

# 2. Create PR: staging → main
# 3. Wait for CI/CD pipeline to complete
# 4. Get approval from team member
# 5. Merge PR
# 6. Code auto-deploys to production environment after manually approved in pipeline
```

## CI/CD Pipeline Integration

### Pipeline Triggers

- The pipeline source stage is triggered by changes to the `dev` branch.
- Promotion to `staging` and `main` occurs through deployment stages within the same pipeline after successful builds
  and approvals.
- Pull requests enforce review and validation before promotion.

### Pipeline Stages per Branch

The `dev` branch goes through the following pipeline stages:

1. **Source** - Fetch code from GitHub
2. **Build** - Compile, test, and package
3. **Test** - Run integration tests
4. **Deploy** - Deploy to respective environment

### Environment-Specific Deployments

- `dev` → Development environment (automatic, no approval)
- `staging` → Staging environment (automatic after PR merge)
- `main` → Production environment (automatic after PR merge, with manual approval gates in pipeline)

## Best Practices

1. **Always test in dev first** before promoting to staging
2. **Never push directly to staging or main** - always use pull requests
3. **Keep branches up to date** - regularly sync with upstream branches
4. **Write meaningful commit messages** - helps with code review and debugging
5. **Review PRs thoroughly** - especially for staging → main promotions
6. **Monitor deployments** - check CloudWatch dashboards after each deployment

## Troubleshooting Branch Protection

### Issue: Cannot push to staging/main

**Solution:** Create a feature branch or use pull requests. Direct pushes are blocked by branch protection.

### Issue: PR cannot be merged - "Required status checks must pass"

**Solution:** Wait for CI/CD pipeline to complete. All stages must succeed before merge is allowed.

### Issue: Approval dismissed on main branch

**Solution:** This happens when new commits are pushed to the PR. Re-request approval after reviewing new changes.

## Repository Structure Alignment

The repository structure supports this branching strategy:

```
├── app/              # Application code (same across all branches)
├── cicd/             # CI/CD configs (same across all branches)
├── infra/            # Infrastructure code (same across all branches)
└── tests/            # Test suites (same across all branches)
```

**Note:** All branches share the same codebase structure. Environment-specific configurations are handled via:

- Terraform variables
- CodeBuild environment variables
- CodeDeploy deployment groups

## Summary

This branching strategy provides:

- Clear separation between development, staging, and production
- Automated deployments aligned with branch merges
- Quality gates through branch protection
- Safe promotion path: dev → staging → main
- Rollback capability through Git history

---
