The following describes the current status of building and booting a
NixOS image for MAAS. Building works but booting the image results in
the error described below:

1. Build the image as follows:
```
imgdir=$(nix-build test-maas-img.nix --no-link)
```

2. Upload it to a MAAS server you have SSH access to:
```
scp $imgdir/nixos-20.09pre-git-x86_64-linux.tgz  me@maas:/home/me/nixos-20.09pre-git-x86_64-linux.tgz
```

3. Login to maas via the CLI:
```
maas login me http://maas:5240/MAAS/api/2.0
```

4. Upload the image to MAAS:
```
maas me boot-resources create \
  name=nixos \
  title=”NixOS” \
  architecture=amd64/generic \
  content@=/home/me/nixos-20.09pre-git-x86_64-linux.tgz \
  filetype=ddtgz
```

5. Deploy a machine with the custom "NixOS" image.

6. Observe in the machine log that the installation failed with the
   following error:

```
Did not find any filesystem on ['sda'] that contained one of ['curtin', 'system-data/var/lib/snapd']
```
