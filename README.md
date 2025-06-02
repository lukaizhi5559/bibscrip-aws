# BibScrip AWS Terraform Infrastructure

BibScrip AWS Terraform Infrastructure is a comprehensive, scalable, secure, and cost-efficient Terraform configuration for deploying the BibScrip Bible Q&A application on AWS. This repository contains the Terraform code to set up the entire infrastructure with environment-aware configurations for development, staging, and production environments.

## Architecture Overview

The infrastructure is designed to support millions of users, combining LLMs with a scalable backend, dynamic frontend, and AI integration. Key components include:

### Global Content Delivery
- CloudFront distribution for static assets, frontend, and backend API routes
- S3 bucket for static asset storage with lifecycle policies
- Route53 with health checks and failover routing for high availability

### Compute Layer
- ECS Fargate for backend API with autoscaling based on CPU, memory, and request count
- Lambda functions for Bible verse lookups integrated with API Gateway
- Elastic Beanstalk for Next.js frontend with Blue/Green deployment in production

### Database & Caching
- RDS PostgreSQL with multi-AZ deployment in production
- ElastiCache Redis for session and data caching with multi-AZ in production
- DynamoDB tables for user data, metrics, and request logs with autoscaling
- DAX accelerator for DynamoDB in production

### Queueing & Async Processing
- SQS queues for request batching and background processing
- EventBridge for scheduled tasks
- Step Functions for AI request orchestration with fallback providers

### Security & Compliance
- WAF Web ACL with AWS managed rules and rate limiting
- Secrets Manager for API keys with automatic rotation in production
- IAM roles with least privilege for all services
- KMS encryption for sensitive data

### Monitoring & Observability
- CloudWatch dashboards for application overview
- CloudWatch alarms for critical metrics
- X-Ray tracing for request tracking
- CloudWatch Synthetics for API and frontend availability monitoring

### Cost Optimization
- Resource sizing appropriate for each environment
- Autoscaling to match demand
- Budget alerts for cost monitoring
- Lifecycle policies for storage optimization

### CI/CD Pipeline
- CodePipeline for continuous delivery
- CodeBuild for building and testing
- CodeDeploy for zero-downtime deployments
- GitHub integration for source control

## Repository Structure

```
├── terraform/
│   ├── modules/
│   │   ├── networking/       # VPC, subnets, security groups, etc.
│   │   ├── compute/          # ECS, Lambda, API Gateway
│   │   ├── database/         # RDS, ElastiCache, DynamoDB
│   │   ├── frontend/         # Elastic Beanstalk for frontend
│   │   │   └── cdn/          # CloudFront, S3, Route53
│   │   ├── security/         # WAF, KMS, Secrets Manager
│   │   ├── queue/            # SQS, EventBridge, Step Functions
│   │   ├── monitoring/       # CloudWatch, X-Ray, Synthetics
│   │   └── cicd/             # CodePipeline, CodeBuild, CodeDeploy
│   ├── environments/
│   │   ├── dev/              # Development environment
│   │   ├── staging/          # Staging environment
│   │   └── prod/             # Production environment
│   └── shared/               # Shared resources (e.g., ECR)
└── lambda/                   # Lambda function code
    ├── bible-lookup/
    ├── daily-cleanup/
    ├── secret-rotation/
    ├── deployment-notification/
    └── ai-providers/         # AI provider functions
```

## Module Details

### Networking Module
Manages the VPC, subnets, security groups, and network ACLs. Provides public, private, and database subnet tiers across multiple availability zones.

### Compute Module
Manages ECS Fargate for the backend API, Lambda functions for Bible verse lookups, and API Gateway. Includes autoscaling policies based on CPU, memory, and request count.

### Database Module
Manages RDS PostgreSQL, ElastiCache Redis, and DynamoDB tables. Includes backups, read replicas in production, and encryption.

### Frontend Module
Manages Elastic Beanstalk for the Next.js frontend application with environment-specific configurations.

### Frontend CDN Module
Manages CloudFront distribution, S3 bucket for static assets, and Route53 DNS records. Includes WAF integration and origin failover.

### Security Module
Manages KMS keys for encryption, WAF Web ACL with AWS managed rule groups, and Secrets Manager for API keys with rotation.

### Queue Module
Manages SQS queues for request batching and background processing, EventBridge for scheduled tasks, and Step Functions for AI request orchestration.

### Monitoring Module
Manages CloudWatch dashboards, alarms, X-Ray tracing, Synthetics canaries, and AWS Budgets. Includes SNS notifications for alerts.

### CI/CD Module
Manages CodePipeline, CodeBuild, CodeDeploy, and GitHub integration for continuous delivery. Includes deployment notifications.

## Getting Started

### Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform v1.5.0 or later
- Git
- Access to GitHub repository
- Valid domain name with Route53 hosted zone
- ACM certificate for your domain

### Initial Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/bibscrip-aws.git
   cd bibscrip-aws
   ```

2. Create a `terraform.tfvars` file in the target environment directory based on the example:
   ```bash
   cd terraform/environments/dev
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Edit the `terraform.tfvars` file with your specific values.

4. Create and upload Lambda function ZIP files to the specified paths.

5. Initialize Terraform:
   ```bash
   terraform init
   ```

6. Validate the configuration:
   ```bash
   terraform validate
   ```

7. Plan the deployment:
   ```bash
   terraform plan -out=tfplan
   ```

8. Apply the configuration:
   ```bash
   terraform apply tfplan
   ```

### Environment-Specific Deployments

The repository supports different environments (dev, staging, prod) with environment-specific configurations:

- **Development**: Lower resource requirements, non-critical alerting, minimal redundancy
- **Staging**: Similar to production with smaller instance sizes
- **Production**: Full redundancy, multi-AZ deployments, strict security, comprehensive monitoring

To deploy to a specific environment:

```bash
cd terraform/environments/[dev|staging|prod]
terraform init
terraform apply
```

## CI/CD Pipeline Setup

The CI/CD pipeline is set up to automatically deploy changes to the appropriate environment based on the branch:

- `develop` branch → Development environment
- `staging` branch → Staging environment
- `main` branch → Production environment

To set up the pipeline:

1. Create the required branches in your GitHub repository
2. Deploy the infrastructure including the CI/CD module
3. Connect the GitHub repository to AWS CodeStar
4. Push changes to the appropriate branch to trigger deployments

## Security Best Practices

- All sensitive data is encrypted at rest and in transit
- API keys are stored in Secrets Manager with automatic rotation in production
- IAM roles follow the principle of least privilege
- WAF protects against common web exploits and DDoS attacks
- Security groups restrict traffic to only necessary ports
- Multi-factor authentication is required for AWS Console access

## Monitoring and Alerts

The infrastructure includes comprehensive monitoring and alerting:

- CloudWatch dashboards provide an overview of all components
- CloudWatch alarms trigger on critical metrics
- X-Ray traces API requests for debugging
- Synthetics canaries check API and frontend availability
- Budget alerts notify when costs exceed thresholds

## Cost Optimization

- Resources are sized appropriately for each environment
- Autoscaling adjusts capacity to match demand
- Lifecycle policies manage storage costs
- Reserved Instances can be used in production for predictable workloads
- Budget alerts provide early warning of cost issues

## Troubleshooting

### Common Issues

1. **Terraform Apply Fails**: Check the error message and ensure all required variables are set correctly in `terraform.tfvars`.

2. **Pipeline Deployment Fails**: Check the CodeBuild logs for build errors or the CodeDeploy logs for deployment errors.

3. **API Errors**: Check the CloudWatch logs for the ECS service and Lambda functions.

4. **Frontend Issues**: Check the Elastic Beanstalk logs and CloudFront distribution settings.

## Contributing

1. Create a feature branch from `develop`
2. Make your changes
3. Submit a pull request to `develop`

## License

This project is licensed under the MIT License - see the LICENSE file for details.
