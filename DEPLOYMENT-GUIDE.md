# EKS Terraform deployment (GitHub Actions secrets)

This project provisions the architecture defined by the original Terraform files: VPC, two public and two private subnets, IGW/NAT, EKS and managed nodes, NGINX Ingress, cert-manager, EFS, and Argo CD.

## Before first deployment

1. Create an S3 bucket in `us-west-1` for Terraform state. Use a globally unique name. Enable S3 Block Public Access, default encryption, and bucket versioning. Do not put public access policies on this bucket.
2. Create a dedicated IAM deployment identity in AWS. Do not use root access keys. Grant the permissions required to create/manage this lab's VPC, EC2, EKS, IAM roles/policies and pass roles, EFS, S3, and related resources. For a learning sandbox, temporary AdministratorAccess is broad and should be removed/replaced after deployment.
3. In GitHub repository Settings → Secrets and variables → Actions, add repository secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `TF_STATE_BUCKET` (the exact S3 bucket name from step 1)
4. Ensure `TF_STATE_BUCKET` names a bucket in `us-west-1`; the workflow uses it both for Terraform state and the kubeconfig object.
5. Review `variables.tf`. The default region is `us-west-1`. The default EKS public endpoint CIDR is `0.0.0.0/0` to allow GitHub-hosted runners with changing egress IPs to reach the API. This exposes the API endpoint publicly (IAM authentication is still required); for stronger security, use a self-hosted runner/private endpoint or a GitHub runner with fixed egress IPs and restrict `cluster_endpoint_public_access_cidrs`.
6. Replace `argocd.digitalwitch.online` and the host in `manifests/argocd-ingress.yaml` / `car-test/car-ingress.yaml` if you do not control that domain. Set the DNS records to the NGINX load balancer hostname after deployment. Let's Encrypt will not issue a certificate until DNS and HTTP reachability are correct.
7. Review `security_group_ingress_cidr` in `variables.tf`; use your own public IP with `/32` rather than `0.0.0.0/0` if the security group is used. The current SG is not explicitly attached to the EKS nodes in this project.

## Local static checks (Windows PowerShell)

From the extracted project root:

```powershell
terraform --version
terraform fmt -recursive
terraform init -backend=false
terraform validate
```

These commands do not create AWS infrastructure. Commit the formatting changes, if any, before pushing.

## Deploy through GitHub Actions

1. Push the repository to GitHub with the default branch named `main`.
2. Add the three repository secrets listed above.
3. Push the reviewed code to `main`, or use Actions → Terraform EKS deployment → Run workflow.
4. Watch the workflow. It applies the AWS foundation first because the Helm/Kubernetes providers depend on the EKS endpoint, then applies the complete configuration.
5. After success, inspect the workflow verification output and AWS Console. Terraform may create billable resources including EKS, EC2, NAT Gateway, EFS, and a load balancer.

## Important

- Never commit AWS credentials, private keys, `terraform.tfstate`, or kubeconfig files.
- The workflow intentionally contains no destroy job. Do not add an automatic destroy job to push-triggered workflows.
- This workflow uses long-lived IAM access keys because that is the requested authentication method. GitHub OIDC with short-lived role credentials is safer for a production setup.
- The Terraform root uses a two-stage apply. The first targeted apply is intentional so EKS exists before Kubernetes/Helm resources are planned. Review the plan output before authorizing deployment in a production account.
