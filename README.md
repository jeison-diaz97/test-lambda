# Dynamic PR Baseline Test for Lambda Deployment

This GitHub Actions workflow automates baseline testing for AWS Lambda deployments whenever a pull request is made to the `develop`, `staging`, or `main` branches. It dynamically detects the project's language (currently supporting Node.js and Python), installs dependencies, attempts to build (for Node.js), and simulates the creation of a deployment ZIP package. Finally, it posts a summary comment on the pull request with the outcome.

## How It Works

The pipeline is triggered on `pull_request` events targeting the specified branches. It consists of a single job, `pr_build_and_package_check`, which performs the following steps:

1.  **Checkout Code**: Fetches the repository content.
2.  **Detect Project Language**:
    * Checks for the presence of `package.json` to identify Node.js projects.
    * Checks for `requirements.txt` or `pyproject.toml` to identify Python projects.
    * Sets an output variable `detected_language` with the result (`node`, `python`, or `unknown`).
3.  **Node.js Specific Steps** (executed if `detected_language` is `node`):
    * **Setup Node.js**: Initializes a Node.js environment (version 18).
    * **Install Node.js dependencies and Build**:
        * Runs `npm install`.
        * Runs `npm ci` (Note: `npm ci` is typically used alone in CI for cleaner installs from a lock file. This workflow currently runs both `npm install` and `npm ci`).
        * Runs `npm run build --if-present` to execute a build script if defined in `package.json`.
    * **Test Create Node.js ZIP package**: Creates a test ZIP file named `lambda-deployment-node-pr-check.zip` containing `.js` files, excluding `.git`, `.github`, and `README.md`.
4.  **Python Specific Steps** (executed if `detected_language` is `python`):
    * **Setup Python**: Initializes a Python environment (version 3.9).
    * **Install Python dependencies**:
        * Upgrades `pip`.
        * If `pyproject.toml` is found, installs dependencies using Poetry (assumes Poetry is used; you might need to adjust for PDM or other tools).
        * If `requirements.txt` is found (and `pyproject.toml` is not), installs dependencies using `pip`.
        * Warns if neither dependency file is found.
    * **Test Create Python ZIP package**:
        * Creates a `python_deployment_package` directory.
        * Copies top-level `*.py` files into this directory.
        * Installs dependencies from `pyproject.toml` (by exporting to a temporary `requirements.for.packaging.txt` and using `pip install -t`) or `requirements.txt` directly into the `python_deployment_package` directory.
        * Zips the content of `python_deployment_package` into `lambda-deployment-python-pr-check.zip`.
        * Cleans up the temporary package directory.
5.  **Report on Language Detection**:
    * Always runs.
    * Outputs the detected language.
    * Posts a notice if the language was `unknown`, suggesting to add specific checks if the Lambda uses a different supported language.
    * Contains commented-out lines that could be enabled to fail the job if a supported language is not detected.
6.  **Post PR Summary Comment**:
    * Runs if the event is a pull request, regardless of the job's success or failure.
    * Uses `actions/github-script` to post or update a comment on the pull request.
    * The comment includes:
        * Overall status of the check (Passed/Failed).
        * The detected programming language.
        * A brief summary of the checks performed for the detected language or a warning if no specific checks were run.
        * A link to the detailed workflow run logs.
    * The script attempts to find and update an existing comment from this action (based on a signature, which is currently an empty string but could be made unique) or creates a new one.

## Variables

### Workflow Triggers

* `on.pull_request.branches`:
    * `develop`
    * `staging`
    * `main`

    The workflow runs when a pull request is opened or updated targeting any of these branches.

### Job Outputs

* `jobs.pr_build_and_package_check.outputs.detected_language`:
    * **Description**: The programming language detected in the project.
    * **Possible Values**: `node`, `python`, `unknown`.
    * **Usage**: Used by subsequent steps within the same job to conditionally execute language-specific commands.

### Environment Variables (Implicit)

* `GITHUB_OUTPUT`: A file path used by steps to set output parameters for subsequent steps (e.g., the `Detect Project Language` step writes `language=node` to this file).
* `GITHUB_TOKEN`: An automatically generated token provided by GitHub Actions, used by the `Post PR Summary Comment` step to authenticate with the GitHub API for posting comments. It has `contents: read` and `pull-requests: write` permissions as defined in the `permissions` block of the job.

### Configurable Parameters within Steps

* **Node.js Version** (in "Setup Node.js" step):
    * `with.node-version: '18'`
    * **Purpose**: Specifies the Node.js version to use. Should match your Lambda's Node.js runtime.
* **Python Version** (in "Setup Python" step):
    * `with.python-version: '3.9'`
    * **Purpose**: Specifies the Python version to use. Should be compatible with your Lambda's Python runtime.
* **Python Packaging for `pyproject.toml`**:
    * The workflow currently assumes `poetry` for projects with `pyproject.toml`. If you use a different tool like PDM, you'll need to modify the `Install Python dependencies` and `Test Create Python ZIP package` steps:
        * `pip install poetry` would change to `pip install pdm` (or your tool of choice).
        * `poetry install --no-interaction --no-ansi` would change to `pdm install` (or the equivalent for your tool).
        * `poetry export -f requirements.txt --output requirements.for.packaging.txt --without-hashes` would change to the equivalent command for your tool to export dependencies to a `requirements.txt` format for packaging.
* **Python Source File Location** (in "Test Create Python ZIP package" step):
    * The current script copies `*.py` files from the root: `find . -maxdepth 1 -name "*.py" -exec cp {} python_deployment_package/ \;`.
    * If your Python source code resides in a subdirectory (e.g., `src/` or `app/`), you'll need to adjust this copy command (e.g., `if [ -d app ]; then cp -r app/* python_deployment_package/; fi`).

## How to Use

1.  **Place this workflow file** in your repository at `.github/workflows/your-workflow-name.yml` (e.g., `.github/workflows/pr-lambda-check.yml`).
2.  **Ensure your project has the necessary configuration files** for language detection:
    * For Node.js: `package.json`
    * For Python: `requirements.txt` or `pyproject.toml`
3.  **Adjust language versions and specific commands** if needed (see "Configurable Parameters within Steps" above), especially for Python projects using tools other than Poetry with `pyproject.toml` or if your source files are not in the root directory.
4.  **Push your code and open a pull request** to one of the target branches (`develop`, `staging`, `main`).
5.  The workflow will automatically run. A comment will be posted on your PR with a summary of the checks.

## Code Examples / Snippets

### Detecting Language

```yaml
- name: Detect Project Language
  id: detect_language
  run: |
    if [ -f package.json ]; then
      echo "language=node" >> $GITHUB_OUTPUT
      echo "Detected Node.js project (package.json found)."
    elif [ -f requirements.txt ] || [ -f pyproject.toml ]; then
      echo "language=python" >> $GITHUB_OUTPUT
      echo "Detected Python project (requirements.txt or pyproject.toml found)."
    else
      echo "language=unknown" >> $GITHUB_OUTPUT
      echo "::warning::Could not detect a supported language (Node.js, Python) by checking for common project files."
    fi
