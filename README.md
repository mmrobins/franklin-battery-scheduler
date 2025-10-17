# FranklinWH Battery Scheduler

Automated scheduling for FranklinWH battery SOC (State of Charge) settings

## Overview

This repository contains a bash script that sets your FranklinWH battery to self-consumption mode with configurable SOC thresholds

The script itself can easily be [run manually](#Local-Script-Execution)

There's lots of ways to automate running this script on a schedule.  One simple
way is to use cron jobs on a local machine or server, but this requires the
machine to be always on and connected to the internet, so a couple different
public CI/CD services are documented below

* [Github Actions](#github-actions)
* [GitLab CI](#gitlab-ci)

## Where to Find Your Gateway ID

In your [FranklinWH mobile app](https://www.franklinwh.com/support/articles/detail/how-can-i-download-the-franklinwh-app) go to:

* **Settings**
* ** Device Info **
* Copy the text after `SN:` - this is your Gateway ID

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

* All bash commands being executed
* Password hash generation
* Exact curl commands being run
* Full API responses
* Token extraction process
* Success/failure checks

This helps diagnose authentication issues, network problems, or API errors.

## GitHub Actions

GitHub Actions is a very popular platform, but it has enough issues that I gave up on it pretty quickly

* [cron schedules run 5-45 minutes late](./github_check_cron_drift.sh)
* no native timezone support (always UTC)
* no per-schedule variables (have to hardcode SOC values in the workflow)

The cron drift might not be as big a problem on paid plans or hosted runners,
but I wanted something free to run something 3-5 times a day

That said, if you want to go this route, follow the instructions below.

### 1. Fork or Clone This Repository

Fork this repository to your GitHub account

### 2. Configure CI Secrets

In your GitHub repository, go to [**Settings → Secrets and variables →
Actions**](https://github.com/yourusername/franklin-battery-scheduler/settings/secrets/actions)
and add these repository secrets:

* `FRANKLIN_EMAIL`: Your FranklinWH account email
* `FRANKLIN_PASSWORD`: Your FranklinWH account password
* `FRANKLIN_GATEWAY_ID`: Your gateway ID (found in FranklinWH app under More → Site Address)
* `ENABLE_GITHUB_ACTIONS`: Set to `true` to enable GitHub Actions scheduling

### 3. Adjust Schedules including Timezone

The workflow is configured for PST (UTC-8). To adjust for your timezone, edit
[.github/workflows/battery-schedule.yml](.github/workflows/battery-schedule.yml)
and modify the cron expressions:

```yaml
# Example for EST (UTC-5):
* cron: '50 11 * * *'  # 6:50 AM EST
* cron: '55 22 * * *'  # 4:55 PM EST
* cron: '0 4 * * *'    # 10:00 PM EST
```

Then you'll need to modify each of the steps to match the new times

```yaml
if: github.event.schedule == '50 11 * * *'
```

and adjust the SOC targets accordingly

## GitLab CI

GitLab CI is similar to GitHub Actions, but has some advantages, the biggest
one being running cron jobs closer to the time declared

1. **Better reliability** - GitLab's scheduled pipelines are generally more consistent
2. **Native timezone support** - You can set the timezone for each schedule
3. **Per-schedule variables** - each schedule can have different SOC targets
4. **Free tier** - GitLab provides 400 minutes/month of CI/CD for free

### 1. Fork or Clone This Repository

Fork this repository to your GitLab account

### 2. Configure CI Secrets

Go to your [GitLab project → **Settings → CI/CD → Variables**](https://gitlab.com/mmrobins/franklin-battery-scheduler/-/settings/ci_cd#js-cicd-variables-settings) and add:

* `FRANKLIN_EMAIL`: Your FranklinWH account email
* `FRANKLIN_PASSWORD`: Your FranklinWH account password (mark as **Masked**)
* `FRANKLIN_GATEWAY_ID`: Your gateway ID from the FranklinWH app
* `ENABLE_GITLAB_CI`: Set to `true` to enable GitLab CI scheduling

### 3. Set Up Pipeline Schedules

You can create the schedules manually in the GitLab UI, or you can use the `glab` command-line tool.

### Using `glab`

```bash
glab schedule create --cron "50 6 * * 1-5" --description "mid-peak 65% 6:50 AM" --ref main --variable "soc_target:65" --cronTimeZone "America/Los_Angeles"
glab schedule create --cron "00 16 * * 1-5" --description "peak prep 95% 4:00 PM" --ref main --variable "soc_target:95" --cronTimeZone "America/Los_Angeles"
glab schedule create --cron "55 16 * * 1-5" --description "peak drain 35% 4:55 PM" --ref main --variable "soc_target:35" --cronTimeZone "America/Los_Angeles"
glab schedule create --cron "10 21 * * 1-5" --description "off-peak recharge 95% 9:10 PM" --ref main --variable "soc_target:95" --cronTimeZone "America/Los_Angeles"
```

## FAQ

### Why is this written in bash?

Bash is lightweight, has no dependencies, and is natively supported just about everywhere you might wanna run this.  It might not be pretty, but it gets the job done.

### Is the FranklinWH API documented?

Not that I know of.  I basically copied what was done in
https://github.com/richo/franklinwh-python, but I always get annoyed setting up
python depenencies, so I ported it to bash to be as easy to run as possible.

## License

MIT License - feel free to modify and distribute.
