repo = "spritsail/acme.sh"
architectures = ["amd64", "arm64"]
publish_branches = ["master"]
publish_events = ["push"]

def main(ctx):
  builds = []
  depends_on = []

  for arch in architectures:
    key = "build-%s" % arch
    builds.append(step(arch, key))
    depends_on.append(key)

  if ctx.build.branch in publish_branches and ctx.build.event in publish_events:
    builds.extend(publish(depends_on))
    builds.append(update_readme())

  return builds

def step(arch, key):
  return {
    "kind": "pipeline",
    "name": key,
    "platform": {
      "os": "linux",
      "arch": arch,
    },
    "steps": [
      {
        "name": "build",
        "image": "registry.spritsail.io/spritsail/docker-build",
        "pull": "always",
      },
      {
        "name": "test",
        "image": "drone/${DRONE_REPO}/${DRONE_BUILD_NUMBER}:${DRONE_STAGE_OS}-${DRONE_STAGE_ARCH}",
        "pull": "never",
        "command": ["acme.sh", "--version"],
      },
      {
        "name": "publish",
        "pull": "always",
        "image": "registry.spritsail.io/spritsail/docker-publish",
        "settings": {
          "registry": {"from_secret": "registry_url"},
          "login": {"from_secret": "registry_login"},
        },
        "when": {
          "branch": publish_branches,
          "event": publish_events,
        },
      },
    ],
  }

def publish(depends_on):
  return [
    {
      "kind": "pipeline",
      "name": "publish-manifest-%s" % name,
      "depends_on": depends_on,
      "platform": {
        "os": "linux",
      },
      "steps": [
        {
          "name": "publish",
          "image": "registry.spritsail.io/spritsail/docker-multiarch-publish",
          "pull": "always",
          "settings": {
            "tags": [
              "latest",
              "%label io.spritsail.version.acme-sh | %auto"
            ],
            "src_registry": {"from_secret": "registry_url"},
            "src_login": {"from_secret": "registry_login"},
            "dest_registry": registry,
            "dest_repo": repo,
            "dest_login": {"from_secret": login_secret},
          },
          "when": {
            "branch": publish_branches,
            "event": publish_events,
          },
        },
      ],
    }
    for name, registry, login_secret in [
      ("dockerhub", "index.docker.io", "docker_login"),
      ("spritsail", "registry.spritsail.io", "spritsail_login"),
      ("ghcr", "ghcr.io", "ghcr_login"),
    ]
  ]

def update_readme():
  return {
    "kind": "pipeline",
    "name": "update-readme-dockerhub",
    "depends_on": [
      "publish-manifest-dockerhub",
    ],
    "steps": [
      {
        "name": "dockerhub-readme",
        "pull": "always",
        "image": "jlesage/drone-push-readme",
        "settings": {
          "repo": repo,
          "username": {"from_secret": "docker_username"},
          "password": {"from_secret": "docker_password"},
        },
        "when": {
          "branch": publish_branches,
          "event": publish_events,
        },
      },
    ],
  }
