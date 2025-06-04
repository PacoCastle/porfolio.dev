# Deployment to AWS Guide

This guide outlines the steps to deploy your Astro site to AWS using S3 for static website hosting and CloudFront for CDN.

## Prerequisites

*   An AWS account.
*   AWS CLI installed and configured with appropriate credentials.
*   Node.js and npm installed.

### Validating and Installing Prerequisites

1.  **AWS CLI:**

    *   **Validate:** Open a terminal and run:

        ```bash
        aws --version
        ```

        If AWS CLI is installed, you'll see the version information.

    *   **Install:** If not installed, follow the instructions on the [AWS CLI documentation](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).

2.  **Node.js and npm:**

    *   **Validate:** Open a terminal and run:

        ```bash
        node -v
        npm -v
        ```

        This will display the versions of Node.js and npm if they are installed.

    *   **Install:** If not installed, download and install Node.js from [nodejs.org](https://nodejs.org/). npm is included with Node.js.

## 1. Clone the Repository

First, clone your project repository to your local machine.  For example:

```bash
git clone https://github.com/your-username/your-astro-project.git
cd your-astro-project
```

If you are working on a development branch, switch to it:

```bash
git checkout develop
```

## 2. Install Dependencies

Install the project dependencies:

```bash
npm install
```

## 3. Build Your Astro Site

Ensure you have a production build of your Astro site:

```bash
npm run build
```

This command generates a `dist` directory (or the directory you configured in your Astro config) containing the static files.

## 4. Configure AWS CLI User

It's recommended to create a dedicated AWS IAM user for CLI access with limited permissions.

1.  **Create an IAM User:**
    *   Go to the AWS IAM (Identity and Access Management) service in the AWS Management Console.
    *   Click "Users" and then "Add user".
    *   Enter a user name (e.g., `astro-deployer`).
    *   Select "Access key - Programmatic access".
    *   Click "Next: Permissions".
    *   Choose "Attach existing policies directly".
    *   Select the `AdministratorAccess` policy **(Use with caution, consider creating a custom policy with more restrictive permissions for production)**.
    *   Click "Next: Tags" (optional).
    *   Click "Next: Review".
    *   Click "Create user".
    *   **Important:** Download the `.csv` file containing the `Access key ID` and `Secret access key`.  This is the only time you'll see the secret key.

2.  **Configure AWS CLI:**

    *   **Check if AWS CLI is configured:**

        ```bash
        aws configure list
        ```

        If it's not configured, or you want to configure a new profile, proceed.

    *   **Configure AWS CLI with the new user's credentials:**

        ```bash
        aws configure
        ```

        Enter the `Access key ID`, `Secret access key`, default region (e.g., `us-east-1`), and default output format (e.g., `json`).

## 5. Create an S3 Bucket

1.  Go to the AWS Management Console and open the S3 service.
2.  Click "Create bucket".
3.  Enter a globally unique bucket name (e.g., `your-astro-site-name`).
4.  Choose the AWS Region closest to your users.
5.  Under "Object Ownership", choose "ACLs disabled (recommended)".
6.  Under "Block Public Access settings for this bucket", uncheck "Block all public access". Acknowledge the warning.
7.  Leave other settings as default and click "Create bucket".

## 6. Configure S3 Bucket for Static Website Hosting

1.  Select the bucket you created.
2.  Go to the "Properties" tab.
3.  Scroll down to the "Static website hosting" section and click "Edit".
4.  Select "Enable".
5.  In the "Index document" field, enter `index.html`.
6.  (Optional) In the "Error document" field, enter `error.html` (create an `error.html` file in your `public` directory, build the site, and upload it to the bucket).
7.  Click "Save changes".
8.  Note the "Bucket website endpoint" URL. You'll need this later.

## 7. Set Bucket Permissions

1.  Go to the "Permissions" tab.
2.  Under "Bucket policy", click "Edit".
3.  Add the following bucket policy, replacing `your-astro-site-name` with your actual bucket name:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::your-astro-site-name/*"
    }
  ]
}
```

4.  Click "Save changes".

## 8. Upload Your Astro Site Files to S3

Use the AWS CLI to upload the contents of your Astro site's `dist` directory to the root of the S3 bucket.

First, configure the AWS CLI with your credentials:

```bash
aws configure
```

Then, upload the files:

```bash
aws s3 sync dist s3://your-astro-site-name --delete
```

Replace `your-astro-site-name` with your bucket name. The `--delete` flag removes files from the bucket that are not present in the `dist` directory.

## 9. (Optional) Configure CloudFront CDN

Using CloudFront provides caching, improved performance, and SSL/TLS encryption.

1.  Go to the CloudFront service in the AWS Management Console.
2.  Click "Create distribution".
3.  Under "Origin domain", enter the S3 bucket website endpoint URL you noted earlier (e.g., `your-astro-site-name.s3-website-us-east-1.amazonaws.com`). **Do not select the bucket from the dropdown; enter the website endpoint.**
4.  Under "Origin access", select "Legacy access identities".
5.  Choose "Create a new OAC" and give it a name.
6.  Choose "Yes, update bucket policy".
7.  Under "Default cache behavior", select "Redirect HTTP to HTTPS".
8.  Under "Distribution settings", enter any "Alternate domain names (CNAMEs)" you want to use (e.g., `www.yourdomain.com`). You'll need to configure your DNS records later to point to the CloudFront distribution.
9.  If you entered CNAMEs, under "Custom SSL certificate", request or import a certificate from AWS Certificate Manager (ACM). The certificate must be in the `us-east-1` region.
10. Click "Create distribution".

## 10. Configure DNS (If Using CloudFront with a Custom Domain)

1.  Go to your DNS provider (e.g., Route 53, GoDaddy, Namecheap).
2.  Create a CNAME record that points your custom domain (e.g., `www.yourdomain.com`) to the CloudFront distribution's domain name (e.g., `d111111abcdef8.cloudfront.net`).

## Summary of Steps

1.  Clone the Repository: `git clone <repository-url>`
2.  Install Dependencies: `npm install`
3.  Build Astro Site: `npm run build`
4.  Create S3 Bucket: Configure for static website hosting.
5.  Set S3 Bucket Permissions: Add a bucket policy to allow public read access.
6.  Upload Files to S3: `aws s3 sync dist s3://your-astro-site-name --delete`
7.  Create CloudFront Distribution (Optional): Configure to use the S3 bucket as the origin.
8.  Configure DNS (Optional): Create a CNAME record pointing to the CloudFront distribution.

This setup provides a scalable and cost-effective way to host your Astro site on AWS. Remember to invalidate the CloudFront cache after deployments to ensure users get the latest version of your site. You can do this from the AWS console or via the AWS CLI.

```bash
aws cloudfront create-invalidation --distribution-id <your-distribution-id> --paths "/*"
```

Replace `<your-distribution-id>` with your CloudFront distribution ID.
