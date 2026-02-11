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

## Features

- **Automatic Authentication**: All scripts automatically detect if your AWS SSO session is active and prompt for login if expired
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

SSH into the first instance returned by aws-list for a given search term.

**Usage:**
```bash
aws-ssh <search-term> [--profile PROFILE] [--stage STAGE] [--attributes ATTRIBUTES]
```

**Examples:**
```bash
aws-ssh production                        # SSH to first production instance
aws-ssh web-server                        # SSH to first instance matching "web-server"
aws-ssh my-env --attributes proc-render   # SSH to first proc-render instance
aws-ssh dev --stage production            # SSH to first dev instance in production stage
```

### aws-ssm-session

Connect to EC2 instances via AWS Systems Manager Session Manager (more secure than SSH).

**Usage:**
```bash
aws-ssm-session <instance_name> [--stage STAGE] [--attributes ATTRIBUTES]
```

**Examples:**
```bash
aws-ssm-session my-instance                           # Connect with default attributes
aws-ssm-session my-instance --stage production        # Connect to production instance
aws-ssm-session my-instance --attributes proc-render  # Connect to render process instance
```

**Default attributes:** "manager"

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

### aws-ecs-deploy

Force a new deployment for an ECS service in a cluster.

**Usage:**
```bash
aws-ecs-deploy <env> <service>
```

**Examples:**
```bash
aws-ecs-deploy fyodor-wolf-elucid api      # Force redeploy api service
aws-ecs-deploy fyodor-wolf-elucid worker-3p # Force redeploy worker-3p service
```

**How it works:**
1. Finds the ECS cluster with matching `env` tag
2. Verifies the service exists in that cluster
3. Forces a new deployment using `aws ecs update-service --force-new-deployment`
4. Shows available services if the specified service is not found

**Filters:**
- `env` tag on the ECS cluster must match the provided environment name

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
