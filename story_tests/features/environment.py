"""Behave hooks for the story tests.

- before_all checks that the Todo Manager is reachable and fixes the run order.
- Every scenario records the objects it creates in `context.created`; after_scenario
  deletes them and checks the server is back in the state it started in, so
  scenarios are independent and can run in any order.

Run order is chosen with the `order` userdata (behave.ini, or -D on the command line):

    behave                      # random order, new seed each run (printed at start)
    behave -D seed=1234         # random order, reproduce a previous run
    behave -D order=defined     # file order
    behave -D order=reverse     # reverse file order
"""

import random
import sys
from pathlib import Path

# api.py and story_helpers.py live next to this file and are shared by the step modules.
sys.path.insert(0, str(Path(__file__).resolve().parent))

from api import call, not_ready_reason, snapshot  # noqa: E402

ORDERS = ("random", "defined", "reverse")


def _reorder(context, items):
    """Reorder a list of features / scenarios / example rows in place."""
    if context.order == "random":
        context.rng.shuffle(items)
    elif context.order == "reverse":
        items.reverse()


def _reorder_children(context, container):
    """Reorder the scenarios (or rules) of a feature or rule, and the example
    rows of every scenario outline in it."""
    _reorder(context, container.run_items)
    for item in container.run_items:
        if hasattr(item, "scenarios") and not hasattr(item, "run_items"):  # ScenarioOutline
            _reorder(context, item.scenarios)


def before_all(context):
    # When the API is down, every scenario still runs and fails at its Background step
    # "Given the Todo Manager API is running". Aborting here instead would make behave
    # report the skipped features as "passed".
    reason = not_ready_reason()
    context.not_ready = reason and (
        f"System not ready: {reason}. Start it with: java -jar runTodoManagerRestAPI-1.5.5.jar"
    )
    if context.not_ready:
        print(context.not_ready + "\n", file=sys.stderr)
        context.order = "defined"
        return

    userdata = context.config.userdata
    context.order = userdata.get("order", "random").lower()
    if context.order not in ORDERS:
        raise SystemExit(f"Unknown order {context.order!r}; use one of {', '.join(ORDERS)}")

    if context.order == "random":
        seed = int(userdata["seed"]) if "seed" in userdata else random.randrange(10**6)
        context.rng = random.Random(seed)
        print(f"Story tests in random order, seed {seed} (reproduce with: behave -D seed={seed})\n")
    else:
        print(f"Story tests in {context.order} order\n")

    # run_model() iterates this same list after before_all returns.
    _reorder(context, context._runner.features)


def before_feature(context, feature):
    _reorder_children(context, feature)


def before_rule(context, rule):
    _reorder_children(context, rule)


def before_scenario(context, scenario):
    # Without the API there is no state to snapshot; the Background step reports the failure.
    context.initial_state = None if context.not_ready else snapshot()
    context.created = []   # (collection, id) of every object this scenario created
    context.objects = {}   # title -> (collection, id), for steps that refer to objects by title
    context.response = None


def after_scenario(context, scenario):
    if context.not_ready:
        return
    # Delete in reverse so dependent objects go first.
    for collection, object_id in reversed(context.created):
        call("DELETE", f"/{collection}/{object_id}")
    assert snapshot() == context.initial_state, (
        f"Scenario '{scenario.name}' did not restore the system to its initial state"
    )
