# AWS-Three-Tier-Web-Architecture-using-Terraform

![image](https://github.com/user-attachments/assets/fe64f954-9c59-4628-953e-29a5326eca38)

In this architecture, a public-facing Application Load Balancer forwards client traffic to our web tier EC2 instances. The web tier is running Nginx webservers that are configured to serve a React.js website and redirects our API calls to the application tier’s internal facing load balancer. The internal facing load balancer then forwards that traffic to the application tier, which is written in Node.js. The application tier manipulates data in an Aurora MySQL multi-AZ database and returns it to our web tier. Load balancing, health checks and autoscaling groups are created at each layer to maintain the availability of this architecture.

## Pre-Requisites

1. Configure IAM Profile in AWS CLI
2. Download Amazon sample application code by running below command in your local diretory
```bash
git clone https://github.com/aws-samples/aws-three-tier-web-architecture-workshop.git
```
3. Create an IAM role for EC2 with below policies
* AmazonSSMManagedInstanceCore (For using Systems Session Manager to securely connect to our instances without SSH keys through the AWS console)
* AmazonS3ReadOnlyAccess (To download our code from S3)
  * ![image](https://github.com/user-attachments/assets/6385c254-ba18-4ad0-846d-89ea2089ded7)
  * ![image](https://github.com/user-attachments/assets/de1122c5-e48c-4087-835f-bf3576c0e08c)
  * ![image](https://github.com/user-attachments/assets/d0b6e361-b574-4a61-b595-1ab347f11cae)
  * ![image](https://github.com/user-attachments/assets/a9dc7184-5998-40e6-8ff2-b5016360983b)
5. Create S3 bucket and upload above code into bucket same like below format
![image](https://github.com/user-attachments/assets/2fb83586-b385-4f5c-a69b-475c889fca0b)
6. Create two Golden Images for Frontend & Backend server by using AWS Management Console. We need this images while executing terraform code. Please check steps below 

### Image Creation for Frontend server

1. Launch an Amazon Linux 2023 EC2 instance in default network configuration and attach above created EC2 role to instance
2.  Connect to instance using System Session Manager (SSM)
3. Switch to EC2 user by using below command
```bash
sudo su - ec2-user
```
4. Make sure we are able to reach internet
```bash
ping google.com
```
5. We need to install all the necessary componenrts needed to run our frontend application. Start with NVM and node
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
source ~/.bashrc
nvm install 16
nvm use 16
```
> Run above commands one by one
6. Now we need to download our code from our S3 buckets into our instance. In the command below, replace BUCKET_NAME with the name of the bucket in which you have uploaded application code
```bash
cd ~/
aws s3 cp s3://BUCKET_NAME/web-tier/ web-tier --recursive
```
7. Navigate to the web-layer folder and create the build folder for the react app so we can serve our code:
```bash
cd ~/web-tier
npm install 
npm run build
```
8. Now we need to install web server
```bash
sudo yum install nginx -y
```
9. Then start the web server and we have to make sure to enable auto-start of web server during system boot
```bash
sudo systemctl start nginx
sudo systemctl enable nginx
```
10. Check the status of the web server
```bash
sudo systemctl status nginx
```
11. Web Tier Server is ready, now create golden image of this server. Wait for image to become available, after that you can safely terminate the instance.
    * ![image](https://github.com/user-attachments/assets/cd1e9b88-9583-446d-9123-f0f0277266e6)
    * ![image](https://github.com/user-attachments/assets/f3efaec2-a164-4a22-bee2-197470ab4add)
12. We have to modify our nginx.conf file in our frontend servers after executing terraform code and infrastructure creation at the end
