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

### Image Creation for Backend server
1. Launch an Amazon Linux 2023 EC2 instance and attach created IAM EC2 role to it.
2. Connect to instance using System Session Manager (SSM)
3. Switch to EC2 user
4. Install necessary components to run backend application
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
source ~/.bashrc
```
5. Install a compatible version of Node.js and make sure it's being used
```bash
nvm install 16
nvm use 16
```
6. PM2 is a daemon process manager that will keep our node.js app running when we exit the instance or if it is rebooted. Install that as well
```bash
nvm install 16
nvm use 16
```
7. Now we need to download our code from our S3 buckets into our instance. In the command below, replace BUCKET_NAME with the name of the bucket in which you have uploaded application code
```bash
cd ~/
aws s3 cp s3://BUCKET_NAME/app-tier/ app-tier --recursive
```
8. Navigate to the app directory, install dependencies, and start the app with pm2
```bash
cd ~/app-tier
npm install
pm2 start index.js
```
9. To make sure the app is running correctly run the following:
```bash
pm2 list
```
> If you see a status of online, the app is running
10. Also Run following commands, this will install mysql CLI which we need to use at the end to configure database.
```bash
sudo wget https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
sudo yum install https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm -y
sudo yum install mysql -y
``` 
11. Now create image from this instance

## Terraform Execution

1. Clone 'AWS-Three-Tier-Web-Architecture-using-Terraform' respository into local directory
2. Open code in code editor of your choice. (Recommended VS Code)
Make necessary changes in 'terraform.tfvars' file. Change resource names and parameters according to your choice. **Make sure to give same name to IAM role and AMI's which you have created in your AWS account**

3. Run below command, this will download required provider plugins and modules
```bash
terraform init
```
4. After that run below command, this will provide brief information of resources to be created
```bash
terraform plan
```
5. Then run bewlo command, it will create planned resources in AWS
```bash
terraform apply -auto-approve
```
> Infrastructure creation will take around 15-20 minutes

## Application Configuration

### Connect to Frontend servers using SSM and execute below steps in both servers:
1. Download nginx.conf file from our s3 bucket using below command
```bash
sudo aws s3 cp s3://BUCKET_NAME/nginx.conf .
```
> Replace bucket name with the one you have created
2. Open downloaded nginx.conf file in 'vi editor' and copy internal load balancer dns as shown below:
 * ![ReplaceCode](https://github.com/user-attachments/assets/d20de8b2-478f-4351-b81e-78b9d7e2937c)
> Make sure to remove parenthesis
3. First you have to remove existing nginx.conf file
```bash
cd /etc/nginx
ls
sudo rm nginx.conf
```
4. Go to directory where you have kept your modified nginx.conf file and copy to /etc/nginx
```bash
cp nginx.conf /etc/nginx
```
5. Now restart and enable nginx
```bash
sudo systemctl restart nginx
sudo systemctl enable nginx
```
6. To make sure Nginx has permission to access our files execute this command:
```bash
chmod -R 755 /home/ec2-user
```
### Connect to Backend servers using SSM and execute below steps in both servers:
1. PM2 is just making sure our app stays running when we leave the SSM session. However, if the server is interrupted for some reason, we still want the app to start and keep running
```bash
pm2 startup
```
> After running above command you will see a message similar to this.
```bash
To setup the Startup Script, copy/paste the following command: sudo env PATH=$PATH:/home/ec2-user/.nvm/versions/node/v16.0.0/bin /home/ec2-user/.nvm/versions/node/v16.0.0/lib/node_modules/pm2/bin/pm2 startup systemd -u ec2-user —hp /home/ec2-user
```
> whatever message like this displayed in your terminal after **pm2 startup command**, you have to copy that and run that as a command
2. After you run it, save the current list of node processes with the following command:
```bash
pm2 save
```
3. Open this file 'app-tier/DbConfig.js' and make required changes as shown below
 * ![image](https://github.com/user-attachments/assets/3f6fd266-e189-4414-b4f7-c1081942ec46)
4. Now you have to connect to database and add some data in it. From this step, no need to execute below steps on both backend servers. Only one server is enough
5. Initiate your DB connection. In the following command, replace the RDS endpoint and the username, and then execute it in the terminal:
```bash
mysql -h CHANGE-TO-YOUR-RDS-ENDPOINT -u CHANGE-TO-USER-NAME -p
```
> You will then be prompted to type in your password. Once you input the password and hit enter, you should now be connected to your database.
6. Create a database called webappdb with the following command
```bash
CREATE DATABASE webappdb; 
```
> You can verify that it was created correctly with the following command:
```bash
SHOW DATABASES;
```
7. Create a data table by first navigating to the database we just created:
```bash
USE webappdb;    
```
> Then, create the following transactions table by executing this create table command:
```bash
CREATE TABLE IF NOT EXISTS transactions(id INT NOT NULL
AUTO_INCREMENT, amount DECIMAL(10,2), description
VARCHAR(100), PRIMARY KEY(id));       
```
> Verify the table was created:
```bash
SHOW TABLES;     
```
8. Insert data into table for use/testing later:
```bash
INSERT INTO transactions (amount,description) VALUES ('400','groceries');   
```
> Verify that your data was added by executing the following command:
```bash
SELECT * FROM transactions;  
```
9. When finished, just type exit and hit enter to exit the MySQL client.


## Testing Web Application

To test the app, copy **internet facing load balancer DNS** and paste in browser. You should able to access the app and add or remove rows from list.


## To Clean infrastruture

1. Open terraform code and run below command in terminal, this will destroy terraform created resources
```bash
terraform destroy -auto-approve
```
> this will take 15-20 min
2. Go to AWS Management Console > EC2 Section > AMI's Section. Now delete the created AMI's. Also go to the snapshots section and delete snapshots if any.
3. You can also delete created IAM role by navigating to: IAM > Roles



