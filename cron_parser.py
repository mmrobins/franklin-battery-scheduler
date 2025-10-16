#!/usr/bin/env python3

import sys
from croniter import croniter
from datetime import datetime

if len(sys.argv) != 3:
    print("Usage: cron_parser.py <cron_expression> <timestamp>", file=sys.stderr)
    sys.exit(1)

cron_expression = sys.argv[1]
timestamp = int(sys.argv[2])

base_time = datetime.fromtimestamp(timestamp)

cron = croniter(cron_expression, base_time)
print(int(cron.get_prev(datetime).timestamp()))
