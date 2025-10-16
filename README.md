# FranklinWH Battery Scheduler

Automated scheduling for FranklinWH battery SOC (State of Charge) settings

## Overview

This repository contains a bash script that sets your FranklinWH battery to self-consumption mode with configurable SOC thresholds

The script itself can easily be [run manually](#Local-Script-Execution)

There are many ways this can be run on a schedule, there's some setup and documentation for some common ones

* Github Actions
* GitLab CI

## Setup

### 1. Fork or Clone This Repository

Fork this repository to your GitHub account or clone it locally.

### 2. Configure CI Secrets

Depending on your CI/CD provider, you will need to configure secrets.

#### GitHub Actions

In your GitHub repository, go to [**Settings → Secrets and variables →
Actions**](https://github.com/yourusername/franklin-battery-scheduler/settings/secrets/actions)
and add these repository secrets:

- `FRANKLIN_EMAIL`: Your FranklinWH account email
- `FRANKLIN_PASSWORD`: Your FranklinWH account password
- `FRANKLIN_GATEWAY_ID`: Your gateway ID (found in FranklinWH app under More → Site Address)
- `ENABLE_GITHUB_ACTIONS`: Set to `true` to enable GitHub Actions scheduling

#### GitLab CI

Go to your [GitLab project → **Settings → CI/CD → Variables**](https://gitlab.com/mmrobins/franklin-battery-scheduler/-/settings/ci_cd#js-cicd-variables-settings) and add:

- `FRANKLIN_EMAIL`: Your FranklinWH account email
- `FRANKLIN_PASSWORD`: Your FranklinWH account password (mark as **Masked**)
- `FRANKLIN_GATEWAY_ID`: Your gateway ID from the FranklinWH app
- `ENABLE_GITLAB_CI`: Set to `true` to enable GitLab CI scheduling

### 3. Adjust Timezone (Optional)

The workflow is configured for PST (UTC-8). To adjust for your timezone, edit `.github/workflows/battery-schedule.yml` and modify the cron expressions:

```yaml
# Example for EST (UTC-5):
- cron: '50 11 * * *'  # 6:50 AM EST
- cron: '55 22 * * *'  # 4:55 PM EST
- cron: '0 4 * * *'    # 10:00 PM EST
```

### 4. Enable CI

- **GitHub Actions**: GitHub Actions should be automatically enabled. The workflow will run according to the schedule once you push the repository.
- **GitLab CI**: See the [GitLab CI Setup](#gitlab-ci-setup-for-franklinwh-battery-scheduler) section for detailed instructions on setting up pipeline schedules.


## GitLab CI Setup for FranklinWH Battery Scheduler

GitLab CI provides better timezone support for scheduled pipelines compared to GitHub Actions.

### 1. Create GitLab Repository

1. Go to [GitLab.com](https://gitlab.com) and create a new project
2. Push your code to the GitLab repository:
   ```bash
   git remote add gitlab https://gitlab.com/yourusername/franklin-battery-scheduler.git
   git push gitlab main
   ```

### 2. Set Up Pipeline Schedules

You can create the schedules manually in the GitLab UI, or you can use the `glab` command-line tool.

#### Using `glab`

```bash
glab schedule create --cron "50 6 * * 1-5" --description "mid-peak 65% 6:50 AM" --ref main --variable "soc_target:65" --cronTimeZone "America/Los_Angeles"
glab schedule create --cron "00 16 * * 1-5" --description "peak prep 95% 4:00 PM" --ref main --variable "soc_target:95" --cronTimeZone "America/Los_Angeles"
glab schedule create --cron "55 16 * * 1-5" --description "peak drain 35% 4:55 PM" --ref main --variable "soc_target:35" --cronTimeZone "America/Los_Angeles"
glab schedule create --cron "10 21 * * 1-5" --description "off-peak recharge 95% 9:10 PM" --ref main --variable "soc_target:95" --cronTimeZone "America/Los_Angeles"
```

### Advantages of GitLab CI

1. **Native timezone support** - schedules automatically handle PST/PDT transitions
2. **Per-schedule variables** - each schedule can have different SOC targets
3. **Better reliability** - GitLab's scheduled pipelines are generally more consistent
4. **Free tier** - GitLab provides 400 minutes/month of CI/CD for free

### Manual Testing

You can manually trigger jobs from **CI/CD → Pipelines → Run Pipeline** and set the `SOC_VALUE` variable.

### Migration from GitHub Actions

1. Set up GitLab repository and schedules as above
2. Disable GitHub Actions schedules (or delete the `.github` folder)
3. Monitor GitLab pipelines to ensure they're running correctly

The same `set_soc.sh` script works in both environments!


## Manual Usage

### Local Script Execution

```bash
# Set environment variables
export FRANKLIN_EMAIL="your_email@example.com"
export FRANKLIN_PASSWORD="your_password"
export FRANKLIN_GATEWAY_ID="your_gateway_id"

# Run script with desired SOC
./set_soc.sh 75

# Enable debug mode for troubleshooting
DEBUG=true ./set_soc.sh 75
```

### Debug Mode

For troubleshooting, you can enable debug mode by setting `DEBUG=true`:

```bash
DEBUG=true ./set_soc.sh 65
```

Debug mode will show:
- All bash commands being executed
- Password hash generation
- Exact curl commands being run
- Full API responses
- Token extraction process
- Success/failure checks

This helps diagnose authentication issues, network problems, or API errors.

### Manual GitHub Actions Trigger

You can manually trigger the workflow from the GitHub Actions tab with a custom SOC value.

## Script Details

The `set_soc.sh` script:

- Takes one argument: SOC percentage (0-100)
- Uses FranklinWH's REST API to authenticate and set battery mode
- Sets the battery to self-consumption mode with the specified SOC threshold
- Provides success/error feedback
- Requires no Python dependencies (pure bash + curl + openssl)
- Includes debug mode for troubleshooting (set `DEBUG=true`)

## Customization

### Changing SOC Values

Edit the workflow file to change the SOC values:

```yaml
run: ./set_soc.sh 80  # Change from default 65%
```

### Changing Schedule Times

Modify the cron expressions in the workflow file. Use [crontab.guru](https://crontab.guru) to help generate cron expressions.

### Adding More Schedule Points

Add additional cron schedules and corresponding job steps to the workflow file.

## Troubleshooting

### Check GitHub Actions Logs

If the automation isn't working, check the Actions tab in your GitHub repository for error logs.

### Verify Secrets

Ensure all three secrets are correctly set in your repository settings.

### Test Locally

Test the script locally first to verify your credentials work:

```bash
./set_soc.sh 50
```

### Common Issues

- **Invalid credentials**: Double-check your email/password
- **Gateway ID**: Ensure you're using the correct gateway ID from the app
- **Network issues**: The script requires internet access to reach FranklinWH servers

## Security

- Never commit credentials directly to the repository
- All sensitive information is stored in GitHub Secrets
- The script only reads environment variables, never logs them

## FAQ

### Why is this written in bash?

Bash is lightweight, has no dependencies, and is natively supported in GitHub Actions runners.  It might not be pretty, but it gets the job done.

### Is the FranklinWH API documented?

Not that I know of.  I basically copied what was done in https://github.com/richo/franklinwh-python, but I always get annoyed setting up python depenencies, so I ported it to bash to be as easy to run as possible.

## License

MIT License - feel free to modify and distribute.
