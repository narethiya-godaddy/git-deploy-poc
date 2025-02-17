# GoDaddy GitHub Action for Wordpress deployment

## Overview

This GitHub Action automates WordPress deployment using `rsync` over SSH. It creates a tar archive of modified files, transfers it to the remote server, and executes a deployment script. The action supports post-deployment commands, WordPress health checks, and automatic rollback in case of failures.

## Features

- **Deploy only changed files** using `rsync --checksum`
- **Remove deleted files** from the repository on the server
- **Execute post-deployment commands**
- **Perform WordPress health checks** and rollback if necessary
- **Secure authentication** via SSH private key

## Usage

### 1. **Add the Action to Your Workflow**

Create a `.github/workflows/deploy.yml` file in your repository:

```yaml
name: Deploy WordPress

on:
  workflow_dispatch:
    inputs:
      deployment_dest:
        description: 'Target server directory, leave blank for root directory'
        required: false
      enable_health_check:
        description: 'Enable wordpress health check?'
        type: choice
        required: false
        default: "yes"
        options:
          - "yes"
          - "no"
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Deploy using GitHub Action
        uses: your-org/your-action-repo@v1
        with:
          remote_host: ${{ secrets.REMOTE_HOST }}
          ssh_user: ${{ secrets.SSH_USER }}
          ssh_private_key: ${{ secrets.SSH_PRIVATE_KEY }}
          deployment_dest: ${{ github.event.inputs.deployment_dest }}
          enable_health_check: ${{ github.event.inputs.enable_health_check }}
```

## Inputs

| Name                    | Description                          | Required | Default |
| ----------------------- | ------------------------------------ | -------- | ------- |
| `remote_host`           | The remote server IP or domain       | ✅ Yes    | -       |
| `ssh_user`              | SSH username for authentication      | ✅ Yes    | -       |
| `ssh_private_key`       | SSH private key for authentication   | ✅ Yes    | -       |
| `deployment_dest`       | Remote WordPress directory           | ❌ No     | `.`     |
| `post_deploy_commands`  | Commands to run after deployment     | ❌ No     | `''`    |
| `cleanup_deleted_files` | Remove deleted files from the server | ❌ No     | `yes`   |
| `enable_health_check`   | Perform a WordPress health check     | ❌ No     | `yes`   |

## Requirements

- **Enable Git Deployment** for site from GoDaddy interface
- **GitHub secrets configured** for `REMOTE_HOST`, `SSH_USER`, and `SSH_PRIVATE_KEY`

## Troubleshooting

### SSH Key Issues

Ensure the private key format is correct and matches the server's authorized keys:

```bash
cat ~/.ssh/id_rsa | base64
```

Set the output as `SSH_PRIVATE_KEY` in GitHub Secrets.

## License

This action is licensed under the MIT License.

## Contributing

Feel free to open issues or submit PRs for improvements!

## Support

For help, open an issue in the repository.

