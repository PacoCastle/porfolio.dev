<!-- filepath: c:\GitHubClean\Astro\porfolio.dev\DEPLOYMENT.md -->
# Deployment to AWS Guide

This guide outlines the steps to deploy your Astro site to AWS.  
**Deployment options:**  
- [Netlify](#netlify)
- [S3 Bucket](#s3-bucket)  
- [ECS Cluster](#ecs-cluster)  

## Netlify

You can easily deploy your Astro site to [Netlify](https://www.netlify.com/) for free static hosting.

- Netlify website: [https://www.netlify.com/](https://www.netlify.com/)

### Create a Netlify Account

1. Go to [https://app.netlify.com/signup](https://app.netlify.com/signup).
2. Sign up using your email, GitHub, GitLab, or Bitbucket account.
3. Follow the prompts to complete your account setup.

### 1. Build Your Astro Site

```bash
npm install
npm run build
```

### 2. Deploy with Netlify CLI

1. Install the Netlify CLI globally (if not already installed):  
   See [Netlify CLI Installation Guide](https://docs.netlify.com/cli/get-started/) for details and configuration instructions.

    ```bash
    npm install -g netlify-cli
    ```

2. Login to your Netlify account:

    ```bash
    netlify login
    ```

3. Deploy your site (from the project root):

    ```bash
    netlify deploy --dir=dist
    ```

    - Follow the prompts to create a new site or link to an existing one.
    - For production deployment, use:

    ```bash
    netlify deploy --prod --dir=dist
    ```

### 3. Deploy via Netlify Web UI

1. Go to [app.netlify.com](https://app.netlify.com/) and log in.
2. Click "Add new site" > "Import an existing project".
3. Connect your GitHub repository and follow the prompts.
4. Set the build command to `npm run build` and the publish directory to `dist`.
5. Click "Deploy site".

Your Astro site will be live on a Netlify URL, and you can add a custom domain if desired.

---

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

3.  **AWS CLI User for Deployments:**

    To securely execute AWS CLI instructions, it is recommended to create a dedicated IAM user with programmatic access:

    1. Go to the AWS Management Console and open the IAM service.
    2. Click "Users" > "Add user".
    3. Enter a user name (e.g., `general-cli-user`).
    4. (Recommended) Do not enable programmatic access at this step. Instead, create the user first.
    5. Click "Next: Permissions".
    6. Attach the necessary policies (e.g., `AmazonS3FullAccess`, `CloudFrontFullAccess`, and for ECS deployments, `AmazonEC2ContainerRegistryFullAccess`, `AmazonECS_FullAccess`). For more restrictive permissions, create a custom policy.
    7. Complete the steps to create the user.

    > **Note:** If you are creating programmatic access through access keys or service-specific credentials for AWS CodeCommit or Amazon Keyspaces, you can generate them after you create this IAM user.

    8. After the user is created, go to the user's "Security credentials" tab and click "Create access key".
    9. When prompted for the use case, select:
        - **Command Line Interface (CLI):**
        - *You plan to use this access key to enable the AWS CLI to access your AWS account.*
    10. Download the `.csv` file with the Access Key ID and Secret Access Key.
    11. Use these credentials to configure the AWS CLI with `aws configure`:

        - Open a terminal.
        - Run:
            ```bash
            aws configure
            ```
        - Enter the Access Key ID and Secret Access Key from the `.csv` file.
        - Enter your preferred default region (e.g., `us-east-2`).
        - Enter your preferred default output format (e.g., `json`).

## S3 Bucket

This section covers deploying your Astro site as a static website using S3 and CloudFront.

### 1. Clone the Repository

First, clone your project repository to your local machine.  For example:

```bash
git clone https://github.com/PacoCastle/porfolio.dev.git
cd porfolio.dev
```

If you are working on a development branch, switch to it:

```bash
git checkout develop
```

### 2. Install Dependencies

Install the project dependencies:

```bash
npm install
```

### 3. Build Your Astro Site

Ensure you have a production build of your Astro site:

```bash
npm run build
```

This command generates a `dist` directory (or the directory you configured in your Astro config) containing the static files.

### 4. Create an S3 Bucket

1. Go to the AWS Management Console and open the S3 service.
2. Click "Create bucket".
3. Enter a globally unique bucket name (e.g., `your-astro-site-name`).
4. Choose the AWS Region closest to your users.
5. Under "Object Ownership", choose "ACLs disabled (recommended)".
6. Under "Block Public Access settings for this bucket", uncheck "Block all public access". Acknowledge the warning.
7. Leave other settings as default and click "Create bucket".

### 5. Configure S3 Bucket for Static Website Hosting

1. Select the bucket you created.
2. Go to the "Properties" tab.
3. Scroll down to the "Static website hosting" section and click "Edit".
4. Select "Enable".
5. In the "Index document" field, enter `index.html`.
6. (Optional) In the "Error document" field, enter `error.html` (create an `error.html` file in your `public` directory, build the site, and upload it to the bucket).
7. Click "Save changes".
8. Note the "Bucket website endpoint" URL. You'll need this later.

### 6. Set Bucket Permissions

1. Go to the "Permissions" tab.
2. Under "Bucket policy", click "Edit".
3. Add the following bucket policy, replacing `your-astro-site-name` with your actual bucket name:

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

4. Click "Save changes".

### 7. Upload Your Astro Site Files to S3

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

### 8. (Optional) Configure CloudFront CDN

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

### 9. (Optional) Configure DNS (If Using CloudFront with a Custom Domain)

1.  Go to your DNS provider (e.g., Route 53, GoDaddy, Namecheap).
2.  Create a CNAME record that points your custom domain (e.g., `www.yourdomain.com`) to the CloudFront distribution's domain name (e.g., `d111111abcdef8.cloudfront.net`).

### Summary of Steps

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

---

## ECS Cluster

This section covers deploying your Astro site using Docker containers on AWS ECS (Elastic Container Service).

### 1. Prepare Dockerfile

You can use the [`Dockerfile`](./Dockerfile) provided in the project root as an example for building and serving your Astro site efficiently.

```Dockerfile
# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# Stage 2: Serve
FROM node:20-alpine

WORKDIR /app

COPY --from=builder /app/package*.json ./
RUN npm install --omit=dev

COPY --from=builder /app/dist ./dist

RUN npm install -g serve

EXPOSE 3000

CMD ["serve", "dist", "-l", "3000"]
```

### 2. Create an Elastic Container Registry (ECR)

Before building and pushing your Docker image, create an ECR repository to store your container images:

1. Go to the ECR service in the AWS Management Console.
2. Click "Create repository".
3. Enter a repository name (e.g., `porfolio-repository`).
4. Leave other settings as default or adjust as needed.
5. Click "Create repository".
6. Note the repository URI (e.g., `277426079602.dkr.ecr.us-east-2.amazonaws.com/porfolio-repository`).

Alternatively, you can create the repository using AWS CLI:

```bash
aws ecr create-repository --repository-name portfolio-repository
```

### 3. Build and Push Docker Image

Build your Docker image and push it to Amazon ECR (Elastic Container Registry):

```bash
# Authenticate Docker to your ECR registry  e.g. -> aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 277426079602.dkr.ecr.us-east-2.amazonaws.com
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<region>.amazonaws.com

# Build your Docker image e.g. -> docker build -t porfolio-repository .
docker build -t porfolio .

# Tag your image for ECR e.g. -> docker tag porfolio:latest 277426079602.dkr.ecr.us-east-2.amazonaws.com/porfolio:latest
docker tag porfolio:latest <aws_account_id>.dkr.ecr.<region>.amazonaws.com/porfolio-repository:latest

# Push the image to ECR e.g. -> docker push 277426079602.dkr.ecr.us-east-2.amazonaws.com/porfolio-repository:latest
docker push <aws_account_id>.dkr.ecr.<region>.amazonaws.com/porfolio-repository:latest
```

### 4. Run the Image from ECR

You can run your Docker image stored in ECR either from the AWS Console (ECS) or using CLI commands.

#### **A. Run via AWS Console (ECS Fargate or EC2)**

1. Go to the ECS service in the AWS Management Console.
2. Create a new **Cluster** (choose "EC2" or "Fargate" as needed).
3. Create a new **Task Definition**:
    - Launch type: Fargate or EC2.
    - Add a container:
        - Image: `<aws_account_id>.dkr.ecr.<region>.amazonaws.com/porfolio-repository:latest`
        - Port mappings: `3000`
    - Set memory and CPU as needed.
4. Create a **Service** using this task definition.
5. Configure networking to allow inbound traffic on port 3000:
    - **VPC/Subnets:**  
      - Choose the VPC where you want to run your ECS service.  
      - Select one or more **public subnets** (these are subnets with a route to an Internet Gateway) if you want your service to be accessible from the internet.  
      - If unsure, in the AWS Console, go to VPC > Subnets and check the "Route Table" for a route to an "igw-" (Internet Gateway) resource.  
      - For private/internal services, select private subnets instead.
    - **Security Group:** Create or select a security group and add an inbound rule:
        - Type: Custom TCP
        - Port range: 3000
        - Source: 0.0.0.0/0 (for public access) or restrict to your IP/CIDR as needed.
    - **Load Balancer (optional):** If using a load balancer, ensure it forwards traffic to port 3000 on your ECS tasks.
6. Deploy the service and use the assigned public IP or load balancer DNS to access your app.

    - **How to find the public IP:**  
      - In the ECS Console, go to your cluster > Tasks, select your running task, and look for the "ENI Id" (Elastic Network Interface).
      - Click the ENI link to open it in the EC2 Console. The "Public IPv4 address" field shows the public IP assigned to your task.
      - If using a load balancer, use the DNS name provided in the EC2 or ECS Console.

#### **B. Run Locally or on an EC2 Instance via CLI**

1. Authenticate Docker to your ECR registry (if not already done):

    ```bash
    aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<region>.amazonaws.com
    # e.g.
    # aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 277426079602.dkr.ecr.us-east-2.amazonaws.com
    ```

2. Pull the image from ECR:

    ```bash
    docker pull <aws_account_id>.dkr.ecr.<region>.amazonaws.com/porfolio-repository:latest
    # e.g.
    # docker pull 277426079602.dkr.ecr.us-east-2.amazonaws.com/porfolio-repository:latest
    ```

3. Run the container:

    ```bash
    docker run -d -p 3000:3000 <aws_account_id>.dkr.ecr.<region>.amazonaws.com/porfolio-repository:latest
    # e.g.
    # docker run -d -p 3000:3000 277426079602.dkr.ecr.us-east-2.amazonaws.com/porfolio-repository:latest
    ```

4. Access your application at `http://localhost:3000` (or the public IP of your EC2 instance).

#### **C. Run on ECS using AWS CLI**

Below are example AWS CLI commands for running your image on ECS (Fargate):

1. **Create a Cluster**  
   ```bash
   aws ecs create-cluster --cluster-name porfolio-cli-cluster
   ```

2. **Register a Task Definition**  
   Save the following JSON as `task-def.json` (recommended path: `./task-def.json` in the root path e.g -> `c:\GitHubClean\Astro\porfolio.dev\task-def.json`) (edit as needed):

   ```json
   {
     "family": "porfolio-cli-task",
     "networkMode": "awsvpc",
     "requiresCompatibilities": ["FARGATE"],
     "cpu": "256",
     "memory": "512",
     "executionRoleArn": "arn:aws:iam::<aws_account_id>:role/ecsTaskExecutionRole",
     "containerDefinitions": [
       {
         "name": "porfolio-cli-container",
         "image": "<aws_account_id>.dkr.ecr.<region>.amazonaws.com/porfolio-repository:latest",
         "portMappings": [
           {
             "containerPort": 3000,
             "hostPort": 3000,
             "protocol": "tcp"
           }
         ],
         "essential": true
       }
     ]
   }
   ```

   Register the task definition:
   ```bash
   aws ecs register-task-definition --cli-input-json file://task-def.json
   ```

3. **Create a Security Group** (if needed, to allow inbound traffic on port 3000)
   ```bash
   aws ec2 create-security-group --group-name porfolio-cli-sg --description "Allow port 3000"
   aws ec2 authorize-security-group-ingress --group-name porfolio-cli-sg --protocol tcp --port 3000 --cidr 0.0.0.0/0
   ```

4. **Run the Task (Fargate)**  
   Replace `<subnet-id>` and `<security-group-id>` with your actual subnet and security group IDs:
   ```bash
   aws ecs run-task --cluster porfolio-cli-cluster --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[subnet-0f11eb2ea1633e850],securityGroups=[sg-0a9ab0718411ed3d2],assignPublicIp=ENABLED}" --task-definition porfolio-cli-task
   ```

5. **(Recommended for Production) Create an ECS Service for Automatic Restarts and Scaling**

   To ensure your application is always running and can scale, use an ECS Service:

   ```bash
   aws ecs create-service \
     --cluster porfolio-cli-cluster \
     --service-name porfolio-cli-service \
     --task-definition porfolio-cli-task \
     --desired-count 1 \
     --launch-type FARGATE \
     --network-configuration "awsvpcConfiguration={subnets=[<subnet-id>],securityGroups=[<security-group-id>],assignPublicIp=ENABLED}"
   ```

   - Adjust `--desired-count` for the number of running tasks you want.
   - The service will automatically restart tasks if they fail and can be updated or scaled as needed.

> For production, consider using a Service (`aws ecs create-service`) for automatic restarts and scaling.
>
> **Explanation:**  
> Running a task with `aws ecs run-task` launches a one-off container that will not automatically restart if it stops or fails.  
> In production, you should use an ECS **Service** (`aws ecs create-service`) to manage your tasks.  
> An ECS Service will:
> - Automatically restart tasks if they stop or crash.
> - Maintain the desired number of running tasks.
> - Support load balancing and rolling updates.
> - Enable scaling up/down as needed.
> This ensures high availability and reliability for your application.

#### **D. (Optional) Clean Up: Remove ECS Resources**

If you want to delete all ECS resources (services, tasks, security groups, and cluster) to avoid leaving resources enabled, follow these steps:

```bash
# 1. Delete the ECS Service (if exists)
aws ecs update-service --cluster porfolio-cli-cluster --service porfolio-cli-service --desired-count 0
aws ecs delete-service --cluster porfolio-cli-cluster --service porfolio-cli-service --force

# 2. Stop and Deregister Tasks (if any are running)
# List running tasks:
aws ecs list-tasks --cluster porfolio-cli-cluster
# Stop each task:
aws ecs stop-task --cluster porfolio-cli-cluster --task <task-arn>

# 3. Delete the ECS Cluster
aws ecs delete-cluster --cluster porfolio-cli-cluster

# 4. Delete the Security Group (replace <sg-id> with your security group ID)
aws ec2 delete-security-group --group-id <sg-id>

# 5. (Optional) Delete the Task Definition (deregister all revisions)
aws ecs list-task-definitions --family-prefix porfolio-cli-task
aws ecs deregister-task-definition --task-definition <task-definition-arn>
```

> **Note:** Replace `<task-arn>`, `<sg-id>`, and `<task-definition-arn>` with your actual resource identifiers.  
> Make sure no resources are in use before deleting security groups or clusters.

---

You can choose the deployment method that best fits your needs:  
- **Netlify:** For free and easy static site hosting.  
- **S3 Bucket:** For static sites, simple and cost-effective.  
- **ECS Cluster:** For containerized deployments, more flexibility and scalability.
