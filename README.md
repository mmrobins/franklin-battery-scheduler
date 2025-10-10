# FranklinWH Battery Scheduler

Automated scheduling for FranklinWH battery SOC (State of Charge) settings using GitHub Actions.

## Overview

This repository contains a bash script that sets your FranklinWH battery to self-consumption mode with configurable SOC thresholds. GitHub Actions automatically runs the script at scheduled times to optimize battery usage throughout the day.

## Default Schedule

- **6:50 AM PST**: Set to 65% SOC (morning mode)
- **4:55 PM PST**: Set to 35% SOC (afternoon mode)  
- **10:00 PM PST**: Set to 95% SOC (evening mode)

## Setup

### 1. Fork or Clone This Repository

Fork this repository to your GitHub account or clone it locally.

### 2. Configure GitHub Secrets

In your GitHub repository, go to **Settings → Secrets and variables → Actions** and add these repository secrets:

- `FRANKLIN_EMAIL`: Your FranklinWH account email
- `FRANKLIN_PASSWORD`: Your FranklinWH account password
- `FRANKLIN_GATEWAY_ID`: Your gateway ID (found in FranklinWH app under More → Site Address)

### 3. Adjust Timezone (Optional)

The workflow is configured for PST (UTC-8). To adjust for your timezone, edit `.github/workflows/battery-schedule.yml` and modify the cron expressions:

```yaml
# Example for EST (UTC-5):
- cron: '50 11 * * *'  # 6:50 AM EST
- cron: '55 22 * * *'  # 4:55 PM EST  
- cron: '0 4 * * *'    # 10:00 PM EST
```

### 4. Enable GitHub Actions

GitHub Actions should be automatically enabled. The workflow will run according to the schedule once you push the repository.

## Manual Usage

### Local Script Execution

```bash
# Set environment variables
export FRANKLIN_EMAIL="your_email@example.com"
export FRANKLIN_PASSWORD="your_password"
export FRANKLIN_GATEWAY_ID="your_gateway_id"

# Run script with desired SOC
./set_soc.sh 75
```

### Manual GitHub Actions Trigger

You can manually trigger the workflow from the GitHub Actions tab with a custom SOC value.

## Script Details

The `set_soc.sh` script:

- Takes one argument: SOC percentage (0-100)
- Uses FranklinWH's REST API to authenticate and set battery mode
- Sets the battery to self-consumption mode with the specified SOC threshold
- Provides success/error feedback
- Requires no Python dependencies (pure bash + curl + openssl)

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

## License

MIT License - feel free to modify and distribute.