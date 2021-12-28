"""Activity statements randomization distribution"""

import json
import sys

from random import randint
from datetime import date, timedelta, datetime

today = date.today()


def patch_data(stream):
    """Patches dates fields to enlarge demonstration dataset consistency by
    transposing statements date generation to the last four current weeks.
    """

    for line in stream:

        # patch date (and keep time): reduce to days in the last four weeks
        statement = json.loads(line)

        new_date = today - timedelta(days=randint(0, 27))

        original_datetime = datetime.fromisoformat(statement["@timestamp"])

        statement["@timestamp"] = original_datetime.replace(
            year=new_date.year,
            month=new_date.month,
            day=new_date.day,
        ).isoformat()

        sys.stdout.write(f"{json.dumps(statement)}\n")


if __name__ == "__main__":

    patch_data(sys.stdin)
