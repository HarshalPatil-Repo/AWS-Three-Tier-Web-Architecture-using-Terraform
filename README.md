# AWS-Three-Tier-Web-Architecture-using-Terraform

![image](https://github.com/user-attachments/assets/fe64f954-9c59-4628-953e-29a5326eca38)

In this architecture, a public-facing Application Load Balancer forwards client traffic to our web tier EC2 instances. The web tier is running Nginx webservers that are configured to serve a React.js website and redirects our API calls to the application tier’s internal facing load balancer. The internal facing load balancer then forwards that traffic to the application tier, which is written in Node.js. The application tier manipulates data in an Aurora MySQL multi-AZ database and returns it to our web tier. Load balancing, health checks and autoscaling groups are created at each layer to maintain the availability of this architecture.

## Pre-Requisites

1. Configure IAM Profile in AWS CLI
2. Download Amazon sample application code by running below command in your local diretory
```bash
  git clone https://github.com/aws-samples/aws-three-tier-web-architecture-workshop.git

```
2. Create S3 bucket and upload above code into bucket same like below format
![image](https://github.com/user-attachments/assets/2fb83586-b385-4f5c-a69b-475c889fca0b)
4. Create two Golden Images for Frontend & Backend server by using AWS Management Console. We need this images while executing terraform code. Please check steps below 
