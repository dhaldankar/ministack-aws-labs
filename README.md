# MiniStack cloud labs

Practice AWS configuration and troubleshooting in a Linux workspace with MiniStack, Terraform, and the AWS CLI.

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
3. Open `START-HERE.md` in the Explorer and visit [the lab catalog](http://localhost:4000). Start with **Orientation** or choose another exercise. Follow its walkthrough in the integrated Bash terminal.

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

Use `lab list` to see available IDs. Each walkthrough gives you the command to start the lab and enter its directory. Starting a lab creates its directory under `/lab`. Starting it again resumes the existing copy. Run `lab check <id>` when the walkthrough calls for it.

Compose volumes keep your files, Terraform state, and MiniStack data across normal shutdowns. If you started the S3 lab before the multi-lab workspace was introduced, its start command returns the existing `/lab` directory so you can resume in place.

Run the walkthrough's cleanup commands from its working directory. Close the Dev Container window, or run `docker compose down` or `podman compose down` from the host. Keep the volumes to resume later with the same engine and Compose project.

The first image build and `terraform init` download dependencies. The Linux image supplies Terraform, AWS CLI v2, Bash, and the built Labforge site. MiniStack is reachable inside the Compose network, and only the site is published to the host loopback interface.

## Add a lab

Add a source folder under `labs/` named `NN_<id>`, such as `labs/01_orientation/` or `labs/04_s3-least-privilege/`. Use a unique position from `01` to `99` and a lowercase, hyphenated ID. Positions can skip numbers for labs that are still pending. The browser catalog and `lab list` follow the numeric order.

Put the walkthrough in `lab.md` with a single-line title and the unprefixed ID in its front matter. Put learner-editable files in `starter/` and the checker in `check.sh`. The checker runs from the learner's working directory and can read fixtures through `$LAB_SOURCE_DIR`. Rebuild to publish the new folder. Commands such as `lab start s3-least-privilege`, browser URLs, and saved workspaces all use the stable ID. See [the curriculum plan](LAB_PLAN.md) for upcoming exercises.
