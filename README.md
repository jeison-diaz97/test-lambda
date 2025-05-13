# Deploy Lambda to AWS 🚀

This GitHub Actions workflow automates the deployment of an AWS Lambda function across different environments: Develop, Staging, and Production. The deployment is triggered by pushes to specific branches.

## 🌟 Introduction

This workflow is designed to streamline the deployment process of a Node.js AWS Lambda function. It leverages GitHub Actions to build, package, and deploy the function to the corresponding AWS environment based on the branch being pushed to. It uses OpenID Connect (OIDC) for secure authentication with AWS.

##  Variablen und Configuration ⚙️

This workflow utilizes GitHub Actions secrets to securely store sensitive information. These secrets need to be configured in your repository's settings under `Settings > Secrets and variables > Actions`.

### Environment-Specific Secrets:

For each environment (develop, staging, production), you need to configure the following secrets within the respective GitHub Environment:

* `AWS_ROLE_ARN_DEVELOP`: The ARN of the IAM role for the **Develop** environment that GitHub Actions will assume to deploy to AWS.
* `AWS_ROLE_ARN_STAGING`: The ARN of the IAM role for the **Staging** environment.
* `AWS_ROLE_ARN_PRODUCTION`: The ARN of the IAM role for the **Production** environment.
* `AWS_REGION`: The AWS region where the Lambda function will be deployed (e.g., `us-east-1`). This secret can be defined once at the repository level or per environment if regions differ.

### Workflow Variables:

* `node-version`: Specifies the version of Node.js to use for the build process. Currently set to `'18'`. You can modify this in the workflow file if needed.
* `LAMBDA_FUNCTION_NAME`: The name of your AWS Lambda function. In this workflow, it's hardcoded as `test_lambda`. You should change this to match your actual Lambda function name in the `Deploy to AWS Lambda` steps.

## How It Works 🛠️

The workflow is defined with three main jobs, one for each environment: `deploy_develop`, `deploy_staging`, and `deploy_production`.

### Trigger Conditions:

* **Push to `develop` branch**: Triggers the `deploy_develop` job.
* **Push to `staging` branch**: Triggers the `deploy_staging` job.
* **Push to `main` branch**: Triggers the `deploy_production` job. (Note: If you use `master` for production, update this in the workflow file).

### Deployment Jobs:

Each deployment job (`deploy_develop`, `deploy_staging`, `deploy_production`) follows these steps:

1.  **Conditional Execution**:
    * The job only runs if the push event is on its designated branch (e.g., `deploy_develop` only runs for pushes to `develop`).
    * `if: github.ref == 'refs/heads/BRANCH_NAME'`

2.  **Set Environment Name**:
    * Specifies the GitHub Environment for the job, allowing for environment-specific secrets and protection rules.
    * `environment: develop` (or `staging`, `production`)

3.  **Permissions**:
    * Grants necessary permissions for OIDC authentication with AWS.
    * `id-token: write` (to request a JWT OIDC token)
    * `contents: read` (to checkout the repository code)

4.  **Checkout Code**:
    * Checks out the repository's code using the `actions/checkout@v4` action.
    * ```yaml
      - name: Checkout code
        uses: actions/checkout@v4
      ```

5.  **Setup Node.js**:
    * Sets up the specified Node.js environment using the `actions/setup-node@v4` action.
    * ```yaml
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
      ```

6.  **Install Dependencies**:
    * Installs project dependencies using npm. It runs `npm install`, `npm ci` (for clean installs), and `npm run build --if-present` (if a build script exists in `package.json`).
    * ```yaml
      - name: Install dependencies
        run: |
          npm install
          npm ci
          npm run build --if-present
      ```

7.  **Create ZIP Package**:
    * Creates a ZIP file named `lambda-deployment.zip` containing all JavaScript files (`*.js`). It excludes the `.git` directory, `.github` workflows directory, and the `README.md` file.
    * ```yaml
      - name: Create ZIP package
        run: |
          zip lambda-deployment.zip *.js -x ".git/*" ".github/*" "README.md"
      ```

8.  **Configure AWS Credentials (OIDC)**:
    * Configures AWS credentials by assuming an IAM role using OIDC. It uses the `aws-actions/configure-aws-credentials@v4` action.
    * The `role-to-assume` and `aws-region` are fetched from the GitHub secrets.
    * **Example for Develop:**
        ```yaml
        - name: Configure AWS Credentials (OIDC)
          uses: aws-actions/configure-aws-credentials@v4
          with:
            role-to-assume: ${{ secrets.AWS_ROLE_ARN_DEVELOP }}
            aws-region: ${{ secrets.AWS_REGION }}
        ```

9.  **Deploy to AWS Lambda**:
    * Updates the AWS Lambda function's code using the AWS CLI.
    * It specifies the function name (`test_lambda` - **remember to change this!**), the ZIP file, and the AWS region.
    * ```yaml
      - name: Deploy to AWS Lambda
        run: |
          aws lambda update-function-code \
            --function-name test_lambda \
            --zip-file fileb://lambda-deployment.zip \
            --region ${{ secrets.AWS_REGION }}
      ```

### Job Dependencies (Optional):

* The `deploy_staging` job has an optional `needs: deploy_develop` dependency. This means the staging deployment will only start if the development deployment was successful.
* Similarly, `deploy_production` has an optional `needs: deploy_staging` dependency.

You can uncomment or remove these `needs` clauses based on your desired deployment strategy.

## Step-by-Step Usage 📖

1.  **Configure AWS IAM Roles for OIDC**:
    * For each environment (Develop, Staging, Production), create an IAM role in your AWS account.
    * Configure the trust relationship of this IAM role to allow GitHub Actions to assume it via OIDC. Refer to the [AWS documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html) and the [GitHub Actions documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services) for detailed instructions.
    * Ensure the IAM role has the necessary permissions to update your Lambda function (e.g., `lambda:UpdateFunctionCode`).

2.  **Set up GitHub Environments and Secrets**:
    * In your GitHub repository, go to `Settings > Environments`.
    * Create three environments: `develop`, `staging`, and `production`.
    * For each environment, add the required secrets:
        * `AWS_ROLE_ARN_DEVELOP` (for `develop` environment)
        * `AWS_ROLE_ARN_STAGING` (for `staging` environment)
        * `AWS_ROLE_ARN_PRODUCTION` (for `production` environment)
        * `AWS_REGION` (can be set per environment or at the repository level under `Settings > Secrets and variables > Actions`).

3.  **Customize Workflow Variables**:
    * Open the workflow file (e.g., `.github/workflows/deploy-lambda.yml`).
    * **Crucially**, change the `--function-name` in the `Deploy to AWS Lambda` steps from `test_lambda` to your actual Lambda function's name for each job.
    * Adjust the `node-version` if your project requires a different Node.js version.

4.  **Commit and Push**:
    * Commit the workflow file to your repository.
    * When you push code to the `develop`, `staging`, or `main` branches, the corresponding deployment job will automatically trigger.

5.  **Monitor Deployments**:
    * Go to the "Actions" tab in your GitHub repository to monitor the progress and logs of your deployments.
    * If you configured environment protection rules (e.g., required reviewers for production), the deployment to that environment will pause for approval.

## Code Examples 📝

### Configuring AWS Credentials Step (Example for Staging):

```yaml
- name: Configure AWS Credentials (OIDC)
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN_STAGING }}
    aws-region: ${{ secrets.AWS_REGION }}