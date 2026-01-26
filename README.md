# AWS Scripts

A collection of AWS management scripts for working with EC2 instances and Auto Scaling groups.

## Installation

Add the `aws-scripts` directory to your PATH:

```bash
export PATH="$HOME/aws-scripts:$PATH"
```

Add this line to your `~/.bashrc` or `~/.zshrc` to make it persistent.

## Prerequisites

- AWS CLI installed and configured
- AWS profile set (default uses `$AWS_PROFILE` environment variable)
- Appropriate AWS permissions for EC2, Auto Scaling, and SSM

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
aws-ssh <search-term>
```

**Examples:**
```bash
aws-ssh production     # SSH to first production instance
aws-ssh web-server     # SSH to first instance matching "web-server"
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

**Default attributes:** "Attribute Manager"

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
