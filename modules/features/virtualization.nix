{ self, inputs, ... }: {
  flake.nixosModules.virtualization = { config, lib, ... }: {
    virtualisation.podman = {
      enable = true;
      # Provide a `docker` CLI that talks to podman, and a docker socket for
      # tools that expect the Docker daemon API.
      dockerCompat = true;
      dockerSocket.enable = true;
    };
  };
}
