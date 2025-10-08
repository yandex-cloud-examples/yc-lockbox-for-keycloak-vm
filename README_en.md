# Yandex Cloud Lockbox password solution

This is a scenario for deploying KeyCloak as an IdP with username/password storage and retrieval in Yandex Cloud Lockbox.

# Issue

When running Keycloak on a VM as a service, you need to specify the DB username and password, as well as the admin credentials in plain text in the `/lib/systemd/system/keycloak.service` configuration. In typical deployment of such scenarios, you also need to provide secrets in your user data in plain text.

# Solution

A service account assigned to a VM can authenticate and authorize to IAM from within a guest OS in a simplified way: all you need to do is get an IAM token via `yc cli` or REST API without providing any information about the subject. This is how you can safely transmit a key-value pair (secret part) from Lockbox to the guest OS using a service account with the minimum required permissions.

# Secure configuration

<img width="441" alt="solution_schema" src="https://user-images.githubusercontent.com/85429798/188415570-30edb050-03f4-47be-9ac8-9bab52968288.png">

1. The service account accesses the Lockbox secret via REST.
1. Lockbox verifies permissions for both the secret and the key, and decrypts the secret.
1. The secret is returned to the guest OS as a JSON file.

After deployment, the script deletes all intermediate secret files and the service account.

# Environment setup

We assume you already have access to Yandex Cloud and know the IDs of your cloud (`cloud-id`) and [folder](https://yandex.cloud/docs/resource-manager/operations/folder/get-id) (`folder-id`) where you will be creating cloud resources.

## Installing YC CLI

To deploy the working environment, you need to install Yandex Cloud CLI (`yc`) on your computer (see [this step-by-step guide](https://yandex.cloud/docs/cli/operations/install-cli#interactive)).

## Installing Git

To retrieve Terraform configuration, install Git following [this guide](https://git-scm.com/book/ru/v2/Введение-Установка-Git).
 
## Installing Terraform

Install `Terraform` on your computer (if not done yet) following [this guide](https://yandex.cloud/docs/tutorials/infrastructure-management/terraform-quickstart#install-terraform).

### Installing Terraform for Windows

Unpack the archive and copy `terraform.exe` to `C:\Windows\System32`.

To properly install all required Terraform resources, create a file named `.terraformrc` (`terraform.rc` for Windows) in your home directory (`/home/<username>` for macOS and Linux, and `C:\Users\Administrator\AppData\Roaming` for Windows). This file must contain the following:

```bash
provider_installation {
    network_mirror {
      url = "https://terraform-mirror.yandexcloud.net/"
      include = ["registry.terraform.io/*/*"]
    }
    direct {
      exclude = ["registry.terraform.io/*/*"]
    }
  }
```

## Connecting to the Yandex Cloud web console

* [Connecting to the Yandex Cloud web console using Yandex ID (option A)](#yandex-id)
* [Connecting to the Yandex Cloud web console using an identity federation in the organization service (option B)](#federation-id)

### Connecting to the Yandex Cloud web console using Yandex ID (option A)

* Open a new browser tab and navigate to the [Yandex Cloud console](https://console.yandex.cloud/). At the bottom left, select **Account** and log out of all current accounts. The screen will now display a page saying **Log in to your Yandex account**. Close this page.
* In a new browser tab, open [this link](https://passport.yandex.ru/auth?mode=add-user&retpath=https%3A%2F%2Fconsole.yandex.cloud%2F) where you will be prompted to log in with your Yandex ID.
* Once you enter your Yandex ID credentials, you will be redirected to the Yandex Cloud console.
* Use [this link](https://oauth.yandex.ru/authorize?response_type=token&client_id=1a6990aa636648e9b2ef855fa7bec2fb) to get an OAuth token. The token value will look like this: `AQAAAAAABQ0pAATrwPdubkJPerC4mJyaRELWbUY`.
* Save your token value to an environment variable (use PowerShell for Windows and Bash for macOS and Linux).

#### Windows:

```PowerShell
$env:YC_TOKEN="<your_OAuth_token>"
```

#### macOS and Linux:

```bash
export YC_TOKEN=<your_OAuth_token>
```

Create a YC profile to access Yandex Cloud.

#### Configuring your YC profile in macOS and Linux:

```bash
yc config profile create lockbox
yc config set cloud-id <cloud-id>
yc config set folder-id <folder-id>
yc config set token $YC_TOKEN
```

#### Configuring your YC profile in Windows:

```PowerShell
yc config profile create lockbox
yc config set cloud-id <cloud-id>
yc config set folder-id <folder-id>
yc config set token $env:YC_TOKEN
```

Replace `<cloud-id>` with your cloud ID and `<folder-id>`, with the folder ID in the cloud. You can get these through the Yandex Cloud management console web UI.

### Connecting to the Yandex Cloud web console using an identity federation in Yandex Cloud Organization (option B)

* Create a YC profile to access Yandex Cloud:
  ```bash
  yc config profile create lockbox
  yc config set cloud-id <cloud-id>
  yc config set folder-id <folder-id>
  yc config set federation-id <federation-id>
  ```
  Replace \<cloud-id\> with your cloud ID, e.g., `b1g8d7gjpvedf23hg3sv`, \<folder-id\>, with the folder ID in the cloud, e.g., `b1guv7crr32qfgiimxwp`, and \<federation-id\> with the federation ID, e.g., `yc.your-org-name.federation`. You can get these through the Yandex Cloud management console web UI in the **Organizations** section.
 
### Uploading Terraform configuration

```bash
git clone https://github.com/Sayanaro/YandexCloud-Security-Course-KeyCloackVersion.git
cd YandexCloud-Security-Course-KeyCloackVersion
```
 
## Deploying a working environment using Terraform

`terraform.tfvars` contains VM names, domain names, and usernames specified as variables. Other variables are predefined with default values in `variables.tf`.

As a first step, define the environment variables:
 
### If using Yandex ID:

#### Windows:
 
* Start PowerShell.
* Run the following command:

```PowerShell
yc config profile activate security
$env:YC_TOKEN = "your OAuth token"
$env:YC_CLOUD_ID=$(yc config get cloud-id)
$env:YC_FOLDER_ID=$(yc config get folder-id)
```

#### MacOS/Linux:
 
* Start Bash.
* Run the following command:

```bash
yc config profile activate security
export YC_TOKEN="your OAuth token"
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)
```

### If using a federated account:

#### Windows:
 
* Start PowerShell.
* Run the following command:

```PowerShell
yc config profile activate security
$env:YC_TOKEN = $(yc iam create token)
$env:YC_CLOUD_ID=$(yc config get cloud-id)
$env:YC_FOLDER_ID=$(yc config get folder-id)
```

#### MacOS/Linux:
 
* Start Bash.
* Run the following command:

```bash
yc config profile activate security
export YC_TOKEN=$(yc iam create token)
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)
```

### Initializing and running the scenario

Initialize Terraform:

```bash
terraform init
terraform apply
```

In this example, you will be prompted to enter two passwords: the admin password and the PostgreSQL DB admin password. The password must be at least 8 characters long and include both uppercase and lowercase letters, at least one number (0-9), and at least one special character (@#$%&*/:;"'\,.?+=-_).

The server will be configured and ready to go four minutes after the scenario is complete.

## Connecting to a VM

```bash
# keycloak:
ssh ubuntu@<keycloak_vm_public_ip> -i pt_key.pem
```
