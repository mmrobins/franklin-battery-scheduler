# GitLab CI Setup for FranklinWH Battery Scheduler

GitLab CI provides better timezone support for scheduled pipelines compared to GitHub Actions.

## Setup Steps

### 1. Create GitLab Repository

1. Go to [GitLab.com](https://gitlab.com) and create a new project
2. Push your code to the GitLab repository:
   ```bash
   git remote add gitlab https://gitlab.com/yourusername/franklin-battery-scheduler.git
   git push gitlab main
   ```

### 2. Configure CI/CD Variables

Go to your GitLab project → **Settings → CI/CD → Variables** and add:

- `FRANKLIN_EMAIL`: Your FranklinWH account email
- `FRANKLIN_PASSWORD`: Your FranklinWH account password (mark as **Masked**)
- `FRANKLIN_GATEWAY_ID`: Your gateway ID from the FranklinWH app
- `ENABLE_GITLAB_CI`: Set to `true` to enable GitLab CI scheduling

### 3. Set Up Pipeline Schedules

Go to your GitLab project → **CI/CD → Schedules** and create 4 schedules:

#### Morning Mid-Peak (6:50 AM Pacific)
- **Description**: Morning Mid-Peak 65% SOC
- **Interval Pattern**: `50 6 * * 1-5` 
- **Timezone**: `America/Los_Angeles`
- **Target Branch**: `main`
- **Variables**: 
  - `SOC_TARGET` = `65`

#### Peak Prep (4:00 PM Pacific)
- **Description**: Peak Prep 95% SOC
- **Interval Pattern**: `0 16 * * 1-5`
- **Timezone**: `America/Los_Angeles`
- **Target Branch**: `main`
- **Variables**:
  - `SOC_TARGET` = `95`

#### Peak Drain (4:55 PM Pacific)
- **Description**: Peak Drain 35% SOC
- **Interval Pattern**: `55 16 * * 1-5`
- **Timezone**: `America/Los_Angeles`
- **Target Branch**: `main`
- **Variables**:
  - `SOC_TARGET` = `35`

#### Off-Peak Recharge (9:10 PM Pacific)
- **Description**: Off-Peak Recharge 95% SOC
- **Interval Pattern**: `10 21 * * 1-5`
- **Timezone**: `America/Los_Angeles`
- **Target Branch**: `main`
- **Variables**:
  - `SOC_TARGET` = `95`

## Advantages of GitLab CI

1. **Native timezone support** - schedules automatically handle PST/PDT transitions
2. **Per-schedule variables** - each schedule can have different SOC targets
3. **Better reliability** - GitLab's scheduled pipelines are generally more consistent
4. **Free tier** - GitLab provides 400 minutes/month of CI/CD for free

## Manual Testing

You can manually trigger jobs from **CI/CD → Pipelines → Run Pipeline** and set the `SOC_VALUE` variable.

## Migration from GitHub Actions

1. Set up GitLab repository and schedules as above
2. Disable GitHub Actions schedules (or delete the `.github` folder)
3. Monitor GitLab pipelines to ensure they're running correctly

The same `set_soc.sh` script works in both environments!