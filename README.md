# MiniStack cloud labs

The first lab uses Terraform and IAM to give a learner read-only access to a single S3 object.

<img width="1920" height="1020" alt="image" src="https://github.com/user-attachments/assets/4b9df980-121e-4cd7-bc05-8100ff021a02" />


## Open the lab in VS Code

Start a Linux container engine and make sure its Compose command works.

| Engine | Setup |
| --- | --- |
| Docker | Run `docker compose version`. On Windows, use Linux containers. |
| OrbStack | On macOS, run `docker context use orbstack`, then `docker compose version`. |
| Podman | On Windows or macOS, start your Podman machine. Make sure `podman compose version` works with an installed Compose provider. |

If you use Podman with the `podman-compose` provider, set these VS Code user settings. Both commands should be available where VS Code runs.

```json
{
  "dev.containers.dockerPath": "podman",
  "dev.containers.dockerComposePath": "podman-compose",
  "dev.containers.mountWaylandSocket": false
}
```

1. Install the [VS Code Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).
2. Open this project folder and choose **Dev Containers: Reopen in Container** from the Command Palette.
3. Open [the lab site](http://localhost:4000) and select **Least-privilege access to S3**. Edit the exercise in VS Code and run the walkthrough in its integrated Bash terminal. The exercise opens at `/lab`.

## Run from a terminal

From the project folder, use the command pair for your engine.

```sh
docker compose up -d --build
docker compose exec lab bash
```

```sh
podman compose up -d --build
podman compose exec lab bash
```

Open the same lab site and follow the walkthrough in the Linux shell. With VS Code you can also choose **Dev Containers: Attach to Running Container**, select the lab container, and open `/lab`.

## Resume or clean up

Compose volumes keep the learner's files, Terraform state, and MiniStack data across normal shutdowns. The exercise starts from the files baked into the lab image. Edits in `/lab` are saved in the exercise volume. Rebuilding refreshes the site and starter files in the image. Existing learner files take precedence.

Run `terraform destroy` from `/lab` before stopping the stack when you finish the exercise. Close the Dev Container window, or run `docker compose down` or `podman compose down` from the host. Keep the volumes to resume later with the same engine and Compose project.

The first image build and `terraform init` download dependencies. The Linux image supplies Terraform, AWS CLI v2, Bash, and the built Labforge site. MiniStack is reachable inside the Compose network, and only the site is published to the host loopback interface.
