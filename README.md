# AWS Scripts

A collection of AWS management scripts for working with EC2 instances, Auto Scaling groups, and ECS services.

## Installation

Add the `aws-scripts` directory to your PATH:

```bash
export PATH="$HOME/aws-scripts:$PATH"
```

Add this line to your `~/.bashrc` or `~/.zshrc` to make it persistent.

## Prerequisites

- AWS CLI installed and configured
- AWS profile set (default uses `$AWS_PROFILE` environment variable)
- Appropriate AWS permissions for EC2, Auto Scaling, ECS, and SSM
- GitHub CLI (`gh`) installed and authenticated (required for `aws-ecs-check`)

## Features

- **Automatic Authentication**: All scripts automatically detect if your AWS SSO session is active and prompt for login if expired. In non-TTY contexts (scripts, CI), they exit with a clear error if the session is expired rather than hanging — run `aws sso login` in a terminal first.
- **Profile Support**: All scripts respect the `$AWS_PROFILE` environment variable or accept a `--profile` flag
- **Tag-based Filtering**: Scripts use AWS tags to find the right resources for your environment

## Scripts

### aws-list

List running EC2 instances filtered by tags.

**Usage:**
```bash
aws-list [stage] [--profile PROFILE] [--stage STAGE] [--attributes ATTRIBUTES]
```

**Examples:**
```bash
aws-list                              # List instances with default attributes (manager)
aws-list production                   # List production instances
aws-list --attributes proc-bg         # List instances with proc-bg attribute
aws-list dev --profile my-profile     # List dev instances with specific profile
```

### aws-ssh

SSH into the first instance returned by aws-list for a given search term. Supports running commands non-interactively by passing them after `--`.

**Usage:**
```bash
aws-ssh <search-term> [--profile PROFILE] [--stage STAGE] [--attributes ATTRIBUTES] [-- COMMAND]
```

**Examples:**
```bash
aws-ssh production                        # SSH to first production instance
aws-ssh web-server                        # SSH to first instance matching "web-server"
aws-ssh my-env --attributes proc-render   # SSH to first proc-render instance
aws-ssh dev --stage production            # SSH to first dev instance in production stage
aws-ssh ft5 -- docker ps                  # Run command non-interactively
aws-ssh ft5 -- "cd /some/path && ls"      # Run shell command non-interactively
```

### aws-ssm-session

Connect to EC2 instances via AWS Systems Manager Session Manager (more secure than SSH, works on instances without SSH access). Supports running commands non-interactively by passing them after `--`.

**Usage:**
```bash
aws-ssm-session <instance_name> [--stage STAGE] [--attributes ATTRIBUTES] [-- COMMAND]
```

**Examples:**
```bash
aws-ssm-session my-instance                               # Connect with default attributes
aws-ssm-session my-instance --stage production            # Connect to production instance
aws-ssm-session my-instance --attributes proc-render      # Connect to render process instance
aws-ssm-session ft5 -- docker ps                          # Run command non-interactively
aws-ssm-session ft5 --stage prod -- "systemctl status api" # Run command on specific stage
```

**Default attributes:** "manager"

**Non-interactive mode** uses `ssm send-command` under the hood — no TTY required, stdout/stderr are printed and the script exits with the remote exit code. Use this for environments where SSH is not available.

### aws-get-case

Download DICOM case folders from AWS instances with optimized settings for large medical imaging files.

**Usage:**
```bash
aws-get-case <search-term> <case-name> [--profile PROFILE] [--stage STAGE] [--attributes ATTRIBUTES] [--checksums]
```

**Examples:**
```bash
aws-get-case ip-ffr patient123                       # Fast download with tar (default)
aws-get-case ip-dev study-001 --attributes manager   # Downloads from specific environment
aws-get-case ip-ffr case-2024 --checksums            # Use rsync with checksums (slower, resumable)
```

**Features:**
- Uses `aws-list` to find instances (same as `aws-ssh`)
- Default attributes: "manager" (if not specified)
- Downloads from `/inst/zenith/AppData/Images/<case-name>` on remote
- Saves to `~/DICOM/<case-name>` locally
- **Default (tar)**: Fastest transfer, no compression overhead, not resumable
- **With --checksums (rsync)**: Slower but resumable, verifies data integrity

**Download Methods:**
- **tar (default)**: Fastest for initial downloads, but if interrupted you must start over
  - With `pv` installed: Shows progress bar with transfer rate and ETA
  - Without `pv`: Shows filenames as they transfer (install with `sudo apt install pv`)
- **rsync (--checksums)**: Slower but can resume interrupted downloads, use for unreliable connections

### aws-scale-up

Scale up Auto Scaling groups to 1 instance (min-size=1, max-size=1, desired-capacity=1).

**Usage:**
```bash
aws-scale-up <env>
```

**Examples:**
```bash
aws-scale-up fyodor-wolf-elucid    # Scale up all matching ASGs
```

**Filters:**
- `env` tag must match the provided environment name
- `Attributes` tag must be one of: `proc-bg`, `proc-vc-inf`, or `proc-render`

### aws-scale-down

Scale down Auto Scaling groups to 0 instances (min-size=0, max-size=0, desired-capacity=0).

**Usage:**
```bash
aws-scale-down <env>
```

**Examples:**
```bash
aws-scale-down fyodor-wolf-elucid  # Scale down all matching ASGs
```

**Filters:**
- `env` tag must match the provided environment name
- `Attributes` tag must be one of: `proc-bg`, `proc-vc-inf`, or `proc-render`

### aws-ecs-check

Check whether running ECS tasks are up to date with the latest image digest in GHCR. Useful for spotting stale services after a new image is built.

**Usage:**
```bash
aws-ecs-check <env> [--service SERVICE] [--profile PROFILE]
```

**Examples:**
```bash
aws-ecs-check fyodor-wolf-elucid               # Check all services
aws-ecs-check fyodor-wolf-elucid --service api # Check a specific service
```

**Output:**
- `[UP TO DATE]` — running digest matches the latest image in the registry
- `[STALE]` — a newer image is available for the same tag; redeploy with `aws-ecs-deploy`
- `[UNKNOWN]` — could not fetch the latest digest (check `gh auth status`)

**Requires:** `gh` CLI authenticated (`gh auth login`)

### aws-ecs-deploy

Force a new deployment for one or all ECS services in a cluster, pulling the latest image for the configured tag.

**Usage:**
```bash
aws-ecs-deploy <env> [service]
```

**Examples:**
```bash
aws-ecs-deploy fyodor-wolf-elucid           # Redeploy all services
aws-ecs-deploy fyodor-wolf-elucid api       # Redeploy api service only
aws-ecs-deploy fyodor-wolf-elucid worker-io # Redeploy worker-io service only
```

**How it works:**
1. Finds the ECS cluster with matching `env` tag
2. If no service specified, redeploys all active services in the cluster
3. Forces a new deployment using `aws ecs update-service --force-new-deployment`
4. Shows available services if the specified service is not found

**Typical workflow:**
```bash
aws-ecs-check fyodor-wolf-elucid    # identify stale services
aws-ecs-deploy fyodor-wolf-elucid   # redeploy all (or specify a single service)
```

## Environment Variables

- `AWS_PROFILE`: AWS profile to use (defaults to 'elucid-dev' or 'default' depending on script)

## Sharing

To share these scripts with others:

1. Copy the entire `aws-scripts` directory
2. Add the directory to PATH in their shell configuration
3. Ensure they have AWS CLI configured with appropriate credentials
4. Set the `AWS_PROFILE` environment variable if needed

## License

Internal use only.
