# Story tests

Acceptance tests for the Todo Manager REST API, written as Gherkin user stories
and run with [behave](https://behave.readthedocs.io/). This suite is separate
from the pytest unit tests in `../test/` and shares no code with them.

## Running

1. Start the API: `java -jar runTodoManagerRestAPI-1.5.5.jar` (listens on `http://localhost:4567`).
2. From this folder:

   ```sh
   python3 -m venv .venv
   .venv/bin/pip install -r requirements.txt
   .venv/bin/behave
   ```

Set `TODO_API_URL` to test a server on another address.

## Run order

Scenarios run in a random order by default. The random order shuffles the
features, the scenarios in each feature and the rows of each `Examples` table.

```sh
behave                       # random order, seed printed at the start
behave -D seed=1234          # reproduce a random order
behave -D order=defined      # file order
behave -D order=reverse      # reverse file order
behave features/todos          # only the todo stories
behave --tags=@error         # only error flows (also @normal, @alternate, @todos, @story3, ...)
```

Each scenario creates its own objects, deletes them afterwards, and fails if the
server is not back in the state it started in.

## Layout

| Path | Contents |
|---|---|
| `behave.ini` | behave settings and the default run order |
| `features/<resource>.feature` | User stories for categories and projects |
| `features/todos/` | One feature file per todo story (behave allows one `Feature:` per file) |
| `features/steps/` | Step definitions: `common_steps.py` plus one module per feature |
| `features/environment.py` | Readiness check, run order, per-scenario cleanup |
| `features/api.py` | HTTP helpers (base URL, requests, server snapshot) |
| `features/story_helpers.py` | Step helpers: create with cleanup, lookup by title, parse types |
